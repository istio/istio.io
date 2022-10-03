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
#          docs/examples/microservices-istio/package-service/index.md
####################################################################################################

snip__1() {
curl -s https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/src/ratings/Dockerfile -o Dockerfile
}

snip__2() {
cat Dockerfile
}

snip__3() {
export USER=user
}

snip__4() {
docker build -t $USER/ratings .
}

! read -r -d '' snip__4_out <<\ENDSNIP
...
Step 9/9 : CMD node /opt/microservices/ratings.js 9080
---> Using cache
---> 77c6a304476c
Successfully built 77c6a304476c
Successfully tagged user/ratings:latest
ENDSNIP

snip__5() {
docker run --name my-ratings  --rm -d -p 9081:9080 $USER/ratings
}

snip__6() {
curl -s localhost:9081/ratings/7
}

! read -r -d '' snip__6_out <<\ENDSNIP
{"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
ENDSNIP

snip__7() {
docker ps
}

! read -r -d '' snip__7_out <<\ENDSNIP
CONTAINER ID        IMAGE            COMMAND                  CREATED             STATUS              PORTS                    NAMES
47e8c1fe6eca        user/ratings     "docker-entrypoint.s…"   2 minutes ago       Up 2 minutes        0.0.0.0:9081->9080/tcp   elated_stonebraker
...
ENDSNIP

snip__8() {
docker stop my-ratings
}
