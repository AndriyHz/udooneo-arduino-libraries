#!/bin/bash

set -e # exit with nonzero exit code if anything fails

TAG=`git describe --tags`
GH_REPO=`basename ${GH_REL%%.git}`

#compile 
./build.sh

#cloning release repo
git clone "https://${GH_REL}" 
cd ${GH_REPO}

#get the tags
git fetch --tags

echo "Copying new revision..."
rm -rf *
cp -r ../build/* .

echo "Adding..."
git add --all .

#configuring git
git config user.name "Travis CI"
git config user.email "social@udoo.org"

#committing
git commit -m "Deploy to Arduino Release repo"

if
  # check if is a semver compliant tag 
  ! [[ $( sed -ne '/^[0-9]*\.[0-9]*\.[0-9]*$/p' <<< $TAG ) ]]
then
  echo "Not a release tag, not pushing tag to release repo"

elif 
  # check if actual version is present
  git tag | egrep -q "^${TAG}$"
then 
  echo "Already pushed this revision! Exit ;)"
  exit 0

else
  git tag -a $TAG -m "Releasing $TAG" 

fi

echo "Pushing to release repo..."
git push --tags -fq "https://${GH_TOKEN}@${GH_REL}" master > /dev/null 2>&1
