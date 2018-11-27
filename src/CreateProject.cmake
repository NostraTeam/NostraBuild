
set(NOSTRA_NAME "" CACHE STRING "The name of the project. Should be in upper camel case and without \"Nostra\" at the \
beginning (e.g. Utils for NostraUtils).")
set(NOSTRA_PREFIX "" CACHE STRING "The prefix of the project, e.g. nou for NostraUtils.")
set(NOSTRA_DESCRIPTION "" CACHE STRING "The description of the project.")
set(NOSTRA_LANGUAGES "CXX" CACHE STRING "The enabled languages. C for C, CXX for C++. Multiple languages need to be \
seperated with spaces.")
set(NOSTRA_LOGO "" CACHE STRING "The path to the logo (relative to the project root.) If empty, no logo is used.")

set(NOSTRA_OUT_ROOT "." CACHE PATH "The root directory of the new project. All files / directories will be put here.")
set(NOSTRA_IN_ROOT "${CMAKE_CURRENT_LIST_DIR}")
set(NOSTRA_INITIAL_VERSION "1.0.0.0" CACHE STRING "The initial version of the project.")
option(NOSTRA_HAVE_CLANG_FORMAT "If disabled, .clang-format will not be part of the new project tree." ON)

set(NOSTRA_NAME_CAMEL "Nostra${NOSTRA_NAME}")
string(TOUPPER "${NOSTRA_NAME}" NOSTRA_NAME_UPPER)
string(TOLOWER "${NOSTRA_NAME}" NOSTRA_NAME_LOWER)

string(TOUPPER "${NOSTRA_PREFIX_UPPER}" NOSTRA_PREFIX_UPPER)
string(TOLOWER "${NOSTRA_PREFIX_LOWER}" NOSTRA_PREFIX_LOWER)

if(NOT NOSTRA_LOGO STREQUAL "")
    set(NOSTRA_LOGO_ACTUAL "LOGO ${NOSTRA_LOGO}")
else()
    set(NOSTRA_LOGO_ACTUAL "")
endif()

function(nostra_create_dir DIRNAME)
    file(MAKE_DIRECTORY "${NOSTRA_OUT_ROOT}/${DIRNAME}")
endfunction()

function(nostra_create_file FNAME)
    file(WRITE "${NOSTRA_OUT_ROOT}/${FNAME}")
endfunction()

function(nostra_configure_file IN_FILE OUT_FILE)
    configure_file("${NOSTRA_IN_ROOT}/${IN_FILE}" "${NOSTRA_OUT_ROOT}/${OUT_FILE}" @ONLY)
endfunction()

function(nostra_copy_file IN_FILE OUT_FILE)
    configure_file("${NOSTRA_IN_ROOT}/${IN_FILE}" "${NOSTRA_OUT_ROOT}/${OUT_FILE}" COPYONLY)
endfunction()

if("${NOSTRA_NAME}" STREQUAL "")
    message(SEND_ERROR "NOSTRA_NAME must not be empty.")
endif()

if("${NOSTRA_PREFIX}" STREQUAL "")
    message(SEND_ERROR "NOSTRA_PREFIX must not be empty.")
endif()

nostra_create_dir("cmake")
nostra_create_dir("doc")
nostra_create_dir("examples")
nostra_create_dir("include")
nostra_create_dir("include/nostra")
nostra_create_dir("include/nostra/${NOSTRA_NAME_LOWER}")
nostra_create_dir("src")
nostra_create_dir("test")

# Root directory files
if(NOSTRA_HAVE_CLANG_FORMAT)
    nostra_configure_file("cmake/root/.clang-format.in" ".clang-format")
endif()
nostra_configure_file("cmake/root/.gitattributes.in" ".gitattributes")
nostra_configure_file("cmake/root/.gitignore.in" ".gitignore")
nostra_configure_file("cmake/root/LICENSE.in" "LICENSE")
nostra_configure_file("cmake/root/README.md.in" "README.md")

# cmake files
nostra_copy_file("cmake/cmake/CPackConfig.cmake.in" "cmake/CPackConfig.cmake")
nostra_configure_file("cmake/cmake/welcome.txt.in" "cmake/welcome.txt")
nostra_configure_file("cmake/cmake/Targets.cmake.in" "cmake/${NOSTRA_NAME_CAMEL}Targets.cmake")

# doc files
nostra_copy_file("cmake/doc/Doxyfile.in" "doc/Doxyfile.in") # Copy, variable expansion is done by the project itself
nostra_configure_file("cmake/doc/additional_doc.dox" "doc/additional_doc.dox")
nostra_configure_file("cmake/doc/style.css" "doc/style.css")

