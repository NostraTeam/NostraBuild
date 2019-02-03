cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

# Get the directory of this file; this needs to be outside of a function b/c CMAKE_CURRENT_LIST_DIR evaluates to
# the calling file inside of a function.
set(_NOSTRA_CMAKE_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

# The ../nostra part of the path is redundant, but necessary to ensure that the path is correct in the source and, 
# after installation, in the install tree.
function(_nostra_include_file FNAME)
    if(EXISTS "${_NOSTRA_CMAKE_LIST_DIR}/../nostra/${FNAME}")
        include("${_NOSTRA_CMAKE_LIST_DIR}/../nostra/${FNAME}")
    else()
        message(FATAL_ERROR "The file nostra/${FNAME} could not be found. Was NostraBuild not properly installed?")
    endif()
endfunction()

_nostra_include_file("PrivateHelpers.cmake")
_nostra_include_file("Utility.cmake")
_nostra_include_file("Testing.cmake")
_nostra_include_file("Examples.cmake")
_nostra_include_file("ExportHeader.cmake")
_nostra_include_file("Documentation.cmake")
