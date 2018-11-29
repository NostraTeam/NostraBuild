cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include("${CMAKE_CURRENT_LIST_DIR}/PrivateHelpers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Utility.cmake")

option(NOSTRA_BUILD_EXAMPLES "If enabled, the examples of all Nostra projects will be build." ON)

#[[
# Parameters:
#   - EXAMPLE_NAME:                  The name of the example.
#   - LANGUAGE:                      The language of the test. Determines the names of files/directories and file
#                                    extensions of the source files. This is either "c" or "cpp".
#   - EXAMPLE_TARGET:                The target that the example is for, i.e. the target to link against. 
#   - ADDITIONAL_SOURCES [optional]: Additional source files required aside from the default one.
# 
# A helper to add examples.
# This helper will:
# - Add an executable with the following source files (the file names are relative to 
#   /test/examples/<example name>.ex.d):
#   - <example name>.ex.<language> (e.g. component.ex.cpp) (called: default source file, this file must always exist)
#   - Any files listed in ADDITIONAL_SOURCES
# - Install that executable into the export target of the current project.
#]]
function(_nostra_add_example_helper EXAMPLE_NAME LANGUAGE)
    cmake_parse_arguments(FUNC "" "EXAMPLE_TARGET" "ADDITIONAL_SOURCES" ${ARGN})

    set(EXAMPLE_NAME "${EXAMPLE_NAME}.ex") # Added .ex as suffix to the example name

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

    add_executable("${PROJECT_PREFIX}.${LANGUAGE}.${EXAMPLE_NAME}" "examples/${EXAMPLE_NAME}.d/${EXAMPLE_NAME}.${LANGUAGE}" "${FUNC_ADDITIONAL_SOURCES}")

    target_link_libraries("${PROJECT_PREFIX}.${LANGUAGE}.${EXAMPLE_NAME}" "${FUNC_EXAMPLE_TARGET}")

    install(TARGETS "${PROJECT_PREFIX}.${LANGUAGE}.${EXAMPLE_NAME}" EXPORT "${PROJECT_EXPORT}"
        RUNTIME 
            DESTINATION "examples"
            COMPONENT "Examples")
endfunction()

#[[
# Parameters:
#   - EXAMPLE_NAME:                  The name of the test. According to the Nostra convetion, this is the component 
#                                    name that the example is for (or another fitting name if the example is not for a 
#                                    single component).
#   - EXAMPLE_TARGET:                The target that the example is for, i.e. the target to link against. 
#   - ADDITIONAL_SOURCES [optional]: Additional source files required aside from the default one.
# 
# A function that creates examples int C for single target (that target is passed using TEST_TARGET). 
# The tests need to be in the standard layout as defined by the Nostra convention.
# 
# The examples will have the name <project prefix>.c.<example name>.ex.
#
# Note that, even if the provided source files have the extension .cpp (or any other extension), the files will be
# compiled as C code.
#
# This function can only be called, if nostra_project() was called first.
#]] 
function(nostra_add_c_example EXAMPLE_NAME)
    if(NOSTRA_BUILD_EXAMPLES)
        _nostra_add_example_helper(EXAMPLE_NAME "c" ${ARGN})
    endif()
endfunction()

#[[
# Parameters:
#   - EXAMPLE_NAME:                  The name of the test. According to the Nostra convetion, this is the component 
#                                    name that the example is for (or another fitting name if the example is not for a 
#                                    single component).
#   - EXAMPLE_TARGET:                The target that the example is for, i.e. the target to link against. 
#   - ADDITIONAL_SOURCES [optional]: Additional source files required aside from the default one.
# 
# A function that creates examples int C++ for single target (that target is passed using TEST_TARGET). 
# The tests need to be in the standard layout as defined by the Nostra convention.
# 
# The examples will have the name <project prefix>.cpp.<example name>.ex.
#
# Note that, even if the provided source files have the extension .c (or any other extension), the files will be
# compiled as C++ code.
#
# This function can only be called, if nostra_project() was called first.
#]] 
function(nostra_add_cpp_example EXAMPLE_NAME)
    if(NOSTRA_BUILD_EXAMPLES)
        _nostra_add_example_helper(EXAMPLE_NAME "cpp" ${ARGN})
    endif()
endfunction()
