
cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

set(NOSTRA_NAME "" CACHE STRING "The name of the project. Should be in upper camel case and without \"Nostra\" at the \
beginning (e.g. Utils for NostraUtils).")
set(NOSTRA_PREFIX "" CACHE STRING "The prefix of the project, e.g. nou for NostraUtils.")
set(NOSTRA_DESCRIPTION "" CACHE STRING "The description of the project.")
set(NOSTRA_LANGUAGES "CXX" CACHE STRING "The enabled languages. C for C, CXX for C++. Multiple languages need to be \
seperated with spaces.")
set(NOSTRA_LOGO "" CACHE STRING "The path to the logo (relative to the project root.) If empty, no logo is used.")

set(NOSTRA_OUT_ROOT "." CACHE PATH "The root directory of the new project. All files / directories will be put here.")
set(NOSTRA_IN_ROOT "${CMAKE_CURRENT_LIST_DIR}/..")
set(NOSTRA_INITIAL_VERSION "1.0.0.0" CACHE STRING "The initial version of the project.")
option(NOSTRA_HAVE_CLANG_FORMAT "If disabled, .clang-format will not be part of the new project tree." ON)
option(NOSTRA_HAVE_CLANG_TIDY "If disabled, .clang-tidy will not be part of the new project tree." ON)
option(NOSTRA_HAVE_CONFIG_H "If disabled, no config.h will be used by the new project." ON)

include("${CMAKE_CURRENT_LIST_DIR}/PrivateHelpers.cmake")

set(NOSTRA_NAME_CAMEL "Nostra${NOSTRA_NAME}")
string(TOUPPER "${NOSTRA_NAME}" NOSTRA_NAME_UPPER)
string(TOLOWER "${NOSTRA_NAME}" NOSTRA_NAME_LOWER)

string(TOUPPER "${NOSTRA_PREFIX}" NOSTRA_PREFIX_UPPER)
string(TOLOWER "${NOSTRA_PREFIX}" NOSTRA_PREFIX_LOWER)

if(NOT NOSTRA_LOGO STREQUAL "")
    set(NOSTRA_LOGO_ACTUAL "LOGO ${NOSTRA_LOGO}")
else()
    set(NOSTRA_LOGO_ACTUAL "")
endif()

function(nostra_create_dir DIRNAME)
    file(MAKE_DIRECTORY "${NOSTRA_OUT_ROOT}/${DIRNAME}")
    message(STATUS "Created directory: ${NOSTRA_OUT_ROOT}/${DIRNAME}")
endfunction()

function(nostra_create_file FNAME)
    file(WRITE "${NOSTRA_OUT_ROOT}/${FNAME}")
    message(STATUS "Created file: ${NOSTRA_OUT_ROOT}/${FNAME}")
endfunction()

function(nostra_configure_file IN_FILE OUT_FILE)
    configure_file("${NOSTRA_IN_ROOT}/${IN_FILE}" "${NOSTRA_OUT_ROOT}/${OUT_FILE}" @ONLY)
    message(STATUS "Configured file:\nFrom\n\t${NOSTRA_IN_ROOT}/${IN_FILE}\nto\n\t${NOSTRA_OUT_ROOT}/${OUT_FILE}")
endfunction()

function(nostra_copy_file IN_FILE OUT_FILE)
    configure_file("${NOSTRA_IN_ROOT}/${IN_FILE}" "${NOSTRA_OUT_ROOT}/${OUT_FILE}" COPYONLY)
    message(STATUS "Copied file:\nFrom\n\t${NOSTRA_IN_ROOT}/${IN_FILE}\nto\n\t${NOSTRA_OUT_ROOT}/${OUT_FILE}")
endfunction()

if("${NOSTRA_NAME}" STREQUAL "")
    nostra_print_error("NOSTRA_NAME must not be empty.")
endif()

if("${NOSTRA_PREFIX}" STREQUAL "")
    nostra_print_error("NOSTRA_PREFIX must not be empty.")
endif()

# Variables that are required for configuring cmake/in/cmake/export.h.in
# These variables are required, because they are not supposed to be configured at this point, but instead they are
# meant to be configured by the project itself later. 
# This works, because at this point, the variables will be replaced 
set(PROJECT_VERSION_MAJOR "@PROJECT_VERSION_MAJOR@")
set(PROJECT_VERSION_MINOR "@PROJECT_VERSION_MINOR@")
set(PROJECT_VERSION_PATCH "@PROJECT_VERSION_PATCH@")
set(PROJECT_VERSION_TWEAK "@PROJECT_VERSION_TWEAK@")

nostra_create_dir(".")
nostra_create_dir("cmake")
nostra_create_dir("doc")
nostra_create_dir("doc/img")
nostra_create_dir("doc/dot")
nostra_create_dir("examples")
nostra_create_dir("include")
nostra_create_dir("include/nostra")
nostra_create_dir("include/nostra/${NOSTRA_NAME_LOWER}")
nostra_create_dir("src")
nostra_create_dir("test")

# Root directory files
if(NOSTRA_HAVE_CLANG_FORMAT)
    nostra_configure_file("cmake/in/.clang-format.in" ".clang-format")
endif()
if(NOSTRA_HAVE_CLANG_TIDY)
    nostra_configure_file("cmake/in/.clang-tidy.in" ".clang-tidy")
endif()
nostra_configure_file("cmake/in/.gitattributes.in" ".gitattributes")
nostra_configure_file("cmake/in/.gitignore.in" ".gitignore")
nostra_configure_file("cmake/in/LICENSE.in" "LICENSE")
nostra_configure_file("cmake/in/README.md.in" "README.md")
nostra_configure_file("cmake/in/CMakeLists.txt.in" "CMakeLists.txt")

# cmake files
nostra_copy_file("cmake/in/cmake/CPackConfig.cmake.in" "cmake/CPackConfig.cmake.in")
nostra_configure_file("cmake/in/cmake/welcome.txt.in" "cmake/welcome.txt")
nostra_configure_file("cmake/in/cmake/Targets.cmake.in" "cmake/${NOSTRA_NAME_CAMEL}Targets.cmake")
nostra_copy_file("cmake/in/cmake/Config.cmake.in" "cmake/${NOSTRA_NAME_CAMEL}Config.cmake.in")
if(NOSTRA_HAVE_CONFIG_H)
    nostra_configure_file("cmake/in/cmake/config.h.in" "cmake/config.h.in")
endif()

# doc files
nostra_copy_file("cmake/in/doc/Doxyfile.in" "doc/Doxyfile.in") # Copy, variable expansion is done by the project itself
nostra_configure_file("cmake/in/doc/additional_doc.dox.in" "doc/additional_doc.dox")
nostra_configure_file("cmake/in/doc/style.css.in" "doc/style.css")
nostra_configure_file("cmake/in/doc/DoxygenLayout.xml.in" "doc/DoxygenLayout.xml")

message("The project has successfully been created.")
