add_library(vela_spool STATIC
    Spool.cc
)

target_include_directories(vela_spool PRIVATE
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(vela_spool PRIVATE
    vela_protos
    SQLite::SQLite3
    spdlog::spdlog
)
