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

PREV=1.6

git checkout "release-${PREV}"
sed -i "
    s/^archive: false$/archive: true/;
    s/^archive_date: .*$/archive_date: $(date +'%Y-%m-%d')/;
    s/^archive_search_refinement: .*$/archive_search_refinement: \"V${PREV}\"/
" data/args.yml

sed -i "s/^disableAliases = true$/disableAliases = false/" config.toml
make archive-version

git add data/args.yml config.toml
git commit -m "archive the release version ${PREV}"
