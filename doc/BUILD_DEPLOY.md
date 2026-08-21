# Vela-Client Build and Deployment

## Purpose and scope

Vela-Client is the C++17 embedded test daemon. It builds against the sibling
`Vela-HAL` tree, generates C++ gRPC/Protobuf sources from HAL contracts, runs
GoogleTest/CTest tests, and produces native or ARM64 binaries for a target
device. The root `Makefile` is the authoritative entry point.

## 1. Prerequisites

- Linux with GNU Make, CMake 3.16+, Ninja, a C++17 compiler, and `nproc`.
- Protobuf, gRPC, `grpc_cpp_plugin`, SQLite3, spdlog, toml++, yaml-cpp, and
  Threads development packages; GoogleTest is required for tests.
- A sibling checkout at `../Vela-HAL` for the HAL library and `.proto` files.
- Docker/buildx for ARM64 builds; `sshpass`, SSH access, and a reachable target
  are required for deployment. The Makefile defaults to `nvidia`/`nvidia` and
  `192.168.1.3`/`192.168.1.13`; override these rather than storing credentials.

## 2. Setup

From this repository, verify the sibling HAL path and install host dependencies.
For Docker, run `make docker-install` if Docker is absent, then `make
docker-image`. `make setup-completion` optionally appends this repository's
completion script to `~/.bashrc`.

## 3. Build and compile

- `make configure` configures `build/native` with Ninja and `BUILD_TESTS=ON`.
- `make build` configures if needed and builds native binaries with
  `ninja -j$(nproc)`; use `JOBS=N` to override parallelism.
- `make docker-configure` and `make docker-build` build ARM64 in the `vela`
  image using `build/cross`; Docker uses `linux/arm64` emulation and a ccache
  volume. `make all` is the default alias for `docker-build`.
- `make list` lists native or cross `bin/` outputs. `make run [name] [args...]`
  runs native applications with the native library path.

## 4. Tests and lint

- `make test` runs the focused native CTest expression for
  `serializer_tests` and `runner_tests`.
- `make docker-test` builds and runs all cross CTest tests under ARM64/QEMU.
- `make format`, `make cppcheck`, and `make doc` run formatting, static
  analysis, and Doxygen through the generated Ninja targets. These are
  conditional on clang-format/cppcheck/Doxygen being installed.

## 5. Packaging and artifacts

Native artifacts are under `build/native/bin` and `build/native/lib`; cross
artifacts are under `build/cross/bin` and `build/cross/lib`. CMake installs the
daemon, sample config, and systemd unit. This Makefile has no package target;
use `cmake --install build/native` for installation artifacts.

## 6. Deployment, install, and run

Install locally with `sudo cmake --install build/native`, or copy the binary,
`conf/client.conf.sample`, and `systemd/vela-client.service` according to the
existing README. Configure the Vela-Server address, spool path, HalService
port, and TLS before starting `vela-client`. For a device deployment use
`make deploy-a IP_A=... USER=... PASS=...` or `make deploy-b`; `make deploy`
does both. `make run-a [app] [args...]` and `make run-b [app] [args...]`
deploy first, then run from `/tmp/acu-test` over SSH.

For the checked-in development runner, `./run.sh` cleans stale diagnostic and
SQLite lock files, creates local data directories, and starts the debug client
with `conf/client.conf.dev`. It requires the runner's expected development
binary/config paths; inspect those paths before use if the Makefile build
layout is being used.

## 7. Cleanup

`make clean` removes `build/`. `make docker-clean` removes the cross build in
the container, while `make docker-shell` opens an ARM64 development shell.

## 8. Hardware, cloud, and manual verification caveats

Build success does not prove access to GPIO, camera, accelerators, or other
device nodes, nor server streaming, TLS, spool replay, or systemd behavior.
The `deploy-*` and `run-*` targets require the stated target hardware, network,
SSH service, `sshpass`, and credentials; they use plaintext password arguments
unless the operator supplies a safer mechanism. Validate each adapter on the
actual board and verify server connectivity and permissions separately.