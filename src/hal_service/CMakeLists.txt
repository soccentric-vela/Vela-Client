add_library(vela_hal_service STATIC
    HalServiceImpl.cc
)

target_include_directories(vela_hal_service PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/../Vela-HAL/src
)

target_link_libraries(vela_hal_service PRIVATE
    vela_registry
    vela_hal_bridge
    vela_protos
    ${VELA_GRPC_LIBRARIES}
    protobuf::libprotobuf
    spdlog::spdlog
)
