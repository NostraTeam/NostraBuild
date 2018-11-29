cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include("${CMAKE_CURRENT_LIST_DIR}/PrivateHelpers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Utility.cmake")

#[[
# Parameters:
#   - RESOURCE_IN:  The directory to copy from
#   - RESOURCE_OUT: The directory to copy to
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
#   - TEST_NAME:                     The name of the test.
#   - LANGUAGE:                      The language of the test. Determines the names of files/directories and file
#                                    extensions of the source files.
#   - TEST_TARGET:                   The target to test, i.e. the target to link against. 
#   - IN_DIR:                        The directory that the test is nested in (e.g. CMAKE_SOURCE_DIR).
#   - OUT_DIR:                       The directory that the testfiles will be copied to if not NOCOPY 
#                                    (e.g. CMAKE_CURRENT_BINARY_DIR).
#   - TEST_TYPE:                     The type of the test, either whitebox (wt) or blackbox (bt).
#   - NOCOPY [optional]:             If TRUE, the resources will not be copied and the working directory is somewhere 
#                                    in a child directory of IN_DIR.
#   - ADDITIONAL_SOURCES [optional]: Additional source files required aside from the default one.
# 
# A helper to add tests.
# This helper will:
# - Copy the resources in IN_DIR/test/<test dir>/resources to OUT_DIR/test/<test dir>/resources (only if NOCOPY is 
#   FALSE)
# - Add an executable with the following source files (the file names are relative to IN_DIR/test/<test dir>/src):
#   - test.<language> (called: default source file, this file must always exist)
#   - Any files listed in ADDITIONAL_SOURCES
# - Install that executable into the export target PROJECT_EXPORT.
# - Add the excutable as test (using add_test()). The working directory of that test will either be 
#   IN_DIR/test/<test directory> or OUT_DIR/test/<test directory>, depending on NOCOPY being TRUE or FALSE.
#]]
macro(_nostra_add_test_helper TEST_NAME LANGUAGE IN_DIR OUT_DIR)
    cmake_parse_arguments(FUNC "NOCOPY" "TEST_TARGET;TEST_TYPE" "ADDITIONAL_SOURCES" "${ARGN}")

    if(NOT DEFINED FUNC_TEST_TYPE)
        message(SEND_ERROR "TEST_TYPE is required.")
    endif()

    if(NOT (FUNC_TEST_TYPE STREQUAL "wt" OR FUNC_TEST_TYPE STREQUAL "bt"))
        message(SEND_ERROR "Invalid test type (only wt and bt are allowed).")
    endif()

    if(NOT DEFINED FUNC_TEST_TARGET)
        message(SEND_ERROR "parameter TEST_TARGET is required")
    endif()

    # Check if PROJECT_PREFIX is defined
    _nostra_check_if_nostra_project()

    _nostra_check_if_lib(${FUNC_TEST_TARGET})

    # Check that there are no additional arguments
    _nostra_check_parameters()

    # The name of the test executable
    set(TARGET_NAME "${PROJECT_PREFIX}.${LANGUAGE}.ex.s.${TEST_NAME}.${FUNC_TEST_TYPE}")
    set(DIR_NAME "test/${TARGET_NAME}.d")

    _nostra_print_debug("============================")
    _nostra_print_debug("Creating new test")
    _nostra_print_debug_value(TARGET_NAME)
    _nostra_print_debug_value(DIR_NAME)
    _nostra_print_debug_value(FUNC_TEST_TARGET)
    _nostra_print_debug_value(FUNC_ADDITIONAL_SOURCES)
    _nostra_print_debug_value(LANGUAGE)
    _nostra_print_debug_value(FUNC_TEST_TYPE)
    _nostra_print_debug_value(FUNC_NOCOPY)

    # Set WORKING_DIR and copy resources if necessary
    if(NOT FUNC_NOCOPY)
        # Set working dir to ${DIR_NAME} in the binary dir because resources have been copied
        set(WORKING_DIR "${OUT_DIR}/${DIR_NAME}")

        # Make sure the working directory for the command exists
        # This is only required if the resources were copied
        file(MAKE_DIRECTORY "${WORKING_DIR}")

        _nostra_print_debug("Copy resources from: ${IN_DIR}/${DIR_NAME}/resources")
        _nostra_print_debug("Copy resources to:   ${OUT_DIR}/${DIR_NAME}")

        _nostra_copy_resources_dir("${IN_DIR}/${DIR_NAME}/resources" "${OUT_DIR}/${DIR_NAME}")
    else()
        # Set working dir to ${DIR_NAME} in the source dir because resources have not been copied
        set(WORKING_DIR "${IN_DIR}/${DIR_NAME}")
    endif()

    _nostra_print_debug_value(WORKING_DIR)

    # Properly prefix the additional source files to locate them in test/<test name>.d/src/
    nostra_prefix_list(FUNC_ACTUAL_ADD_SOURCES "${IN_DIR}/${DIR_NAME}/src/" "${FUNC_ADDITIONAL_SOURCES}")

    _nostra_print_debug_value(FUNC_ACTUAL_ADD_SOURCES)
    _nostra_print_debug("main source file=${IN_DIR}/${DIR_NAME}/src/test.${LANGUAGE}")

    add_executable("${TARGET_NAME}" "${IN_DIR}/${DIR_NAME}/src/test.${LANGUAGE}" "${FUNC_ACTUAL_ADD_SOURCES}")

    target_link_libraries("${TARGET_NAME}" 
        PRIVATE
            "${FUNC_TEST_TARGET}")

    install(TARGETS "${TARGET_NAME}" EXPORT "${PROJECT_EXPORT}"
        RUNTIME 
            DESTINATION "${DIR_NAME}"
            COMPONENT "Test")

    # Install ressources folder from the SOURCES directory (if it exists)
    if(EXISTS "${IN_DIR}/${DIR_NAME}/resources")
        install(DIRECTORY "${IN_DIR}/${DIR_NAME}/resources" 
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
endmacro()

#[[
# Parameter:
#   - TEST_NAME:              The name of the test.
#   - DIR_NAME:               The root directory of the test (test/<test name>.d)
#   - CPP_TEST_DIR:           The root directory of the C++ test (build/test/cpp/test/<test name>.d)
#   - ADDITIONAL_SOURCES:     The additional source of the test
#   - ADDITIONAL_SOURCES_OUT: The name of the output variable that the processed list of additional source files will
#                             be stored in.
#
# Copies the default source file and the additional source files in DIR_NAME/src to CPP_TEST_DIR/src-
# Also creates a list of the full paths to the ADDITIONAL_SOURCES after they have been copied.
# After copying, the files will have the extension .cpp.
#]]
function(_nostra_copy_source_tree_to_cpp TEST_NAME DIR_NAME CPP_TEST_DIR ADDITIONAL_SOURCES ADDITIONAL_SOURCES_OUT)
    _nostra_check_no_parameters()
    # Must end with .c.cpp b/c this is the language of the test
    # Copy the main source file <testname>.c into a separate directory (test/cpp/test/<test dir>/src)
    configure_file("${DIR_NAME}/src/test.c" "${CPP_TEST_DIR}/src/test.c.cpp" COPYONLY)

    message("=======: ${CPP_TEST_DIR}")

    #=============================
    # Converts ADDITIONAL_SOURCES (which is a list of .c files) into a list of .cpp files
    #
    # E.g.: source.c -> source.c.cpp (they must end with .c.cpp not just .cpp)
    #
    # AND
    # 
    # Copies those files into a separate directory (test/cpp/test/<test dir>/src)
    #=============================
    # Create additional source file list to pass to _nostra_add_test_helper()
    # Paths need to be unprocessed, the source must not be FUNC_ACTUAL_ADD_SOURCES
    set(ADDITIONAL_SOURCES_CPP "")

    foreach(ADD_SRC_FILE IN LISTS ADDITIONAL_SOURCES)
        configure_file("${DIR_NAME}/src/${ADD_SRC_FILE}" "${CPP_TEST_DIR}/src/${ADD_SRC_FILE}.cpp" COPYONLY)
        list(APPEND ADDITIONAL_SOURCES_CPP "${ADD_SRC_FILE}.cpp")
    endforeach()

    set("${ADDITIONAL_SOURCES_OUT}" "${ADDITIONAL_SOURCES_CPP}" PARENT_SCOPE)
    #=============================
endfunction()

#[[
# Parameters:
#   - TEST_NAME:                                      The name of the test. According to the Nostra convetion, this is 
#                                                     the name of the component that the test is for, (or another 
#                                                     fitting name if the  test does not test a single component).
#   - TEST_TYPE:                                      The type of the test, either wt (if the test is a whitebox test)
#                                                     or bt (if the test is a blackbox test).
#   - TEST_TARGET [single value]:                     The target to test, i.e. the target that the test executable will  
#                                                     be linked aginst.
#   - NOCOPY [flag, optional]:                        If set, the test will be run in the source directory instead of  
#                                                     the build directory and no resources will be copied.
#   - ADDITIONAL_SOURCES [multiple values, optional]: Additional source files aside from the default file that each  
#                                                     test has.
#   - TEST_CPP[flag, optional]:                       If set, the test will be added again as C++ test.
# 
# A function that creates unit tests for C that test a single target (that target is passed using TEST_TARGET). 
# The tests need to be in the standard layout as defined by the Nostra convention.
# 
# Unless the flag NOCOPY has been passed, the files from test/<test name>/resources will be copied into the build
# directory and the test executable will be executed in that directory.
# 
# The tests will have the name <project prefix>.c.ex.s.<test name>.<test type>.
#
# If TEST_CPP is set, the test will also be run as C++ test (this time it will be called 
# <project prefix>.c.cpp.ex.s.<test name>.<test type>). That test will have its seperate working directory (the 
# resources will also be copied to that seperate working directory, no matter what the value of NOCOPY is). TEST_CPP is
# useful to make sure that a library can also be properly linked against when used in a C++ project.
#
# This function can only be called, if nostra_project() was called first as well as CTest needs to be included using 
# include() and enable_testing() needs to have been called.
#
# The test will only be added and build if BUILD_TESTING is TRUE.
#]]
function(nostra_add_c_test TEST_NAME)
    if(BUILD_TESTING)
        cmake_parse_arguments(FUNC "TEST_CPP" "" "" "${ARGN}")

        _nostra_add_test_helper("${TEST_NAME}" "c" "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}" "${FUNC_UNPARSED_ARGUMENTS}")

        if(FUNC_TEST_CPP)
            # Re-Build TEST_DIR from scratch, but change <prefix>.c.<name>.d to <prefix>.c.cpp.<name>.d
            set(CPP_TEST_DIR "${CMAKE_CURRENT_BINARY_DIR}/test/cpp/test/${PROJECT_PREFIX}.c.cpp.ex.s.${TEST_NAME}.${FUNC_TEST_TYPE}.d")

            #============================= TODO: this is not correcty anymore, but will likely removed
            # Copy the source dir of the test into the build dir
            # 
            # Copy the test dir into build/test/cpp
            # 
            # Such a tree:
            # test
            # └── ntp.c.component.wt.d
            #     ├── resources
            #     │   └── resource.txt
            #     └── src
            #         ├── component.wt.c
            #         └── source.c
            # 
            # would result in:
            # build
            # └── test
            #     └── cpp
            #         └── test
            #             └── ntp.c.cpp.component.wt.d
            #                 ├── resources
            #                 │   └── resource.txt
            #                 └── src
            #                     ├── component.wt.c.cpp
            #                     └── source.c.cpp
            # 
            # The entire tree is nested into the additional test dir (build/test/cpp/test)
            # because _nostra_add_test_helper() does expect it there                 ^^^^
            # =============================
            # Copy sources
            _nostra_copy_source_tree_to_cpp("${TEST_NAME}" 
                "${DIR_NAME}" 
                "${CPP_TEST_DIR}" 
                "${FUNC_ADDITIONAL_SOURCES}" 
                "ADDITIONAL_SOURCES_CPP")

            # Copy resources
            _nostra_print_debug("Copy resources for C++ from: ${DIR_NAME}/resources")
            _nostra_print_debug("Copy resources for C++ to:   ${CPP_TEST_DIR}")
            _nostra_copy_resources_dir("${DIR_NAME}/resources" "${CPP_TEST_DIR}")
            #=============================

            # Add the actual C++ test
            _nostra_add_test_helper("${TEST_NAME}"         # Test name is still the same, but the language has changed
                    "c.cpp"                                # Language (c.cpp to distingush from regular c/cpp tests)
                    "${CMAKE_CURRENT_BINARY_DIR}/test/cpp" # Input dir is the directory that the files were copied into
                    "${CMAKE_CURRENT_BINARY_DIR}/test/cpp" # Output dir is this aswell
                TEST_TYPE
                    "${FUNC_TEST_TYPE}"
                TEST_TARGET
                    "${FUNC_TEST_TARGET}"                  # The test target is still the same
                ADDITIONAL_SOURCES
                    "${ADDITIONAL_SOURCES_CPP}"            # Processed file list, with .cpp added as extension
                NOCOPY)                                    # The files were already copied, no need to copy again
        endif()
    endif()
endfunction()

#[[
# Parameters:
#   - TEST_NAME:                                      The name of the test. According to the Nostra convetion, this is 
#                                                     the name of the component that the test is for, (or another 
#                                                     fitting name if the  test does not test a single component).
#   - TEST_TYPE:                                      The type of the test, either wt (if the test is a whitebox test)
#                                                     or bt (if the test is a blackbox test).
#   - TEST_TARGET [single value]:                     The target to test, i.e. the target that the test executable will  
#                                                     be linked aginst.
#   - NOCOPY [flag, optional]:                        If set, the test will be run in the source directory instead of  
#                                                     the build directory and no resources will be copied.
#   - ADDITIONAL_SOURCES [multiple values, optional]: Additional source files aside from the default file that each  
#                                                     test has.
# 
# A function that creates unit tests for C++ that test a single target (that target is passed using TEST_TARGET). 
# The tests need to be in the standard layout as defined by the Nostra convention.
# 
# Unless the flag NOCOPY has been passed, the files from test/<test name>/resources will be copied into the build
# directory and the test executable will be executed in that directory.
# 
# The tests will have the name <project prefix>.cpp.ex.s.<test name>.<test type>.
#
# This function can only be called, if nostra_project() was called first as well as CTest needs to be included using 
# include() and enable_testing() needs to have been called.
#
# The test will only be added and build if BUILD_TESTING is TRUE.
#]] 
# TODO use the language property to set the language to C or C++. This would also not required copying the entire test 
#      tree for a c++ test
# TODO Add support for test numbers
function(nostra_add_cpp_test TEST_NAME)
    if(BUILD_TESTING)
        _nostra_add_test_helper("${TEST_NAME}" "cpp" "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}" "${ARGN}")
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
function(_nostra_add_compile_test_helper TEST_NAME LANGUAGE)
    cmake_parse_arguments(FUNC "SHOULD_FAIL" "TEST_TARGET;TEST_TYPE" "ADDITIONAL_SOURCES" ${ARGN})
    
    if(NOT DEFINED FUNC_TEST_TYPE)
        message(SEND_ERROR "TEST_TYPE is required.")
    endif()

    if(NOT (FUNC_TEST_TYPE STREQUAL "wt" OR FUNC_TEST_TYPE STREQUAL "bt"))
        message(SEND_ERROR "Invalid test type (only wt and bt are allowed).")
    endif()

    if(NOT DEFINED FUNC_TEST_TARGET)
        message(SEND_ERROR "parameter TEST_TARGET is required")
    endif()

    _nostra_check_parameters()
    _nostra_check_if_lib(${FUNC_TEST_TARGET})
    _nostra_check_if_nostra_project()

    if(FUNC_SHOULD_FAIL)
        set(SUCCESS_REQUIREMENT "f")
    else()
        set(SUCCESS_REQUIREMENT "s")
    endif()

    # The name of the test executable
    set(TARGET_NAME "${PROJECT_PREFIX}.${LANGUAGE}.bu.${SUCCESS_REQUIREMENT}.${TEST_NAME}.${FUNC_TEST_TYPE}")
    set(DIR_NAME "test/${TARGET_NAME}.d")
    set(IN_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    set(OUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

    _nostra_print_debug("============================")
    _nostra_print_debug("Creating new test")
    _nostra_print_debug_value(TARGET_NAME)
    _nostra_print_debug_value(DIR_NAME)
    _nostra_print_debug_value(FUNC_TEST_TARGET)
    _nostra_print_debug_value(FUNC_ADDITIONAL_SOURCES)
    _nostra_print_debug_value(LANGUAGE)
    _nostra_print_debug_value(FUNC_TEST_TYPE)

    # Properly prefix the additional source files to locate them in test/<test name>.d/src/
    nostra_prefix_list(FUNC_ACTUAL_ADD_SOURCES "${IN_DIR}/${DIR_NAME}/src/" "${FUNC_ADDITIONAL_SOURCES}")

    _nostra_print_debug_value(FUNC_ACTUAL_ADD_SOURCES)
    _nostra_print_debug("main source file=${IN_DIR}/${DIR_NAME}/src/test.${LANGUAGE}")

    if("${LANGUAGE}" STREQUAL "c")
        set(UPPER_LANG "C")
    elseif("${LANGUAGE}" STREQUAL "cpp")
        set(UPPER_LANG "CXX")
    else()
        message(SEND_ERROR "Invalid language ${LANGUAGE}")
    endif()

    # Set language of the default source file
    set_source_files_properties("${IN_DIR}/${DIR_NAME}/src/test.${LANGUAGE}" PROPERTIES LANGUAGE "${UPPER_LANG}")

    # Set language of the additional source files
    foreach(F IN LISTS FUNC_ACTUAL_ADD_SOURCES)
        set_source_files_properties("${F}" PROPERTIES LANGUAGE "${UPPER_LANG}")
    endforeach()

    # Use library because that way, no main() is needed
    add_library("${TARGET_NAME}" 
        STATIC 
        EXCLUDE_FROM_ALL # should not be build with the other targets, instead this is build during CTest
        "${IN_DIR}/${DIR_NAME}/src/test.${LANGUAGE}" # default source file
        "${FUNC_ACTUAL_ADD_SOURCES}")

    target_link_libraries("${TARGET_NAME}" 
        PRIVATE
            "${FUNC_TEST_TARGET}")

    #[[ Do not install for now
    install(TARGETS "${TARGET_NAME}" EXPORT "${PROJECT_EXPORT}"
        RUNTIME 
            DESTINATION "${DIR_NAME}"
            COMPONENT "Test")

    # Install ressources folder from the SOURCES directory (if it exists)
    if(EXISTS "${IN_DIR}/${DIR_NAME}/resources")
        install(DIRECTORY "${IN_DIR}/${DIR_NAME}/resources" 
            DESTINATION
                "${DIR_NAME}"
            COMPONENT 
                "Test")
    endif()
    #]]

    # Add the actual test to CTest
    add_test(
        NAME 
            "${TARGET_NAME}"
        COMMAND 
            # In this case, this must be CMAKE_BINARY_DIR instead of CMAKE_CURRENT_BINARY_DIR
            "${CMAKE_COMMAND}" "--build" "${CMAKE_BINARY_DIR}" "--target" "${TARGET_NAME}")

    if(FUNC_SHOULD_FAIL)
        set_tests_properties("${TARGET_NAME}" PROPERTIES WILL_FAIL "ON")
    endif()
endfunction()

#[[
# Parameters:
#   - TEST_NAME:                     The name of the test.
#   - TEST_TARGET:                   The target to test, i.e. the target to link against. 
#   - TEST_TYPE:                     The type of the test, either wt (if the test is a whitebox test) or bt (if the 
#                                    test is a blackbox test).
#   - SHOULD_FAIL [flag, optional]:  If set, the test will succeed if the compilation fails.
#   - ADDITIONAL_SOURCES [optional]: Additional source files required aside from the default one.
#
# A function that creates unit tests that, instead of running an executable, will attempt to compile a target using a C 
# compiler. If that compilation succeeds (or fails if SHOULD_FAIL is set), the test will be successful.
#
# Note that, even if the provided source files have the extension .cpp (or any other extension), the files will be
# compiled as C code.
#
# This function can only be called, if nostra_project() was called first as well as CTest needs to be included using 
# include() and enable_testing() needs to have been called.
#
# The test will only be added and build if BUILD_TESTING is TRUE.
#]]
function(nostra_add_c_compile_test TEST_NAME)
    if(BUILD_TESTING)
        _nostra_add_compile_test_helper("${TEST_NAME}" "c" ${ARGN})    
    endif()
endfunction()

#[[
# Parameters:
#   - TEST_NAME:                     The name of the test.
#   - TEST_TARGET:                   The target to test, i.e. the target to link against. 
#   - TEST_TYPE:                     The type of the test, either wt (if the test is a whitebox test) or bt (if the 
#                                    test is a blackbox test).
#   - SHOULD_FAIL [flag, optional]:  If set, the test will succeed if the compilation fails.
#   - ADDITIONAL_SOURCES [optional]: Additional source files required aside from the default one.
#
# A function that creates unit tests that, instead of running an executable, will attempt to compile a target using a 
# C++ compiler. If that compilation succeeds (or fails if SHOULD_FAIL is set), the test will be successful.
#
# Note that, even if the provided source files have the extension .c (or any other extension), the files will be
# compiled as C++ code.
#
# This function can only be called, if nostra_project() was called first as well as CTest needs to be included using 
# include() and enable_testing() needs to have been called.
#
# The test will only be added and build if BUILD_TESTING is TRUE.
#]]
function(nostra_add_cpp_compile_test TEST_NAME)
    if(BUILD_TESTING)
        _nostra_add_compile_test_helper("${TEST_NAME}" "cpp" ${ARGN})     
    endif() 
endfunction()
