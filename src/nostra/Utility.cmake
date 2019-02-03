cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

#[[
# Parameters:
#     - OUT    The variable that the output list will be stored in
#     - PREFIX The prefix to add
# 
# Adds a prefix to all elements in a list.
# 
# E.g.:
# The list "one;two;three" and the prefix "prefix_" would result in the list "prefix_one;prefix_two;prefix_three".
#]]
function(nostra_prefix_list OUT PREFIX)
    _nostra_check_no_parameters()
	set(LIST_INTERNAL "")

	foreach(STR IN LISTS ARGN)
		list(APPEND LIST_INTERNAL "${PREFIX}${STR}")
	endforeach()

	set("${OUT}" "${LIST_INTERNAL}" PARENT_SCOPE)
endfunction()

#[[
# Parameters:
#     - OUT:    The variable that the output list will be stored in
#     - SUFFIX: The suffix to add
# 
# Adds a suffix to all elements in a list.
# 
# E.g.:
# The list "one;two;three" and the suffix "suffix_" would result in the list "one_suffix;two_suffix;three_suffix".
#]]
function(nostra_suffix_list OUT SUFFIX)
    _nostra_check_no_parameters()
	set(LIST_INTERNAL "")

	foreach(STR IN LISTS ARGN)
		list(APPEND LIST_INTERNAL "${STR}${SUFFIX}")
	endforeach()

	set("${OUT}" "${LIST_INTERNAL}" PARENT_SCOPE)
endfunction()

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
#   - OUT_VAR: The name of the output variable.
#   - TARGET:  The target to get the name of.
#
# Stores the actual name TARGET in OUT_VAR is TARGET is an alias name. If TARGET is not a name, the value in OUT_VAR
# will be the value of TARGET.
#]]
function(nostra_alias_get_actual_name OUT_VAR TARGET)
    _nostra_check_no_parameters()

    get_target_property(ALIAS_NAME "${TARGET}" ALIASED_TARGET)

    if(NOT "${ALIAS_NAME}" STREQUAL "ALIAS_NAME-NOTFOUND")
        set("${OUT_VAR}" "${ALIAS_NAME}" PARENT_SCOPE)
    else()
        set("${OUT_VAR}" "${TARGET}" PARENT_SCOPE)
    endif()
endfunction()

#[[
# Parameters:
#     - OUT_VAR: The variable that the compiler ID will be stored in.
# 
# Obtains the compiler ID of the current compiler. If CXX (and possbile C) are enabled as languages, the ID of the CXX 
# compiler will be used, if only C is enabled, the ID of that compiler will be used. If neither C nor CXX are enabled,
# an error will be triggered.
#]]
function(nostra_get_compiler_id OUT_VAR)
    _nostra_check_no_parameters()

    get_property(ENABLED_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)

    if("CXX" IN_LIST ENABLED_LANGUAGES)
        set("${OUT_VAR}" "${CMAKE_CXX_COMPILER_ID}" PARENT_SCOPE)
    elseif("C" IN_LIST ENABLED_LANGUAGES) # If C is in the list but not CXX
        set("${OUT_VAR}" "${CMAKE_C_COMPILER_ID}" PARENT_SCOPE)
    else()
        nostra_print_error("Neither C nor C++ are enabled as languages.")
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
    _nostra_check_no_parameters()

    nostra_alias_get_actual_name(OUT_VAR ${${VAR}})
    set("${VAR}" "${OUT_VAR}" PARENT_SCOPE)
endfunction()

#[[
# Parameters:
#   - STR: The string to print.
#
# Prints a status message in the format "<project name>: <STR>".
#
# This function can only be called, if nostra_project() was called first.
#]]
function(nostra_message STR)
    _nostra_check_no_parameters()
    _nostra_check_if_nostra_project()

    message(STATUS "${PROJECT_NAME}: ${STR}")
endfunction()

#[[
# Parameters:
#   - STR: The string to print.
#
# Prints an error message in the format "<project name>: <STR>" and makes the configuration fail.
#
# This function can only be called, if nostra_project() was called first.
#]]
function(nostra_print_error STR)
    if(NOT DEFINED PROJECT_NAME)
        set(PROJECT_NAME "<no project>")
    endif()

    message(FATAL_ERROR "${PROJECT_NAME}: ${STR}")
endfunction()

#[[
# Parameters:
#     - NAME:  The name of the library that will be added.
#     - <any>: Any additional parameters, these will be redirected to add_library().
# 
# Similar to add_library(), but it does a few additional things:
#     - It adds an option to build that specific library as shared or static library (the option is called 
#       <project prefix>_BUILD_<library name>_SHARED). If the option is FALSE, the library will be built as static 
#       library, if it is TRUE, it will be build as shared library.
#     - It sets the compile definition NOSTRA_HAS_<project prefix> as an INTERFACE compile definition. This macro can
#       then be used by another project that uses the library to check if it can be used (e.g. is it possible to only 
#       include the header files from this library if the macro is defined).
#       
# This function can only be called, if nostra_project() was called first.
#]]
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
