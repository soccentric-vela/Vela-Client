add_library(vela_stream STATIC
    StreamClient.cc
)

target_include_directories(vela_stream PRIVATE
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(vela_stream PRIVATE
    vela_protos
    ${VELA_GRPC_LIBRARIES}
    spdlog::spdlog
)
