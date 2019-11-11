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

# This script copies test snippets from documentation tests in the istio/istio repo.
# These snippets are put into the examples directory and referenced from markdown files
# throughout the site.

if [[ "$1" != "" ]]; then
  SOURCE_BRANCH_NAME="$1"
else
  SOURCE_BRANCH_NAME="master"
fi

# TODO: for the 1.4 timeframe, we need to grab the bits from master
SOURCE_BRANCH_NAME=master

SNIPPET_REPO=https://github.com/istio/istio

rm -fr examples/*.snippets.txt

echo Cloning "${SNIPPET_REPO}@${SOURCE_BRANCH_NAME}"

WORK_DIR="$(mktemp -d)"
mkdir -p "${WORK_DIR}"
git clone -q -b """${SOURCE_BRANCH_NAME}""" "${SNIPPET_REPO}" "${WORK_DIR}"
COMMITS=$(git --git-dir="${WORK_DIR}/.git" log --oneline --no-abbrev-commit | cut -d " " -f 1)
rm -fr "${WORK_DIR}"

echo "Querying for snippets"

# iterate through all the commits for the repo until we find one that has the needed artifacts
# in gcs
for COMMIT in $COMMITS; do
    if gsutil -m cp "gs://istio-snippets/${COMMIT}/*.txt" examples; then
        echo "Example snippets updated"
        exit 0
    fi
done

echo "Unable to download example snippets"
exit 1
