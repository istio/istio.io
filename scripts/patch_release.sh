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
PREV_VERSION="${MAJOR}.${MINOR}.$((PATCH-1))"
RELEASE_BRANCH="release-${MAJOR}.${MINOR}"

git checkout "${RELEASE_BRANCH}"
git pull "${ISTIOIO_GIT_SOURCE}" "${RELEASE_BRANCH}"

echo "Migrating to the new release ${NEW_VERSION}..."
go get istio.io/istio@"${NEW_VERSION}"
go mod tidy

sed -i "s/^full_version: .*$/full_version: \"${NEW_VERSION}\"/" data/args.yml

if [ "${SECURITY_PATCH}" != 'true' ]; then
    make update_ref_docs
fi

RELEASE_NOTE_PATH="content/en/news/releases/${MAJOR}.${MINOR}.x/announcing-${NEW_VERSION}"
RELEASE_TYPE="$([[ ${SECURITY_PATCH} != 'true' ]] && echo 'patch' || echo 'security')"
mkdir -p "${RELEASE_NOTE_PATH}"
echo "---
title: Announcing Istio ${NEW_VERSION}
linktitle: ${NEW_VERSION}
subtitle: Patch Release
description: Istio ${NEW_VERSION} ${RELEASE_TYPE} release.
publishdate: $(date +'%Y-%m-%d')
release: ${NEW_VERSION}
aliases:
    - /news/announcing-${NEW_VERSION}
---

This release note describes what's different between Istio ${PREV_VERSION} and Istio ${NEW_VERSION}.
" >> "${RELEASE_NOTE_PATH}/index.md"

git add -A

echo "
[SUCCESS] Almost there! Now complete the release note, then commit and push all the changes.
Release note is located at ${RELEASE_NOTE_PATH}/index.md"
