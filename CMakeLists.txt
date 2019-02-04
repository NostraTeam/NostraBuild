cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

option(NOSTRA_BUILD_SHARED_TESTS "If enabled, the test libraries will be shared libraries." OFF)

project(NostraBuild
	VERSION 1.0.0.0
	DESCRIPTION "CMake module(s) and script(s) that are used to build Nostra packages."
	LANGUAGES NONE)

include("src/nostra/Nostra.cmake")

include(CTest)

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

add_test(
    NAME
        "ncm.cmake._nostra_check_no_parameters.wt"
    COMMAND
        "cmake" "-P" "_nostra_check_no_parameters.cmake"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/nostra_list_functions")
        
add_test(
    NAME
        "ncm.cmake._nostra_check_parameter.wt"
    COMMAND
        "cmake" "-P" "_nostra_check_parameter.cmake"
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/nostra_list_functions")
        
# Make sure the working directories exists for the next tests
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_nofail/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.1/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.2/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.3/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.4/build")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.5/build")

# Each of these tests call the commands "cmake ..", "cmake --build .", "ctest"; in that order and all of them need
# to be successful.

set(NOSTRA_CTEST_ADDITIONAL_FLAGS "--output-on-failure;-C;Debug")

if(NOSTRA_BUILD_SHARED_TESTS)
    set(NOSTRA_CMAKE_ADDITIONAL_FLAGS "-DNOSTRA_BUILD_SHARED=${NOSTRA_BUILD_SHARED_TESTS}")
endif()

add_test(
    NAME
        "ncm.cmake.nostra_add_c_test.wt"
    COMMAND
        "${CMAKE_COMMAND}"
            "-DNOSTRA_TEST_PROJECT_ROOT=${CMAKE_SOURCE_DIR}/test/nostra_add_c_test/CTestProject" 
            "-DNOSTRA_CMAKE_ADDITIONAL_FLAGS=${NOSTRA_CMAKE_ADDITIONAL_FLAGS}" 
            "-DNOSTRA_CTEST_ADDITIONAL_FLAGS=${NOSTRA_CTEST_ADDITIONAL_FLAGS}" 
            "-P" 
                "${CMAKE_SOURCE_DIR}/test/TestRunner.cmake")

add_test(
    NAME
        "ncm.cmake.nostra_add_cpp_test.wt"
    COMMAND
        "${CMAKE_COMMAND}"
            "-DNOSTRA_TEST_PROJECT_ROOT=${CMAKE_SOURCE_DIR}/test/nostra_add_cpp_test/CppTestProject" 
            "-DNOSTRA_CMAKE_ADDITIONAL_FLAGS=${NOSTRA_CMAKE_ADDITIONAL_FLAGS}" 
            "-DNOSTRA_CTEST_ADDITIONAL_FLAGS=${NOSTRA_CTEST_ADDITIONAL_FLAGS}" 
            "-P" 
                "${CMAKE_SOURCE_DIR}/test/TestRunner.cmake")

add_test(
    NAME
        "ncm.cmake.nostra_add_compile_test.wt"
    COMMAND
        "${CMAKE_COMMAND}"
            "-DNOSTRA_TEST_PROJECT_ROOT=${CMAKE_SOURCE_DIR}/test/nostra_add_compile_test/CompileTestProject" 
            "-DNOSTRA_CMAKE_ADDITIONAL_FLAGS=${NOSTRA_CMAKE_ADDITIONAL_FLAGS}" 
            "-DNOSTRA_CTEST_ADDITIONAL_FLAGS=${NOSTRA_CTEST_ADDITIONAL_FLAGS}" 
            "-P" 
                "${CMAKE_SOURCE_DIR}/test/TestRunner.cmake")

add_test(
    NAME
        "ncm.cmake.general_function_tests_nofail"
    COMMAND 
        "${CMAKE_COMMAND}" ".."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_nofail/build")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.1"
    COMMAND 
        "${CMAKE_COMMAND}" ".."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.1/build")

set_tests_properties("ncm.cmake.general_function_tests_fail.1" PROPERTIES WILL_FAIL "ON")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.2"
    COMMAND 
        "${CMAKE_COMMAND}" ".."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.2/build")
       
set_tests_properties("ncm.cmake.general_function_tests_fail.2" PROPERTIES WILL_FAIL "ON")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.3"
    COMMAND 
        "${CMAKE_COMMAND}" ".."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.3/build")
       
set_tests_properties("ncm.cmake.general_function_tests_fail.3" PROPERTIES WILL_FAIL "ON")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.4"
    COMMAND 
        "${CMAKE_COMMAND}" ".."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.4/build")

set_tests_properties("ncm.cmake.general_function_tests_fail.4" PROPERTIES WILL_FAIL "ON")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.5"
    COMMAND 
        "${CMAKE_COMMAND}" ".."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.5/build")

set_tests_properties("ncm.cmake.general_function_tests_fail.5" PROPERTIES WILL_FAIL "ON")  

install(
    FILES 
        "src/nostra/CreateProject.cmake" 
        "src/nostra/Documentation.cmake" 
        "src/nostra/Examples.cmake" 
        "src/nostra/ExportHeader.cmake" 
        "src/nostra/Nostra.cmake" 
        "src/nostra/PrivateHelpers.cmake" 
        "src/nostra/Testing.cmake" 
        "src/nostra/Utility.cmake"
    DESTINATION
        "nostra")

install(
    FILES
        "cmake/in/cmake/Config.cmake.in"
        "cmake/in/cmake/config.h.in"
        "cmake/in/cmake/CPackConfig.cmake.in"
        "cmake/in/cmake/Targets.cmake.in"
        "cmake/in/cmake/welcome.txt.in"
    DESTINATION
        "cmake/in/cmake")

install(
    FILES
        "cmake/in/doc/additional_doc.dox.in"
        "cmake/in/doc/Doxyfile.in"
        "cmake/in/doc/DoxygenLayout.xml.in"
        "cmake/in/doc/style.css.in"
    DESTINATION
        "cmake/in/doc")
        
install(
    FILES
        "cmake/in/.clang-format.in"
        "cmake/in/.clang-tidy.in"
        "cmake/in/.gitattributes.in"
        "cmake/in/.gitignore.in"
        "cmake/in/CMakeLists.txt.in"
        "cmake/in/LICENSE.in"
        "cmake/in/README.md.in"
    DESTINATION
        "cmake/in")

install(
    FILES
        "cmake/export.h.in"
    DESTINATION
        "cmake/")

install(
    FILES
        "src/nostra/nostra.sh"
    DESTINATION
        "bin"
    PERMISSIONS
        OWNER_WRITE 
        OWNER_READ 
        OWNER_EXECUTE 
        GROUP_READ
        GROUP_EXECUTE
        WORLD_READ
        WORLD_EXECUTE
    RENAME
        "nostra")

include(CMakePackageConfigHelpers)

write_basic_package_version_file("${CMAKE_BINARY_DIR}/NostraSocketWrapperConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY AnyNewerVersion)
     
install(
    FILES
        "${CMAKE_BINARY_DIR}/NostraSocketWrapperConfigVersion.cmake"
    DESTINATION
        "share/NostraBuild")

install(
    FILES
        "${CMAKE_SOURCE_DIR}/cmake/NostraBuildConfig.cmake"
    DESTINATION
        "share/NostraBuild")

configure_file("cmake/CPackConfig.cmake.in" "cmake/CPackConfig.cmake" @ONLY)
include("${CMAKE_BINARY_DIR}/cmake/CPackConfig.cmake")

include(CPack)
