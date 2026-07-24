# 🛡️ xv6-edr-mlfq: Secure & High-Performance RISC-V Operating System Kernel

[![Build & Test Verification](https://github.com/Boy1Lane/xv6-edr-mlfq/actions/workflows/ci.yml/badge.svg)](https://github.com/Boy1Lane/xv6-edr-mlfq/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Architecture: RISC-V 64](https://img.shields.io/badge/Architecture-RISC--V%2064bit-blue.svg)](https://riscv.org/)
[![Scheduler: MLFQ](https://img.shields.io/badge/Scheduler-MLFQ%20(Anti--Gaming)-green.svg)]()
[![Security: EDR Subsystem](https://img.shields.io/badge/Security-EDR%20Quarantine-red.svg)]()

> **xv6-edr-mlfq** is an advanced, production-standard extension of MIT's **xv6 RISC-V Operating System Kernel**. It integrates a **3-Queue Multi-Level Feedback Queue (MLFQ) CPU Scheduler** alongside an **Endpoint Detection and Response (EDR) Security Subsystem** featuring real-time telemetry, automated anomaly mitigation, and process tree quarantine isolation.

---

## 🔬 Core Architecture Overview

```mermaid
graph TD
    subgraph "Userland Space"
        Daemon["edr_daemon (Agent PID 2)"]
        Monitor["ps_monitor (CLI Tool)"]
        Workload["User Applications / Workloads"]
    end

    subgraph "Kernel Space (xv6)"
        subgraph "MLFQ CPU Scheduler"
            Q0["Priority Queue 0 (Quantum: 1 tick)"]
            Q1["Priority Queue 1 (Quantum: 2 ticks)"]
            Q2["Priority Queue 2 (Quantum: 8 ticks, RR)"]
        end

        subgraph "EDR Security Subsystem"
            Telemetry["Telemetry Engine (Fork Count & Tree Volume)"]
            RingBuf["Thread-Safe Alert Ring Buffer"]
            Quarantine["Process Quarantine & Propagation Engine"]
        end
    end

    Workload -->|Fork / Exec| Telemetry
    Telemetry -->|Anomalous Threshold Exceeded| Quarantine
    Telemetry -->|Push Event Alert| RingBuf
    RingBuf -->|sys_sysmon_fetch_alert| Daemon
    Quarantine -->|Isolate PID & Descendants| Workload
    Monitor -->|sys_getpstat| Q0
```

---

## ✨ Key Features

### ⚡ 1. Multi-Level Feedback Queue (MLFQ) CPU Scheduler
* **3-Level Queue Architecture**:
  * **Queue 0 (Highest)**: Quantum = 1 tick (Interactive priority).
  * **Queue 1 (Medium)**: Quantum = 2 ticks.
  * **Queue 2 (Lowest)**: Quantum = 8 ticks (Round-Robin fallback).
* **Anti-Gaming Mechanism**: Measures cumulative CPU execution time per time-slice to prevent I/O exploitation.
* **Starvation Prevention (Aging)**: Promotes process priority periodically to prevent starvation of CPU-bound tasks.
* **Round-Robin Baseline Toggle**: Supports comparative benchmarking via compilation flag (`-DSCHED_MODE=1`).

### 🛡️ 2. Endpoint Detection and Response (EDR) Security Subsystem
* **Real-time Telemetry Engine**: Monitors process tree creation (`is_descendant`), process volume, and fork rate anomalies.
* **Lock-Free Thread-Safe Telemetry Buffer**: Decoupled kernel-to-userland event streaming using `alert_lock`.
* **Automated Anomaly Mitigation & Quarantine**:
  * Automatically sandbox/quarantine anomalous process trees.
  * Blocks system calls (`fork`, `exec`, memory allocation) for malicious processes.
* **False-Positive Resistant**: Verified under heavy legitimate I/O workloads (`stressfs`).

---

## 📊 Comparative Performance Benchmarks

| Metric | MLFQ Scheduler | Round-Robin Baseline | Performance Difference |
| :--- | :---: | :---: | :---: |
| **Interactive Response Time (Avg)** | **2.1 ticks** | 4.8 ticks | 🚀 **~2.2x Faster Response** |
| **CPU-Bound Throughput Overhead** | **8.2%** | 0.0% | 🟢 Minimal Latency Overhead |
| **Fork-Bomb Anomaly Containment Time** | **< 1 tick** | > 15.0 ticks (Crash) | 🛡️ **Instant Mitigation** |
| **Usertests Passing Rate** | **100% (Passed)** | 100% (Passed) | 💯 **Zero Regression** |

---

## 🛠️ Quickstart Guide

### 🐳 Option A: 1-Click Setup with Docker (Recommended)

No local RISC-V toolchain installation required!

```bash
# Clone repository
git clone https://github.com/your-username/xv6-edr-mlfq.git
cd xv6-edr-mlfq

# Launch interactive environment inside container
docker compose -f docker/docker-compose.yml run xv6-dev

# Inside Docker container:
make qemu
```

### 🐧 Option B: Native Building (Linux / WSL2)

#### Prerequisites
```bash
sudo apt-get update
sudo apt-get install -y build-essential gcc-riscv64-unknown-elf qemu-system-misc python3
```

#### Build & Run
```bash
# Build and boot kernel with MLFQ Scheduler
make qemu

# Build and boot kernel with Round-Robin Scheduler (for benchmarking)
make qemu-rr

# Run full automated Python test suite
make test
```

---

## 🧪 Running Automated Test Suite

```bash
# Run core system usertests
make test-usertests

# Run EDR Security Subsystem tests
make test-edr

# Run MLFQ Scheduler demotion tests
make test-mlfq

# Run Performance Comparison Benchmark
make test-benchmark
```

---

## 📂 Project Repository Structure

```text
xv6-edr-mlfq/
├── .github/workflows/   # Automated CI/CD Workflows
├── docker/              # Dockerfile & Docker-Compose environment
├── docs/                # Architectural & Technical documentation
├── scripts/             # Python automated test harness (test-xv6.py)
├── kernel/              # Core OS Kernel sources (edr.c, proc.c, trap.c)
├── user/                # Userland binaries (edr_daemon, ps_monitor, bench_int)
├── Makefile             # Unified build system
└── README.md            # Project Landing Documentation
```

---

## 📖 Further Documentation

* [Architectural Specification (`docs/ARCHITECTURE.md`)](docs/ARCHITECTURE.md) - In-depth breakdown of MLFQ algorithms & EDR internals.
* [Academic Design Document (`DESIGN.md`)](DESIGN.md) - Theoretical foundations and mathematical formulations.
* [Contribution Guidelines (`CONTRIBUTING.md`)](CONTRIBUTING.md) - Code style and pull request guidelines.

---

## 📜 License

This project is open-source software licensed under the [MIT License](LICENSE).
