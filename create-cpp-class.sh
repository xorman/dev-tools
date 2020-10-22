#!/bin/bash
#######################################################################
# Description: Please refer to command line help (-h)
#
# Copyright 2020 Norman MEINZER, <real.norman.meinzer@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################

help() {
cat << EOF
Creates a C++ header, source, unit-test, and makefile
including a stub class as well as a test object in main().

Usage: `basename $0` [OPTION]...  [path/]class-name  [author-name]
    -h, --help    Display this help and exit
    -f            Force file overwrite
    -m            Create only the makefile
    class-name    All names are derived from this parameter.
                  Style: class-file.cpp, ClassDefinition,
                  class_instance, CLASS_MACRO
    author-name   Adds license header to all files if present.
                  Example parameter: "First LAST, <em@il.com>"
EOF
exit 1
}


main() {
  if [[ $# -lt 1 ]]; then
    help # class-name argument is mandatory
  fi
  [ "$1" == "-h" -o "$1" == "--help" ] && help

  local flag
  force_file_overwrite='no'
  create_makefile_only_flag='no'
  while getopts 'fm' flag; do
    case ${flag} in
      f) force_file_overwrite='yes' && shift ;;
      m) create_makefile_only_flag='yes' && shift ;;
      *) die "invalid option ${flag}" && shift ;;
    esac
  done

  apply_naming_conventions "$@"
  makefile_name="${dir_name}/makefile"
  if [[ -f $makefile_name ]]; then
    makefile_name="${dir_name}/${file_name}-makefile"
  fi
  create_makefile "$makefile_name"
  [[ $create_makefile_only_flag == 'yes' ]] && exit 0
  create_header_file "${dir_name}/${file_name}.h"
  create_source_file "${dir_name}/${file_name}.${extension_name}"
  create_unit_test_file "${dir_name}/${file_name}-test.${extension_name}"
  echo "Done. Output can be compiled with: cd \"$dir_name\"; make -f $makefile_name"
}


add_license() {
local comment=$1
local author=$2
local border=$(printf "%0.s$comment" {1..80})
border=${border:0:80}
((${#author})) || return
cat << EOF >> "$3"
$border
$comment Description :
$comment Created     : `date --rfc-3339=date`
$comment References  :
$comment
$comment Copyright `date +%Y` $author
$comment
$comment This program is free software: you can redistribute it and/or modify
$comment it under the terms of the GNU General Public License as published by
$comment the Free Software Foundation, either version 3 of the License, or
$comment (at your option) any later version.
$comment
$comment This program is distributed in the hope that it will be useful,
$comment but WITHOUT ANY WARRANTY; without even the implied warranty of
$comment MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
$comment GNU General Public License for more details.
$comment
$comment You should have received a copy of the GNU General Public License
$comment along with this program.  If not, see <http://www.gnu.org/licenses/>.
$border
EOF
}


apply_naming_conventions() {
  author_name="$2"
  dir_name=$(dirname "$1")
  base_name=$(basename "$1")
  base_name_no_ext=${base_name%.*} # remove extension
  base_name_dashes=${base_name_no_ext//_/-} # replace _ with -
  base_name_dashes=${base_name_dashes// /-}
  file_name=$(echo $base_name_dashes | tr '[:upper:]' '[:lower:]')
  instance_name=${file_name//-/_}
  macro_name=$(echo $instance_name | tr '[:lower:]' '[:upper:]')
  for s in $(echo $file_name | sed 's/-/ /g'); do
    camel_case+=$(echo -n $s | cut -c 1 | tr '[:lower:]' '[:upper:]');
    camel_case+=$(echo -n $s | cut -c 2-);
  done
  class_name=$(echo $camel_case | cut -c 1 | tr '[:lower:]' '[:upper:]')
  class_name+=$(echo $camel_case | cut -c 2-)
  extension_name=cpp
  extension_macro_name=$(echo $extension_name | tr '[:lower:]' '[:upper:]')
}


check_if_file_exists() {
  if [[ "$force_file_overwrite" == "no" ]] && [[ -f "$1" ]]; then
    echo "Override existing file \"$1\"? (a/y/n)"
    read answer
    case $answer in
      'a') force_file_overwrite="yes" ;;
      'y') rm "$1";;
        *) exit 1  ;;
    esac
  fi

  if [[ "$force_file_overwrite" == "yes" ]] && [[ -f "$1" ]]; then
    rm "$1"
  fi
}


create_header_file() {
check_if_file_exists "$1"
add_license '//' "$author_name" "$1"
cat << EOF >> "$1"
#ifndef ${macro_name}_H_
#define ${macro_name}_H_
#include <cstdint>

using namespace std;

class ${class_name} {
    public:
        ${class_name}();
        ~${class_name}();
    protected:
    private:
};

#endif // ${macro_name}_H_
EOF
}


create_source_file() {
check_if_file_exists "$1"
add_license '//' "$author_name" "$1"
cat << EOF >> "$1"
#ifndef ${macro_name}_${extension_macro_name}_
#define ${macro_name}_${extension_macro_name}_
#include "${file_name}.h"
#include <iostream>

///////////////////////////// PUBLIC MEMBERS ///////////////////////////////
///
${class_name}::${class_name}() {
}

///
${class_name}::~${class_name}() {

}

//////////////////////////// PRIVATE MEMBERS ///////////////////////////////
///

#endif // ${macro_name}_${extension_macro_name}_
EOF
}


create_unit_test_file() {
check_if_file_exists "$1"
add_license '//' "$author_name" "$1"
cat << EOF >> "$1"
#include "${file_name}.h"
// C system files.
#include <cstdint>
// C++ system files.
#include <iostream>
#include <string>
// Other libraries' .h files.
// Your project's .h files.

using namespace std;

int main(int argc, char *argv[]) {
    ${class_name} ${instance_name};
    exit(EXIT_SUCCESS);
}
EOF
}


create_makefile() {
check_if_file_exists "$1"
add_license '#' "$author_name" "$1"
cat << EOF >> "$1"
CC=\$(CROSS_COMPILE)g++
CFLAGS=-Wall -std=c++11 -ggdb
LDFLAGS=
NAME=${file_name}
SOURCES=\$(NAME).${extension_name} \$(NAME)-test.${extension_name}
OBJECTS=\$(SOURCES:.${extension_name}=.o)
EXECUTABLE=\$(NAME)

.PHONY: all clean

all: \$(EXECUTABLE)

\$(EXECUTABLE): \$(OBJECTS) $makefile_name
	\$(CC) \$(LDFLAGS) \$(OBJECTS) -o \$@

.${extension_name}.o:  %.${extension_name} \$(SOURCES) \$(NAME).h
	\$(CC) \$(CFLAGS) -c \$< -o \$@

clean:
	rm -f \$(NAME).o \$(NAME)-test.o \$(EXECUTABLE) \$(NAME)-tags \$(NAME)-cscope.out
EOF
}


main "$@"
exit 0
