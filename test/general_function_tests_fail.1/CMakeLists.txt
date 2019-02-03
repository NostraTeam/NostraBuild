cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include("${CMAKE_SOURCE_DIR}/../../src/nostra/Nostra.cmake")

add_executable(TestExec "source.c")

_nostra_check_if_lib(TestExec)