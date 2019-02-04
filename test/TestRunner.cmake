
#set(NOSTRA_TEST_PROJECT_ROOT "" CACHE STRING "The root of the test project.")
#set(NOSTRA_CMAKE_ADDITIONAL_FLAGS "" CACHE STRING "Additional flags for CMake. ;-separated")
#set(NOSTRA_CTEST_ADDITIONAL_FLAGS "" CACHE STRING "Additional flags for CTest. ;-separated")

file(MAKE_DIRECTORY "${NOSTRA_TEST_PROJECT_ROOT}/build") # Make sure the build dir exists

execute_process(
    COMMAND 
        "${CMAKE_COMMAND}"  ".." ${NOSTRA_CMAKE_ADDITIONAL_FLAGS}
    WORKING_DIRECTORY 
        "${NOSTRA_TEST_PROJECT_ROOT}/build"
    RESULT_VARIABLE
        EXIT_CODE)

if(NOT ${EXIT_CODE} EQUAL 0)
    message(FATAL_ERROR "Error running CMake.")
endif()

execute_process(
    COMMAND 
        "${CMAKE_COMMAND}"  "--build" "."
    WORKING_DIRECTORY 
        "${NOSTRA_TEST_PROJECT_ROOT}/build"
    RESULT_VARIABLE
        EXIT_CODE)

if(NOT ${EXIT_CODE} EQUAL 0)
    message(FATAL_ERROR "Error running CMake.")
endif()

execute_process(
    COMMAND 
        "${CMAKE_CTEST_COMMAND}" ${NOSTRA_CTEST_ADDITIONAL_FLAGS}
    WORKING_DIRECTORY 
        "${NOSTRA_TEST_PROJECT_ROOT}/build"
    RESULT_VARIABLE
        EXIT_CODE)

if(NOT ${EXIT_CODE} EQUAL 0)
    message(FATAL_ERROR "Error running CTest.")
endif()
