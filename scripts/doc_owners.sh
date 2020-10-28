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

WORKGROUPS="istio/wg-docs-maintainers istio/wg-environments-maintainers istio/wg-networking-maintainers istio/wg-policies-and-telemetry-maintainers istio/wg-security-maintainers istio/wg-user-experience-maintainers"

owners_listing() {
    echo "<!-- WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. UPDATE THE OWNER ATTRIBUTE IN THE DOCUMENT FILES, INSTEAD -->"
    echo "# Istio.io Document Owners"
    echo ""
    echo "There are $(find docs -name '*.md' -exec grep -q '^owner: istio/wg-' {} \; -print | wc -l) owned istio.io docs."

    for wg in $WORKGROUPS; do
        echo ""
        list=$(find docs -name '*.md' -exec grep -q "^owner: $wg" {} \; -print | LC_ALL=C sort)
        echo "## $wg: $(wc -l <<<"$list") docs"
        echo ""
        echo "$list"
    done
}

pushd content/en >/dev/null

owners_listing | sed -e 's|^docs/\(.*\)/\(_\?index\).md|- [docs/\1/\2.md](https://preliminary.istio.io/latest/docs/\1)|' >../../DOC_OWNERS.md

popd >/dev/null
