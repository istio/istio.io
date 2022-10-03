#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2034,SC2153,SC2155,SC2164

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

set -e
set -u
set -o pipefail

# @setup profile=none
# @child microservice-example
# @order 4

snip__1

snip__2

npm start 9080 > /dev/null 2>&1 &

_verify_same snip__4  "$snip__4_out"

_verify_same snip__5  "$snip__5_out"

_verify_same snip__6  "$snip__6_out"

# @cleanup
set +e # ignore cleanup errors

pgrep node | awk \{'print $1'\} | xargs kill -9


