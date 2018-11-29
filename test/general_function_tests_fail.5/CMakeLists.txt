cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

include("${CMAKE_SOURCE_DIR}/../../src/nostra/Nostra.cmake")

function(testfunc)
    message("1: ${ARGN}")
    _nostra_check_no_parameters(${ARGN})
endfunction()

testfunc(a b c) # Pass three additional, unexpected parameters