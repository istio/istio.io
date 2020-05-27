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

echo "Istio Documents Summary: \
   $(find content/en/docs -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print | wc -l) (tested) \
   $(find content/en/docs -name '*.md' -exec grep --quiet '^test: no$' {} \; -print | wc -l) (untested) \
   $(find content/en/docs -name '*.md' -exec grep --quiet '^test: n/a$' {} \; -print | wc -l) (n/a) \
   $(find content/en/docs -name '*.md' -print | wc -l) (total)"

echo ""
echo "Tasks Docs"
echo "=========="

echo "Summary: \
   $(find content/en/docs/tasks -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print | wc -l) (tested) \
   $(find content/en/docs/tasks -name '*.md' -exec grep --quiet '^test: no$' {} \; -print | wc -l) (untested) \
   $(find content/en/docs/tasks -name '*.md' -exec grep --quiet '^test: n/a$' {} \; -print | wc -l) (n/a)"

echo ""
echo "Untested:"
find content/en/docs/tasks -name '*.md' -exec grep --quiet '^test: no$' {} \; -print

echo ""
echo "Examples Docs"
echo "============="

echo "Summary: \
   $(find content/en/docs/examples -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print | wc -l) (tested) \
   $(find content/en/docs/examples -name '*.md' -exec grep --quiet '^test: no$' {} \; -print | wc -l) (untested) \
   $(find content/en/docs/examples -name '*.md' -exec grep --quiet '^test: n/a$' {} \; -print | wc -l) (n/a)"

echo ""
echo "Untested:"
find content/en/docs/examples -name '*.md' -exec grep --quiet '^test: no$' {} \; -print

echo ""
echo "Setup Docs"
echo "=========="

echo "Summary: \
   $(find content/en/docs/setup -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print | wc -l) (tested) \
   $(find content/en/docs/setup -name '*.md' -exec grep --quiet '^test: no$' {} \; -print | wc -l) (untested) \
   $(find content/en/docs/setup -name '*.md' -exec grep --quiet '^test: n/a$' {} \; -print | wc -l) (n/a)"

echo ""
echo "Untested:"
find content/en/docs/setup -name '*.md' -exec grep --quiet '^test: no$' {} \; -print

echo ""
echo "Operations Docs"
echo "==============="

echo "Summary: \
   $(find content/en/docs/ops -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print | wc -l) (tested) \
   $(find content/en/docs/ops -name '*.md' -exec grep --quiet '^test: no$' {} \; -print | wc -l) (untested) \
   $(find content/en/docs/ops -name '*.md' -exec grep --quiet '^test: n/a$' {} \; -print | wc -l) (n/a)"

echo ""
echo "Untested:"
find content/en/docs/ops -name '*.md' -exec grep --quiet '^test: no$' {} \; -print
