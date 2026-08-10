#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "common/result.h"

namespace vela::client::config {

struct ClientConfig {
    // gRPC server (outbound — connects to Vela-Server)
    std::string server_address;
    uint16_t    server_port{50051};

    // HalService listener (inbound — PySDK connects here; no DB writes)
    // Default port 50052; set hal_service_bind = "127.0.0.1" to restrict access.
    std::string hal_service_bind{"0.0.0.0"};
    uint16_t    hal_service_port{50052};

    // Identity — loaded or generated at startup; persisted separately.
    // client_id_path is the file where the UUID is stored; override in tests.
    std::string client_id;
    std::string client_id_path{"/var/lib/vela/client_id"};

    // Spool
    std::string spool_path{"/var/lib/vela/spool/spool.db"};
    uint64_t    result_spool_cap_bytes{2ULL * 1024 * 1024 * 1024};
    uint64_t    log_spool_cap_bytes{500ULL * 1024 * 1024};

    // Extra log paths to tail
    std::vector<std::string> log_paths;

    // Path to modules.yaml (read-only reference to HAL registry)
    std::string modules_yaml_path{"/etc/vela/modules.yaml"};

    // TLS (empty = plaintext; used in a later step)
    std::string tls_ca;
    std::string tls_cert;
    std::string tls_key;

    // Parse /etc/vela/client.conf (TOML).
    // Also loads or creates /var/lib/vela/client_id.
    static Result<ClientConfig> load(const std::string& path);
};

} // namespace vela::client::config
