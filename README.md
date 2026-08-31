## Overview

## Project Summary

Vela-Client is the embedded C++17 daemon that orchestrates hardware-validation
tests and streams results to Vela-Server. The source tree contains application,
configuration, diagnostic, HAL bridge, HAL service, and janitor components; the
checked-in protobuf contracts define client, common, HAL, and module messages.
The existing documentation also describes a module registry with 35+ adapters,
SQLite durable result/log spooling, bidirectional gRPC transport, a Python SDK
HalService endpoint, log collection, and a Unix diagnostic socket. CMake,
Makefile, Docker, sample configuration, and systemd artifacts provide build and
deployment surfaces. The source inventory supports those component claims, but
hardware behavior and full runtime integration remain environment-dependent.

The repository also includes sample configuration, a systemd unit, Docker
cross-compilation support, generated service contracts, and focused GoogleTest
targets. These artifacts make the client operationally shaped, but they do not
prove that the server is reachable, the local port is secured, or that every
adapter can access its target device. The documented spool, replay, retry, and
heartbeat paths should be exercised with an unavailable server and then a
recovered server. Hardware-module claims should be checked on the exact Vela
board because source-level adapter presence is not equivalent to a passing
device test. Configuration defaults, service permissions, spool capacity, and
TLS settings should likewise be reviewed for the deployment image. The status
table intentionally records those distinctions and keeps manual acceptance
separate from automated test evidence.

## Feature Status

| # | Name / Description | Implemented? | Test Coverage? | Manual Test |
|---:|---|---|---|---|
| 1 | C++17 CMake/Make build | Implemented | Build/test targets documented; execution not verified | [ ] Manual verification required |
| 2 | Test orchestration and module registry | Implemented | `test_run_orchestrator` documented; depth unknown | [ ] Manual verification required |
| 3 | 35+ hardware module adapters | Implemented | Adapter-wide coverage unknown | [ ] Manual verification required |
| 4 | Stub adapter for unavailable modules | Implemented | Result behavior coverage unknown | [ ] Manual verification required |
| 5 | HAL result serialization | Implemented | `test_result_serializer` documented | [ ] Manual verification required |
| 6 | SQLite durable spool and replay | Implemented | Spool integration coverage unknown | [ ] Manual verification required |
| 7 | Bidirectional server stream, reconnect, and heartbeat | Implemented | End-to-end coverage unknown | [ ] Manual verification required |
| 8 | Python SDK HalService endpoint | Implemented | Integration coverage unknown | [ ] Manual verification required |
| 9 | Log collection and forwarding | Implemented | No dedicated coverage identified | [ ] Manual verification required |
| 10 | Local diagnostic socket and janitor cleanup | Partial | No dedicated coverage identified | [ ] Manual verification required |
| 11 | Native, Docker, and systemd deployment | Partial | Build/deployment execution not verified | [ ] Manual verification required |

## Useful Validation

Use `make build` (Docker cross-build) and `make test` (ctest inside Docker); the documented focused binaries are
`test_result_serializer` and `test_run_orchestrator`. Docker and systemd
procedures are described in the existing sections above.
# Vela-Client > **gRPC-based daemon for IV&V (Independent Verification & Validation) hardware testing on embedded Linux platforms** Vela-Client is a C++17 daemon that orchestrates hardware validation tests, collects results, and streams them to an Vela-Server instance. It manages test execution, durable result storage, log collection, and provides gRPC endpoints for both server communication and SDK integration. --- ## Table of Contents - [Overview](#overview)
- [Architecture](#architecture)
- [System Requirements](#system-requirements)
- [Dependencies](#dependencies)
- [Building](#building) - [Native Build](#native-build) - [Docker Build (Cross-compilation)](#docker-build-cross-compilation)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running](#running) - [Manual Execution](#manual-execution) - [Systemd Service](#systemd-service)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Supported Hardware Modules](#supported-hardware-modules)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [License](#license) --- ## Overview Vela-Client provides: - **Test Orchestration**: Executes hardware validation tests via 35+ module adapters (CPU, GPU, Thermal, Storage, USB, Ethernet, etc.)
- **Result Serialization**: Converts HAL test results to Protocol Buffer format with proper sequencing and timestamping
- **Durable Storage**: SQLite-based spool for result buffering and replay on network interruption
- **Server Streaming**: Bidirectional gRPC stream to Vela-Server for commands and result delivery
- **SDK Interface**: HalService gRPC endpoint for Python SDK and end-to-end test integration
- **Log Collection**: Tails specified log files and forwards entries to server
- **Diagnostic Socket**: Local diagnostic interface for health monitoring **Target Platforms**: Qualcomm QCS6490 (Qualcomm QCS6490), Qualcomm QCS6490, or any ARM64/x86_64 Linux system with GPIO/hardware access. --- ## Architecture ```
┌─────────────────────────────────────────────────────────────┐
│ Vela-Client │
│ │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│ │ StreamClient │──│ Spool │──│RunOrchestrator│ │
│ │ (gRPC to │ │ (SQLite3) │ │ (Test Exec) │ │
│ │ Server) │ └──────────────┘ └───────┬───────┘ │
│ └──────────────┘ │ │
│ │ │
│ ┌──────────────┐ ┌──────────────┐ ┌───────▼───────┐ │
│ │ LogCollector │ │ DiagSocket │ │ Module │ │
│ │ │ │ │ │ Registry │ │
│ └──────────────┘ └──────────────┘ └───────┬───────┘ │
│ │ │
│ ┌──────────────┐ ┌───────▼───────┐ │
│ │ HalService │◄───────────────────│ 35+ Adapters │ │
│ │ (gRPC for │ │ (HAL Bridge) │ │
│ │ PySDK) │ └───────────────┘ │
│ └──────────────┘ │
└─────────────────────────────────────────────────────────────┘ ▲ │ │ │ │ ▼ Vela-Server Vela-HAL (gRPC Stream) (Hardware Abstraction)
``` ### Core Components | Component | Purpose |
|-----------|---------|
| **StreamClient** | Bidirectional gRPC stream to Vela-Server; handles reconnection and heartbeat |
| **Spool** | SQLite3 database for durable result/log storage; enforces capacity limits |
| **RunOrchestrator** | Executes test runs, invokes module adapters, serializes results |
| **ModuleRegistry** | Loads `modules.yaml` and dispatches tests to appropriate adapters |
| **HalService** | gRPC service (port 50052) for Python SDK to invoke HAL tests |
| **LogCollector** | Tails configured log files and forwards to server |
| **Janitor** | Periodic cleanup of old spool entries |
| **DiagSocket** | Unix socket for local diagnostics | --- ## System Requirements ### Hardware
- **Minimum**: ARM64 or x86_64 processor (Qualcomm QCS6490, Qualcomm QCS6490, or similar)
- **Recommended**: 1 GB RAM, 2 GB storage for spool database ### Operating System
- **Ubuntu 22.04 LTS** (primary target)
- **Ubuntu 20.04 LTS** (supported with manual dependency builds)
- Other Debian-based ARM64/x86_64 distributions (untested) ### Network
- Connectivity to **Vela-Server** (configurable IP/port)
- Optional: Access to hardware peripherals (GPIO, I2C, SPI, USB, etc.) --- ## Dependencies ### Build-time Dependencies | Library | Version | Purpose |
|---------|---------|---------|
| **CMake** | ≥ 3.16 | Build system |
| **GCC/G++** | ≥ 9.0 (C++17) | Compiler |
| **Protocol Buffers** | ≥ 3.12 | Message serialization |
| **gRPC** | ≥ 1.30 | RPC framework |
| **spdlog** | ≥ 1.x | Structured logging |
| **toml++** | ≥ 3.4 | Configuration parsing |
| **yaml-cpp** | ≥ 0.7 | Module registry parsing |
| **SQLite3** | ≥ 3.x | Spool database |
| **GoogleTest** | ≥ 1.10 | Unit testing | ### Runtime Dependencies | Dependency | Notes |
|------------|-------|
| **Vela-HAL** | Sibling repository (must be in `../Vela-HAL/`) |
| **libprotobuf.so** | Shared library for Protocol Buffers |
| **libgrpc++.so** | gRPC C++ runtime | --- ## Building ### Prerequisites 1. **Clone both repositories** (they must be siblings): ```bash mkdir -p ~/workspace/Vela cd ~/workspace/Vela git clone <vela-client-repo-url> Vela-Client git clone <vela-hal-repo-url> Vela-HAL ``` 2. **Install system dependencies**: **Ubuntu 22.04/ 20.04:** ```bash sudo apt-get update sudo apt-get install -y \ build-essential cmake git \ protobuf-compiler libprotobuf-dev \ libgrpc++-dev libgrpc-dev \ libsqlite3-dev libspdlog-dev \ libgtest-dev pkg-config ninja-build ``` 3. **Install header-only libraries** (if not packaged): **toml++** (required on Ubuntu 22.04 ARM64): ```bash git clone --depth=1 --branch v3.4.0 https://github.com/marzer/tomlplusplus.git/tmp/tomlplusplus cmake -S/tmp/tomlplusplus -B/tmp/tomlplusplus/build \ -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib sudo cmake --install/tmp/tomlplusplus/build rm -rf/tmp/tomlplusplus ``` **yaml-cpp 0.8.0** (if system version lacks CMake targets): ```bash git clone --depth=1 --branch 0.8.0 https://github.com/jbeder/yaml-cpp.git/tmp/yaml-cpp cmake -S/tmp/yaml-cpp -B/tmp/yaml-cpp/build \ -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DYAML_CPP_BUILD_TESTS=OFF cmake --build/tmp/yaml-cpp/build --parallel sudo cmake --install/tmp/yaml-cpp/build rm -rf/tmp/yaml-cpp ``` 4. **Build grpc_cpp_plugin** (if missing): ```bash # Check if grpc_cpp_plugin exists which grpc_cpp_plugin || { # Build from source (see Dockerfile for full build script) # Alternatively, install grpc-plugins package if available sudo apt-get install -y protobuf-compiler-grpc } ``` --- ### Native Build **Using Makefile** (recommended):
```bash
cd ~/workspace/Vela/Vela-Client
make docker-configure # Configure inside Docker
make build # Compile with Ninja
``` **Using CMake directly**:
```bash
cd ~/workspace/Vela/Vela-Client
mkdir -p build/cross
cd build/cross
cmake ../.. -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build . --parallel $(nproc)
``` **Output**:
- Binary: `build/cross/bin/vela-client`
- Tests: `build/cross/bin/test_result_serializer`, `build/cross/bin/test_run_orchestrator` --- ### Docker Build (Cross-compilation) For cross-compiling from x86_64 to ARM64 (Qualcomm QCS6490): 1. **Build Docker image**: ```bash cd ~/workspace/Vela/Vela-Client/docker make build # or: docker buildx build --platform linux/arm64 --load -t vela . ``` 2. **Enter build container**: ```bash make run # Interactive shell in ARM64 container ``` 3. **Build inside container**: ```bash # Inside container: cd/workspace/Vela-Client make docker-configure make docker-build ``` 4. **Extract binaries**: ```bash # On host: cd ~/workspace/Vela/Vela-Client docker run --rm -v $(pwd):/host vela \ cp -r/workspace/Vela-Client/build/cross/bin/host/build/cross/ ``` --- ## Installation ### Manual Installation 1. **Copy binary**: ```bash sudo install -m 0755 build/cross/bin/vela-client/usr/bin/vela-client ``` 2. **Create configuration directory**: ```bash sudo mkdir -p/etc/vela sudo cp conf/client.conf.sample/etc/vela/client.conf sudo chown root:root/etc/vela/client.conf sudo chmod 0644/etc/vela/client.conf ``` 3. **Create spool directory**: ```bash sudo mkdir -p/var/lib/vela/spool sudo chown vela:vela/var/lib/vela/spool # See user setup below ``` 4. **Create vela user** (for systemd service): ```bash sudo useradd -r -s/usr/sbin/nologin -d/var/lib/vela vela sudo chown -R vela:vela/var/lib/vela ``` 5. **Install systemd service**: ```bash sudo cp systemd/vela-client.service/etc/systemd/system/ sudo systemctl daemon-reload ``` --- ### CMake Install Alternatively, use the CMake install target:
```bash
cd build/cross
sudo cmake --install .
``` This installs:
- Binary → `/usr/bin/vela-client`
- Config → `/etc/vela/client.conf`
- Service → `/lib/systemd/system/vela-client.service` --- ## Configuration Edit `/etc/vela/client.conf`: ```toml
# Vela-Client configuration # ---------------------------------------------------------------------------
# gRPC server (outbound — connects to Vela-Server)
# ---------------------------------------------------------------------------
server_address = "192.168.1.100" # REQUIRED — IP or hostname of Vela-Server
server_port = 50051 # ---------------------------------------------------------------------------
# HalService listener (inbound — PySDK connects to this Client port)
# ---------------------------------------------------------------------------
# hal_service_bind = "0.0.0.0" # bind address; "127.0.0.1" for loopback only
# hal_service_port = 50052 # default 50052 # ---------------------------------------------------------------------------
# Spool (durability store)
# ---------------------------------------------------------------------------
spool_path = "/var/lib/vela/spool/spool.db"
result_spool_cap_bytes = 2147483648 # 2 GiB
log_spool_cap_bytes = 524288000 # 500 MiB # ---------------------------------------------------------------------------
# TLS (leave empty for plaintext — lab-subnet default)
# ---------------------------------------------------------------------------
# tls_ca = "/etc/vela/ca.crt"
# tls_cert = "/etc/vela/client.crt"
# tls_key = "/etc/vela/client.key" # ---------------------------------------------------------------------------
# Extra log paths to tail and forward to server
# ---------------------------------------------------------------------------
# log_paths = [
# "/var/log/vela/hal.log",
# ]
``` **Required fields**:
- `server_address`: IP/hostname of Vela-Server instance **Optional**:
- `hal_service_port`: Change if port 50052 conflicts
- `tls_*`: Enable TLS for production deployments
- `log_paths`: Additional log files to tail (e.g., HAL library logs) --- ## Running ### Manual Execution **Development run** (foreground):
```bash/usr/bin/vela-client --config/etc/vela/client.conf
``` **With debug logging**:
```bash
SPDLOG_LEVEL=debug/usr/bin/vela-client --config/etc/vela/client.conf
``` The daemon will:
1. Load configuration from `/etc/vela/client.conf`
2. Initialize spool database
3. Connect to Vela-Server (retry on failure)
4. Start HalService listener on port 50052
5. Begin heartbeat loop **Graceful shutdown**: Send `SIGTERM` or `SIGINT` (Ctrl+C) --- ### Systemd Service **Enable and start**:
```bash
sudo systemctl enable vela-client.service
sudo systemctl start vela-client.service
``` **Check status**:
```bash
sudo systemctl status vela-client.service
``` **View logs**:
```bash
sudo journalctl -u vela-client.service -f # Follow logs
sudo journalctl -u vela-client.service -n 100 # Last 100 lines
``` **Stop service**:
```bash
sudo systemctl stop vela-client.service
``` **Restart after config changes**:
```bash
sudo systemctl restart vela-client.service
``` --- ## Testing ### Run Unit Tests ```bash
cd build/cross
ctest --output-on-failure
``` Or run individual test binaries:
```bash
./bin/test_result_serializer
./bin/test_run_orchestrator
``` ### Available Tests | Test | Purpose |
|------|---------|
| `test_result_serializer` | Validates HAL → Protobuf serialization |
| `test_run_orchestrator` | Tests orchestration logic and batching | ### Manual Integration Test 1. **Start Vela-Server** (on remote machine or localhost)
2. **Configure client** to point to server IP
3. **Run client** with `--config` flag
4. **Trigger test via SDK**: ```python # Python SDK example from vela_sdk import Client client = Client("localhost:50052") result = client.run_test("cpu", "frequency_test") print(result) ``` --- ## Project Structure ```
Vela-Client/
├── CMakeLists.txt # Root build configuration
├── Makefile # High-level build commands
├── Doxyfile.in # Doxygen documentation config
├── src/
│ ├── main.cpp # Entry point
│ ├── app.h/ app.cpp # Top-level App object
│ ├── common/ # Shared utilities
│ ├── config/ # Configuration parsing (TOML)
│ ├── stream/ # StreamClient (gRPC to server)
│ ├── spool/ # Spool (SQLite3 storage)
│ ├── run/ # RunOrchestrator (test execution)
│ ├── registry/ # ModuleRegistry + 35+ adapters
│ │ ├── AdapterBase.h # Base class for all adapters
│ │ ├── AdapterRegistry.h # Adapter registration/lookup
│ │ └── adapters/ # Module-specific adapters
│ │ ├── cpu_adapter.h
│ │ ├── gpu_adapter.h
│ │ ├── thermal_adapter.h
│ │ └── ... (35+ total)
│ ├── hal_service/ # HalService gRPC endpoint
│ ├── hal_bridge/ # ResultSerializer (HAL → Protobuf)
│ ├── log/ # LogCollector
│ ├── janitor/ # Cleanup tasks
│ └── diag/ # DiagSocket
├── tests/ # Unit tests (GoogleTest)
├── conf/
│ └── client.conf.sample # Sample configuration
├── systemd/
│ └── vela-client.service # Systemd unit file
├── docker/
│ ├── Dockerfile # ARM64 build container
│ └── Makefile # Docker build helpers
└── client_update/ # Design documents ├── 01_discovery.md ├── 02_plan.md └── ...
``` --- ## Supported Hardware Modules Vela-Client includes adapters for **35 hardware modules** (with 16 additional modules planned): ### Active Modules (35) | Category | Modules |
|----------|---------|
| **Compute** | CPU, GPU, Deep Learning Accelerator, Vision Accelerator |
| **Memory** | System Memory, Storage |
| **Thermal** | Thermal, Environmental |
| **Power** | Power Management, Watchdog and Reset |
| **Networking** | Ethernet, Ethernet Switch, Communication Interface |
| **Connectivity** | USB, PCIe, External Connector |
| **Peripherals** | GPIO, Camera Interfaces, Camera Module 3, Display Interfaces |
| **Sensors** | IMU, GNSS |
| **Audio/Video** | Audio Interfaces, Video Encode/Decode |
| **System** | Clock and Timing, Software Interface, System Integration |
| **Safety** | Functional Safety, Reliability, Security Features |
| **Debug** | Debug and Development Interfaces, MCU Interface |
| **Specialized** | Serializer/Deserializer, PoE HAT, Sense HAT | ### Phase 3 Modules (16 — Planned) Accelerometer, Analog Input, Battery, Bluetooth, CAN Bus, eMMC, I²C, MIPI CSI, MIPI DSI, NVMe, PWM Output, RS-485, RTC, SD Card, SPI, UART ### Stub Adapter Unrecognized modules fall back to `StubAdapter`, which logs test invocations but returns honest SKIPPED results. --- ## Development ### Coding Standards - **Language**: C++17
- **Style**: Follow existing conventions (see `.clang-format` if present)
- **Logging**: Use `spdlog` macros (`spdlog::info`, `spdlog::error`, etc.)
- **Error Handling**: Return `bool` or `Status` from init methods; log errors before returning ### Adding a New Module Adapter 1. **Create adapter files**: ```bash touch src/registry/adapters/my_module_adapter.h touch src/registry/adapters/my_module_adapter.cc ``` 2. **Implement `AdapterBase` interface**: ```cpp// my_module_adapter.h #pragma once #include "registry/AdapterBase.h" class MyModuleAdapter : public AdapterBase { public: std::string module_id const override { return "my_module"; } hal::TestResult run_test(const std::string& test_id, const TestParameters& params) override; }; ``` 3. **Register in `app.cpp`**: ```cpp #include "registry/adapters/my_module_adapter.h"// ... reg->register_adapter(std::make_unique<MyModuleAdapter>); ``` 4. **Build and test**: ```bash make build ./build/cross/bin/vela-client --config/etc/vela/client.conf ``` --- ## Troubleshooting ### Common Issues #### 1. **gRPC connection fails** ``` [ERROR] StreamClient failed to connect to 192.168.1.100:50051 ``` **Solution**: - Verify `server_address` in `/etc/vela/client.conf` - Check network connectivity: `ping 192.168.1.100` - Ensure Vela-Server is running and reachable - Check firewall rules: `sudo ufw status` #### 2. **Missing `grpc_cpp_plugin`** ``` CMake Error: grpc_cpp_plugin not found ``` **Solution**: ```bash sudo apt-get install -y protobuf-compiler-grpc # OR build from source (see Dockerfile) ``` #### 3. **Spool database locked** ``` [ERROR] Spool::init failed: database is locked ``` **Solution**: - Stop conflicting instance: `sudo systemctl stop vela-client` - Check for stale processes: `ps aux | grep vela-client` - Remove lock if safe: `rm/var/lib/vela/spool/spool.db-shm` #### 4. **Permission denied on `/var/lib/vela`** ``` [ERROR] Failed to create spool.db: Permission denied ``` **Solution**: ```bash sudo chown -R vela:vela/var/lib/vela sudo chmod 0755/var/lib/vela ``` #### 5. **HAL library not found** ``` CMake Error: Could not find Vela-HAL ``` **Solution**: - Ensure `Vela-HAL` is in sibling directory: ```bash ls -ld ../Vela-HAL # Should exist ``` - Clone HAL repository: `git clone <hal-repo> ../Vela-HAL` #### 6. **Port 50052 already in use** ``` [ERROR] HalService failed to bind: Address already in use ``` **Solution**: - Check what's using the port: `sudo lsof -i :50052` - Change `hal_service_port` in config, or kill conflicting process --- ### Debug Logging Enable verbose logging:
```bash
SPDLOG_LEVEL=debug/usr/bin/vela-client --config/etc/vela/client.conf
``` Or modify `main.cpp` and rebuild:
```cpp
spdlog::set_level(spdlog::level::debug);// Change from ::info
``` --- ### Getting Help - **Check logs**: `journalctl -u vela-client.service -n 200`
- **Inspect spool**: `sqlite3/var/lib/vela/spool/spool.db ".tables"`
- **Test connectivity**: `grpcurl -plaintext <server_ip>:50051 list`
- **GitHub Issues**: Report bugs with full logs and config (redact sensitive data) --- ## License [Specify license here — e.g., MIT, Apache 2.0, Proprietary] --- ## Contributing 1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-adapter`)
3. Commit changes (`git commit -am 'Add XYZ adapter'`)
4. Push to branch (`git push origin feature/my-adapter`)
5. Open a Pull Request **Guidelines**:
- Add tests for new functionality
- Update documentation
- Follow existing code style
- Ensure CI passes --- ## Acknowledgments - Built for IV&V hardware validation on Qualcomm QCS6490 and Qualcomm QCS6490 platforms
- Uses gRPC for efficient client-server communication
- Protocol Buffers for portable serialization
- SQLite3 for durable local storage --- **Questions?** Contact the Vela development team or file an issue on GitHub.
