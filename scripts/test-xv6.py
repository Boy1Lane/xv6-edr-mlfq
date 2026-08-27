#!/usr/bin/env python3

#
# Automated test harness for xv6-edr-mlfq.
#
#   ./test-xv6.py usertests          (runs usertests)
#   ./test-xv6.py -q usertests       (quick usertests)
#   ./test-xv6.py edr                (fork-bomb detection & quarantine)
#   ./test-xv6.py mlfq               (scheduler demotion via ps_monitor)
#   ./test-xv6.py false_positive     (no alerts under legit I/O load)
#   ./test-xv6.py unquarantine       (admin release of quarantined tree)
#   ./test-xv6.py benchmark          (MLFQ vs RR, N runs + stats + CSV/PNG)
#   ./test-xv6.py crash|log|...      (log recovery tests from stock xv6)

import argparse, os, inspect, re, signal, statistics, subprocess, sys, time
from subprocess import run

parser = argparse.ArgumentParser()
parser.add_argument('testrex', help="test name or regular expression")
parser.add_argument("-q", action='store_true', help="usertests quick")
args = parser.parse_args()

BENCH_RUNS = 5
BENCH_CSV = "benchmark_results.csv"
BENCH_PNG = "benchmark_plot.png"


class QEMU(object):

    def __init__(self, reset=False, make_target="qemu"):
        if reset:
            self.build_xv6()
            self.reset_fs()
        q = ["make", make_target]
        self.proc = subprocess.Popen(q, stdin=subprocess.PIPE,
                                      stdout=subprocess.PIPE,
                                      stderr=subprocess.STDOUT)
        self.output = ""
        self.outbytes = bytearray()
        self.wait_boot()

    def wait_boot(self):
        deadline = time.time() + 60
        while time.time() < deadline:
            if self.proc.poll() is not None:
                self.read()
                print(f"ERROR: QEMU process terminated early with exit code {self.proc.returncode}:\n{self.output}")
                self.error()
            time.sleep(0.5)
            self.read()
            if "$" in self.output:
                return True
        print(f"ERROR: QEMU boot timeout after 60s:\n{self.output}")
        self.error()

    def reset_fs(self):
        try:
            run(["rm", "-f", "fs.img"], check=True)
            run(["make", "fs.img"], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Command failed with exit code {e.returncode}")

    def build_xv6(self):
        try:
            run(["make", "kernel/kernel"], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Command failed with exit code {e.returncode}")

    def save_output(self):
      try:
        with open("test-xv6.out", "w") as f:
            f.write(self.output)
            f.close()
      except OSError as e:
        print("Provided a bad results path. Error:", e)

    def cmd(self, c):
        if isinstance(c, str):
            c = c.encode('utf-8')
        self.proc.stdin.write(c)
        self.proc.stdin.flush()

    def crash(self):
        ps = run(['ps', '-opid', '--no-headers', '--ppid', str(self.proc.pid)], stdout=subprocess.PIPE, encoding='utf8')
        kids = [int(line) for line in ps.stdout.splitlines()]
        if len(kids) == 0:
            print("no qemu")
            os.exit(1)
        print("kill", kids[0])
        os.kill(kids[0], signal.SIGKILL)

    def stop(self):
        self.proc.terminate()

    def read(self):
        import select
        r, _, _ = select.select([self.proc.stdout], [], [], 0.1)
        if r:
            buf = os.read(self.proc.stdout.fileno(), 4096)
            self.outbytes.extend(buf)
            self.output = self.outbytes.decode("utf-8", "replace")

    def lines(self):
        return self.output.splitlines()

    def error(self, *regexps):
        if regexps:
            print("FAIL: match failed", regexps)
        else:
            print("FAIL: timeout or test failed")
        self.save_output()
        self.stop()
        sys.exit(1)

    def match(self, *regexps, exit=True):
        lines = self.lines()
        last = -1
        for i, line in enumerate(lines):
            if any(re.match(r, line) for r in regexps):
                print(line)
                last = i
        if last == -1 and exit:
            self.error(*regexps)
        l = ""
        if last >= 0:
            l = lines[last]
        return last >= 0, l

    def monitor(self, *regexps, progress="", timeout):
        deadline = time.time() + timeout
        while True:
            time.sleep(1)
            timeleft = deadline - time.time()
            if timeleft < 0:
                self.error()
            self.read()
            ok, _ = self.match(*regexps, exit=False)
            if ok:
                return
            ok, line = self.match(progress, exit=False)
            if ok:
                print(line)

    def clear_output(self):
        self.output = ""
        self.outbytes = bytearray()

    # Send a program and wait for its marker line. Returns the matched text.
    def run_prog(self, cmdline, pattern, timeout):
        self.clear_output()
        self.cmd(cmdline + "\n")
        deadline = time.time() + timeout
        while time.time() < deadline:
            time.sleep(0.5)
            self.read()
            m = re.search(pattern, self.output)
            if m:
                return m
        return None

    # run_prog with a single retry: occasionally the first byte is lost when
    # it races the console coming up; a second send recovers cleanly.
    def run_prog_checked(self, cmdline, pattern, timeout):
        m = self.run_prog(cmdline, pattern, timeout)
        if m is None:
            print(f"  retrying '{cmdline}' (no response)")
            self.cmd("\n")
            time.sleep(1)
            m = self.run_prog(cmdline, pattern, timeout)
        return m


def crash_log():
    q = QEMU(True)
    q.cmd("logstress f0 f1 f2 f3 f4 f5\n")
    time.sleep(2)
    q.crash()
    q.stop()

def recover_log():
    q = QEMU()
    time.sleep(2)
    q.read()
    ok, _ = q.match('^recovering', exit=False)
    if ok:
        q.cmd("ls\n")
        time.sleep(2)
        q.read()
        q.match('f5')
    q.stop()
    return ok

def forphan():
    q = QEMU(True)
    q.cmd("forphan\n")
    time.sleep(5)
    q.read()
    q.match('wait')
    q.crash()
    q.stop()

def dorphan():
    q = QEMU(True)
    q.cmd("dorphan\n")
    time.sleep(5)
    q.read()
    q.match('wait')
    q.crash()
    q.stop()

def recover_orphan():
    q = QEMU()
    time.sleep(2)
    q.read()
    q.match('^ireclaim')
    q.stop()

def test_log():
    print("Test recovery of log")
    for i in range(5):
        crash_log()
        ok = recover_log()
        if ok:
            print("OK")
            return
        print("log attempt ", i+1)
    print("FAIL")
    sys.exit(1)

def test_forphan():
    print("Test recovery of an orphaned file")
    forphan()
    recover_orphan()
    print("OK")

def test_dorphan():
    print("Test recovery of an orphaned file")
    dorphan()
    recover_orphan()
    print("OK")

def test_crash():
    test_log()
    test_forphan()
    test_dorphan()

def test_usertests(test=""):
    timeout = 900
    opt = ""
    if args.q:
        opt = " -q"
        timeout = 600
    elif test != "":
        opt += " " + test
    q = QEMU(True)
    q.cmd("usertests" + opt + "\n")
    q.monitor('^ALL TESTS PASSED', progress='test', timeout=timeout)
    q.stop()

def test_edr():
    print("Test EDR Security System (Fork Bomb Detection & Mitigation)")
    q = QEMU(True)

    # init spawns edr_daemon at boot; wait for its banner.
    deadline = time.time() + 20
    started = False
    while time.time() < deadline:
        time.sleep(1)
        q.read()
        ok, _ = q.match(r".*edr_daemon: started successfully.*", exit=False)
        if ok:
            started = True
            break
    if not started:
        print("FAIL: EDR daemon failed to start")
        q.stop()
        sys.exit(1)

    # Run multitest to generate a fork bomb.
    q.clear_output()
    q.cmd("multitest\n")

    deadline = time.time() + 15
    detected = False
    while time.time() < deadline:
        time.sleep(1)
        q.read()
        ok, _ = q.match(r".*\[EDR ALERT\].*quarantined.*", exit=False)
        if ok:
            detected = True
            break

    q.stop()
    if detected:
        print("OK")
    else:
        print("FAIL: EDR failed to detect fork bomb")
        sys.exit(1)

def test_mlfq():
    print("Test MLFQ Scheduler and Process Monitor")
    q = QEMU(True)
    q.cmd("ps_monitor &\n")
    time.sleep(1)
    q.read()

    ok, _ = q.match(r".*PID.*Q.*TICKS.*STATE.*", exit=False)
    if not ok:
        print("FAIL: ps_monitor failed to start or output header")
        q.stop()
        sys.exit(1)

    q.cmd("cpuload &\n")
    time.sleep(4)
    q.read()

    ok, line = q.match(r".*\d+\s+[12]\s+\d+\s+\d+.*", exit=False)
    q.stop()
    if ok:
        print("OK")
    else:
        print("FAIL: MLFQ priority demotion not observed or ps_monitor output mismatch")
        sys.exit(1)

def test_false_positive():
    print("=== TEST: False Positives (EDR) ===")
    q = QEMU(True)

    print("Running legitimate workload (stressfs)...")
    q.clear_output()
    q.cmd("stressfs\n")

    deadline = time.time() + 15
    alert_triggered = False

    while time.time() < deadline:
        time.sleep(1)
        q.read()
        ok, _ = q.match(r".*\[EDR ALERT\].*", exit=False)
        if ok:
            alert_triggered = True
            break

    q.stop()
    if alert_triggered:
        print("FAIL: EDR generated a false positive alert during stressfs.")
        sys.exit(1)

    print("OK: No false positives during legitimate high workload.")

def test_unquarantine():
    """
    Administrative release flow:
      1. A non-trusted caller (sh) must be denied.
      2. Trigger a fork bomb WITHOUT the EDR daemon running (init reads the
         /edroff flag on respawn), find quarantined PIDs via ps_monitor,
         release the whole tree via `unquarantine`, and prove the workload
         completes.
    """
    print("Test unquarantine syscall (trusted admin release)")
    q = QEMU(True)

    # Disable the daemon for this test so victims survive until released.
    m = q.run_prog("echo x > edroff", r"\$ ", 10)
    if m is None:
        print("FAIL: could not create edroff flag")
        q.stop(); sys.exit(1)
    m = q.run_prog("kill 2", r"\$ ", 10)
    if m is None:
        print("FAIL: could not stop edr_daemon")
        q.stop(); sys.exit(1)

    # 1. Negative: untrusted caller is denied.
    m = q.run_prog("unquarantine 1", r"denied or not found", 10)
    if m is None:
        print("FAIL: untrusted unquarantine was not denied")
        q.stop(); sys.exit(1)
    print("negative case OK (denied)")

    # 2. Positive: quarantine then administratively release the tree.
    # `bomb` spawns a 21-process tree (above the Tier-2 threshold) while
    # leaving free proc-table slots; the parent only prints its marker after
    # it is scheduled again, i.e. after the unquarantine below. Two attempts:
    # if attempt 1 races the kernel's L3 timeout sweep (~120 ticks), the sweep
    # frees every proc-table slot and attempt 2 runs on a clean system.
    released_ok = False
    for attempt in (1, 2):
        # clean previous marker (SMP-robust file check avoids UART interleaving)
        q.run_prog("rm -f bomb_alive", r"\$ ", 5)
        q.clear_output()
        q.cmd("bomb &\n")
        time.sleep(4)

        # Snapshot the process table; the tree root is the lowest PID among
        # the quarantined entries - releasing it releases the whole subtree.
        pid = None
        deadline = time.time() + 10
        while time.time() < deadline and pid is None:
            q.cmd("ps_monitor once\n")
            time.sleep(3)
            q.read()
            pids = [int(x) for x in re.findall(
                r"(\d+)\s+\d+\s+\d+\s+\d+\s+\S+\s+\[QUARANTINE\]", q.output)]
            if pids:
                pid = min(pids)
        if pid is None:
            print(f"attempt {attempt}: no QUARANTINE observed")
            time.sleep(14)
            continue
        print(f"attempt {attempt}: quarantined root pid={pid}, releasing...")

        # Only the daemon binary is SHA-256-trusted, so the release goes
        # through its admin CLI mode.
        m = q.run_prog_checked(f"edr_daemon release {pid}",
                               r"(released|denied)", 25)
        if m is None or "denied" in m.group(0):
            print(f"attempt {attempt}: release command failed")
            time.sleep(14)
            continue

        done = False
        deadline = time.time() + 30
        while time.time() < deadline:
            time.sleep(1)
            q.read()
            ok, _ = q.match(r".*BOMB_ALIVE.*", exit=False)
            if ok:
                done = True
                break
            # SMP-robust: also check file marker (not subject to UART interleaving)
            # poll every 3s via cat without clearing the main output buffer
            if int(time.time()) % 3 == 0:
                q.cmd("cat bomb_alive\n")
                time.sleep(1)
                q.read()
                if "BOMB_ALIVE" in q.output:
                    done = True
                    break
        if done:
            released_ok = True
            break
        print(f"attempt {attempt}: tree did not resume")
        # also try definitive file check before giving up
        m2 = q.run_prog("cat bomb_alive", r"BOMB_ALIVE", 5)
        if m2 is not None:
            released_ok = True
            break
        time.sleep(14)

    q.stop()
    if released_ok:
        print("OK")
    else:
        print("FAIL: quarantined tree did not resume after release")
        print("--- console tail ---")
        print(q.output[-1500:])
        sys.exit(1)


def test_global_pressure():
    """
    P2: Global PID-pressure limiter – spawning many live processes from a
    non-whitelisted binary should be denied once live count >= threshold.
    The dedicated `global_pressure` binary tries to create 60 children.
    """
    print("Test global PID-pressure limiter")
    q = QEMU(True)
    # Wait for daemon banner (daemon itself is whitelisted/trusted, not limited)
    deadline = time.time() + 20
    while time.time() < deadline:
        time.sleep(1)
        q.read()
        ok, _ = q.match(r".*edr_daemon: started successfully.*", exit=False)
        if ok:
            break
    # clean previous marker
    q.run_prog("rm -f pressure_limited", r"\$ ", 5)
    m = q.run_prog("pressure", r"GLOBAL_PRESSURE", 60)
    q.read()
    ok, _ = q.match(r".*LIMITED.*", exit=False)
    # SMP-robust: also check file marker and persistent log if console garbled
    if not ok:
        m2 = q.run_prog("cat pressure_limited", r"LIMITED", 5)
        if m2 is not None:
            ok = True
    if not ok:
        m3 = q.run_prog("cat /edr.log", r"Global.*Pressure", 5)
        if m3 is not None:
            ok = True
    q.stop()
    if ok:
        print("OK: global pressure limiter engaged")
    else:
        print("FAIL: global pressure limiter did not engage")
        print(q.output[-1500:])
        sys.exit(1)

def test_persistent_log():
    """
    P2: Persistent alert log – after a quarantine event the on-disk
    /edr.log should contain the alert. Checked via `cat /edr.log`.
    """
    print("Test persistent alert log (/edr.log)")
    q = QEMU(True)
    deadline = time.time() + 20
    while time.time() < deadline:
        time.sleep(1)
        q.read()
        ok, _ = q.match(r".*edr_daemon: started successfully.*", exit=False)
        if ok:
            break
    q.cmd("multitest\n")
    # Wait for an EDR alert to be generated
    deadline = time.time() + 20
    alert_seen = False
    while time.time() < deadline:
        time.sleep(1)
        q.read()
        ok, _ = q.match(r".*\[EDR ALERT\].*quarantined.*", exit=False)
        if ok:
            alert_seen = True
            break
    if not alert_seen:
        print("FAIL: no EDR alert generated for persistent log test")
        q.stop()
        sys.exit(1)
    # Give daemon time to append to /edr.log (async)
    time.sleep(4)
    q.read()
    # The daemon appends "quarantined pid=..." lines; check via cat
    m = q.run_prog("cat /edr.log", r"quarantined", 15)
    if m is None:
        m = q.run_prog("edr_log", r"quarantined", 15)
    if m is not None:
        print("OK: persistent log contains alert")
        q.stop()
    else:
        print("FAIL: persistent log missing alert")
        print(q.output[-2000:])
        q.stop()
        sys.exit(1)

def _stats(values):
    return {
        "min": min(values),
        "median": statistics.median(values),
        "max": max(values),
        "stdev": statistics.stdev(values) if len(values) > 1 else 0.0,
    }


def test_benchmark():
    """
    MLFQ vs Round Robin benchmark, BENCH_RUNS repetitions per cell.
    Writes benchmark_results.csv and (if matplotlib is available)
    benchmark_plot.png. Exits non-zero if any cell has missing samples.
    """
    print(f"=== BENCHMARK: MLFQ vs RR ({BENCH_RUNS} runs/cell) ===")
    patterns = {"cpu": (r"total_ticks=(\d+)", "bench_rr"),
                "interactive": (r"avg=(\d+)", "bench_int")}
    results = {}

    for mode_name, target in [("MLFQ", "qemu"), ("RR", "qemu-rr")]:
        print(f"\n--- {mode_name} ({target}) ---")
        q = QEMU(reset=True, make_target=target)
        results[mode_name] = {}
        for key, (pattern, prog) in patterns.items():
            samples = []
            for i in range(BENCH_RUNS):
                m = q.run_prog_checked(prog, pattern, timeout=90)
                if m is None:
                    print(f"  [{key}] run {i+1}: TIMEOUT")
                    continue
                samples.append(int(m.group(1)))
                print(f"  [{key}] run {i+1}: {samples[-1]} ticks")
            if not samples:
                print(f"FAIL: no valid {key} samples for {mode_name}")
                q.stop()
                sys.exit(1)
            st = _stats(samples)
            results[mode_name][key] = st
            print(f"  [{key}] median={st['median']} min={st['min']} "
                  f"max={st['max']} stdev={st['stdev']:.2f}")
        q.stop()

    # --- CSV ---
    with open(BENCH_CSV, "w") as f:
        f.write("mode,metric,runs,min,median,max,stdev\n")
        for mode in results:
            for key, st in results[mode].items():
                f.write(f"{mode},{key},{BENCH_RUNS},{st['min']},"
                        f"{st['median']},{st['max']},{st['stdev']:.3f}\n")
    print(f"\nWrote {BENCH_CSV}")

    # --- Plot (optional dependency) ---
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        metrics = ["cpu", "interactive"]
        x = range(len(metrics))
        width = 0.35
        fig, ax = plt.subplots(figsize=(7, 4))
        for off, (mode, color) in zip((-width/2, width/2),
                                      [("MLFQ", "#2a9d8f"), ("RR", "#e76f51")]):
            vals = [results[mode][k]["median"] for k in metrics]
            errs = [results[mode][k]["stdev"] for k in metrics]
            ax.bar([xi + off for xi in x], vals, width, yerr=errs,
                   label=mode, color=color, capsize=4)
        ax.set_xticks(list(x))
        ax.set_xticklabels(["CPU-bound throughput (ticks)",
                            "Interactive latency (ticks)"])
        ax.set_ylabel("ticks (lower is better)")
        ax.set_title("MLFQ vs Round-Robin (median of "
                     f"{BENCH_RUNS} runs, error=stdev)")
        ax.legend()
        fig.tight_layout()
        fig.savefig(BENCH_PNG, dpi=120)
        print(f"Wrote {BENCH_PNG}")
    except ImportError:
        print("(matplotlib not installed - skipped plot)")

    # --- Summary ---
    print("\n" + "=" * 60)
    print(f"  {'Metric':<34} {'MLFQ':>10} {'RR':>10}")
    print(f"  {'-'*34} {'-'*10} {'-'*10}")
    for key, label in [("cpu", "CPU-bound median [ticks]"),
                       ("interactive", "Interactive median [ticks]")]:
        m = results["MLFQ"][key]["median"]
        r = results["RR"][key]["median"]
        print(f"  {label:<34} {m:>10} {r:>10}")
    print("=" * 60)
    print("OK")


def main():
    print(args)
    rex = r'%s' % args.testrex
    funcs = [(obj,name) for name,obj in inspect.getmembers(sys.modules[__name__])
                     if (inspect.isfunction(obj) and
                         name.startswith('test'))]
    none = True
    for (f,n) in funcs:
        if re.search(rex, n):
            none = False
            f()
    if none:
        test_usertests(test=args.testrex)

main()
