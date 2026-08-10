add_library(vela_ota STATIC
    OtaClient.cc
)

target_include_directories(vela_ota PRIVATE
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(vela_ota PRIVATE
    vela_protos
    ${VELA_GRPC_LIBRARIES}
    spdlog::spdlog
)
