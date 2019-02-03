cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include("${CMAKE_SOURCE_DIR}/../../src/nostra/Nostra.cmake")

function(testfunc)
    cmake_parse_arguments(FUNC "" "" "" ${ARGN})

    _nostra_check_parameters()
endfunction()

testfunc(additional params) # Call function with too many params
