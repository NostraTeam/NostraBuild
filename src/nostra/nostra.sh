#!/bin/sh

print_usage()
{
    printf "Usage:\n"
    printf "$1 init: Initialize a new Nostra project.\n"
}

print_vertical_line()
{
    COLS=$(tput cols)

    for i in $(seq 1 ${COLS})
    do
        printf "="
    done

    printf "\n"
}

var_matches()
{
    if [ "$#" -ne "2" ]
    then
        printf "var_matches() was used incorrectly."
    fi

    GREP_OUTPUT=$(echo "$1" | grep "$2" 2> /dev/null)

    if [ "${GREP_OUTPUT}" = "" ]
    then
        return 1
    fi
}

var_does_not_match()
{
    if [ "$#" -ne "2" ]
    then
        printf "var_does_not_match() was used incorrectly."
    fi

    # Invert the result of var_matches()
    if var_matches "$1" "$2"
    then
        return 1
    fi
}

ask_yes_no()
{
    if  [ "$#" -ne "1" ] || [ "$1" != "yes" ] && [ "$1" = "no" ]
    then
        printf "ask_yes_no() was used incorrectly."
    fi

    read INPUT

    if [ "${INPUT}" = "Y" ] || [ "${INPUT}" = "N" ] ||
       [ "${INPUT}" = "y" ] || [ "${INPUT}" = "n" ]
    then
        if [ "${INPUT}" = "Y" ] || [ "${INPUT}" = "y" ]
        then
            return 0
        else
            return 1
        fi
    else

        if [ "${INPUT}" = "" ]
        then
            # Return default value
            if [ "$1" = "yes" ]
            then
                return 0
            else
                return 1
            fi
        else
            printf "Invalid input.\n"
            ask_yes_no
        fi
    fi
}

ask_for_name()
{
    printf "What is the name of the project (without a leading 'Nostra')?\n"
    printf "The name can consist only of letters.\n"
    printf "==> "
    read NAME

    if var_does_not_match "${NAME}" "^[a-zA-Z]\{1,\}$"
    then
        printf "The name has the wrong format.\n"
        ask_for_name
    else
        printf "The name is '${NAME}'. The final name of the project will be 'Nostra${NAME}'.\n"
    fi
}

ask_for_prefix()
{
    printf "What is the prefix of the project? The prefix is a short, optimally three letter\n"
    printf "long abbreviation of the project name.\n"
    printf "Prefixes consist of only lowercase letters. They have a minimum lentgth of\n"
    printf "three (3). For example, the prefix of the project 'Nostra Utils' is 'nou'.\n"
    printf "==> "
    read PREFIX

    if var_does_not_match "${PREFIX}" "^[a-z]\{3,\}$"
    then
        printf "The prefix has the wrong format.\n"
        ask_for_prefix
    else
        printf "The prefix is '${PREFIX}'.\n"
    fi
}

ask_for_description()
{
    printf "Please give a short description for the project.\n"
    printf "==> "
    read DESCRIPTION

    printf "The description is '${DESCRIPTION}'.\n"
}

ask_for_version()
{
    printf "Please give the initial version of the project. The version needs to be\n"
    printf "given in in the format <major>.<minor>.<patch>.<tweak>, e.g. 1.0.2.0.\n"
    printf "Entering an empty string will set the initial version to 1.0.0.0.\n"
    printf "==> "
    read VERSION

    if [ "${VERSION}" = "" ]
    then
        VERSION="1.0.0.0"
    fi

    if var_does_not_match "${VERSION}" "^[0-9][0-9]*\(\.[0-9][0-9]*\)\{0,3\}$"
    then
        printf "The version format is incorrect.\n"
        ask_for_version
    else
        #Format: x ; extends to x.0.0.0
        if var_matches "${VERSION}" "^[0-9][0-9]*$"
        then
            VERSION="${VERSION}.0.0.0"
        else
            #Format: x.y ; extends to x.y.0.0
            if var_matches "${VERSION}" "^[0-9][0-9]*\.[0-9][0-9]*$"
            then
                VERSION="${VERSION}.0.0"
            else
                #Format: x.y.z ; extends to x.y.z.0
                if var_matches "${VERSION}" "^[0-9][0-9]\.[0-9][0-9]*\.[0-9][0-9]*$"
                then
                    VERSION="${VERSION}.0"
                fi
            fi
        fi

        printf "The initial version is '${VERSION}'.\n"
    fi
}

ask_for_root_dir()
{
    printf "Where should the gererated files be placed? Entering an empty string will\n"
    printf "place the files in a subdirectory of the current working directory.\n"
    printf "==> "
    read ROOT_DIR

    if [ "${ROOT_DIR}" = "" ]
    then
        ROOT_DIR="./Nostra${NAME}"
    fi

    printf "The files will be generated into the directory '$ROOT_DIR'\n"
}

ask_for_creator_name()
{
    printf "What is the name of the creator of the project?\n"
    printf "==> "

    read CREATOR_NAME

    printf "The creator of the project is '${CREATOR_NAME}'.\n"
}

ask_for_mit()
{
    printf "Does the project use the MIT license? Y/N (Default: Y)\n"
    printf "==> "

    if ask_yes_no "yes"
    then
        USE_MIT="ON"
        printf "Using MIT license.\n"

        printf "\n"
        ask_for_creator_name
    else
        USE_MIT="OFF"
        printf "Not using MIT license.\n"
    fi
}

ask_for_github()
{
    printf "Please enter the link to the project's GitHub repository. Entering an empty\n"
    printf "string will set no link.\n"
    printf "Note: This will not initialize a new Git repository on your local machine.\n"
    printf "==> "

    read GITHUB_LINK

    printf "The GitHub Link is '${GITHUB_LINK}'.\n"
}

ask_for_clang_format()
{
    printf "Should the project use clang-format? Y/N (Default: Y)\n"
    printf "==> "

    if ask_yes_no "yes"
    then
        USE_CLANG_FORMAT="ON"
        printf "Using clang-format.\n"
    else
        USE_CLANG_FORMAT="OFF"
        printf "Not using clang-format.\n"
    fi
}

ask_for_clang_tidy()
{
    printf "Should the project use clang-tidy? Y/N (Default: Y)\n"
    printf "==> "

    if ask_yes_no "yes"
    then
        USE_CLANG_TIDY="ON"
        printf "Using clang-tidy.\n"
    else
        USE_CLANG_TIDY="OFF"
        printf "Not using clang-tidy.\n"
    fi
}

ask_for_config_h()
{
    printf "Should the project use a config.h file? Y/N (Default: Y)\n"
    printf "==> "

    if ask_yes_no "yes"
    then
        USE_CONFIG_H="ON"
        printf "Using config.h file.\n"
    else
        USE_CONFIG_H="OFF"
        printf "Not using config.h file.\n"
    fi
}

generate_files()
{
    # Get location of the script file. Location is <project root>/bin. CMake script is in 
    # <project root>/nostra/CreateProject.cmake
    SCRIPT=$(readlink -f "$0")
    SCRIPTPATH=$(dirname "$SCRIPT")

    printf "\n"

    cmake -DNOSTRA_NAME="${NAME}" -DNOSTRA_PREFIX="${PREFIX}" -DNOSTRA_DESCRIPTION="${DESCRIPTION}" \
    -DNOSTRA_OUT_ROOT="${ROOT_DIR}" -DNOSTRA_HAVE_CLANG_FORMAT="${USE_CLANG_FORMAT}" \
    -DNOSTRA_HAVE_CLANG_TIDY="${USE_CLANG_TIDY}" -DNOSTRA_HAVE_CONFIG_H="${USE_CONFIG_H}" \
    -DNOSTRA_INITIAL_VERSION="${VERSION}" -DNOSTRA_HAVE_MIT="${USE_MIT}" -DNOSTRA_CREATOR_NAME="${CREATOR_NAME}" \
    -DNOSTRA_GITHUB_LINK="${GITHUB_LINK}" \
    -P "${SCRIPTPATH}/../nostra/CreateProject.cmake" > /dev/null

    printf "\n"

    return $?
}

init()
{
    printf "Welcome to the interactive Nostra project creation.\n"
    printf "This tool will walk you through the creation of your project.\n"
    printf "\n"
    printf "The tool will ask you for input to customize the project. Please enter the\n"
    printf "desired values and accept them by pressing ENTER.\n"
    print_vertical_line
    ask_for_name
    printf "\n"
    ask_for_prefix
    printf "\n"
    ask_for_description
    printf "\n"
    ask_for_version
    printf "\n"
    ask_for_mit
    printf "\n"
    ask_for_github
    printf "\n"
    ask_for_root_dir
    printf "\n"
    ask_for_clang_format
    printf "\n"
    ask_for_clang_tidy
    printf "\n"
    ask_for_config_h
    print_vertical_line
    printf "The interactive dialog is now over. The project files will now be generated.\n"

    if generate_files
    then
        printf "Files were generated.\n"
    else
        printf "Error generating files.\n"
    fi
}

if [ "$#" -eq "1" ]
then
    if [ "$1" = "init" ]
    then
        init
    else
        print_usage "$0"
    fi
else
    print_usage "$0"
fi
