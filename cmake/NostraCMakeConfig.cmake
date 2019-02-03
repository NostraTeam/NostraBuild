cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/../../nostra/Nostra.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/../../nostra/Nostra.cmake")
else()
    message(FATAL_ERROR "The file nostra/Nostra.cmake could not be found. Was NostraCMake not properly installed?")
endif()
