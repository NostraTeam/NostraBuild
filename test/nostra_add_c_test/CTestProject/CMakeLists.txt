cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

option(NOSTRA_BUILD_SHARED "If enabled, the library will be build as shared library." OFF)

#set(NOSTRA_CMAKE_DEBUG "ON")
include("${CMAKE_SOURCE_DIR}/../../../src/Nostra.cmake")

nostra_project(NostraCTestProject ntp
    VERSION 1.0.0.0
    DESCRIPTION "A test project."
    LANGUAGES C)

if(NOSTRA_BUILD_SHARED)
    add_library(CTestLib SHARED "src/component.c")
else()
    add_library(CTestLib STATIC "src/component.c")
endif()

add_library(Nostra::CTestLib ALIAS CTestLib)

target_include_directories(CTestLib
	PUBLIC
        "include")

include(CTest)

enable_testing()

nostra_add_c_test("component.wt" TEST_TARGET "Nostra::CTestLib" ADDITIONAL_SOURCES "source.c" TEST_CPP)
nostra_add_c_test("component.1.wt" TEST_TARGET "Nostra::CTestLib" TEST_CPP NOCOPY)
