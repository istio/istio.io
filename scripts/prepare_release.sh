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

[[ $1 =~ ^prepare-([0-9]\.[0-9]+)\.0$ ]] ||
    { echo "Target format error: should be 'prepare-x.x.0', got '$1'"; exit 1; }

VERSION="${BASH_REMATCH[1]}"

git checkout "${MASTER}"
git pull --ff-only "${ISTIOIO_GIT_SOURCE}" "${MASTER}"

sed -i "s/^source_branch_name: .*$/source_branch_name: release-${VERSION}/" data/args.yml
sed -i "s/^export SOURCE_BRANCH_NAME ?=.*$/export SOURCE_BRANCH_NAME ?= release-${VERSION}/" Makefile.core.mk

echo "Running make update_all..."
make update_all

echo "Running make gen..."
make gen

if [[ $(git status --porcelain) ]]; then
    git add -A
    git commit -m "prepare for v${VERSION} as istio source is already branched"
    git push origin "${MASTER}"
fi
