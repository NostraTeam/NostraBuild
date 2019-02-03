cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

option(NOSTRA_BUILD_SHARED_TESTS "If enabled, the test libraries will be shared libraries." OFF)

project(NostraCMake
	VERSION 1.0.0.0
	DESCRIPTION "CMake module(s) and script(s) to support the Nostra Project."
	LANGUAGES NONE)

include("src/nostra/Nostra.cmake")

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
        
# TODO: Clean up the following process, if possible, do not rely on platform specific cmd line interpreters

# Choose cmd line interpreter for the command; cmd.exe on Windows, Bourne Shell on Unix. 
if(WIN32)
    set(NOSTRA_CMAKE_CTEST_COMMAND "cmd.exe" "/C")
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
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.5/build")

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
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.1/build")

set_tests_properties("ncm.cmake.general_function_tests_fail.1" PROPERTIES WILL_FAIL "ON")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.2"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.2/build")
       
set_tests_properties("ncm.cmake.general_function_tests_fail.2" PROPERTIES WILL_FAIL "ON")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.3"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.3/build")
       
set_tests_properties("ncm.cmake.general_function_tests_fail.3" PROPERTIES WILL_FAIL "ON")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.4"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.4/build")

set_tests_properties("ncm.cmake.general_function_tests_fail.4" PROPERTIES WILL_FAIL "ON")

add_test(
    NAME
        "ncm.cmake.general_function_tests_fail.5"
    COMMAND 
        ${NOSTRA_CMAKE_CTEST_COMMAND} "${CMAKE_COMMAND} .."
    WORKING_DIRECTORY
        "${CMAKE_SOURCE_DIR}/test/general_function_tests_fail.5/build")

set_tests_properties("ncm.cmake.general_function_tests_fail.5" PROPERTIES WILL_FAIL "ON")  

#[=[
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    if(UNIX)
        set (CMAKE_INSTALL_PREFIX "/opt/nostracmake-${PROJECT_VERSION}" CACHE PATH "Install path prefix, prepended onto install directories." FORCE )
    elseif(WIN32)
        set (CMAKE_INSTALL_PREFIX "C:/Program Files/nostracmake-${PROJECT_VERSION}" CACHE PATH "Install path prefix, prepended onto install directories." FORCE )
endif()#]=]

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
        "nostra"
    COMPONENT
        "Required")

install(
    FILES
        "cmake/in/cmake/Config.cmake.in"
        "cmake/in/cmake/config.h.in"
        "cmake/in/cmake/CPackConfig.cmake.in"
        "cmake/in/cmake/Targets.cmake.in"
        "cmake/in/cmake/welcome.txt.in"
    DESTINATION
        "cmake/in/cmake"
    COMPONENT
        "Required")

install(
    FILES
        "cmake/in/doc/additional_doc.dox.in"
        "cmake/in/doc/Doxyfile.in"
        "cmake/in/doc/DoxygenLayout.xml.in"
        "cmake/in/doc/style.css.in"
    DESTINATION
        "cmake/in/doc"
    COMPONENT
        "Required")
        
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
        "cmake/in"
    COMPONENT
        "Required")

install(
    FILES
        "cmake/export.h.in"
    DESTINATION
        "cmake/"
    COMPONENT
        "Required")

include(CMakePackageConfigHelpers)

write_basic_package_version_file("${CMAKE_BINARY_DIR}/NostraSocketWrapperConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY AnyNewerVersion)
     
install(
    FILES
        "${CMAKE_BINARY_DIR}/NostraSocketWrapperConfigVersion.cmake"
    DESTINATION
        "share/NostraCMake"
    COMPONENT
        "Required")

install(
    FILES
        "${CMAKE_SOURCE_DIR}/cmake/NostraCMakeConfig.cmake"
    DESTINATION
        "share/NostraCMake"
    COMPONENT
        "Required")

include(CPack)
