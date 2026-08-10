add_library(vela_log STATIC LogCollector.cc
) target_include_directories(vela_log PRIVATE ${CMAKE_SOURCE_DIR}/src
) target_link_libraries(vela_log PRIVATE vela_protos spdlog::spdlog
)
