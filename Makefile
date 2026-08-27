K=kernel
U=user

OBJS = \
  $K/entry.o \
  $K/start.o \
  $K/console.o \
  $K/printf.o \
  $K/uart.o \
  $K/kalloc.o \
  $K/spinlock.o \
  $K/string.o \
  $K/main.o \
  $K/vm.o \
  $K/proc.o \
  $K/edr.o \
  $K/sha256.o \
  $K/swtch.o \
  $K/trampoline.o \
  $K/trap.o \
  $K/syscall.o \
  $K/sysproc.o \
  $K/bio.o \
  $K/fs.o \
  $K/log.o \
  $K/sleeplock.o \
  $K/file.o \
  $K/pipe.o \
  $K/exec.o \
  $K/sysfile.o \
  $K/kernelvec.o \
  $K/plic.o \
  $K/virtio_disk.o

# riscv64-unknown-elf- or riscv64-linux-gnu-
# perhaps in /opt/riscv/bin
#TOOLPREFIX = 

# Try to infer the correct TOOLPREFIX if not set
ifndef TOOLPREFIX
TOOLPREFIX := $(shell if riscv64-unknown-elf-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-unknown-elf-'; \
	elif riscv64-elf-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-elf-'; \
	elif riscv64-none-elf-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-none-elf-'; \
	elif riscv64-linux-gnu-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-linux-gnu-'; \
	elif riscv64-unknown-linux-gnu-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-unknown-linux-gnu-'; \
	else echo "***" 1>&2; \
	echo "*** Error: Couldn't find a riscv64 version of GCC/binutils." 1>&2; \
	echo "*** To turn off this error, run 'gmake TOOLPREFIX= ...'." 1>&2; \
	echo "***" 1>&2; exit 1; fi)
endif

QEMU = qemu-system-riscv64
MIN_QEMU_VERSION = 7.2

CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)gas
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

CFLAGS = -Wall -Werror -Wno-unknown-attributes -O -fno-omit-frame-pointer -ggdb -gdwarf-2
CFLAGS += -march=rv64gc
CFLAGS += -MD
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding
CFLAGS += -fno-common -nostdlib
CFLAGS += -fno-builtin-strncpy -fno-builtin-strncmp -fno-builtin-strlen -fno-builtin-memset
CFLAGS += -fno-builtin-memmove -fno-builtin-memcmp -fno-builtin-log -fno-builtin-bzero
CFLAGS += -fno-builtin-strchr -fno-builtin-exit -fno-builtin-malloc -fno-builtin-putc
CFLAGS += -fno-builtin-free
CFLAGS += -fno-builtin-memcpy -Wno-main
CFLAGS += -fno-builtin-printf -fno-builtin-fprintf -fno-builtin-vprintf
CFLAGS += -I.
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)

# Disable PIE when possible (for Ubuntu 16.10 toolchain)
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]no-pie'),)
CFLAGS += -fno-pie -no-pie
endif
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]nopie'),)
CFLAGS += -fno-pie -nopie
endif

LDFLAGS = -z max-page-size=4096

$K/kernel: $(OBJS) $K/kernel.ld
	$(LD) $(LDFLAGS) -T $K/kernel.ld -o $K/kernel $(OBJS)
	$(OBJDUMP) -S $K/kernel > $K/kernel.asm
	$(OBJDUMP) -t $K/kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $K/kernel.sym

$K/%.o: $K/%.S
	$(CC) -march=rv64gc -g -c -o $@ $<

tags: $(OBJS)
	etags kernel/*.S kernel/*.c

ULIB = $U/ulib.o $U/usys.o $U/printf.o $U/umalloc.o

_%: %.o $(ULIB) $U/user.ld
	$(LD) $(LDFLAGS) -T $U/user.ld -o $@ $< $(ULIB)
	$(OBJDUMP) -S $@ > $*.asm
	$(OBJDUMP) -t $@ | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $*.sym

$U/usys.S : $U/usys.pl
	perl $U/usys.pl > $U/usys.S

$U/usys.o : $U/usys.S
	$(CC) $(CFLAGS) -c -o $U/usys.o $U/usys.S

$U/_forktest: $U/forktest.o $(ULIB)
	# forktest has less library code linked in - needs to be small
	# in order to be able to max out the proc table.
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o $U/_forktest $U/forktest.o $U/ulib.o $U/usys.o
	$(OBJDUMP) -S $U/_forktest > $U/forktest.asm

mkfs/mkfs: mkfs/mkfs.c $K/fs.h $K/param.h
	gcc -Wno-unknown-attributes -I. -o mkfs/mkfs mkfs/mkfs.c

# --- EDR hash-based whitelist (see scripts/gen-whitelist.sh) ---------------
# kernel/whitelist.h is generated from the actual built binaries, so the
# kernel verifies binary identity by SHA-256 at exec-time instead of by
# spoofable file paths.
WL_PROGS = $U/_init $U/_sh $U/_usertests $U/_forktest $U/_edr_daemon

$K/whitelist.h: $(WL_PROGS) scripts/gen-whitelist.sh
	bash scripts/gen-whitelist.sh $(WL_PROGS) > $@

$K/exec.o: $K/whitelist.h
# ---------------------------------------------------------------------------

# Prevent deletion of intermediate files, e.g. cat.o, after first build, so
# that disk image changes after first build are persistent until clean.  More
# details:
# http://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
.PRECIOUS: %.o

UPROGS=\
	$U/_cat\
	$U/_echo\
	$U/_forktest\
	$U/_grep\
	$U/_init\
	$U/_kill\
	$U/_ln\
	$U/_ls\
	$U/_mkdir\
	$U/_rm\
	$U/_sh\
	$U/_stressfs\
	$U/_usertests\
	$U/_grind\
	$U/_wc\
	$U/_zombie\
	$U/_logstress\
	$U/_forphan\
	$U/_dorphan\
	$U/_ps_monitor\
	$U/_cpuload\
	$U/_multitest\
	$U/_edr_daemon\
	$U/_unquarantine\
	$U/_bomb\
	$U/_edr_log\
	$U/_pressure\
	$U/_bench_rr\
	$U/_bench_int\

README: README.md
	cp README.md README

fs.img: mkfs/mkfs README $(UPROGS)
	mkfs/mkfs fs.img README $(UPROGS)

-include kernel/*.d user/*.d

clean:
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	*/*.o */*.d */*.asm */*.sym \
	$K/kernel fs.img README \
	$K/whitelist.h .sched-mode \
	$U/usys.S \
	$(UPROGS)

# try to generate a unique GDB port
GDBPORT = $(shell expr `id -u` % 5000 + 25000)
# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)
ifndef CPUS
# P2: EDR and MLFQ hot paths are now SMP-safe (p->lock + atomics).
# Default to 3 harts to exercise multi-CPU paths; override with CPUS=1 if needed.
CPUS := 3
endif

QEMUOPTS = -machine virt -bios none -kernel $K/kernel -m 128M -smp $(CPUS) -nographic
QEMUOPTS += -global virtio-mmio.force-legacy=false
QEMUOPTS += -drive file=fs.img,if=none,format=raw,id=x0
QEMUOPTS += -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

# Scheduler mode: pass SCHED_MODE=1 (make qemu-rr does this for you) to build
# the Round-Robin baseline used by benchmarks. We must APPEND to CFLAGS here
# instead of overriding CFLAGS on the command line: a recursive assignment like
# make qemu CFLAGS="$(CFLAGS) -D..." makes CFLAGS reference itself and GNU make
# aborts with "Recursive variable 'CFLAGS' references itself".
ifeq ($(SCHED_MODE),1)
CFLAGS += -DSCHED_MODE=1
endif

# Scheduler-mode stamp: when SCHED_MODE changes the stamp is rewritten, and
# because every kernel object depends on it, all objects recompile for the new
# mode. When the mode is stable the stamp keeps its mtime and nothing churns.
.PHONY: sched-force
sched-force:
	@if [ "$$(cat .sched-mode 2>/dev/null)" != "$(SCHED_MODE)" ]; then \
		echo "== Scheduler mode -> $(SCHED_MODE): rebuilding kernel objects =="; \
		printf "%s" "$(SCHED_MODE)" > .sched-mode; \
	fi

.sched-mode: sched-force
	@test -f $@ || touch $@

$(OBJS): .sched-mode

qemu: check-qemu-version $K/kernel fs.img
	$(QEMU) $(QEMUOPTS)

# Build và chạy với Round Robin scheduler (cho benchmark comparison).
# Đổi SCHED_MODE tự động buộc recompile toàn bộ kernel objects.
qemu-rr:
	$(MAKE) qemu SCHED_MODE=1

.gdbinit: .gdbinit.tmpl-riscv
	sed "s/:1234/:$(GDBPORT)/" < $^ > $@

qemu-gdb: $K/kernel .gdbinit fs.img
	@echo "*** Now run 'gdb' in another window." 1>&2
	$(QEMU) $(QEMUOPTS) -S $(QEMUGDB)

print-gdbport:
	@echo $(GDBPORT)

QEMU_VERSION := $(shell $(QEMU) --version | head -n 1 | sed -E 's/^QEMU emulator version ([0-9]+\.[0-9]+)\..*/\1/')
# Dùng awk thay cho bc (bc không có sẵn trong Docker image). awk so sánh được số thập phân.
check-qemu-version:
	@if ! $(QEMU) --version | awk 'BEGIN { min = $(MIN_QEMU_VERSION) + 0 } \
		match($$0, /version [0-9]+(\.[0-9]+)*/) { \
			v = substr($$0, RSTART + 8, RLENGTH - 8) + 0; \
			if (v < min) { printf "ERROR: Need qemu version >= %s (found: %s)\n", min, v; exit 1 } \
		}'; then \
		exit 1; \
	fi

# ==============================================================================
# Helper & DevX Targets
# ==============================================================================

.PHONY: help test test-usertests test-edr test-mlfq test-benchmark test-false-positive test-unquarantine test-global-pressure test-persistent-log fmt fmt-check docker-build docker-test

help:
	@echo "xv6-edr-mlfq DevX Build System"
	@echo "Usage:"
	@echo "  make qemu             Build and boot xv6 with MLFQ Scheduler"
	@echo "  make qemu-rr          Build and boot xv6 with Round-Robin Scheduler (for benchmarking)"
	@echo "  make test             Run full automated Python test suite"
	@echo "  make test-usertests   Run core xv6 usertests"
	@echo "  make test-edr         Run EDR security subsystem tests"
	@echo "  make test-mlfq        Run MLFQ scheduler priority demotion tests"
	@echo "  make test-unquarantine Run admin-release flow tests"
	@echo "  make test-global-pressure Run global PID-pressure limiter tests"
	@echo "  make test-persistent-log Run persistent EDR log tests"
	@echo "  make test-benchmark   Run MLFQ vs Round Robin performance comparison"
	@echo "  make fmt              Format owned C sources using clang-format"
	@echo "  make fmt-check        Verify formatting of owned C sources (CI gate)"
	@echo "  make docker-build     Build Docker image locally"
	@echo "  make docker-test      Run full test suite inside Docker container"
	@echo "  make clean            Clean all build artifacts"

test:
	python3 scripts/test-xv6.py usertests

test-usertests:
	python3 scripts/test-xv6.py -q usertests

test-edr:
	python3 scripts/test-xv6.py edr

test-mlfq:
	python3 scripts/test-xv6.py mlfq

test-benchmark:
	python3 scripts/test-xv6.py benchmark

test-false-positive:
	python3 scripts/test-xv6.py false_positive

test-unquarantine:
	python3 scripts/test-xv6.py unquarantine

test-global-pressure:
	python3 scripts/test-xv6.py global_pressure

test-persistent-log:
	python3 scripts/test-xv6.py persistent_log

# Only sources owned by this project are formatted - vendored xv6 files keep
# their original K&R style. These four files follow the repo .clang-format
# (LLVM, Attach) so `make fmt-check` is a real CI gate.
FMT_FILES = kernel/sha256.c user/edr_daemon.c user/ps_monitor.c user/unquarantine.c

fmt:
	clang-format -i $(FMT_FILES)

fmt-check:
	clang-format --dry-run --Werror $(FMT_FILES)

docker-build:
	docker compose -f docker/docker-compose.yml build

docker-test:
	docker compose -f docker/docker-compose.yml run xv6-test

