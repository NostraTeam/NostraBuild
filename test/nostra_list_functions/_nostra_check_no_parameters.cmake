cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

include("${CMAKE_SOURCE_DIR}/../../src/Nostra.cmake")

function(testfunc)
    _nostra_check_no_parameters()
endfunction()

testfunc()