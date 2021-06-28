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

docs="content/en/docs"

red="tput setaf 1"
green="tput setaf 2"
reset="tput sgr0"

echo "Istio Documents Summary: \
   $(find "${docs}" -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print | wc -l) (tested) \
   $(find "${docs}" -name '*.md' -exec grep --quiet '^test: no$' {} \; -print | wc -l) (untested) \
   $(find "${docs}" -name '*.md' -exec grep --quiet '^test: n/a$' {} \; -print | wc -l) (n/a) \
   $(find "${docs}" -name '*.md' -exec grep --quiet '^test: table-of-contents$' {} \; -print | wc -l) (table-of-contents) \
   $(find "${docs}" -name '*.md' -print | wc -l) (total)"

echo ""
echo "Tasks Docs"
echo "=========="

echo "Summary: \
   $(find "${docs}/tasks" -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print | wc -l) (tested) \
   $(find "${docs}/tasks" -name '*.md' -exec grep --quiet '^test: no$' {} \; -print | wc -l) (untested) \
   $(find "${docs}/tasks" -name '*.md' -exec grep --quiet '^test: table-of-contents$' {} \; -print | wc -l) (table-of-contents) \
   $(find "${docs}/tasks" -name '*.md' -exec grep --quiet '^test: n/a$' {} \; -print | wc -l) (n/a)"

echo ""
echo "Tested:"
${green}
find "${docs}/tasks" -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print
${reset}
echo "Untested:"
${red}
find "${docs}/tasks" -name '*.md' -exec grep --quiet '^test: no$' {} \; -print
${reset}

echo ""
echo "Examples Docs"
echo "============="

echo "Summary: \
   $(find "${docs}/examples" -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print | wc -l) (tested) \
   $(find "${docs}/examples" -name '*.md' -exec grep --quiet '^test: no$' {} \; -print | wc -l) (untested) \
   $(find "${docs}/examples" -name '*.md' -exec grep --quiet '^test: table-of-contents$' {} \; -print | wc -l) (table-of-contents) \
   $(find "${docs}/examples" -name '*.md' -exec grep --quiet '^test: n/a$' {} \; -print | wc -l) (n/a)"

echo ""
echo "Tested:"
${green}
find "${docs}/examples" -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print
${reset}
echo "Untested:"
${red}
find "${docs}/examples" -name '*.md' -exec grep --quiet '^test: no$' {} \; -print
${reset}

echo ""
echo "Setup Docs"
echo "=========="

echo "Summary: \
   $(find "${docs}/setup" -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print | wc -l) (tested) \
   $(find "${docs}/setup" -name '*.md' -exec grep --quiet '^test: no$' {} \; -print | wc -l) (untested) \
   $(find "${docs}/setup" -name '*.md' -exec grep --quiet '^test: table-of-contents$' {} \; -print | wc -l) (table-of-contents) \
   $(find "${docs}/setup" -name '*.md' -exec grep --quiet '^test: n/a$' {} \; -print | wc -l) (n/a)"

echo ""
echo "Tested:"
${green}
find "${docs}/setup" -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print
${reset}
echo "Untested:"
${red}
find "${docs}/setup" -name '*.md' -exec grep --quiet '^test: no$' {} \; -print
${reset}

echo ""
echo "Operations Docs"
echo "==============="

echo "Summary: \
   $(find "${docs}/ops" -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print | wc -l) (tested) \
   $(find "${docs}/ops" -name '*.md' -exec grep --quiet '^test: no$' {} \; -print | wc -l) (untested) \
   $(find "${docs}/ops" -name '*.md' -exec grep --quiet '^test: table-of-contents$' {} \; -print | wc -l) (table-of-contents) \
   $(find "${docs}/ops" -name '*.md' -exec grep --quiet '^test: n/a$' {} \; -print | wc -l) (n/a)"

echo ""
echo "Tested:"
${green}
find "${docs}/ops" -name '*.md' -exec grep --quiet '^test: yes$' {} \; -print
${reset}
echo "Untested:"
${red}
find "${docs}/ops" -name '*.md' -exec grep --quiet '^test: no$' {} \; -print
${reset}
