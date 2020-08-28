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

BOILERPLATE_DIR="content/en/boilerplates"

if [ ! -d "$BOILERPLATE_DIR/snips" ]; then
  echo "boilerplate snippets directory does not exist. creating one..."
  mkdir -p content/en/boilerplates/snips
fi

for f in "$BOILERPLATE_DIR"/*.md; do
  bp_file=$(echo "$f" | awk -F'/' '{ print $NF }' | cut -f1 -d'.')
  bp_func_name=$(echo "$bp_file" | tr '-' '_')
  python3 scripts/snip.py "$f" \
      -d content/en/boilerplates/snips \
      -p "bpsnip_$bp_func_name" \
      -f "$bp_file.sh" \
      -b "$BOILERPLATE_DIR/snips"
done

find content/en/docs -name '*.md' -exec grep --quiet '^test: yes$' {} \; -exec python3 scripts/snip.py -b "$BOILERPLATE_DIR/snips" {} \;
