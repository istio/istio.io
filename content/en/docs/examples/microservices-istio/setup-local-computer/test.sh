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

set -e
set -u
set -o pipefail

# @setup profile=none
# @child microservice-example
# @order 3

export KUBECONFIG=$PWD/tutorial-user-config.yaml

_verify_same snip__2 "$snip__2_out"

snip__3

# @cleanup
set +e # ignore cleanup errors



