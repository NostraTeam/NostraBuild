cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

include("src/Nostra.cmake")

include(CTest)

enable_testing()

add_test(
    NAME
        "ncm.cmake.nostra_prefix_list.wt"
    COMMAND
        "cmake" "-P" "nostra_prefix_list.cmake"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/nostra_list_functions")

add_test(
    NAME
        "ncm.cmake.nostra_suffix_list.wt"
    COMMAND
        "cmake" "-P" "nostra_suffix_list.cmake"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/nostra_list_functions")

# Make sure the working directory exists for the next test
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/nostra_add_c_test/CTestProject/build")

add_test(
    NAME
        "ncm.cmake.nostra_add_c_test.wt"
    COMMAND
        "cmake" ".."
    WORKING_DIRECTORYt
        "${CMAKE_SOURCE_DIR}/test/nostra_add_c_test/CTestProject/build")
        
# Make sure the working directory exists for the next test
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/nostra_add_cpp_test/CppTestProject/build")

add_test(
    NAME
        "ncm.cmake.nostra_add_cpp_test.wt"
    COMMAND
        "cmake" ".."
    WORKING_DIRECTORYt
        "${CMAKE_SOURCE_DIR}/test/nostra_add_cpp_test/CppTestProject/build")
        