#!/usr/bin/env bash
# Full verification: clean build, both scheduler modes, full test suite.
set -u
cd "$(dirname "$0")/.."
FAIL=0

echo "===== 1. CLEAN BUILD (MLFQ) ====="
make clean > /dev/null 2>&1
if make kernel/kernel fs.img > v-build.log 2>&1; then
  echo "PASS: kernel + fs.img"
else
  echo "FAIL: build"; grep "error:" v-build.log | head -5; FAIL=1
fi
[ -f kernel/whitelist.h ] && echo "PASS: whitelist.h generated" || { echo "FAIL: no whitelist.h"; FAIL=1; }

echo "===== 2. RR MODE BUILD ====="
if make kernel/kernel SCHED_MODE=1 > v-rr.log 2>&1; then
  echo "PASS: SCHED_MODE=1 build"
else
  echo "FAIL: RR build"; FAIL=1
fi

echo "===== 3. BACK TO MLFQ ====="
make kernel/kernel SCHED_MODE=0 > /dev/null 2>&1 || make kernel/kernel > /dev/null 2>&1
# /mnt/c clock skew can leave whitelist.h hashed against stale binaries;
# force a clean relink of the whitelisted programs, then regenerate.
rm -f user/_init user/_sh user/_usertests user/_forktest user/_edr_daemon
make fs.img > /dev/null 2>&1 || FAIL=1
rm -f kernel/whitelist.h
make kernel/kernel > /dev/null 2>&1 || FAIL=1
rm -f fs.img && make fs.img > /dev/null 2>&1 || FAIL=1

echo "===== 4. TEST SUITE ====="
for t in edr mlfq false_positive unquarantine global_pressure persistent_log; do
  timeout 200 python3 scripts/test-xv6.py $t > v-$t.log 2>&1
  res=$(tail -n 1 v-$t.log)
  echo "$t => $res"
  case "$res" in OK*|*OK*) ;; *) FAIL=1 ;; esac
done

echo "===== 5. USERTESTS (quick) ====="
timeout 800 python3 scripts/test-xv6.py -q usertests > v-usertests.log 2>&1
res=$(tail -n 1 v-usertests.log)
echo "usertests => $res"
case "$res" in *ALL\ TESTS\ PASSED*) ;; *) FAIL=1 ;; esac

echo "===== RESULT ====="
[ $FAIL -eq 0 ] && echo "ALL VERIFICATIONS PASSED" || echo "SOME CHECKS FAILED"
exit $FAIL
