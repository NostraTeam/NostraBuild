cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

option(NOSTRA_BUILD_SHARED_TESTS "If enabled, the test libraries will be shared libraries." OFF)

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
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/nostra_add_compile_test/CompileTestProject/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_nofail/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.1/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.2/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.3/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.4/build")

# Each of these tests call the commands "cmake ..", "cmake --build .", "ctest"; in that order and all of them need
# to be successful.

if(NOSTRA_BUILD_SHARED_TESTS)
    set(NOSTRA_CMAKE_ADDITIONAL_FLAGS "-DNOSTRA_BUILD_SHARED=${NOSTRA_BUILD_SHARED_TESTS}")
endif()

add_test(
    NAME
        "ncm.cmake.nostra_add_c_test.wt"
    COMMAND
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} ${NOSTRA_CMAKE_ADDITIONAL_FLAGS} .. && ${CMAKE_COMMAND} --build . && ${CMAKE_CTEST_COMMAND}"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/nostra_add_c_test/CTestProject/build")
      
add_test(
    NAME
        "ncm.cmake.nostra_add_cpp_test.wt"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} ${NOSTRA_CMAKE_ADDITIONAL_FLAGS} .. && ${CMAKE_COMMAND} --build . && ${CMAKE_CTEST_COMMAND}"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/nostra_add_cpp_test/CppTestProject/build")

add_test(
    NAME
        "ncm.cmake.nostra_add_compile_test.wt"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} ${NOSTRA_CMAKE_ADDITIONAL_FLAGS} .. && ${CMAKE_COMMAND} --build . && ${CMAKE_CTEST_COMMAND} --output-on-failure"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/nostra_add_compile_test/CompileTestProject/build")
        
add_test(
    NAME
        "ncm.cmake.general_function_tests_nofail"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_nofail/build")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.1"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .. || echo Failed"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.1/build")

set_property(TEST "ncm.cmake.general_function_tests_fail.1" PROPERTY PASS_REGULAR_EXPRESSION "Failed")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.2"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .. || echo Failed"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.2/build")
       
set_property(TEST "ncm.cmake.general_function_tests_fail.2" PROPERTY PASS_REGULAR_EXPRESSION "Failed")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.3"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .. || echo Failed"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.3/build")
       
 set_property(TEST "ncm.cmake.general_function_tests_fail.3" PROPERTY PASS_REGULAR_EXPRESSION "Failed")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.4"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .. || echo Failed"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.4/build")

set_property(TEST "ncm.cmake.general_function_tests_fail.4" PROPERTY PASS_REGULAR_EXPRESSION "Failed")      
