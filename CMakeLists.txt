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

# TODO: Clean up the following process, if possible, do not rely on platform specific cmd line interpreters

# Choose cmd line interpreter for the command; cmd.exe on Windows, Bourne Shell on Unix. 
if(WIN32)
    set(NOSTRA_CMD_INTERPRETER "cmd.exe" "/C")
else()
    set(NOSTRA_CMAKE_CTEST_COMMAND "sh" "-c")
endif()

# Make sure the working directories exists for the next tests
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/nostra_add_c_test/CTestProject/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/nostra_add_cpp_test/CppTestProject/build")

# Each of these tests call the commands "cmake ..", "cmake --build .", "ctest"; in that order and all of them need
# to be successful.

add_test(
    NAME
        "ncm.cmake.nostra_add_c_test.wt"
    COMMAND
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .. && ${CMAKE_COMMAND} --build . && ${CMAKE_CTEST_COMMAND}"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/nostra_add_c_test/CTestProject/build")
      
add_test(
    NAME
        "ncm.cmake.nostra_add_cpp_test.wt"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .. && ${CMAKE_COMMAND} --build . && ${CMAKE_CTEST_COMMAND}"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/nostra_add_cpp_test/CppTestProject/build")