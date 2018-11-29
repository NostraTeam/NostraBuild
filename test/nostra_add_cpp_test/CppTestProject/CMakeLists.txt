cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

option(NOSTRA_BUILD_SHARED "If enabled, the library will be build as shared library." OFF)

include("${CMAKE_SOURCE_DIR}/../../../src/nostra/Nostra.cmake")

nostra_project(NostraCppTestProject ntp
    VERSION 1.0.0.0
    DESCRIPTION "A test project."
    LANGUAGES CXX)

if(NOSTRA_BUILD_SHARED)
    add_library(CppTestLib SHARED "src/component.cpp")
else()
    add_library(CppTestLib STATIC "src/component.cpp")
endif()

add_library(Nostra::CppTestLib ALIAS CppTestLib)

target_include_directories(CppTestLib
	PUBLIC
        "include")

include(CTest)

enable_testing()

nostra_add_cpp_test(TEST_NAME "component" TEST_TYPE "wt" TEST_TARGET "Nostra::CppTestLib" ADDITIONAL_SOURCES "source.cpp")
nostra_add_cpp_test(TEST_NAME "component.1" TEST_TYPE "wt" TEST_TARGET "Nostra::CppTestLib" NOCOPY)
