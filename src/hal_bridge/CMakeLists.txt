add_library(vela_hal_bridge STATIC
    ResultSerializer.cc
)

target_include_directories(vela_hal_bridge PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/../Vela-HAL/src
)

target_link_libraries(vela_hal_bridge PRIVATE
    vela_protos
    spdlog::spdlog
)
