# ---------------------------------------------------------------------------
# src/CMakeLists.txt
# Adds each module as a static library then defines the main executable.
# Subdirectories are ordered leaf-first so inter-target references resolve.
# ---------------------------------------------------------------------------

add_subdirectory(config)
add_subdirectory(diag)
add_subdirectory(spool)
add_subdirectory(stream)
add_subdirectory(hal_bridge)
add_subdirectory(registry)
add_subdirectory(ota)
add_subdirectory(log)
add_subdirectory(janitor)
add_subdirectory(run)
add_subdirectory(hal_service)

# ---------------------------------------------------------------------------
# Main executable
# ---------------------------------------------------------------------------

add_executable(vela-client
    main.cpp
    app.cpp
)

target_include_directories(vela-client PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/../Vela-HAL/src
)

target_link_libraries(vela-client PRIVATE
    vela_config
    vela_diag
    vela_hal_bridge
    vela_hal_service
    vela_janitor
    vela_log
    vela_ota
    vela_registry
    vela_run
    vela_spool
    vela_stream
    vela_protos
    spdlog::spdlog
    tomlplusplus::tomlplusplus
    yaml-cpp::yaml-cpp
    SQLite::SQLite3
    ${VELA_GRPC_LIBRARIES}
    protobuf::libprotobuf
)

target_compile_definitions(vela-client PRIVATE
    VELA_CLIENT_VERSION="${PROJECT_VERSION}"
)

set_compiler_warnings(vela-client)
