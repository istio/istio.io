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

TMP=$(mktemp -d)
mv ./public/* "${TMP}"
cp -r ./archive/* ./public/
mkdir ./public/latest
cp -r "${TMP}"/* ./public/latest/

#copy top level pages, such as landing page, redirects, headers, robots.txt, etc
find "${TMP}" -maxdepth 1 -type f -exec cp -t ./public/ {} +