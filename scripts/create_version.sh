#!/bin/bash

# Copyright Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[[ $1 =~ ^release-([0-9])\.([0-9]+)\.([0-9]+)$ ]]

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

if [ "${MAJOR}" == '' ]; then
    echo "Release format error: should be 'release-x.x.x', got '$1'"
    exit 1
else
    echo "Creating a version for ${MAJOR}.${MINOR}.${PATCH}..."
fi

set -e

# TODO: patch release?
if [ "${PATCH}" != '0' ]; then
    exit 1
fi

CURR="${MAJOR}.${MINOR}"     # current version
PREV="${MAJOR}.$((MINOR-1))" # previous version
NEXT="${MAJOR}.$((MINOR+1))" # next version

if [ "${MINOR}" == '0' ]; then
    PREV_MINOR=$(
        git branch -a |
        grep "release-$((MAJOR-1))." |
        sed -r "s/^.*release-$((MAJOR-1))\.([0-9]+)$/\1/" |
        sort -n |
        tail -1
    )
    PREV="$((MAJOR-1)).${PREV_MINOR}"
fi

echo "Previous version: ${PREV}"
echo "Upcoming version: ${NEXT}"

git checkout "release-${PREV}"
sed -i "
    s/^archive: false$/archive: true/;
    s/^archive_date: .*$/archive_date: $(date +'%Y-%m-%d')/;
    s/^archive_search_refinement: .*$/archive_search_refinement: \"V${PREV}\"/
" data/args.yml

sed -i "s/^disableAliases = true$/disableAliases = false/" config.toml
make archive-version

git add data/args.yml config.toml
git commit -m "archive the release version ${PREV}"

ORIGIN="https://github.com/istio/istio.io"
git push "${ORIGIN}"

git checkout master
sed -i "
    s/^preliminary: .*$/preliminary: \"${NEXT}\"/;
    s/^main: .*$/main: \"${CURR}\"/
" data/versions.yml

mv "archived_version/v${PREV}" "archive/v${PREV}"
sed -i "0,/<li>/s//\<li>\n\
            <a href=\/v${PREV}>v${PREV}<\/a>\n\
        <\/li>\n\
        <li>/" archive/archive/index.html

git add data/versions.yml archive
git commit -m "build an archive in the master branch"
git push

git checkout -b "release-${CURR}"
sed -i "
    s/^preliminary: true$/preliminary: false/;
    s/^doc_branch_name: .*$/doc_branch_name: release-${CURR}/;
    s/^source_branch_name: .*$/source_branch_name: release-${CURR}/
" data/args.yml

sed -i "s/^SOURCE_BRANCH_NAME ?=.*$/SOURCE_BRANCH_NAME ?= release-${CURR}/" Makefile.core.mk
make update_all

sed -i "s/^UPDATE_BRANCH ?=.*$/UPDATE_BRANCH ?= release-${CURR}/" common/Makefile.common.mk
make update-common

git add *
git commit -m "create a new release branch for v${CURR}"
git push

git checkout master
sed -i "
    s/^version: .*$/version: \"${NEXT}\"/;
    s/^full_version: .*$/full_version: \"${NEXT}.0\"/;
    s/^previous_version: .*$/previous_version: \"${CURR}\"/
" data/args.yml
make update_all

git add *
git commit -m "advance master to the next release v${NEXT}"
git push
