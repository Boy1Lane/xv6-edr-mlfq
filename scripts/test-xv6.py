#!/usr/bin/env python3

#
# python script that tests xv6 without having to boot it and type to its shell
#
# ./test-xv6.py usertests  (runs usertests)
# ./test-xv6.py -q usertests (runs the quick tests of usertests)
# ./test-xv6.py crash  (runs the crash tests)
# ./test-xv6.py log (runs the log crash test)

import argparse, os, inspect, re, signal, subprocess, sys, time
from subprocess import run

parser = argparse.ArgumentParser()
parser.add_argument('testrex', help="test name or regular expression")
parser.add_argument("-q", action='store_true', help="usertests quick")
args = parser.parse_args()

class QEMU(object):

    def __init__(self, reset=False):
        if reset:
            self.build_xv6()
            self.reset_fs()
        q = ["make", "qemu"]
        self.proc = subprocess.Popen(q, stdin=subprocess.PIPE,
                                      stdout=subprocess.PIPE,
                                      stderr=subprocess.STDOUT)
        self.output = ""
        self.outbytes = bytearray()       
        self.wait_boot()

    def wait_boot(self):
        deadline = time.time() + 15
        while time.time() < deadline:
            time.sleep(0.5)
            self.read()
            if "$" in self.output:
                break

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
            f.write(self.out)
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
    # Khởi động edr_daemon chạy ngầm
    q.cmd("edr_daemon &\n")
    time.sleep(1)
    q.read()
    ok, _ = q.match(r".*edr_daemon: started successfully.*", exit=False)
    if not ok:
        print("FAIL: EDR daemon failed to start")
        q.stop()
        sys.exit(1)
    
    # Chạy multitest để sinh Fork bomb
    q.cmd("multitest\n")
    
    # Đợi cảnh báo EDR phát hiện và cách ly
    deadline = time.time() + 15
    detected = False
    while time.time() < deadline:
        time.sleep(1)
        q.read()
        ok, line = q.match(r".*EDR ALERT.*quarantined.*", exit=False)
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
    # Khởi động ps_monitor chạy ngầm
    q.cmd("ps_monitor &\n")
    time.sleep(1)
    q.read()
    
    # Kiểm tra tiêu đề hiển thị của ps_monitor
    ok, _ = q.match(r".*PID.*Q.*TICKS.*STATE.*", exit=False)
    if not ok:
        print("FAIL: ps_monitor failed to start or output header")
        q.stop()
        sys.exit(1)
        
    # Chạy cpuload để chiếm CPU
    q.cmd("cpuload &\n")
    time.sleep(4)
    q.read()
    
    # Kiểm tra xem có tiến trình nào rơi xuống hàng đợi 1 hoặc 2 không
    ok, line = q.match(r".*\d+\s+[12]\s+\d+\s+\d+.*", exit=False)
    q.stop()
    if ok:
        print("OK")
    else:
        print("FAIL: MLFQ priority demotion not observed or ps_monitor output mismatch")
        sys.exit(1)

def test_benchmark():
    """
    Benchmark test: so sánh MLFQ vs Round Robin scheduler.
    Chạy bench_rr và bench_int trên cả 2 scheduler mode.
    In bảng so sánh kết quả.
    """
    print("=== BENCHMARK: MLFQ vs Round Robin Comparison ===")
    results = {}

    for mode_name, make_target in [("MLFQ", "qemu"), ("RoundRobin", "qemu-rr")]:
        print(f"\n--- Testing {mode_name} Scheduler ---")
        
        # Override QEMU command cho mode này
        q = QEMU.__new__(QEMU)
        q.output = ""
        q.outbytes = bytearray()
        import subprocess
        make_cmd = ["make", make_target]
        q.proc = subprocess.Popen(make_cmd, stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        time.sleep(2)

        # CPU-bound benchmark
        print(f"  [CPU-bound] 4 workers...")
        q.proc.stdin.write(b"bench_rr\n")
        q.proc.stdin.flush()
        
        deadline = time.time() + 30
        cpu_ticks = -1
        while time.time() < deadline:
            time.sleep(1)
            import select
            r, _, _ = select.select([q.proc.stdout], [], [], 0.1)
            if r:
                buf = os.read(q.proc.stdout.fileno(), 4096)
                q.outbytes.extend(buf)
                q.output = q.outbytes.decode("utf-8", "replace")
            import re
            m = re.search(r'total_ticks=(\d+)', q.output)
            if m:
                cpu_ticks = int(m.group(1))
                break

        # Interactive benchmark
        print(f"  [Interactive] sleep-heavy...")
        q.proc.stdin.write(b"bench_int\n")
        q.proc.stdin.flush()
        
        deadline = time.time() + 30
        avg_ticks = -1
        while time.time() < deadline:
            time.sleep(1)
            import select
            r, _, _ = select.select([q.proc.stdout], [], [], 0.1)
            if r:
                buf = os.read(q.proc.stdout.fileno(), 4096)
                q.outbytes.extend(buf)
                q.output = q.outbytes.decode("utf-8", "replace")
            m = re.search(r'avg=(\d+)', q.output)
            if m:
                avg_ticks = int(m.group(1))
                break

        q.proc.terminate()
        results[mode_name] = {"cpu": cpu_ticks, "interactive": avg_ticks}
        print(f"  CPU-bound ticks: {cpu_ticks}")
        print(f"  Interactive avg: {avg_ticks}")

    # In bảng so sánh
    print("\n" + "="*55)
    print("  BENCHMARK COMPARISON: MLFQ vs Round Robin")
    print("="*55)
    print(f"  {'Metric':<30} {'MLFQ':>10} {'RR':>10}")
    print(f"  {'-'*30} {'-'*10} {'-'*10}")
    
    mlfq_cpu = results.get("MLFQ", {}).get("cpu", -1)
    rr_cpu   = results.get("RoundRobin", {}).get("cpu", -1)
    mlfq_int = results.get("MLFQ", {}).get("interactive", -1)
    rr_int   = results.get("RoundRobin", {}).get("interactive", -1)
    
    print(f"  {'CPU-bound (4 workers) [ticks]':<30} {mlfq_cpu:>10} {rr_cpu:>10}")
    print(f"  {'Interactive latency [ticks/iter]':<30} {mlfq_int:>10} {rr_int:>10}")
    
    if mlfq_cpu > 0 and rr_cpu > 0:
        overhead_pct = ((mlfq_cpu - rr_cpu) / rr_cpu) * 100
        print(f"\n  MLFQ scheduling overhead: {overhead_pct:+.1f}% vs RR")
    
    if mlfq_int > 0 and rr_int > 0 and mlfq_int < rr_int:
        print(f"  Interactive improvement : {rr_int - mlfq_int} ticks faster ({((rr_int-mlfq_int)/rr_int*100):.0f}%)")
    
    print("="*55)
    print("OK")

def test_false_positive():
    print("=== TEST: False Positives (EDR) ===")
    q = QEMU()
    
    # Khởi động edr_daemon
    q.cmd("edr_daemon &\n")
    time.sleep(1)
    
    print("Running legitimate workload (stressfs)...")
    q.cmd("stressfs\n")
    
    deadline = time.time() + 15
    alert_triggered = False
    
    while time.time() < deadline:
        time.sleep(1)
        q.read()
        ok, line = q.match(r".*\[EDR ALERT\].*", exit=False)
        if ok:
            alert_triggered = True
            break

    q.stop()
    if alert_triggered:
        print("FAIL: EDR generated a false positive alert during stressfs.")
        sys.exit(1)
    
    print("OK: No false positives during legitimate high workload.")


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
