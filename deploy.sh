#!/bin/bash
set -e # exit with nonzero exit code if anything fails
TAG=`git describe --tags`
GH_REPO=`basename ${GH_REL%%.git}`

# Compile 
./build.sh

# go to the out directory and create a *new* Git repo
cd build 
git init

# inside this git repo we'll pretend to be a new user
git config user.name "Travis CI"
git config user.email "social@udoo.org"

# The first and only commit to this new Git repo contains all the
# files present with the commit message "Deploy to GitHub Pages".
git add .
git commit -m "Deploy to Arduino branch"

# Force push from the current repo's master branch to the remote
# repo's gh-pages branch. (All previous history on the gh-pages branch
# will be lost, since we are overwriting it.) We redirect any output to
# /dev/null to hide any sensitive credential data that might otherwise be exposed.
git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:arduino > /dev/null 2>&1

cd ..


#cloning release repo
git clone "https://${GH_REL}" 
cd ${GH_REPO}

#get the tags
git fetch --tags

if
  # check if is a semver compliant tag 
  ! [[ $( sed -ne '/^[0-9]*\.[0-9]*\.[0-9]*$/p' <<< $TAG ) ]]
then
  echo "Not a release tag, not deploying to arduino repo"

elif 
  # check if actual version is present
  git tag | egrep -q "^${TAG}$"
then 
  echo "Already pushed this revision! Exit ;)"

else

  echo "Copying new revision..."
  rm -rf *
  cp -r ../build/* .

  echo "Adding..."
  git add .
  git commit -m "Deploy to Arduino branch"
  git tag -a $TAG -m "Releasing $TAG" 

  echo "Pushing..."
  git push --tags -fq "https://${GH_TOKEN}@${GH_REL}" master > /dev/null 2>&1

fi

#DOWNLOAD_URL="https://udooboard.github.io/udooneo-arduino-libraries"
#./publish.sh origin/arduino "$DOWNLOAD_URL" deploy
#
#cd deploy
#git init
#
## inside this git repo we'll pretend to be a new user
#git config user.name "Travis CI"
#git config user.email "social@udoo.org"
#
## The first and only commit to this new Git repo contains all the
## files present with the commit message "Deploy to GitHub Pages".
#git add .
#git commit -m "Deploy to GitHub Pages"
#
## Force push from the current repo's master branch to the remote
## repo's gh-pages branch. (All previous history on the gh-pages branch
## will be lost, since we are overwriting it.) We redirect any output to
## /dev/null to hide any sensitive credential data that might otherwise be exposed.
#git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:gh-pages > /dev/null 2>&1
