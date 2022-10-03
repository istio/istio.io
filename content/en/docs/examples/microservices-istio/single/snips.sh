#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

# Copyright Istio Authors. All Rights Reserved.
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

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          docs/examples/microservices-istio/single/index.md
####################################################################################################

snip__1() {
mkdir ratings
cd ratings
curl -s https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/src/ratings/ratings.js -o ratings.js
curl -s https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/src/ratings/package.json -o package.json
}

snip__2() {
npm install
}

! read -r -d '' snip__2_out <<\ENDSNIP
npm notice created a lockfile as package-lock.json. You should commit this file.
npm WARN ratings No description
npm WARN ratings No repository field.
npm WARN ratings No license field.

added 24 packages in 2.094s
ENDSNIP

snip__3() {
npm start 9080
}

! read -r -d '' snip__3_out <<\ENDSNIP
> @ start /tmp/ratings
> node ratings.js "9080"
Server listening on: http://0.0.0.0:9080
ENDSNIP

snip__4() {
curl -s localhost:9080/ratings/7
}

! read -r -d '' snip__4_out <<\ENDSNIP
{"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
ENDSNIP

snip__5() {
curl -s -X POST localhost:9080/ratings/7 -d '{"Reviewer1":1,"Reviewer2":1}'
}

! read -r -d '' snip__5_out <<\ENDSNIP
{"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
ENDSNIP

snip__6() {
curl -s localhost:9080/ratings/7
}

! read -r -d '' snip__6_out <<\ENDSNIP
{"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
ENDSNIP
