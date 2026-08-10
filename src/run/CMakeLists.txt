add_library(vela_run STATIC
    RunOrchestrator.cc
)

target_include_directories(vela_run PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/../Vela-HAL/src
)

target_link_libraries(vela_run PRIVATE
    vela_hal_bridge
    vela_protos
    spdlog::spdlog
)
