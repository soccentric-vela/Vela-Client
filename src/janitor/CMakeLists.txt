add_library(vela_janitor STATIC
    Janitor.cc
)

target_include_directories(vela_janitor PRIVATE
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(vela_janitor PRIVATE
    vela_protos
    spdlog::spdlog
)
