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

set -e

MAJOR=$1
MINOR=$2
PATCH=$3

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
RELEASE_BRANCH="release-${MAJOR}.${MINOR}"

git checkout "${RELEASE_BRANCH}"
git pull --ff-only "${ISTIOIO_GIT_SOURCE}" "${RELEASE_BRANCH}"

echo "Migrating to the new release ${NEW_VERSION}..."

sed -i "s/^full_version: .*$/full_version: \"${NEW_VERSION}\"/" data/args.yml

if [ "${PRIVATE_PATCH}" != 'true' ]; then
    go get istio.io/istio@"${NEW_VERSION}"
    go mod tidy
    make update_ref_docs
fi

if [[ $(git status --porcelain) ]]; then
    git add -A
    git commit -m "prepare for v${VERSION} as istio source is already branched"
    git push origin "${RELEASE_BRANCH}"
fi
