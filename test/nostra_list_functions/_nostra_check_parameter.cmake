cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include("${CMAKE_CURRENT_LIST_DIR}/../../src/nostra/Nostra.cmake")

function(testfunc)
    cmake_parse_arguments("FUNC" "FLAG" "ARG1;ARG2" "" "${ARGN}")

    _nostra_check_parameter("FUNC" "FLAG")
    _nostra_check_parameter("FUNC" "ARG1" "value")
    _nostra_check_parameter_match("FUNC" "ARG2" "^[a-b]$")
endfunction()

testfunc(FLAG ARG1 "value" ARG2 "a")
testfunc(FLAG ARG1 "value" ARG2 "b")