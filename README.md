# NostraBuild
CMake module(s) and script(s) that are used to build Nostra packages.

GitHub: https://github.com/NostraTeam/NostraBuild

CMake is developed and maintained by KitWare and it is not affiliated with the Nostra Project.  
CMake website: https://cmake.org/

## Requirements

### Build Requirements
In order to build and install the package, CMake version 3.9.0 or newer is required.

### Usage Requirements
Most of these usage requirements are not universal, but instead they depend on what features are actually being used. 
The following list gives information about the possible requirements and the context in which they are required. 

- CMake: Always required. Minimum required version is 3.9.0.
- Doxygen: Required for `nostra_generate_doc()` (which is used by projects generated by `nostra init`).
- clang-format: Required for projects that are generated by `nostra init`.
- clang-tidy: Required for projects that are generated by `nostra init`.
- Git: Required for projects that are generated by `nostra init`.
- A working C or C++ compiler (depending on the language used): Required for compiling the targets (that is libraries, 
  executables, examples and tests) that are produced by projects generated by `nostra init`.

## Build and install from source
The following commands will describe how to build and install the package. It is assumed that, at the beginning of the 
list, the current working directory of the command line interface is the root directory of the package.

```bash
mkdir build
cd build

cmake ..
cmake --build . --target install
```

These commands will build and install the package. They work with SH, BASH, cmd.exe and the powershell.

Variables that may be used to modify the build and installation process can be passed to the third command (`cmake ..`)
in the form `cmake -D<variable name>=<value>`. Commonly used variables and their possible values are:
- BUILD_TESTING: Possible values are ON or OFF. If set to ON, the test targets will be build. In order to run the 
  tests, the command `ctest` can be used.
- CMAKE_INSTALL_PREFIX: Possible values are any valid paths in the local filesystem. This determines the directory that
  the package will be installed to.

## Installation from installer

The package can be installed by using an installer. The available installers are:

- Windows:
    - None yet.
- Linux:
    - DEB package
    - RPM package
    - STGZ (self extracting archive)
- OSX:
    - None yet.

Installers can be downloaded from https://github.com/NostraTeam/NostraBuild/releases.

## Usage
The package provides two basic functionalities: a CMake library and `nostra init`, an interactive tool to
generate the project files of a new package.

### CMake Library
To use the CMake library, the CMake command `find_package("NostraBuild")` needs to be used.

The first lines of a CMakeLists.txt file usually look something like this:
```
cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

find_package("NostraBuild")
```
Note that, if the package was installed in a non-standard\* location, the installation directory needs to be
explicitly set. This can be done by using the command 
```
list(APPEND CMAKE_PREFIX_PATH "<path to installation directory>")
```
before the command
```
find_package("NostraBuild")
```
is called.

\*the standard locations vary between operating systems, but some of them are:
- Linux:
    - /usr
    - /usr/local
    - /opt
- Windows:
    - C:\Program Files (x86)\
    - C:\Program Files\
- OSX:
    - /usr
    - /usr/local
    - /opt
    - /opt/local

### nostra init
`nostra init` is an interactive command line tool that can be used to create a new package.

On Linux/Unix systems, the tool can be started by simply calling `nostra init`. However, if the tool can not be found via 
the PATH variable, the full path needs to be given. The path is `<installation directory>/bin/nostra`.

On Windows, the tool can not be run from `cmd.exe` or the powershell. Instead, a shell like Git Bash is required. To start 
the tool from `cmd.exe` or the powershell, the command 
`"<git installation directory>/bin/sh.exe" "<NostraBuild installation directory>/nostra/nostra.sh" init`
can to be used.

## Changelog
### Version 1.0.0.0
#### Additions
- Added nostra/CreateProject.cmake, a script that can be used to create the default files of a new Nostra package.
- Added the program `nostra`, a utility program that comes with NostraBuild. As of now, it only provides `nostra init`
  which is a front-end for nostra/CreateProject.cmake.
- Added the CMake function `nostra_generate_doc()` which can be used to automate the generation of a project by using 
  Doxygen.
- Added the CMake functions `nostra_add_c_example()` and `nostra_add_cpp_example()` which can be used to add examples
  for a Nostra package.
- Added the CMake functions `nostra_add_c_test()` and `nostra_add_cpp_test()` which can be used to add ex-tests for a 
  Nostra package.
- Added the CMake functions `nostra_add_c_compile_test()` and `nostra_add_cpp_compile_test()` which can be used to add 
  bu-tests for a Nostra package.
- Added the CMake function `nostra_generate_export_header()` which can be used to generate C/C++ macros to export/import
  symbols into/from a shared library.
- Added the CMake function `nostra_prefix_list()` which can be used to add a prefix to all items in a list.
- Added the CMake function `nostra_suffix_list()` which can be used to add a suffix to all items in a list.
- Added the CMake function `nostra_project()` which is just like CMake's regular `project()` function, but with some
  additional, Nostra specific, features.
- Added the CMake function `nostra_alias_get_actual_name()` which will return the actual target that an alias target
  points to.
- Added the CMake function `nostra_get_compiler_id()` which gives the compiler ID depending on the language in use -
  i.e. it returns either CMAKE_C_COMPILER_ID or CMAKE_CXX_COMPILER_ID.
- Added the CMake function `nostra_alias_to_actual_name()` which is similar to `nostra_alias_get_actual_name()`. The
  documentation describes the difference.
- Added the CMake function `nostra_message()` which is just like CMake's regular `message()` function, but it prefixes
  the message with the name of the current project. `nostra_message()` uses the status code STATUS.
- Added the CMake function `nostra_error()` which is just like CMake's regular `message()` function, but it prefixes
  the message with the name of the current project. `nostra_message()` uses the status code FATAL_ERROR.
- Added the CMake function `nostra_add_library()` which is just like CMake's regular `add_library()` function, but it 
  adds a CMake option for each library that determines whether the library will be build as shared or static library.
#### Removals
None.
#### Deprecations
None.
#### Improvements
None.
#### Fixes
None.
#### Known issues
None.
