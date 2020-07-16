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

owners_listing() {
    echo "<!-- WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. UPDATE THE OWNER ATTRIBUTE IN THE DOCUMENT FILES, INSTEAD -->"
    echo "# Istio.io Document Owners"
    echo ""
    echo "There are $(find docs -name '*.md' -exec grep -q '^owner: istio/wg-' {} \; -print | wc -l) owned istio.io docs."
    echo ""
    echo "## istio/wg-docs-maintainers: \
        $(find docs -name '*.md' -exec grep -q '^owner: istio/wg-docs-maintainers' {} \; -print | wc -l) docs"
    echo ""
    find docs -name '*.md' -exec grep -q '^owner: istio/wg-docs-maintainers' {} \; -print | sort

    echo ""
    echo "## istio/wg-environments-maintainers: \
        $(find docs -name '*.md' -exec grep -q '^owner: istio/wg-environments-maintainers' {} \; -print | wc -l) docs"
    echo ""
    find docs -name '*.md' -exec grep -q '^owner: istio/wg-environments-maintainers' {} \; -print | sort

    echo ""
    echo "## istio/wg-networking-maintainers: \
        $(find docs -name '*.md' -exec grep -q '^owner: istio/wg-networking-maintainers' {} \; -print | wc -l) docs"
    echo ""
    find docs -name '*.md' -exec grep -q '^owner: istio/wg-networking-maintainers' {} \; -print | sort

    echo ""
    echo "## istio/wg-policies-and-telemetry-maintainers: \
        $(find docs -name '*.md' -exec grep -q '^owner: istio/wg-policies-and-telemetry-maintainers' {} \; -print | wc -l) docs"
    echo ""
    find docs -name '*.md' -exec grep -q '^owner: istio/wg-policies-and-telemetry-maintainers' {} \; -print | sort

    echo ""
    echo "## istio/wg-security-maintainers: \
        $(find docs -name '*.md' -exec grep -q '^owner: istio/wg-security-maintainers' {} \; -print | wc -l) docs"
    echo ""
    find docs -name '*.md' -exec grep -q '^owner: istio/wg-security-maintainers' {} \; -print | sort

    echo ""
    echo "## istio/wg-user-experience-maintainers: \
        $(find docs -name '*.md' -exec grep -q '^owner: istio/wg-user-experience-maintainers' {} \; -print | wc -l) docs"
    echo ""
    find docs -name '*.md' -exec grep -q '^owner: istio/wg-user-experience-maintainers' {} \; -print | sort
}

pushd content/en

owners_listing > ../../DOC_OWNERS.md

sed -i '' -e 's|^docs/\(.*\)/index.md|- [docs/\1/index.md](https://preliminary.istio.io/latest/docs/\1)|' ../../DOC_OWNERS.md

popd
