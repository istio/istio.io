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

### Parse the release version input ###
[[ $1 =~ ^release-([0-9])\.([0-9]+)\.([0-9]+)$ ]]

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

if [ "${MAJOR}" == '' ]; then
    echo "Release format error: should be 'release-x.x.x', got '$1'"
    exit 1
fi

set -e
echo "Creating a version for ${MAJOR}.${MINOR}.${PATCH}..."

# patch release
if [ "${PATCH}" != '0' ]; then
    scripts/patch_release.sh "${MAJOR}" "${MINOR}" "${PATCH}"
    exit 0
fi

# major/minor release
CURR_MINOR="${MAJOR}.${MINOR}"     # current version
PREV_MINOR="${MAJOR}.$((MINOR-1))" # previous version
NEXT_MINOR="${MAJOR}.$((MINOR+1))" # next version

# for a major release x.0, find the latest minor release
if [ "${MINOR}" == '0' ]; then
    LAST_MINOR_OF_PREV_MAJOR=$(
        git branch -a |
        grep "release-$((MAJOR-1))." |
        sed -r "s/^.*release-$((MAJOR-1))\.([0-9]+)$/\1/" |
        sort -n |
        tail -1
    )
    PREV_MINOR="$((MAJOR-1)).${LAST_MINOR_OF_PREV_MAJOR}"
fi

echo "Previous minor release: ${PREV_MINOR}"
echo "Upcoming minor release: ${NEXT_MINOR}"

### Archive the old release branch ###
echo -e "\nStep 1: archive the old release branch"
git checkout "release-${PREV_MINOR}"
sed -i "
    s/^archive: false$/archive: true/;
    s/^archive_date: .*$/archive_date: $(date +'%Y-%m-%d')/;
    s/^archive_search_refinement: .*$/archive_search_refinement: \"V${PREV_MINOR}\"/
" data/args.yml

sed -i "s/^disableAliases = true$/disableAliases = false/" config.toml

CREDENTIAL_HELPER=$(git config --get credential.helper)
git config credential.helper cache

git add -u
git commit -m "mark v${PREV_MINOR} as archived"
git push origin "release-${PREV_MINOR}"

# complete the archive process in master
MASTER="master"
git checkout ${MASTER}
scripts/redo_archive.sh "redo-archive-${PREV_MINOR}"

sed -i "
    s/^preliminary: .*$/preliminary: \"${NEXT_MINOR}\"/;
    s/^main: .*$/main: \"${CURR_MINOR}\"/
" data/versions.yml

sed -i "0,/<li>/s//\<li>\n\
            <a href=\/v${PREV_MINOR}>v${PREV_MINOR}<\/a>\n\
        <\/li>\n\
        <li>/" archive/archive/index.html

git add -u
git commit -m "update data/versions.yml and archive index page"
git push origin ${MASTER}

### Create a branch for the new release ###
echo -e "\nStep 2: create a new branch for release-${CURR_MINOR}"
git checkout -b "release-${CURR_MINOR}"
sed -i "
    s/^preliminary: true$/preliminary: false/;
    s/^doc_branch_name: .*$/doc_branch_name: release-${CURR_MINOR}/;
    s/^source_branch_name: .*$/source_branch_name: release-${CURR_MINOR}/
" data/args.yml

echo "Running make update_all..."
sed -i "s/^SOURCE_BRANCH_NAME ?=.*$/SOURCE_BRANCH_NAME ?= release-${CURR_MINOR}/" Makefile.core.mk
make update_all

echo "Running make update-common..."
sed -i "s/^UPDATE_BRANCH ?=.*$/UPDATE_BRANCH ?= release-${CURR_MINOR}/" common/Makefile.common.mk
make update-common

git add -A
git commit -m "create a new release branch for v${CURR_MINOR}"
git push origin "release-${CURR_MINOR}"

### Advance master to the next release ###
echo -e "\nStep 3: advance master to release-${NEXT_MINOR}..."
git checkout ${MASTER}
sed -i "
    s/^version: .*$/version: \"${NEXT_MINOR}\"/;
    s/^full_version: .*$/full_version: \"${NEXT_MINOR}.0\"/;
    s/^previous_version: .*$/previous_version: \"${CURR_MINOR}\"/
" data/args.yml
make update_all

git add -A
git commit -m "advance master to release-${NEXT_MINOR}"
git push origin ${MASTER}

git config credential.helper "${CREDENTIAL_HELPER}"
