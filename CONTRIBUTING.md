# 🤝 Contributing to xv6-edr-mlfq

Thank you for your interest in contributing to **xv6-edr-mlfq**! We welcome contributions from open-source developers, security researchers, and operating systems enthusiasts.

---

## 📜 Development Guidelines

### 1. Code Formatting & Style
* All C source code (`kernel/`, `user/`) must follow LLVM formatting.
* Run `make fmt` before committing code to format all files automatically via `clang-format`.

### 2. Commit Message Standards
Use clear and structured commit messages:
* `feat(edr): add process tree volume calculation`
* `fix(sched): fix priority demotion edge case`
* `docs: update architecture documentation`
* `ci: add GitHub Actions workflow`

### 3. Testing Requirements
Before opening a Pull Request, verify that all tests pass locally:
```bash
make clean
make test
```
All system `usertests`, EDR anomaly tests, and MLFQ benchmarks must pass with **0 failures**.

---

## 📬 Pull Request Process

1. Fork the repository and create your branch from `main` (`git checkout -b feature/amazing-feature`).
2. Make your changes and commit with descriptive messages.
3. Verify formatting (`make fmt`) and run test suite (`make test`).
4. Push to your branch and submit a Pull Request targeting `main`.
