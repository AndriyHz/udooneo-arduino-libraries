#!/bin/bash
# 
# publish.sh
# Publish Arduino zip library to GH Pages
#
# Copyright (C) 2016 Aidilab Srl
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


# set variables
BRANCH="${1:-master}"
URL="$2"
[ -z $1 ] && exit 99

PKG_VER=`git describe --tags`
PKG_ORIG=`basename $(git remote show -n origin | grep Fetch | cut -d: -f2-)`
PKG_OUTPUT="$PKG_ORIG-$PKG_VER.zip"
LATEST="$URL/$PKG_OUTPUT"

# create lib archive
git archive --format zip -o "$PKG_OUTPUT" "$BRANCH"

# create redirect
cat << LOL > index.html
<html>
<head>
<meta http-equiv="Refresh" content="0; url="$LATEST" />
</head>
<body>
</body>
</html>
LOL

