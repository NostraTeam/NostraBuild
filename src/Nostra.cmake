cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

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
    cmake_parse_arguments(NOSTRA_CMAKE "" "VERSION;DESCRIPTION" "LANGUAGES" "${ARGN}")

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
#   - TEST_NAME:                     The name of the test. Usually something like: component.wt 
#   - LANGUAGE:                      The language of the test. Determines the names of files/directories and file
#                                    extensions of the source files.
#   - IN_DIR:                        The directory that the test is nested in (e.g. CMAKE_SOURCE_DIR).
#   - OUT_DIR:                       The directory that the testfiles will be copied to if not NOCOPY 
#                                    (e.g. CMAKE_BINARY_DIR).
#   - NOCOPY [optional]:             If TRUE, the resources will not be copied and the working directory is somewhere 
#                                    in a child directory of IN_DIR.
#   - TEST_TARGET [optional]:        The target to test, i.e. to link against. 
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
macro(_nostra_add_test_helper TEST_NAME LANGUAGE IN_DIR OUT_DIR)
    cmake_parse_arguments(FUNC "NOCOPY" "TEST_TARGET" "ADDITIONAL_SOURCES" "${ARGN}")

    if(NOT DEFINED FUNC_TEST_TARGET)
        message(SEND_ERROR "parameter TEST_TARGET is required")
    endif()

    # Check if PROJECT_PREFIX is defined
    _nostra_check_if_nostra_project()

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
    cmake_parse_arguments(FUNC "TEST_CPP" "" "" "${ARGN}")

	_nostra_add_test_helper("${TEST_NAME}" "c" "${CMAKE_SOURCE_DIR}" "${CMAKE_BINARY_DIR}" "${FUNC_UNPARSED_ARGUMENTS}")

    if(FUNC_TEST_CPP)
        # Re-Build TEST_DIR from scratch, but change <prefix>.c.<name>.d to <prefix>.c.cpp.<name>.d
        set(CPP_TEST_DIR "${CMAKE_BINARY_DIR}/test/cpp/test/${PROJECT_PREFIX}.c.cpp.${TEST_NAME}.d")

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
        _nostra_add_test_helper("${TEST_NAME}" # Test name is still the same, but the language has changed
                "c.cpp"                        # Language (c.cpp to distingush from regular c/cpp tests)
                "${CMAKE_BINARY_DIR}/test/cpp" # Input dir is the directory that the files were copied into
                "${CMAKE_BINARY_DIR}/test/cpp" # Output dir is this aswell
            TEST_TARGET
                "${FUNC_TEST_TARGET}"          # The test target is still the same
            ADDITIONAL_SOURCES
                "${ADDITIONAL_SOURCES_CPP}"    # Processed file list, with .cpp added as extension
            NOCOPY)                            # The files were already copied, no need to copy again
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
function(nostra_add_cpp_test TEST_NAME)
	_nostra_add_test_helper("${TEST_NAME}" "cpp" "${CMAKE_SOURCE_DIR}" "${CMAKE_BINARY_DIR}" "${ARGN}")
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

function(_nostra_check_if_lib TARGET)

    get_target_property(NOSTRA_CMAKE_TARGET_TYPE ${TARGET} TYPE)

    if(NOT "${NOSTRA_CMAKE_TARGET_TYPE}" MATCHES "(SHARED|STATIC)_LIBRARY")
        message(SEND_ERROR "Target ${TARGET} is not a shared or static library.")
    endif()
endfunction()

function(nostra_alias_get_actual_name OUT_VAR TARGET)
    get_target_property(ALIAS_NAME ${TARGET} ALIASED_TARGET)

    if(DEFINED ALIAS_NAME)
        set(${OUT_VAR} ${ALIAS_NAME} PARENT_SCOPE)
    else()
        set(${OUT_VAR} ${TARGET} PARENT_SCOPE)
    endif()
endfunction()

macro(nostra_alias_to_actual_name VAR)
    nostra_alias_get_actual_name(${VAR} ${${VAR}})
endmacro()

# Get the directory of this file; this needs to be outside of a function
set(_NOSTRA_CMAKE_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(_nostra_generate_export_header_helper TARGET PREFIX OUT_DIR)
    nostra_alias_to_actual_name(TARGET)

    _nostra_check_if_nostra_project()
    _nostra_check_if_lib(${TARGET})

    set(NOSTRA_CMAKE_PREFIX "${PREFIX}")
    string(TOUPPER "${NOSTRA_CMAKE_PREFIX}" NOSTRA_CMAKE_PREFIX)

    target_compile_definitions(${TARGET} 
            PRIVATE 
                "${NOSTRA_CMAKE_PREFIX}_SHOULD_EXPORT")

    get_target_property(NOSTRA_CMAKE_TARGET_TYPE ${TARGET} TYPE)

    if("${NOSTRA_CMAKE_TARGET_TYPE}" STREQUAL "STATIC_LIBRARY")
        target_compile_definitions(${TARGET} 
            PRIVATE 
                "${NOSTRA_CMAKE_PREFIX}_IS_STATIC_LIB")
    endif()

    if(WIN32)
        set(NOSTRA_CMAKE_EXPORT_ATTRIBUTE "__declspec(dllexport)")
        set(NOSTRA_CMAKE_IMPORT_ATTRIBUTE "__declspec(dllimport)")
        set(NOSTRA_CMAKE_NO_EXPORT_ATTRIBUTE "")
        set(NOSTRA_CMAKE_DEPRECATED_ATTRIBUTE "__declspec(deprecated)")
    elseif(APPLE OR UNIX)
        set(NOSTRA_CMAKE_EXPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_IMPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_NO_EXPORT_ATTRIBUTE "__attribute__((visibility(\"hidden\")))")
        set(NOSTRA_CMAKE_DEPRECATED_ATTRIBUTE "__attribute__((__deprecated__))")
    else()
        message(SEND_ERROR "This operating system is not supported.")
    endif()

    if(NOT DEFINED "${OUT_DIR}")
        set(OUT_DIR "${CMAKE_BINARY_DIR}")
    endif()

    configure_file("${_NOSTRA_CMAKE_LIST_DIR}/../cmake/export.h.in" "${OUT_DIR}/export.h" @ONLY)
endfunction()

macro(nostra_generate_export_header TARGET)
    cmake_parse_arguments(FUNC_ "" "OUTPUT_DIR" "" ${ARGN})

    # Put FUNC_OUTPUT_DIR into quotes to make sure an empty string gets passed if it is not defined
    # That way, the output directory will be the build directory
    _nostra_generate_export_header_helper(${TARGET} ${PROJECT_PREFIX} "${FUNC_OUTPUT_DIR}")
endmacro()

