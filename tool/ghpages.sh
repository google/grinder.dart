#!/bin/bash

set -o errexit -o nounset

rev=$(git rev-parse --short HEAD)

cd doc/api

git init
git config user.name "Devon Carew"
git config user.email "devoncarew@google.com"

git remote add upstream "https://$GH_TOKEN@github.com/google/grinder.dart.git"
git fetch upstream
git reset upstream/gh-pages

touch .

git add -A .
git commit -m "rebuild pages at ${rev}"
git push -q upstream HEAD:gh-pages
