cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

include("${CMAKE_SOURCE_DIR}/../../src/Nostra.cmake")

add_executable(TestExec "source.c")

_nostra_check_if_lib(TestExec)