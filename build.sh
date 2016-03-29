#!/bin/bash
# 
# build_index_packages.sh
# Builds packages and index file for Arduino IDE
#
# Copyright (C) 2015 Aidilab Srl
# Author: Ettore Chimenti <ek5.chimenti@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

unset D
DEBUG=${DEBUG:-0}
(( $DEBUG == 1 )) && D='-v'

# we need bash 4 for associative arrays
if [ "${BASH_VERSION%%[^0-9]*}" -lt "4" ]; then
  echo "BASH VERSION < 4: ${BASH_VERSION}" >&2
  exit 1
fi

# get package script directory
REPO_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BUILD=build

scm_ver()
{
  ## from kernel sources

	# Check for git and a git repo.
	if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
	   head=`git rev-parse --verify --short HEAD 2>/dev/null`; then

		# If we are at a tagged commit (like "v2.6.30-rc6"), we ignore
		# it, because this version is defined in the top level Makefile.
		if [ -z "`git describe --exact-match 2>/dev/null`" ]; then

			# If we are past a tagged commit (like
			# "v2.6.30-rc5-302-g72357d5"), we pretty print it.
			if atag="`git describe 2>/dev/null`"; then
        
        #edited by ek5 -> 1.6.6-00001-g0bc4b15% (need plus)
        awk -F- '{printf("%s-%05d-%s", $(NF-2), $(NF-1), $(NF))}' <<< "$atag"

			# If we don't have a tag at all we print -g{commitish}.
			else
				printf '%s%s' -g $head
			fi

    else
      #we do not have Makefiles lol
      printf '%s' "`git describe 2>/dev/null`" 
		fi

		# Check for uncommitted changes
		if git diff-index --name-only HEAD | grep -qv "^debian/"; then
			printf '%s' -dirty
		fi

		# All done with git
		return
	fi
}

PACKAGE_VERSION=$( scm_ver ) 
BOARD_DOWNLOAD_URL="https://udooboard.github.io/udooneo-arduino-libraries"

GREEN="\e[32m"
RED="\e[31m"
BOLD="\e[1m"
RST="\e[0m"

function log() {

  # args: string
  local EXIT 
  local COLOR=${GREEN}${BOLD}  
  local MOD="-e"

  case $1 in
    err) COLOR=${RED}${BOLD}
      shift ;;
    pre) MOD+="n" 
      shift ;;
    fat) COLOR=${RED}${BOLD}
      EXIT=1
      shift ;;
    *) ;;
  esac

  echo $MOD ${COLOR}$@${RST}

  (( $EXIT )) && exit $EXIT

}

# clean build dir
cd "$REPO_DIR"
rm -rf $BUILD
mkdir $BUILD

#change version as we like
sed -e "s/VERSION/$PACKAGE_VERSION/" \
    -e "s|URL|$BOARD_DOWNLOAD_URL|" \
    < library.properties > $BUILD/library.properties

#sync all libraries
git submodule init
git submodule sync
git submodule update

#copy all the examples
mkdir $D $BUILD/examples
find -type d -path '*/examples/*' -exec cp -r $D {} $BUILD/examples \;

#concatenate all the keywords
cat */keywords.txt > $BUILD/keywords.txt

#copy all the sources in the same dir
for i in `find -type f \( -name '*.c' -o -name '*.cpp' \)`
do 
  #add _neo suffix 
  unset NEW OLD
  OLD=`basename $i`
  NEW=`basename ${i%.*}_neo.${i##*.}`
  cp $D "$i" "$BUILD/$NEW"
done

#copy all headers
for i in `find -type f -name '*.h'`
do 

  #add _neo suffix 
  unset NEW OLD
  OLD=`basename $i`
  NEW=`basename ${i%.*}_neo.${i##*.}`
  cp $D "$i" "$BUILD/$NEW"

  #rename header includes inside sources
  find -D stat $BUILD -type f \( -name '*.c' -o -name '*.cpp' -o -name '*.ino' \) \
    -exec sed -i -e "s|$OLD|$NEW|" {} \;

done
