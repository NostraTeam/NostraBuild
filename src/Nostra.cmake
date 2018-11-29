cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

option(NOSTRA_BUILD_EXAMPLES "If enabled, the examples of all Nostra projects will be build." ON)

# TODO: add cmake_parse_arguments() and _nostra_check_params() to all functions

#[[
Parameters:
    - OUT    The variable that the output list will be stored in
    - PREFIX The prefix to add

Adds a prefix to all elements in a list.

E.g.:
The list "one;two;three" and the prefix "prefix_" would result in the list "prefix_one;prefix_two;prefix_three".
""
#]]
function(nostra_prefix_list OUT PREFIX)
	set(LIST_INTERNAL "")

	foreach(STR IN LISTS ARGN)
		list(APPEND LIST_INTERNAL "${PREFIX}${STR}")
	endforeach()

	set("${OUT}" "${LIST_INTERNAL}" PARENT_SCOPE)
endfunction()

#[[
Parameters:
    - OUT    The variable that the output list will be stored in
    - SUFFIX The suffix to add

Adds a suffix to all elements in a list.

E.g.:
The list "one;two;three" and the suffix "suffix_" would result in the list "one_suffix;two_suffix;three_suffix".
""
#]]
function(nostra_suffix_list OUT SUFFIX)
	set(LIST_INTERNAL "")

	foreach(STR IN LISTS ARGN)
		list(APPEND LIST_INTERNAL "${STR}${SUFFIX}")
	endforeach()

	set("${OUT}" "${LIST_INTERNAL}" PARENT_SCOPE)
endfunction()

#[[
Checks if FUNC_UNPARSED_ARGUMENTS is defined and triggers an error if it is not.

This can be used to check if there were unexpected arguments passed to function or macro.
Usually, this used with and used after cmake_parse_arguments().
#]]
macro(_nostra_check_parameters)
    if(DEFINED FUNC_UNPARSED_ARGUMENTS)
        message(SEND_ERROR "unknown argument \"${FUNC_UNPARSED_ARGUMENTS}\"")
    endif()
endmacro()

macro(_nostra_print_debug NOSTRA_CMAKE_STR)
    if(NOSTRA_CMAKE_DEBUG)
        message(STATUS "[NOSTRA_CMAKE_DEBUG] ${NOSTRA_CMAKE_STR}")
    endif()
endmacro()

macro(_nostra_print_debug_value NOSTRA_CMAKE_VARNAME)
    _nostra_print_debug("${NOSTRA_CMAKE_VARNAME}=${${NOSTRA_CMAKE_VARNAME}}")
endmacro()

#[[
# Parameters:
#   - NAME:                   The name of the project - see project() for mor information
#   - PREFIX:                 The prefix of the project
#   - VERSION [optional]:     The current version of the project - see project() for mor information
#   - DESCRIPTION [optional]: The description of the project - see project() for mor information
#   - LANGUAGES [optional]:   The language(s) that are enabled for the project  - see project() for mor information
#   - LOGO [optional]:        The path to the logo of the project (as image file).
# Similar to CMake's project() command, but with some extra Nostra-related stuff.
#
# Aside from creating a regular CMake project, this function defines:
# - <project name>_PREFIX, the three character abbreviation of the Project (e.g. nou for NostraUtils)
# - PROJECT_PREFIX, same as <project name>_PREFIX
# - <project name>_EXPORT, the name of the export target of that project
# - PROJECT_EXPORT, same as <project name>_EXPORT
#
# These variables are used by other functions in this module.
#]]
macro(nostra_project NAME PREFIX)
    cmake_parse_arguments(NOSTRA_CMAKE "" "VERSION;DESCRIPTION;LOGO" "LANGUAGES" "${ARGN}")

    _nostra_check_parameters()

    if(DEFINED NOSTRA_CMAKE_VERSION)
        set(NOSTRA_CMAKE_PARAM_VERSION VERSION "${NOSTRA_CMAKE_VERSION}")
    endif()

    if(DEFINED NOSTRA_CMAKE_DESCRIPTION)
        set(NOSTRA_CMAKE_PARAM_DESCRIPTION DESCRIPTION "${NOSTRA_CMAKE_DESCRIPTION}")
    endif()

    if(DEFINED NOSTRA_CMAKE_LANGUAGES)
        set(NOSTRA_CMAKE_PARAM_LANGUAGES LANGUAGES "${NOSTRA_CMAKE_LANGUAGES}")
    endif()

    # Do not put variables in quotes!
    project("${NAME}" 
        ${NOSTRA_CMAKE_PARAM_VERSION}     # Version
        ${NOSTRA_CMAKE_PARAM_DESCRIPTION} # Description
        ${NOSTRA_CMAKE_PARAM_LANGUAGES})  # Language(s)

    # Project prefix
    set("${NAME}_PREFIX" "${PREFIX}")
    set("PROJECT_PREFIX" "${PREFIX}")

    # Export target name
    set("${NAME}_EXPORT" "${NAME}Targets")
    set("PROJECT_EXPORT" "${NAME}Targets")
    
    # Logo
    if(DEFINED NOSTRA_CMAKE_LOGO)
        set("${NAME}_LOGO" "doc/img/${NOSTRA_CMAKE_LOGO}")
        set("PROJECT_LOGO" "doc/img/${NOSTRA_CMAKE_LOGO}")
    else()
        set("${NAME}_LOGO" "")
        set("PROJECT_LOGO" "")
    endif()
endmacro()

#[[
# Parameters:
#   - RESOURCE_IN:  The directory to copy from
#   - RESOURCE_OUT: The directory to copy to
# Copies everything from RESOURCE_IN to RESOURCE_OUT, but only if RESOURCE_IN exists.
#]]
function(_nostra_copy_resources_dir RESOURCE_IN RESOURCE_OUT)
    if(EXISTS "${RESOURCE_IN}")
        file(COPY "${RESOURCE_IN}" DESTINATION "${RESOURCE_OUT}")
    endif()
endfunction()

macro(_nostra_check_if_nostra_project)
    if(NOT DEFINED PROJECT_PREFIX)
        message(SEND_ERROR "PROJECT_PREFIX is not defined, has nostra_project() been called?")
    endif()
endmacro()

#[[
# Parameters:
#   - TARGET: The target to check.
#
# Checks if the passed target is a library (target property TYPE is SHARED_LIBRARY or STATIC_LIBRARY). If not, the
# the function will trigger an error.
#]]
function(_nostra_check_if_lib TARGET)
    get_target_property(NOSTRA_CMAKE_TARGET_TYPE ${TARGET} TYPE)

    if(NOT "${NOSTRA_CMAKE_TARGET_TYPE}" MATCHES "(SHARED|STATIC)_LIBRARY")
        message(SEND_ERROR "Target ${TARGET} is not a shared or static library.")
    endif()
endfunction()

#[[
# Parameters:
#   - TEST_NAME:                     The name of the test. Usually something like: component.wt 
#   - LANGUAGE:                      The language of the test. Determines the names of files/directories and file
#                                    extensions of the source files.
#   - TEST_TARGET:                   The target to test, i.e. the target to link against. 
#   - IN_DIR:                        The directory that the test is nested in (e.g. CMAKE_SOURCE_DIR).
#   - OUT_DIR:                       The directory that the testfiles will be copied to if not NOCOPY 
#                                    (e.g. CMAKE_CURRENT_BINARY_DIR).
#   - NOCOPY [optional]:             If TRUE, the resources will not be copied and the working directory is somewhere 
#                                    in a child directory of IN_DIR.
#   - ADDITIONAL_SOURCES [optional]: Additional source files required aside from the default one.
# 
# A helper to add tests.
# This helper will:
# - Copy the resources in IN_DIR/test/<test dir>/resources to OUT_DIR/test/<test dir>/resources (only if NOCOPY is 
#   FALSE)
# - Add an executable with the following source files (the file names are relative to IN_DIR/test/<test dir>/src):
#   - TEST_NAME.LANGUAGE (e.g. component.cpp) (called: default source file, this file must always exist)
#   - Any files listed in ADDITIONAL_SOURCES
# - Install that executable into the export target PROJECT_EXPORT.
# - Add the excutable as test (using add_test()). The working directory of that test will either be 
#   IN_DIR/test/<test directory> or OUT_DIR/test/<test directory>, depending on NOCOPY being TRUE or FALSE.
#]]
# TODO: Fix test names
macro(_nostra_add_test_helper TEST_NAME LANGUAGE IN_DIR OUT_DIR)
    cmake_parse_arguments(FUNC "NOCOPY" "TEST_TARGET" "ADDITIONAL_SOURCES" "${ARGN}")

    if(NOT DEFINED FUNC_TEST_TARGET)
        message(SEND_ERROR "parameter TEST_TARGET is required")
    endif()

    # Check if PROJECT_PREFIX is defined
    _nostra_check_if_nostra_project()

    _nostra_check_if_lib(${FUNC_TEST_TARGET})

    # Check that there are no additional arguments
    _nostra_check_parameters()

    # The name of the test executable
    set(TARGET_NAME "${PROJECT_PREFIX}.${LANGUAGE}.${TEST_NAME}")
    set(DIR_NAME "test/${TARGET_NAME}.d")

    _nostra_print_debug("============================")
    _nostra_print_debug("Creating new test")
    _nostra_print_debug_value(TARGET_NAME)
    _nostra_print_debug_value(DIR_NAME)
    _nostra_print_debug_value(FUNC_TEST_TARGET)
    _nostra_print_debug_value(FUNC_ADDITIONAL_SOURCES)
    _nostra_print_debug_value(LANGUAGE)
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
    _nostra_print_debug("main source file=${IN_DIR}/${DIR_NAME}/src/${TEST_NAME}.${LANGUAGE}")

    add_executable("${TARGET_NAME}" "${IN_DIR}/${DIR_NAME}/src/${TEST_NAME}.${LANGUAGE}" "${FUNC_ACTUAL_ADD_SOURCES}")

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
        # Must end with .c.cpp b/c this is the language of the test
        # Copy the main source file <testname>.c into a separate directory (test/cpp/test/<test dir>/src)
        configure_file("${DIR_NAME}/src/${TEST_NAME}.c" "${CPP_TEST_DIR}/src/${TEST_NAME}.c.cpp" COPYONLY)

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
# In general, this is the same function as nostra_add_cpp_test() but for C instead of C++ (the tests will be called 
# <project prefix>.cpp.<test name>.). The only other difference is the additional, optional flag parameter TEST_CPP. If 
# that flag is set, the test will be added a second time, but as C++ test (the test is called 
# <project prefix>.c.cpp.<test name>). The C++ test will also have its seperate working directory that the resources
# will have been copied to.
#]]
function(nostra_add_c_test TEST_NAME)
    if(BUILD_TESTING)
        cmake_parse_arguments(FUNC "TEST_CPP" "" "" "${ARGN}")

        _nostra_add_test_helper("${TEST_NAME}" "c" "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}" "${FUNC_UNPARSED_ARGUMENTS}")

        if(FUNC_TEST_CPP)
            # Re-Build TEST_DIR from scratch, but change <prefix>.c.<name>.d to <prefix>.c.cpp.<name>.d
            set(CPP_TEST_DIR "${CMAKE_CURRENT_BINARY_DIR}/test/cpp/test/${PROJECT_PREFIX}.c.cpp.${TEST_NAME}.d")

            #=============================
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
#                                                     <component name>.(wt|bt), with <component name> being the name of 
#                                                     the component that will be tested (or another fitting name if the 
#                                                     test does not test a single component) and (wt|bt) being wt in  
#                                                     the case of a whitebox test and bt in the case of a blackbox test.
#   - NOCOPY [flag, optional]:                        If set, the test will be run in the source directory instead of  
#                                                     the build directory and no resources will be copied.
#   - TEST_TARGET [single value, optional]:           The target to test, i.e. the target that the test executable will  
#                                                     be linked aginst.
#   - ADDITIONAL_SOURCES [multiple values, optional]: Additional source files aside from the default file that each  
#                                                     test has.
# 
# A function that creates unit tests for C++ to test a single target (that target is passed using TEST_TARGET). 
# The tests need to be in the standard layout after Nostra convention.
# 
# Unless the flag NOCOPY has been passed, the files from test/<test name>/resources will be copied into the build
# directory and the test executable will be executed in that directory.
# 
# The tests will have the name <project prefix>.cpp.<test name>.
#
# This function can only be called, if nostra_project() was called first.
#]] 
# TODO update the entire doc of test related functions
function(nostra_add_cpp_test TEST_NAME)
    if(BUILD_TESTING)
        _nostra_add_test_helper("${TEST_NAME}" "cpp" "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}" "${ARGN}")
    endif()
endfunction()

#[[
# Parameters:
#   - TEST_NAME: The name of the test.
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
# TODO: right now, TEST_NAME contains the component name, the type (wt/bt) and number. this should be split up
# TODO: Add support for multiple, additional targets
# TODO: Add required resource files for tests
# TODO: add comment that CTest needs to be included and enable_testing() needs to have been called
function(_nostra_add_compile_test_helper TEST_NAME LANGUAGE)
    cmake_parse_arguments(FUNC "SHOULD_FAIL" "TEST_TARGET" "ADDITIONAL_SOURCES" ${ARGN})
    
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
    set(TARGET_NAME "${PROJECT_PREFIX}.${LANGUAGE}.bu.${SUCCESS_REQUIREMENT}.${TEST_NAME}")
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

    # Properly prefix the additional source files to locate them in test/<test name>.d/src/
    nostra_prefix_list(FUNC_ACTUAL_ADD_SOURCES "${IN_DIR}/${DIR_NAME}/src/" "${FUNC_ADDITIONAL_SOURCES}")

    _nostra_print_debug_value(FUNC_ACTUAL_ADD_SOURCES)
    _nostra_print_debug("main source file=${IN_DIR}/${DIR_NAME}/src/${TEST_NAME}.${LANGUAGE}")

    if("${LANGUAGE}" STREQUAL "c")
        set(UPPER_LANG "C")
    elseif("${LANGUAGE}" STREQUAL "cpp")
        set(UPPER_LANG "CXX")
    else()
        message(SEND_ERROR "Invalid language ${LANGUAGE}")
    endif()

    # Set language of the default source file
    set_source_files_properties("${IN_DIR}/${DIR_NAME}/src/${TEST_NAME}.${LANGUAGE}" PROPERTIES LANGUAGE "${UPPER_LANG}")

    # Set language of the additional source files
    foreach(F IN LISTS FUNC_ACTUAL_ADD_SOURCES)
        set_source_files_properties("${F}" PROPERTIES LANGUAGE "${UPPER_LANG}")
    endforeach()

    # Use library because that way, no main() is needed
    add_library("${TARGET_NAME}" 
        STATIC 
        EXCLUDE_FROM_ALL # should not be build with the other targets, instead this is build during CTest
        "${IN_DIR}/${DIR_NAME}/src/${TEST_NAME}.${LANGUAGE}" # default source file
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
# The same as nostra_add_cpp_compile_test() but a C compiler will be used to compile the target.
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
#   - SHOULD_FAIL [flag, optional]:  If set, the test will succeed if the compilation fails.
#   - ADDITIONAL_SOURCES [optional]: Additional source files required aside from the default one.
#
# A function that creates unit tests that, instead of running an executable, will attempt to compile a target. If that
# compilation succeeds (or fails if SHOULD_FAIL is set), the test will be successful.
#
# For all source files of this project, independently of their actual file extension, a C++ compiler will be used.
#
# This function can only be called, if nostra_project() was called first.
#]]
function(nostra_add_cpp_compile_test TEST_NAME)
    if(BUILD_TESTING)
        _nostra_add_compile_test_helper("${TEST_NAME}" "cpp" ${ARGN})     
    endif() 
endfunction()

#[[
# Parameters:
#   - An expression that is valid in an if() command (e.g.: NOT "${MY_VAR}" STREQUAL "mystring").
# 
# A simple test function to check if a passed statement is true.
# If the passed statement is not true, the function will trigger an error.
#]]
function(_nostra_test)
    if(NOT ${ARGN})
        string(REPLACE ";" " " STR_OUT "${ARGN}")
        message(SEND_ERROR "Test Failed: ${STR_OUT}")
    endif()
endfunction()

#[[
# Parameters:
#   - OUT_VAR: The name of the output variable.
#   - TARGET:  The target to get the name of.
#
# Stores the actual name TARGET in OUT_VAR is TARGET is an alias name. If TARGET is not a name, the value in OUT_VAR
# will be the value of TARGET.
#]]
function(nostra_alias_get_actual_name OUT_VAR TARGET)
    get_target_property(ALIAS_NAME "${TARGET}" ALIASED_TARGET)

    if(NOT "${ALIAS_NAME}" STREQUAL "ALIAS_NAME-NOTFOUND")
        set("${OUT_VAR}" "${ALIAS_NAME}" PARENT_SCOPE)
    else()
        set("${OUT_VAR}" "${TARGET}" PARENT_SCOPE)
    endif()
endfunction()

function(nostra_get_compiler_id OUT_VAR)
    get_property(ENABLED_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)

    if("CXX" IN_LIST ENABLED_LANGUAGES)
        set("${OUT_VAR}" "${CMAKE_CXX_COMPILER_ID}" PARENT_SCOPE)
    elseif("C" IN_LIST ENABLED_LANGUAGES) # If C is in the list but not CXX
        set("${OUT_VAR}" "${CMAKE_C_COMPILER_ID}" PARENT_SCOPE)
    else()
        message(SEND_ERROR "Neither C nor C++ are enabled as languages.")
    endif()
endfunction()

#[[
# Parameters:
#   - VAR: The name of the variable with the target name.
#
# Replaces the value of VAR with the actual name of the target stored in VAR.
#
# Example:
# 
# # MY_TARGET stores the name of a target (it is not known if it is an alias name or not)
# nostra_alias_to_actual_name(MY_TARGET) # Important: do not expand MY_TARGET
# # Now, MY_TARGET stores the name of the actual of the target, even if it was an alias name before
#]]
function(nostra_alias_to_actual_name VAR)
    nostra_alias_get_actual_name(OUT_VAR ${${VAR}})
    set("${VAR}" "${OUT_VAR}" PARENT_SCOPE)
endfunction()

# Get the directory of this file; this needs to be outside of a function
set(_NOSTRA_CMAKE_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

# Helper for nostra_generate_export_header(). See doc of that function.
function(_nostra_generate_export_header_helper TARGET PREFIX OUT_DIR)
    nostra_alias_to_actual_name(TARGET)

    _nostra_check_if_nostra_project()
    _nostra_check_if_lib(${TARGET})

    # Make the prefix upper case
    set(NOSTRA_CMAKE_PREFIX "${PREFIX}")
    string(TOUPPER "${NOSTRA_CMAKE_PREFIX}" NOSTRA_CMAKE_PREFIX)

    get_target_property(NOSTRA_CMAKE_TARGET_TYPE ${TARGET} TYPE)

    if("${NOSTRA_CMAKE_TARGET_TYPE}" STREQUAL "STATIC_LIBRARY")
        target_compile_definitions(${TARGET} 
            PRIVATE 
                "${NOSTRA_CMAKE_PREFIX}_SHOULD_EXPORT")
    endif()

    get_target_property(NOSTRA_CMAKE_TARGET_TYPE ${TARGET} TYPE)

    if("${NOSTRA_CMAKE_TARGET_TYPE}" STREQUAL "STATIC_LIBRARY")
        target_compile_definitions(${TARGET} 
            PRIVATE 
                "${NOSTRA_CMAKE_PREFIX}_IS_STATIC_LIB")
    endif()

    nostra_get_compiler_id(NOSTRA_COMPILER_ID)

    if("${NOSTRA_COMPILER_ID}" STREQUAL "MSVC")
        set(NOSTRA_CMAKE_EXPORT_ATTRIBUTE "__declspec(dllexport)")
        set(NOSTRA_CMAKE_IMPORT_ATTRIBUTE "__declspec(dllimport)")
        set(NOSTRA_CMAKE_NO_EXPORT_ATTRIBUTE "") # no export is the default behavior on Windows
        set(NOSTRA_CMAKE_DEPRECATED_ATTRIBUTE "__declspec(deprecated)")
    elseif("${NOSTRA_COMPILER_ID}" STREQUAL "AppleClang")
        set(NOSTRA_CMAKE_EXPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_IMPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_NO_EXPORT_ATTRIBUTE "__attribute__((visibility(\"hidden\")))")
        set(NOSTRA_CMAKE_DEPRECATED_ATTRIBUTE "__attribute__((__deprecated__))")
    elseif("${NOSTRA_COMPILER_ID}" STREQUAL "Clang")
        set(NOSTRA_CMAKE_EXPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_IMPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_NO_EXPORT_ATTRIBUTE "__attribute__((visibility(\"hidden\")))")
        set(NOSTRA_CMAKE_DEPRECATED_ATTRIBUTE "__attribute__((__deprecated__))")
    elseif("${NOSTRA_COMPILER_ID}" STREQUAL "GNU")
        set(NOSTRA_CMAKE_EXPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_IMPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_NO_EXPORT_ATTRIBUTE "__attribute__((visibility(\"hidden\")))")
        set(NOSTRA_CMAKE_DEPRECATED_ATTRIBUTE "__attribute__((__deprecated__))")
    else()
        message(SEND_ERROR "The compiler with the ID ${NOSTRA_COMPILER_ID} is not supported.")
    endif()

    # If OUT_DIR is undefined, explicitly define it. This is required b/c the next configure_file() command would put
    # the generated file into the root directory if OUT_DIR is empty/undefined.
    if(NOT DEFINED OUT_DIR)
        set(OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    endif()

    configure_file("${_NOSTRA_CMAKE_LIST_DIR}/../cmake/export.h.in" "${OUT_DIR}/export.h" @ONLY)
endfunction()

#[=[
# Parameters:
#   - TARGET:                The target that the export header is generated for.
#   - OUTPUT_DIR [optional]: The directory that the output file will be put. If this is not given, the output directory
#                            will be CMAKE_CURRENT_BINARY_DIR.
#
# This function works very similar to CMake's generate_export_header() function, but it is usable without enabling C++
# as a language. In addition to that, it is less customizable because the names are pulled from the Nostra convention.
#
# When included, the generated header will provide the following macros:
# - <project prefix>_EXPORT:     Functions that are supposed to be part of the public interface of the library need to
#                                be prefixed with this macro.
# - <project prefix>_NO_EXPORT:  Functions that are not supposed to be part of the public interface of the library need 
#                                to be prefixed with this macro.
# - <project prefix>_DEPRECATED: Functions that are deprecated are supposed to be prefixed with this macro. This is a 
#                                (better) alternative to C++'s attribute [[deprecated]], because it is compatible to C 
#                                and older versions of C++.
# In addition to these macros, the CMake function itself will define the macro <project prefix>_IS_STATIC_LIB if the 
# library that is being build is a static library. If the library is a shared library, the macro is not defined (if the
# macro is defined, it is always defined, it is not required to include the header generated by this function).
#
# Note: Every function should either be explicitly prefixed with <project name>_EXPORT or <project name>_NO_EXPORT,
#       because the default behavior is different from platform to platform.
# Note: This file should not be shared across compilers and platforms. To prevent this, it should only be stored in the
#       build directory, not the source directory.
#
# This function can only be called, if nostra_project() was called first and TARGET needs to be either a
# shared or static library.
#]=]
macro(nostra_generate_export_header TARGET)
    cmake_parse_arguments(FUNC "" "OUTPUT_DIR" "" ${ARGN})

    _nostra_check_if_nostra_project()
    _nostra_check_parameters()

    # Put FUNC_OUTPUT_DIR into quotes to make sure an empty string gets passed if it is not defined
    # That way, the output directory will be the build directory
    _nostra_generate_export_header_helper(${TARGET} ${PROJECT_PREFIX} "${FUNC_OUTPUT_DIR}")
endmacro()

#[[
# Parameters:
#   - STR: The string to print.
#
# Prints a status message in the format "<project name>: <STR>".
#
# This function can only be called, if nostra_project() was called first.
#]]
function(nostra_message STR)
    _nostra_check_if_nostra_project()

    message(STATUS "${PROJECT_NAME}: ${STR}")
endfunction()

#[[
# Parameters:
#   - OUT_VAR: The name of the output variable.
#
# Stores in OUT_VAR whether the language C is currently enabled.
#]]
function(_nostra_is_c_enabled OUT_VAR)
    get_property(LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)

    list(FIND "${LANGUAGES}" "C" ${OUT_VAR}) # Check if the language is in the list, if it is, it is enabled

    set(${OUT_VAR} ${${OUT_VAR}} PARENT_SCOPE) # Make the result also visible outside of the function
endfunction()

#[[
# Parameters:
#   - OUT_VAR: The name of the output variable.
#
# Stores in OUT_VAR whether the language C++ is currently enabled.
#]]
function(_nostra_is_cpp_enabled OUT_VAR)
    get_property(LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)

    list(FIND "${LANGUAGES}" "CXX" ${OUT_VAR}) # Check if the language is in the list, if it is, it is enabled

    set(${OUT_VAR} ${${OUT_VAR}} PARENT_SCOPE) # Make the result also visible outside of the function
endfunction()

macro(_nostra_generate_doc_forwards_comp_helper)
    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.9.0") # This is only required if the version is after 2.8.
        if(TARGET Doxygen::doxygen)
            get_target_property(DOXYGEN_EXECUTABLE Doxygen::doxygen IMPORTED_LOCATION)
        else()
            message(FATAL_ERROR "DOXYGEN_FOUND was true but Doxygen::doxygen does not exist.")
        endif()

        if(TARGET Doxygen::dot)
            get_target_property(DOXYGEN_DOT_EXECUTABLE Doxygen::dot IMPORTED_LOCATION)
            set(DOXYGEN_DOT_FOUND "TRUE")
        else()
            set(DOXYGEN_DOT_FOUND "FALSE")
        endif()
    endif()
endmacro()

#[[
# Parameters:
#   - OUT_DIR [optional]: The directory in which the documentation output will be stored. If this parameter is not
#                         given, the directory <current binary directory>/doc will be used (usually, it is not 
#                         necessary to pass this parameter, the default value should be fine).
#
# Enables Doxygen based documentation generation for the current project. To allow this, the project must strictly 
# conform to the Nostra conventions.
#
# The input files/directories are (all paths relative to the current source directory):
# - doc/Doxyfile.in:       The blueprint of the Doxyfile that will be used. Will be configured using CMake's 
#                          configure_file() (with the setting @ONLY)
# - doc/style.css:         An additional CSS file that is used by Doxygen.
# - doc/DoxygenLayout.xml: The layout file for doxygen.
# - doc/:                  Aside from the files named above, all files in this directory are part of the Doxygen input. 
#                          This can be used to add additional documentation from outside of the source code (see Nostra
#                          conventions for more information).
# - doc/img:               Images from this directory can be used by using the "\image" command.
# - doc/dot:               Dot files from this directory can be used by using the "\dotfile" command.
# - include/:              The code files that hold the documentation (only headers are documented, not source files).
# - README.md:             The README file. Will be used as the mainpage of the documentation.
# - examples/:             The example files.
#
# The output files are (all paths relative to the current source directory):
# - <output directory>/html: The generated HTML pages.
# - <output directory>/Doxyfile: The configured file doc/Doxyfile.in
#
# When installing, the contents of the directory <output directory>/html will be installed into the directory doc in 
# the component Documentation.
#
# This function can only be called, if nostra_project() was called first.
#]]
function(nostra_generate_doc)
    #[[
    # The Doxyfile uses the following CMake variables:
    # - PROJECT_NAME
    # - PROJECT_VERSION
    # - PROJECT_DESCRIPTION
    # - PROJECT_LOGO
    # - NOSTRA_CMAKE_OUT_DIR
    # - CMAKE_CURRENT_SOURCE_DIR
    # - NOSTRA_CMAKE_OPTIMIZE_OUTPUT_FOR_C
    # - NOSTRA_CMAKE_BUILTIN_STL_SUPPORT
    # - NOSTRA_CMAKE_HAVE_DOT
    # - NOSTRA_CMAKE_DOT_PATH
    #]]

    cmake_parse_arguments(FUNC "" "OUT_DIR" "" ${ARGN})

    _nostra_check_parameters()
    _nostra_check_if_nostra_project()

    if(NOT DEFINED FUNC_OUT_DIR)
        set(NOSTRA_CMAKE_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/doc")
    else()
        set(NOSTRA_CMAKE_OUT_DIR "FUNC_OUT_DIR")
    endif()

    # Add the option for the current project
    option(${PROJECT_PREFIX}_BUILD_DOC "If enabled, the documentation for ${PROJECT_NAME} will be built." ON)

    if(${PROJECT_PREFIX}_BUILD_DOC)
        find_package(Doxygen OPTIONAL_COMPONENTS dot)

        if(DOXYGEN_FOUND)
            _nostra_generate_doc_forwards_comp_helper()

            nostra_message("Doxygen: Executable was found at ${DOXYGEN_EXECUTABLE}, documentation will be generated.")

            # Handle dot usage/configuration
            if(DOXYGEN_DOT_FOUND)
                nostra_message("Doxygen: Found dot at ${DOXYGEN_DOT_EXECUTABLE}.")

                set(NOSTRA_CMAKE_HAVE_DOT "YES")
                set(NOSTRA_CMAKE_DOT_PATH "${DOXYGEN_DOT_EXECUTABLE}")
            else()
                nostra_message("Doxygen: Could not find dot. Graph generation will be omitted.")

                set(NOSTRA_CMAKE_HAVE_DOT "NO")
            endif()

            # Handle language usage/configuration
            _nostra_is_c_enabled(IS_C_ENABLED)
            _nostra_is_cpp_enabled(IS_CPP_ENABLED)

            # If C++ is not enabeld, Doxygen can optimize the output for C
            if(${IS_C_ENABLED} AND NOT ${IS_CPP_ENABLED})
                set(NOSTRA_CMAKE_OPTIMIZE_OUTPUT_FOR_C "YES")
            else()
                set(NOSTRA_CMAKE_OPTIMIZE_OUTPUT_FOR_C "NO")
            endif()

            # If C++ is enabled, this will optimize the doc for STL usage
            if(${IS_CPP_ENABLED})
                set(NOSTRA_CMAKE_BUILTIN_STL_SUPPORT "YES")
            else()
                set(NOSTRA_CMAKE_BUILTIN_STL_SUPPORT "NO")
            endif()
            # End of language usage/configuration

	    	configure_file("doc/Doxyfile.in" "${NOSTRA_CMAKE_OUT_DIR}/Doxyfile")

	    	add_custom_target(NostraSocketWrapperDoc
	    		ALL COMMAND "${DOXYGEN_EXECUTABLE}" "${NOSTRA_CMAKE_OUT_DIR}/Doxyfile"
	    		WORKING_DIRECTORY "."
	    		COMMENT "Generating Doxygen documentation for ${PROJECT_NAME}"
	    		VERBATIM)

	    	install(DIRECTORY "${NOSTRA_CMAKE_OUT_DIR}/html/"
	    		DESTINATION
	    			"doc"
	    		COMPONENT
	    			"Documentation")
        else()
            nostra_message("Doxygen executable could not be found, documentation generation will be omitted.")
        endif()
    endif()
endfunction()

function(_nostra_add_example_helper EXAMPLE_NAME LANGUAGE)

    cmake_parse_arguments(FUNC "" "EXAMPLE_TARGET" "ADDITIONAL_SOURCES" ${ARGN})

    if(NOT DEFINED FUNC_EXAMPLE_TARGET)
        message(SEND_ERROR "parameter EXAMPLE_TARGET is required")
    endif()

    _nostra_check_parameters()
    _nostra_check_if_nostra_project()

    if(${LANGUAGE} STREQUAL "c")
        set(UPPER_LANG "C")
    elseif(${LANGUAGE} STREQUAL "cpp")
        set(UPPER_LANG "CXX")
    else()
        message(SEND_ERROR "Invalid language ${LANGUAGE}")
    endif()

    set_source_files_properties("examples/${EXAMPLE_NAME}.d/${EXAMPLE_NAME}.${LANGUAGE}" PROPERTIES LANGUAGE "${UPPER_LANG}")

    nostra_prefix_list(FUNC_ADDITIONAL_SOURCES "examples/${EXAMPLE_NAME}.d/")

    foreach(SRC IN LISTS FUNC_ADDITIONAL_SOURCES)
        set_source_files_properties("${SRC}" PROPERTIES LANGUAGE "${UPPER_LANG}")
    endforeach()

    add_executable("${EXAMPLE_NAME}" "examples/${EXAMPLE_NAME}.d/${EXAMPLE_NAME}.${LANGUAGE}" "${FUNC_ADDITIONAL_SOURCES}")

    target_link_libraries("${EXAMPLE_NAME}" "${FUNC_EXAMPLE_TARGET}")

    install(TARGETS "${EXAMPLE_NAME}" EXPORT "${PROJECT_EXPORT}"
        RUNTIME 
            DESTINATION "examples"
            COMPONENT "Examples")
endfunction()

function(nostra_add_c_example EXAMPLE_NAME)
    if(NOSTRA_BUILD_EXAMPLES)
        _nostra_add_example_helper(EXAMPLE_NAME "c" ${ARGN})
    endif()
endfunction()

function(nostra_add_cpp_example EXAMPLE_NAME)
    if(NOSTRA_BUILD_EXAMPLES)
        _nostra_add_example_helper(EXAMPLE_NAME "cpp" ${ARGN})
    endif()
endfunction()

function(nostra_add_library NAME)

    _nostra_check_if_nostra_project()

    option("${PROJECT_PREFIX}_BUILD_${NAME}_SHARED" "If enabled, the library ${NAME} will be build as shared library.")

    if(${PROJECT_PREFIX}_BUILD_${NAME}_SHARED)
        add_library(${NAME} SHARED ${ARGN})
    else()
        add_library(${NAME} STATIC ${ARGN})
    endif()

    target_compile_definitions(${NAME} 
        INTERFACE
            "NOSTRA_HAS_${PROJECT_PREFIX}")
endfunction()

function(nostra_get_compiler_id OUT_VAR)
    get_property(ENABLED_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)

    if("CXX" IN_LIST ENABLED_LANGUAGES)
        set("${OUT_VAR}" "${CMAKE_CXX_COMPILER_ID}" PARENT_SCOPE)
    elseif("C" IN_LIST ENABLED_LANGUAGES) # If C is in the list but not CXX
        set("${OUT_VAR}" "${CMAKE_C_COMPILER_ID}" PARENT_SCOPE)
    else()
        message(SEND_ERROR "Neither C nor C++ are enabled as languages.")
    endif()
endfunction()

