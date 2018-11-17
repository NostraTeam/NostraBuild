cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

function(nostra_prefix_list OUT PREFIX)
	set(LIST_INTERNAL "")

	foreach(STR IN LISTS ARGN)
		list(APPEND LIST_INTERNAL "${PREFIX}${STR}")
	endforeach()

	set("${OUT}" "${LIST_INTERNAL}" PARENT_SCOPE)
endfunction()

macro(_nostra_check_parameters)
    if(DEFINED FUNC_UNPARSED_ARGUMENTS)
        message(SEND_ERROR "unknown argument \"${FUNC_UNPARSED_ARGUMENTS}\"")
    endif()
endmacro()

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

function(_nostra_add_test_helper TEST_NAME LANGUAGE)
    cmake_parse_arguments(FUNC "NOCOPY" "TEST_TARGET" "ADDITIONAL_SOURCES" "${ARGN}")

    if(NOT DEFINED FUNC_TEST_TARGET)
        message(SEND_ERROR "parameter TEST_TARGET is required")
    endif()

    # Check if PROJECT_PREFIX is defined
    if(NOT DEFINED PROJECT_PREFIX)
        message(SEND_ERROR "PROJECT_PREFIX is not defined, has nostra_project() been called?")
    endif()

    _nostra_check_parameters()

    # The name of the test executable
    set(TARGET_NAME "${PROJECT_PREFIX}.${LANGUAGE}.${TEST_NAME}")
    set(DIR_NAME "test/${TARGET_NAME}.d")

    if(NOT FUNC_NOCOPY)
        # Make sure the working directory for the command exists
        # This is only required if the resources were copied, 
        file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/${DIR_NAME}")

        # If the resources folder exists, copy it
        if(EXISTS "${CMAKE_SOURCE_DIR}/${DIR_NAME}/resources")
            file(COPY "${DIR_NAME}/resources" DESTINATION "${CMAKE_BINARY_DIR}/${DIR_NAME}")
        endif()

        # Set working dir to ${DIR_NAME} in the binary dir because resources have been copied
        set(WORKING_DIR "${CMAKE_BINARY_DIR}/${DIR_NAME}")
    else()
        # Set working dir to ${DIR_NAME} in the source dir because resources have not been copied
        set(WORKING_DIR "${CMAKE_SOURCE_DIR}/${DIR_NAME}")
    endif()

    # Properly prefix the additional source files to locate them in test/<test name>.d/src/
    nostra_prefix_list(FUNC_ACTUAL_ADD_SOURCES "${DIR_NAME}/src/" "${FUNC_ADDITIONAL_SOURCES}")

    add_executable("${TARGET_NAME}" "${DIR_NAME}/src/${TEST_NAME}.${LANGUAGE}" "${FUNC_ACTUAL_ADD_SOURCES}")

    target_link_libraries("${TARGET_NAME}" PRIVATE "${FUNC_TEST_TARGET}")

    install(TARGETS "${TARGET_NAME}" EXPORT "${PROJECT_EXPORT}"
        RUNTIME 
            DESTINATION "${DIR_NAME}"
            COMPONENT "Test")

    # Install ressources folder from the SOURCES directory (if it exists)
    if(EXISTS "${CMAKE_SOURCE_DIR}/${DIR_NAME}/resources")
        install(DIRECTORY "${CMAKE_SOURCE_DIR}/${DIR_NAME}/resources" 
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
endfunction()

function(nostra_add_c_test TEST_NAME)
	_nostra_add_test_helper("${TEST_NAME}" "c" "${ARGN}")
endfunction()

function(nostra_add_cpp_test TEST_NAME)
	_nostra_add_test_helper("${TEST_NAME}" "cpp" "${ARGN}")
endfunction()