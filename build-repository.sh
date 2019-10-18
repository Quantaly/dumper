#!/bin/bash

cd /tmp

if [ ! -e $1 ]
then
    mkdir -p $1
    git clone --bare $2 $1/bare
    git clone $1/bare $1/master
    git clone $1/bare $1/gh-pages -b gh-pages

    if [ ! $? -eq 0 ]
    then
        git clone $1/bare $1/gh-pages
        bash -c "cd $1/gh-pages && git checkout -b gh-pages"
    fi
else
    bash -c "cd $1/bare && git fetch"
    bash -c "cd $1/master && git pull"
    bash -c "cd $1/gh-pages && git pull"
fi

cd $1/gh-pages
git rm -rf .
git clean -fxd

cd ../master
pub get
webdev build
mv build/** ../gh-pages

cd ../gh-pages
git add .
git commit -m "Dump"
git push

cd ../bare
git push