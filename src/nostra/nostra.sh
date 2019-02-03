#!/bin/sh

print_usage()
{
    printf "Usage:\n"
    printf "$1 init: Initialize a new Nostra package.\n"
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

ask_for_name()
{
    printf "What is the name of the package (without a leading 'Nostra')?\n"
    printf "==> "
    read NAME

    if [ "${NAME}" = "" ]
    then
        printf "The name can not be empty. Please choose a different one.\n"
        ask_for_name
    fi

    printf "The name is '${NAME}'. The final name of the package will be 'Nostra${NAME}'.\n"
}

ask_for_prefix()
{
    printf "What is the prefix of the package? The prefix is a short, optimally three letter\n"
    printf "long abbreviation of the package name. For example, the prefix of the package\n"
    printf "'Nostra Utils' is 'nou'.\n"
    printf "==> "
    read PREFIX

    if [ "${PREFIX}" = "" ]
    then
        printf "The prefix can not be empty. Please choose a different one.\n"
        ask_for_prefix
    fi

    printf "The prefix is '${PREFIX}'.\n"
}

ask_for_description()
{
    printf "Please give a short description for the package.\n"
    printf "==> "
    read DESCRIPTION

    printf "The description is '${DESCRIPTION}'.\n"
}

ask_for_root_dir()
{
    printf "Where should the gererated files be placed? Entering an empty string will place\n"
    printf "the files in a subdirectory of the current working directory.\n"
    printf "==> "
    read ROOT_DIR

    if [ "${ROOT_DIR}" = "" ]
    then
        ROOT_DIR="./Nostra${NAME}"
    fi

    printf "The files will be generated into the directory '$ROOT_DIR'\n"
}

ask_for_clang_format()
{
    printf "Should the package use clang-format? Y/N\n"
    printf "==> "
    read USE_CLANG_FORMAT

    if [ "${USE_CLANG_FORMAT}" = "Y" ] || [ "${USE_CLANG_FORMAT}" = "N" ] ||
       [ "${USE_CLANG_FORMAT}" = "y" ] || [ "${USE_CLANG_FORMAT}" = "n" ]
    then
        if [ "${USE_CLANG_FORMAT}" = "Y" ] || [ "${USE_CLANG_FORMAT}" = "y" ]
        then
            USE_CLANG_FORMAT="ON"
            printf "Using clang-format.\n"
        else
            USE_CLANG_FORMAT="OFF"
            printf "Not using clang-format.\n"
        fi
    else
        printf "Invalid input.\n"
        ask_for_clang_format
    fi
}

ask_for_clang_tidy()
{
    printf "Should the package use clang-tidy? Y/N\n"
    printf "==> "
    read USE_CLANG_TIDY

    if [ "${USE_CLANG_TIDY}" = "Y" ] || [ "${USE_CLANG_TIDY}" = "N" ] ||
       [ "${USE_CLANG_TIDY}" = "y" ] || [ "${USE_CLANG_TIDY}" = "n" ]
    then
        if [ "${USE_CLANG_TIDY}" = "Y" ] || [ "${USE_CLANG_TIDY}" = "y" ]
        then
            USE_CLANG_TIDY="ON"
            printf "Using clang-tidy.\n"
        else
            USE_CLANG_TIDY="OFF"
            printf "Not using clang-tidy.\n"
        fi
    else
        printf "Invalid input.\n"
        ask_for_clang_tidy
    fi
}

ask_for_config_h()
{
    printf "Should the package use a config.h file? Y/N\n"
    printf "==> "
    read USE_CONFIG_H

    if [ "${USE_CONFIG_H}" = "Y" ] || [ "${USE_CONFIG_H}" = "N" ] ||
       [ "${USE_CONFIG_H}" = "y" ] || [ "${USE_CONFIG_H}" = "n" ]
    then
        if [ "${USE_CONFIG_H}" = "Y" ] || [ "${USE_CONFIG_H}" = "y" ]
        then
            USE_CONFIG_H="ON"
            printf "Using config.h file.\n"
        else
            USE_CONFIG_H="OFF"
            printf "Not using config.h file.\n"
        fi
    else
        printf "Invalid input.\n"
        ask_for_config_h
    fi
}

generate_files()
{
    # Get location of the script file. Location is <package root>/bin. CMake script is in 
    # <package root>/nostra/CreateProject.cmake
    SCRIPT=$(readlink -f "$0")
    SCRIPTPATH=$(dirname "$SCRIPT")

    printf "\n"

    cmake -DNOSTRA_NAME="${NAME}" -DNOSTRA_PREFIX="${PREFIX}" -DNOSTRA_DESCRIPTION="${DESCRIPTION}" \
    -DNOSTRA_OUT_ROOT="${ROOT_DIR}" -DNOSTRA_HAVE_CLANG_FORMAT="${USE_CLANG_FORMAT}" \
    -DNOSTRA_HAVE_CLANG_TIDY="${USE_CLANG_TIDY}" -DNOSTRA_HAVE_CONFIG_H="${USE_CONFIG_H}" \
    -P "${SCRIPTPATH}/../nostra/CreateProject.cmake" > /dev/null

    printf "\n"

    return $?
}

init()
{
    printf "Welcome to the interactive Nostra package creation.\n"
    printf "This tool will walk you through the creation of your package.\n"
    printf "\n"
    printf "The tool will ask you for input to customize the package. Please enter the\n"
    printf "desired values and accept them by pressing ENTER.\n"
    print_vertical_line
    ask_for_name
    printf "\n"
    ask_for_prefix
    printf "\n"
    ask_for_description
    printf "\n"
    ask_for_root_dir
    printf "\n"
    ask_for_clang_format
    printf "\n"
    ask_for_clang_tidy
    printf "\n"
    ask_for_config_h
    print_vertical_line
    printf "The interactive dialog is now over. The package files will now be generated.\n"

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
        print_usage
    fi
else
    print_usage
fi
