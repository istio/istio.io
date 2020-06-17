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

MAJOR=$1
MINOR=$2
PATCH=$3

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
PREV_VERSION="${MAJOR}.${MINOR}.$((PATCH-1))"

git checkout "release-${MAJOR}.${MINOR}"
go get istio.io/istio@${NEW_VERSION}
go mod tidy

sed -i "s/^full_version: .*$/full_version: \"${NEW_VERSION}.0\"/" data/args.yml

RELEASE_NOTE_PATH="content/en/news/releases/${MAJOR}.${MINOR}.x/announcing-${NEW_VERSION}/index.md"
echo "---
title: Announcing Istio ${NEW_VERSION}
linktitle: ${NEW_VERSION}
subtitle: Patch Release
description: Istio ${NEW_VERSION} release.
publishdate: $(date +'%Y-%m-%d')
release: ${NEW_VERSION}
aliases:
    - /news/announcing-${NEW_VERSION}
test: n/a
---

This release note describes what's different between Istio ${NEW_VERSION} and Istio ${PREV_VERSION}.
" >> ${RELEASE_NOTE_PATH}

make update_ref_docs
git add -A

echo "Almost there. Now complete the release note and push all the changes."
echo "Release note is located at ${RELEASE_NOTE_PATH}"
