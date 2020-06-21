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

# NOTE: this would only work for v1.6+

[[ $1 =~ ^redo-archive-([0-9]\.[0-9]+)\.0$ ]]

VERSION="${BASH_REMATCH[1]}"
if [ "${VERSION}" == '' ]; then
    echo "Target format error: should be 'redo-archive-x.x.0', got '$1'"
    exit 1
fi

set -e

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
ARCHIVE_BRANCH="release-${VERSION}"

git checkout "${ARCHIVE_BRANCH}"
git pull "${ISTIOIO_GIT_SOURCE}" "${ARCHIVE_BRANCH}"

echo "Making an archive for ${ARCHIVE_BRANCH}..."
make archive-version

git checkout "${CURRENT_BRANCH}"
mv "archived_version/v${VERSION}" "archive/v${VERSION}"

if [[ $(git status --porcelain) ]]; then
    git add "archive/v${VERSION}"
    git commit -m "build an archive of v${VERSION} in ${CURRENT_BRANCH}"
    git push origin "${CURRENT_BRANCH}"
fi
