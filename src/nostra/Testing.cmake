cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include("${CMAKE_CURRENT_LIST_DIR}/PrivateHelpers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Utility.cmake")

#[[
# Parameters:
#   - RESOURCE_IN:  The directory to copy from
#   - RESOURCE_OUT: The directory to copy to
#
# Copies everything from RESOURCE_IN to RESOURCE_OUT, but only if RESOURCE_IN exists.
#]]
function(_nostra_copy_resources_dir RESOURCE_IN RESOURCE_OUT)
    _nostra_check_no_parameters()  
    if(EXISTS "${RESOURCE_IN}")
        file(COPY "${RESOURCE_IN}" DESTINATION "${RESOURCE_OUT}")
    endif()
endfunction()

#[[
# Parameters:
#   - OUT_VAR:  The output variable.
#   - LANGUAGE: The language.
#
# Stores the language of the orignal test in OUT_VAR. c for LANGUAGE=c or = c.cpp and cpp for LANGUAGE=cpp.
#]]
function(_nostra_get_original_language OUT_VAR LANGUAGE)
    _nostra_check_no_parameters()

    if(LANGUAGE STREQUAL "c" OR LANGUAGE STREQUAL "c.cpp")
        set("${OUT_VAR}" "c" PARENT_SCOPE)
    elseif(LANGUAGE STREQUAL "cpp")
        set("${OUT_VAR}" "cpp" PARENT_SCOPE)
    else()
        nostra_send_error("Invalid language ${LANGUAGE}")
    endif()
endfunction()

#[[
# Parameters:
#   - TEST_TARGET: The target to set the requirement of.
#   - WILL_FAIL:   If TRUE, the test is supposed to fail, if not, it is supposed to succeed.
#
# Sets the success requirement of a test by either setting the test property WILL_FAIL to ON or OFF.
#]]
function(_nostra_set_test_success_requirement TEST_TARGET WILL_FAIL)
    _nostra_check_no_parameters()    

    if(NOT TARGET "${TEST_TARGET}")
        nostra_send_error("${TEST_TARGET} is not a test target")
    endif()

    if(WILL_FAIL)
        set_tests_properties("${TARGET_NAME}" PROPERTIES WILL_FAIL "ON")
    else()
        set_tests_properties("${TARGET_NAME}" PROPERTIES WILL_FAIL "OFF")
    endif()
endfunction()

#[[
# Parameters:
#   - TEST_NAME:            The name of the test.
#   - LANGUAGE:             The language of the test. Either c, c.cpp or cpp.
#   - EXEC_TYPE:            The execution type. Either ex or bu.
#   - TEST_TYPE:            The test type. Either wt or bt.
#   - TEST_TARGET:          The target that will be tested, i.e. the target that will be linked against.
#   - SHOULD_FAIL:          If TRUE, the test is expected to fail.
#   - ADDITIONAL_SOURCES:   Additional source files. Relative to /test/<test dir>/src.
#
# A helper for both ex and bu tests, that does checks and sets variables that are shared by all execution types.
# This helper does:
# - set TARGET_NAME and DIR_NAME
# - check that all the parameters have proper values
# - create a single source file list FUNC_ACTUAL_ADD_SOURCES (this includes the default test file)
# - set the language of that list
#]]
macro(_nostra_add_any_test_helper LANGUAGE EXEC_TYPE)
    cmake_parse_arguments(FUNC "SHOULD_FAIL" "TEST_TARGET;TEST_TYPE;TEST_NAME" "ADDITIONAL_SOURCES" "${ARGN}")

    _nostra_check_parameters()
    _nostra_check_if_lib(${FUNC_TEST_TARGET})
    _nostra_check_if_nostra_project()

    _nostra_get_original_language(ORIGINAL_LANGUAGE ${LANGUAGE})

    if(NOT DEFINED FUNC_TEST_NAME)
        nostra_send_error("TEST_NAME is required.")
    endif()

    if(NOT DEFINED FUNC_TEST_TYPE)
        nostra_send_error("TEST_TYPE is required.")
    endif()

    if(NOT ("${FUNC_TEST_TYPE}" STREQUAL "wt" OR "${FUNC_TEST_TYPE}" STREQUAL "bt"))
        nostra_send_error("Invalid test type (only wt and bt are allowed).")
    endif()

    if(NOT ("${EXEC_TYPE}" STREQUAL "bu" OR "${EXEC_TYPE}" STREQUAL "ex"))
        nostra_send_error("Invalid execution type (only bu and ex are allowed).")
    endif()

    if(NOT DEFINED FUNC_TEST_TARGET)
        nostra_send_error("parameter TEST_TARGET is required")
    endif()

    if(FUNC_SHOULD_FAIL)
        set(SUCCESS_REQUIREMENT "f")
    else()
        set(SUCCESS_REQUIREMENT "s")
    endif()

    # The name of the test executable
    set(TARGET_NAME "${PROJECT_PREFIX}.${LANGUAGE}.${EXEC_TYPE}.${SUCCESS_REQUIREMENT}.${FUNC_TEST_NAME}.${FUNC_TEST_TYPE}")
    set(DIR_NAME "test/${PROJECT_PREFIX}.${ORIGINAL_LANGUAGE}.${EXEC_TYPE}.${SUCCESS_REQUIREMENT}.${FUNC_TEST_NAME}.${FUNC_TEST_TYPE}.d")

    _nostra_print_debug("============================")
    _nostra_print_debug("Creating new test")
    _nostra_print_debug_value(TARGET_NAME)
    _nostra_print_debug_value(DIR_NAME)
    _nostra_print_debug_value(FUNC_TEST_TARGET)
    _nostra_print_debug_value(FUNC_ADDITIONAL_SOURCES)
    _nostra_print_debug_value(LANGUAGE)
    _nostra_print_debug_value(FUNC_TEST_TYPE)

    # Add the default test file to FUNC_ADDITIONAL_SOURCES. This way, they can be handled as one
    list(APPEND FUNC_ADDITIONAL_SOURCES "test.${ORIGINAL_LANGUAGE}")

    # Properly prefix the additional source files to locate them in test/<test name>.d/src/
    nostra_prefix_list(FUNC_ACTUAL_ADD_SOURCES "${DIR_NAME}/src/" "${FUNC_ADDITIONAL_SOURCES}")

    _nostra_set_source_file_language(${LANGUAGE} ${FUNC_ACTUAL_ADD_SOURCES})

    _nostra_print_debug_value(FUNC_ACTUAL_ADD_SOURCES)
    _nostra_print_debug("main source file=${DIR_NAME}/src/test.${LANGUAGE}")
endmacro()


#[[
# Parameters:
#   - TEST_NAME:                     The name of the test.
#   - LANGUAGE:                      The language of the test. Determines the names of files/directories and file
#                                    extensions of the source files.
#   - TEST_TARGET:                   The target to test, i.e. the target to link against. 
#   - NOCOPY [optional]:             If TRUE, the resources will not be copied and the working directory is somewhere 
#   - Any additional parameters that are used by _nostra_add_any_test_helper().
# 
# A helper to add execution tests.
# This helper will:
# - Copy the resources in /test/<test dir>/resources to <binary dir>/test/<test dir>/resources (only if NOCOPY is 
#   FALSE)
# - call _nostra_add_any_test_helper()
# - Add an executable with the source files that are listed in _nostra_add_any_test_helper()'s FUNC_ACTUAL_ADD_SOURCES
# - Install that executable into the export target PROJECT_EXPORT.
# - Add the excutable as test (using add_test()). The working directory of that test will either be 
#   /test/<test directory> or <binary dir>/test/<test directory>, depending on NOCOPY being TRUE or FALSE.
# - Set the success requirement according to _nostra_add_any_test_helper()'s SHOULD_FAIL
#]]
function(_nostra_add_ex_test_helper LANGUAGE)
    cmake_parse_arguments("FUNC" "NOCOPY" "" "" "${ARGN}")    

    _nostra_add_any_test_helper("${LANGUAGE}" "ex" "${FUNC_UNPARSED_ARGUMENTS}")

    # Set WORKING_DIR and copy resources if necessary
    if(NOT FUNC_NOCOPY)
        # Set working dir to ${DIR_NAME} in the binary dir because resources have been copied
        set(WORKING_DIR "${CMAKE_CURRENT_BINARY_DIR}/${DIR_NAME}")

        # Make sure the working directory for the command exists
        # This is only required if the resources were copied
        file(MAKE_DIRECTORY "${WORKING_DIR}")

        _nostra_print_debug("Copy resources from: ${DIR_NAME}/resources")
        _nostra_print_debug("Copy resources to:   ${CMAKE_CURRENT_BINARY_DIR}/${DIR_NAME}")

        _nostra_copy_resources_dir("${DIR_NAME}/resources" "${CMAKE_CURRENT_BINARY_DIR}/${DIR_NAME}")
    else()
        # Set working dir to ${DIR_NAME} in the source dir because resources have not been copied
        set(WORKING_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${DIR_NAME}")
    endif()

    add_executable("${TARGET_NAME}" "${FUNC_ACTUAL_ADD_SOURCES}")

    target_link_libraries("${TARGET_NAME}" 
        PRIVATE
            "${FUNC_TEST_TARGET}")

    install(TARGETS "${TARGET_NAME}" EXPORT "${PROJECT_EXPORT}"
        RUNTIME 
            DESTINATION "${DIR_NAME}"
            COMPONENT "Test")

    # Install ressources folder from the SOURCES directory (if it exists)
    if(EXISTS "${DIR_NAME}/resources")
        install(DIRECTORY "${DIR_NAME}/resources" 
            DESTINATION
                "${DIR_NAME}"
            COMPONENT 
                "Test")
    endif()

    # Add the actual test to CTest
    add_test(
        NAME 
            "${TARGET_NAME}"
        COMMAND 
            "${TARGET_NAME}"
        WORKING_DIRECTORY
            "${WORKING_DIR}")

    _nostra_set_test_success_requirement("${TARGET_NAME}" "${FUNC_SHOULD_FAIL}")
endfunction()

#[=[
# nostra_add_c_test(TEST_NAME <name> 
#                   TEST_TYPE <type> 
#                   TEST_TARGET <target> 
#                   [ADDITIONAL_SOURCES [source1 [source2 [source3 ...]]]] 
#                   [TEST_CPP] 
#                   [NOCOPY]
#                   [SHOULD_FAIL])
#
# A function that creates unit tests for C that test a single target. 
# The tests need to have the layout that is defined by the Nostra convention.
#
# TEST_NAME:
#   The name of the test. According to the Nostra convention, this is the name of the component that the test is for
#   (or another fitting name if the test does not test a single component).
#
# TEST_TYPE:
#   The type of the test. The actual value can either be wt (if the test is a whitebox test) or bt (if the test is a 
#   blackbox test).
#
# TEST_TARGET:
#   The target to test, i.e. the target that the test executable will be linked aginst.
# 
# ADDITIONAL_SOURCES:
#   Additional source files that are required aside from test.c. The paths that are passed are relative to 
#   /test/<test directory>/src.
#
# TEST_CPP:
#   If set, the entire test will be added a second time, but as C++ test (the language in the full test name will be
#   c.cpp). This is useful to check if a C library also works when linked against a C++ executable. The source files 
#   will be exactly the same, with the only difference being that they will be compiled as C++ code instead of C code.
#   Not that, even if NOCOPY is set, the resources of the C++ test will still be copied. Hence, the C++ test never has
#   the same working directory than the C test that it belongs to it.
#
# NOCOPY:
#   If set, the files in /test/<test directory>/resouces will not be copied into the build directory. Note that, if
#   this flag is set, a test may change the source directory. Also, if the flag is set, the working directory will be
#   in /test/<test directory> instead of the directory that the resources were copied to in the build directory.
# 
# SHOULD_FAIL:
#   If set, the test counts as successful, if the exit code of the executable is not zero (0). Otherwise, the test 
#   counts as successful, if the exit code is zero (0).
#
# Unless the flag NOCOPY has been passed, the files from test/<test name>/resources will be copied into the build
# directory and the test executable will be executed in that directory.
# 
# The tests will have the name <project prefix>.c.ex.<success requirement>.<test name>.<test type> (<success 
# requirement> is "s", if SHOULD_FAIL was not passed and "f" if it was).
#
# Note that, the file extensions of the provided source files are ignored - they will always be compiled as C code.
#
# This function can only be called, if nostra_project() was called first. Also CTest needs to be included using 
# include() and enable_testing() needs to have been called.
#
# Additionally, the tests added by this function will only be added and build if BUILD_TESTING is TRUE.
#]=]
function(nostra_add_c_test)
    if(BUILD_TESTING)
        cmake_parse_arguments(FUNC "TEST_CPP" "" "" "${ARGN}")

        _nostra_add_ex_test_helper("c" "${FUNC_UNPARSED_ARGUMENTS}")

        # remove NOCOPY from the unparsed args b/c c.cpp must be copied
        cmake_parse_arguments(FUNC "NOCOPY" "" "" "${FUNC_UNPARSED_ARGUMENTS}") 

        if(FUNC_TEST_CPP)
            _nostra_add_ex_test_helper("c.cpp" "${FUNC_UNPARSED_ARGUMENTS}")
        endif()
    endif()
endfunction()

#[=[
# nostra_add_cpp_test(TEST_NAME <name> 
#                     TEST_TYPE <type> 
#                     TEST_TARGET <target> 
#                     [ADDITIONAL_SOURCES [source1 [source2 [source3 ...]]]] 
#                     [NOCOPY]
#                     [SHOULD_FAIL])
#
# A function that creates unit tests for C++ that test a single target. 
# The tests need to have the layout that is defined by the Nostra convention.
#
# TEST_NAME:
#   The name of the test. According to the Nostra convention, this is the name of the component that the test is for
#   (or another fitting name if the test does not test a single component).
#
# TEST_TYPE:
#   The type of the test. The actual value can either be wt (if the test is a whitebox test) or bt (if the test is a 
#   blackbox test).
#
# TEST_TARGET:
#   The target to test, i.e. the target that the test executable will be linked aginst.
# 
# ADDITIONAL_SOURCES:
#   Additional source files that are required aside from test.cpp. The paths that are passed are relative to 
#   /test/<test directory>/src.
#
# NOCOPY:
#   If set, the files in /test/<test directory>/resouces will not be copied into the build directory. Note that, if
#   this flag is set, a test may change the source directory. Also, if the flag is set, the working directory will be
#   in /test/<test directory> instead of the directory that the resources were copied to in the build directory.
# 
# SHOULD_FAIL:
#   If set, the test counts as successful, if the exit code of the executable is not zero (0). Otherwise, the test 
#   counts as successful, if the exit code is zero (0).
#
# Unless the flag NOCOPY has been passed, the files from test/<test name>/resources will be copied into the build
# directory and the test executable will be executed in that directory.
# 
# The tests will have the name <project prefix>.cpp.ex.<success requirement>.<test name>.<test type> (<success 
# requirement> is "s", if SHOULD_FAIL was not passed and "f" if it was).
#
# Note that, the file extensions of the provided source files are ignored - they will always be compiled as C++ code.
#
# This function can only be called, if nostra_project() was called first. Also CTest needs to be included using 
# include() and enable_testing() needs to have been called.
#
# Additionally, the tests added by this function will only be added and build if BUILD_TESTING is TRUE.
#]=]
# TOOD add links to nostra convention
# TODO Add support for test numbers
function(nostra_add_cpp_test)
    if(BUILD_TESTING)
        _nostra_add_ex_test_helper("cpp" "${ARGN}")
    endif()
endfunction()

#[[
# Parameters:
#   - TEST_NAME:                     The name of the test.
#   - TEST_TYPE:                     wt or bt
#   - LANGUAGE:                      Either c or cpp, determines parts of the name of the test.
#   - TEST_TARGET:                   The target to test, i.e. the target to link against. 
#   - SHOULD_FAIL [flag, optional]:  If set, the test will succeed if the compilation fails.
#   - ADDITIONAL_SOURCES [optional]: Additional source files required aside from the default one.
#
# A helper for nostra_add_c_compile_test() and nostra_add_cpp_compile_test().
#
# A function that creates unit tests that, instead of running an executable, will attempt to compile a program. If that
# compilation succeeds (or fails if SHOULD_FAIL is set), the test will be successful.
#
# This function can only be called, if nostra_project() was called first.
#]]
# TODO: Add support for multiple, additional targets
# TODO: Add required resource files for tests
function(_nostra_add_bu_test_helper LANGUAGE)
    _nostra_add_any_test_helper("${LANGUAGE}" "bu" "${ARGN}")    

    # Use library because that way, no main() is needed
    add_library("${TARGET_NAME}" 
        STATIC 
        EXCLUDE_FROM_ALL # should not be build with the other targets, instead this is build during CTest
        "${DIR_NAME}/src/test.${LANGUAGE}" # default source file
        "${FUNC_ACTUAL_ADD_SOURCES}")

    target_link_libraries("${TARGET_NAME}" 
        PRIVATE
            "${FUNC_TEST_TARGET}")

    # Add the actual test to CTest
    add_test(
        NAME 
            "${TARGET_NAME}"
        COMMAND 
            # In this case, this must be CMAKE_BINARY_DIR instead of CMAKE_CURRENT_BINARY_DIR
            "${CMAKE_COMMAND}" "--build" "${CMAKE_BINARY_DIR}" "--target" "${TARGET_NAME}")
    
    _nostra_set_test_success_requirement("${TARGET_NAME}" "${FUNC_SHOULD_FAIL}")
endfunction()

#[=[
# nostra_add_c_compile_test(TEST_NAME <name> 
#                           TEST_TYPE <type> 
#                           TEST_TARGET <target> 
#                           [ADDITIONAL_SOURCES [source1 [source2 [source3 ...]]]] 
#                           [NOCOPY]
#                           [SHOULD_FAIL])
#
# A function that creates unit tests for C that test a single target. Tests that are created by this function will only
# be build but not executed.
# The tests need to have the layout that is defined by the Nostra convention.
#
# TEST_NAME:
#   The name of the test. According to the Nostra convention, this is the name of the component that the test is for
#   (or another fitting name if the test does not test a single component).
#
# TEST_TYPE:
#   The type of the test. The actual value can either be wt (if the test is a whitebox test) or bt (if the test is a 
#   blackbox test).
#
# TEST_TARGET:
#   The target to test, i.e. the target that the test executable will be linked aginst.
# 
# ADDITIONAL_SOURCES:
#   Additional source files that are required aside from test.c. The paths that are passed are relative to 
#   /test/<test directory>/src.
#
# SHOULD_FAIL:
#   If set, the test counts as successful if the build fails. Otherwise, the test counts as successful if the build 
#   succeeds.
#
# The tests will have the name <project prefix>.c.bu.<success requirement>.<test name>.<test type> (<success 
# requirement> is "s", if SHOULD_FAIL was not passed and "f" if it was).
#
# Note that, the file extensions of the provided source files are ignored - they will always be compiled as C code.
#
# This function can only be called, if nostra_project() was called first. Also CTest needs to be included using 
# include() and enable_testing() needs to have been called.
#
# Additionally, the tests added by this function will only be added and build if BUILD_TESTING is TRUE.
#]=]
function(nostra_add_c_compile_test)
    if(BUILD_TESTING)
        _nostra_add_bu_test_helper("c" ${ARGN})    
    endif()
endfunction()

#[=[
# nostra_add_cpp_compile_test(TEST_NAME <name> 
#                             TEST_TYPE <type> 
#                             TEST_TARGET <target> 
#                             [ADDITIONAL_SOURCES [source1 [source2 [source3 ...]]]] 
#                             [NOCOPY]
#                             [SHOULD_FAIL])
#
# A function that creates unit tests for C++ that test a single target. Tests that are created by this function will 
# only be build but not executed.
# The tests need to have the layout that is defined by the Nostra convention.
#
# TEST_NAME:
#   The name of the test. According to the Nostra convention, this is the name of the component that the test is for
#   (or another fitting name if the test does not test a single component).
#
# TEST_TYPE:
#   The type of the test. The actual value can either be wt (if the test is a whitebox test) or bt (if the test is a 
#   blackbox test).
#
# TEST_TARGET:
#   The target to test, i.e. the target that the test executable will be linked aginst.
# 
# ADDITIONAL_SOURCES:
#   Additional source files that are required aside from test.cpp. The paths that are passed are relative to 
#   /test/<test directory>/src.
#
# SHOULD_FAIL:
#   If set, the test counts as successful if the build fails. Otherwise, the test counts as successful if the build 
#   succeeds.
#
# The tests will have the name <project prefix>.cpp.bu.<success requirement>.<test name>.<test type> (<success 
# requirement> is "s", if SHOULD_FAIL was not passed and "f" if it was).
#
# Note that, the file extensions of the provided source files are ignored - they will always be compiled as C++ code.
#
# This function can only be called, if nostra_project() was called first. Also CTest needs to be included using 
# include() and enable_testing() needs to have been called.
#
# Additionally, the tests added by this function will only be added and build if BUILD_TESTING is TRUE.
#]=]
function(nostra_add_cpp_compile_test)
    if(BUILD_TESTING)
        _nostra_add_bu_test_helper("cpp" ${ARGN})     
    endif() 
endfunction()
