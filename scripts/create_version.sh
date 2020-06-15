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
    s/^archive: false/archive: true/;
    s/^archive_date: .*$/archive_date: $(date +'%Y-%m-%d')/;
    s/^archive_search_refinement: .*$/archive_search_refinement: \"V${PREV}\"/
" data/args.yml

sed -i "s/^disableAliases = true$/disableAliases = false/" config.toml
make archive-version

git add data/args.yml config.toml
git commit -m "archive the release version ${PREV}"
git push

# git checkout master

