cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

#[[
# Checks if FUNC_UNPARSED_ARGUMENTS is defined and triggers an error if it is not.
# 
# This can be used to check if there were unexpected arguments passed to function or macro.
# Usually, this used with and used after cmake_parse_arguments().
#]]
macro(_nostra_check_parameters)
    if(DEFINED FUNC_UNPARSED_ARGUMENTS)
        nostra_print_error("unknown argument \"${FUNC_UNPARSED_ARGUMENTS}\"")
    endif()
endmacro()

#[[
# Makes sure that ARGN has a size of 0. If that is not the case, an error will be triggered.
# 
# This function can not be used when cmake_parse_arguments() is used in the same function.
#]]
function(_nostra_check_no_parameters)
    if(ARGC GREATER 0)
        nostra_print_error("Unexpected parameters were passed to a function: ${ARGN}")
    endif()
endfunction()

#[[
# Parameters:
#     - NOSTRA_CMAKE_STR: The string to print.
# 
# Prints the passed variable, but only if NOSTRA_CMAKE_DEBUG is set to TRUE.
#]]
macro(_nostra_print_debug NOSTRA_CMAKE_STR)
    _nostra_check_no_parameters()
    if(NOSTRA_CMAKE_DEBUG)
        message(STATUS "[NOSTRA_CMAKE_DEBUG] ${NOSTRA_CMAKE_STR}")
    endif()
endmacro()

#[[
# Parameters:
#     - NOSTRA_CMAKE_VARNAME: The name of the variable to print.
# 
# Prints the passed variable using _nostra_print_debug() in the format <name of the variable>=<value of the variable>.
#]]
macro(_nostra_print_debug_value NOSTRA_CMAKE_VARNAME)
    _nostra_check_no_parameters()
    _nostra_print_debug("${NOSTRA_CMAKE_VARNAME}=${${NOSTRA_CMAKE_VARNAME}}")
endmacro()

macro(_nostra_check_if_nostra_project)
    _nostra_check_no_parameters()
    if(NOT DEFINED PROJECT_PREFIX)
        nostra_print_error("PROJECT_PREFIX is not defined, has nostra_project() been called?")
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
    _nostra_check_no_parameters()
    get_target_property(NOSTRA_CMAKE_TARGET_TYPE ${TARGET} TYPE)

    if(NOT "${NOSTRA_CMAKE_TARGET_TYPE}" MATCHES "(SHARED|STATIC)_LIBRARY")
        nostra_print_error("Target ${TARGET} is not a shared or static library.")
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
        nostra_print_error("Test Failed: ${STR_OUT}")
    endif()
endfunction()

#[[
# Parameters:
#   - OUT_VAR: The name of the output variable.
#
# Stores in OUT_VAR whether the language C is currently enabled.
#]]
function(_nostra_is_c_enabled OUT_VAR)
    _nostra_check_no_parameters()

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
    _nostra_check_no_parameters()

    get_property(LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)

    list(FIND "${LANGUAGES}" "CXX" ${OUT_VAR}) # Check if the language is in the list, if it is, it is enabled

    set(${OUT_VAR} ${${OUT_VAR}} PARENT_SCOPE) # Make the result also visible outside of the function
endfunction()

#[[
# Parameters:
#   - LANGUAGE: The language to set. "c" or "c.cpp" for C and "cpp" for CXX.
#   - ARGN:     The files to set the language of.
#
# Sets the language of the files in ARGN.
#]]
function(_nostra_set_source_file_language LANGUAGE)
    # ARGN holds the list of source files    

    if(LANGUAGE STREQUAL "c")
        set(UPPER_LANG "C")
    elseif(LANGUAGE STREQUAL "cpp" OR LANGUAGE STREQUAL "c.cpp")
        set(UPPER_LANG "CXX")
    else()
        nostra_print_error("Invalid language ${LANGUAGE}")
    endif()

    foreach(FILE IN LISTS ARGN)
        set_source_files_properties("${SRC}" PROPERTIES LANGUAGE "${UPPER_LANG}")
    endforeach()
endfunction()

#[[
# Parameters:
#   - PREFIX: The same prefix that was also passed to cmake_parse_arguments().
#   - NAME:   The name of the variable (without the prefix).
#   - REGEX:  The regex that the variable must match.
#
# Checks if a variable matches a particular regex.
#]]
macro(_nostra_check_parameter_match PREFIX NAME REGEX)
    if(NOT DEFINED "${PREFIX}_${NAME}")
        nostra_print_error("${NAME} is required.")
    else()
        if(NOT "${${PREFIX}_${NAME}}" MATCHES "${REGEX}")
            nostra_print_error("${NAME} must match ${REGEX}.")
        endif()
    endif()
endmacro()

#[[
# Parameters:
#   - PREFIX: The same prefix that was also passed to cmake_parse_arguments().
#   - NAME:   The name of the variable (without the prefix).
#   - ARGN:   A list of the possible values for the variables.
#
# Checks if a variable has one of a set of values.
#]]
macro(_nostra_check_parameter PREFIX NAME)
    if(NOT DEFINED "${PREFIX}_${NAME}")
        nostra_print_error("${NAME} is required.")
    else()
        if(NOT "${ARGN}" STREQUAL "")
            foreach(VAL IN LISTS ARGN)
                if("${${PREFIX}_${NAME}}" STREQUAL "${VAL}")
                    set(FOUND TRUE)
                endif()
            endforeach()

            if(NOT FOUND)
                nostra_print_error("${NAME} must have one of these values: ${ARGN}.")
            endif()
        endif()
    endif()
endmacro()
