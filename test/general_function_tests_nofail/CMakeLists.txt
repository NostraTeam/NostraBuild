cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

set(NOSTRA_CMAKE_DEBUG "ON")

include("${CMAKE_SOURCE_DIR}/../../src/nostra/Nostra.cmake")

add_library(TestShared SHARED "source.c")
add_library(TestStatic STATIC "source.c")

add_library(AliasForTestShared ALIAS TestShared)

_nostra_check_if_lib(TestShared)
_nostra_check_if_lib(TestStatic)

_nostra_test(TRUE)

nostra_alias_get_actual_name(ALIAS_0 TestShared)
nostra_alias_get_actual_name(ALIAS_1 AliasForTestShared)

_nostra_test("${ALIAS_0}" STREQUAL "TestShared")
_nostra_test("${ALIAS_1}" STREQUAL "TestShared")

set(ALIAS_2 "TestShared")
set(ALIAS_3 "AliasForTestShared")

nostra_alias_to_actual_name(ALIAS_2)
nostra_alias_to_actual_name(ALIAS_3)

_nostra_test("${ALIAS_2}" STREQUAL "TestShared")
_nostra_test("${ALIAS_3}" STREQUAL "TestShared")

function(testfunc)
    cmake_parse_arguments(FUNC "" "" "" ${ARGN})

    _nostra_check_parameters()
endfunction()

testfunc() # Call function properly
