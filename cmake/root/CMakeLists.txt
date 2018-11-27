cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

list(APPEND CMAKE_MODULE_PATH "~/.nostra/NostraCMake/src")

include("Nostra")

if(NOT FOUND_Nostra)
    message("Nostra.cmake was not found at ${CMAKE_MODULE_PATH}.")
endif()

nostra_project(@NOSTRA_NAME_CAMEL@ @NOSTRA_PREFIX_LOWER@ 
    VERSION     "@NOSTRA_INITIAL_VERSION@"
    DESCRIPTION "@NOSTRA_DESCRIPTION@"
    LANGUAGES   "@NOSTRA_LANGUAGES@"
    @NOSTRA_LOGO_ACTUAL@)



nostra_generate_doc()