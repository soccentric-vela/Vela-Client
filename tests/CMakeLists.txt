# ---------------------------------------------------------------------------
# tests/CMakeLists.txt
# --------------------------------------------------------------------------- # GTest
find_package(GTest REQUIRED) # ---------------------------------------------------------------------------
# test_result_serializer — unit tests for hal_bridge serialization
# --------------------------------------------------------------------------- add_executable(test_result_serializer test_result_serializer.cc
) target_include_directories(test_result_serializer PRIVATE ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/../Vela-HAL/src
) target_link_libraries(test_result_serializer PRIVATE vela_hal_bridge vela_protos spdlog::spdlog GTest::gtest_main
) add_test(NAME serializer_tests COMMAND test_result_serializer) # ---------------------------------------------------------------------------
# test_run_orchestrator — integration tests for RunOrchestrator
# --------------------------------------------------------------------------- add_executable(test_run_orchestrator test_run_orchestrator.cc
) target_include_directories(test_run_orchestrator PRIVATE ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/../Vela-HAL/src
) target_link_libraries(test_run_orchestrator PRIVATE vela_hal_bridge vela_registry vela_spool vela_stream vela_run vela_protos spdlog::spdlog SQLite::SQLite3 yaml-cpp::yaml-cpp ${VELA_GRPC_LIBRARIES} protobuf::libprotobuf GTest::gtest_main
) add_test(NAME runner_tests COMMAND test_run_orchestrator)
