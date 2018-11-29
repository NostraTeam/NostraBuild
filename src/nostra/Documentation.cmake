cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include("${CMAKE_CURRENT_LIST_DIR}/PrivateHelpers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Utility.cmake")

#[[
# Parameters:
#   - OUT_DIR [optional]: The directory in which the documentation output will be stored. If this parameter is not
#                         given, the directory <current binary directory>/doc will be used (usually, it is not 
#                         necessary to pass this parameter, the default value should be fine).
#
# Enables Doxygen based documentation generation for the current project. To allow this, the project must strictly 
# conform to the Nostra conventions.
#
# The input files/directories are (all paths relative to the current source directory):
# - doc/Doxyfile.in:       The blueprint of the Doxyfile that will be used. Will be configured using CMake's 
#                          configure_file() (with the setting @ONLY)
# - doc/style.css:         An additional CSS file that is used by Doxygen.
# - doc/DoxygenLayout.xml: The layout file for doxygen.
# - doc/:                  Aside from the files named above, all files in this directory are part of the Doxygen input. 
#                          This can be used to add additional documentation from outside of the source code (see Nostra
#                          conventions for more information).
# - doc/img:               Images from this directory can be used by using the "\image" command.
# - doc/dot:               Dot files from this directory can be used by using the "\dotfile" command.
# - include/:              The code files that hold the documentation (only headers are documented, not source files).
# - README.md:             The README file. Will be used as the mainpage of the documentation.
# - examples/:             The example files.
#
# The output files are (all paths relative to the current source directory):
# - <output directory>/html: The generated HTML pages.
# - <output directory>/Doxyfile: The configured file doc/Doxyfile.in
#
# When installing, the contents of the directory <output directory>/html will be installed into the directory doc in 
# the component Documentation.
#
# This function can only be called, if nostra_project() was called first.
#]]
function(nostra_generate_doc)
    #[[
    # The Doxyfile uses the following CMake variables:
    # - PROJECT_NAME
    # - PROJECT_VERSION
    # - PROJECT_DESCRIPTION
    # - PROJECT_LOGO
    # - NOSTRA_CMAKE_OUT_DIR
    # - CMAKE_CURRENT_SOURCE_DIR
    # - NOSTRA_CMAKE_OPTIMIZE_OUTPUT_FOR_C
    # - NOSTRA_CMAKE_BUILTIN_STL_SUPPORT
    # - NOSTRA_CMAKE_HAVE_DOT
    # - NOSTRA_CMAKE_DOT_PATH
    #]]

    cmake_parse_arguments(FUNC "" "OUT_DIR" "" ${ARGN})

    _nostra_check_parameters()
    _nostra_check_if_nostra_project()

    if(NOT DEFINED FUNC_OUT_DIR)
        set(NOSTRA_CMAKE_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/doc")
    else()
        set(NOSTRA_CMAKE_OUT_DIR "FUNC_OUT_DIR")
    endif()

    # Add the option for the current project
    option(${PROJECT_PREFIX}_BUILD_DOC "If enabled, the documentation for ${PROJECT_NAME} will be built." ON)

    if(${PROJECT_PREFIX}_BUILD_DOC)
        find_package(Doxygen OPTIONAL_COMPONENTS dot)

        if(DOXYGEN_FOUND)
            nostra_message("Doxygen: Executable was found, documentation will be generated.")

            # Handle dot usage/configuration
            if(TARGET Doxygen::dot)
                get_target_property(DOT_EXECUTABLE Doxygen::dot IMPORTED_LOCATION)

                nostra_message("Doxygen: Found dot at ${DOT_EXECUTABLE}.")

                set(NOSTRA_CMAKE_HAVE_DOT "YES")
                set(NOSTRA_CMAKE_DOT_PATH "${DOT_EXECUTABLE}")
            else()
                nostra_message("Doxygen: Could not find dot. Graph generation will be omitted.")

                set(NOSTRA_CMAKE_HAVE_DOT "NO")
            endif()

            # Handle language usage/configuration
            _nostra_is_c_enabled(IS_C_ENABLED)
            _nostra_is_cpp_enabled(IS_CPP_ENABLED)

            # If C++ is not enabeld, Doxygen can optimize the output for C
            if(${IS_C_ENABLED} AND NOT ${IS_CPP_ENABLED})
                set(NOSTRA_CMAKE_OPTIMIZE_OUTPUT_FOR_C "YES")
            else()
                set(NOSTRA_CMAKE_OPTIMIZE_OUTPUT_FOR_C "NO")
            endif()

            # If C++ is enabled, this will optimize the doc for STL usage
            if(${IS_CPP_ENABLED})
                set(NOSTRA_CMAKE_BUILTIN_STL_SUPPORT "YES")
            else()
                set(NOSTRA_CMAKE_BUILTIN_STL_SUPPORT "NO")
            endif()
            # End of language usage/configuration

	    	configure_file("doc/Doxyfile.in" "${NOSTRA_CMAKE_OUT_DIR}/Doxyfile")

	    	add_custom_target(NostraSocketWrapperDoc
	    		ALL COMMAND Doxygen::doxygen "${NOSTRA_CMAKE_OUT_DIR}/Doxyfile"
	    		WORKING_DIRECTORY "."
	    		COMMENT "Generating Doxygen documentation for ${PROJECT_NAME}"
	    		VERBATIM)

	    	install(DIRECTORY "${NOSTRA_CMAKE_OUT_DIR}/html/"
	    		DESTINATION
	    			"doc"
	    		COMPONENT
	    			"Documentation")
        else()
            nostra_message("Doxygen executable could not be found, documentation generation will be omitted.")
        endif()
    endif()
endfunction()
