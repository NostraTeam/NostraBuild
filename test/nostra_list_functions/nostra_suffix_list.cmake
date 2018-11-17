cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

include("${CMAKE_SOURCE_DIR}/../../src/Nostra.cmake")

set(TEST_LIST_0 "one")
set(TEST_LIST_1 "one;two")
set(TEST_LIST_2 "one;two;three")
set(TEST_LIST_3 "one;two;three;four")

nostra_suffix_list(TEST_LIST_0_OUT "_SUFFIX" "${TEST_LIST_0}")

list(GET TEST_LIST_0_OUT 0 TEST_LIST_0_OUT_0)

_nostra_test("${TEST_LIST_0_OUT_0}" STREQUAL "one_SUFFIX")

nostra_suffix_list(TEST_LIST_1_OUT "_SUFFIX" "${TEST_LIST_1}")

list(GET TEST_LIST_1_OUT 0 TEST_LIST_1_OUT_0)
list(GET TEST_LIST_1_OUT 1 TEST_LIST_1_OUT_1)

_nostra_test("${TEST_LIST_1_OUT_0}" STREQUAL "one_SUFFIX")
_nostra_test("${TEST_LIST_1_OUT_1}" STREQUAL "two_SUFFIX")

nostra_suffix_list(TEST_LIST_2_OUT "_SUFFIX" "${TEST_LIST_2}")

list(GET TEST_LIST_2_OUT 0 TEST_LIST_2_OUT_0)
list(GET TEST_LIST_2_OUT 1 TEST_LIST_2_OUT_1)
list(GET TEST_LIST_2_OUT 2 TEST_LIST_2_OUT_2)

_nostra_test("${TEST_LIST_2_OUT_0}" STREQUAL "one_SUFFIX")
_nostra_test("${TEST_LIST_2_OUT_1}" STREQUAL "two_SUFFIX")
_nostra_test("${TEST_LIST_2_OUT_2}" STREQUAL "three_SUFFIX")

nostra_suffix_list(TEST_LIST_3_OUT "_SUFFIX" "${TEST_LIST_3}")

list(GET TEST_LIST_3_OUT 0 TEST_LIST_3_OUT_0)
list(GET TEST_LIST_3_OUT 1 TEST_LIST_3_OUT_1)
list(GET TEST_LIST_3_OUT 2 TEST_LIST_3_OUT_2)
list(GET TEST_LIST_3_OUT 3 TEST_LIST_3_OUT_3)

_nostra_test("${TEST_LIST_3_OUT_0}" STREQUAL "one_SUFFIX")
_nostra_test("${TEST_LIST_3_OUT_1}" STREQUAL "two_SUFFIX")
_nostra_test("${TEST_LIST_3_OUT_2}" STREQUAL "three_SUFFIX")
_nostra_test("${TEST_LIST_3_OUT_3}" STREQUAL "four_SUFFIX")

