cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

include("${CMAKE_SOURCE_DIR}/../../../src/Nostra.cmake")

nostra_project(NostraCppTestProject ntp
    VERSION 1.0.0.0
    DESCRIPTION "A test project."
    LANGUAGES CXX)

add_library(CppTestLib STATIC "src/component.cpp")
add_library(Nostra::CppTestLib ALIAS CppTestLib)

target_include_directories(CppTestLib
	PUBLIC
        "include")

include(CTest)

enable_testing()

nostra_add_cpp_test("component.wt" TEST_TARGET "Nostra::CppTestLib" ADDITIONAL_SOURCES "source.cpp")
nostra_add_cpp_test("component.1.wt" TEST_TARGET "Nostra::CppTestLib" NOCOPY)
