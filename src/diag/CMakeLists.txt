add_library(vela_diag STATIC DiagSocket.cc
) target_include_directories(vela_diag PRIVATE ${CMAKE_SOURCE_DIR}/src
) target_link_libraries(vela_diag PRIVATE spdlog::spdlog
)
