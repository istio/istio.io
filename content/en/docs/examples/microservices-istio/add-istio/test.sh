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
# @order 9

export NAMESPACE=tutorial
export KUBECONFIG=$PWD/tutorial-user-config.yaml

snip__1

_verify_same snip__2 "$snip__2_out"

for services in "details-v1" "productpage-v1" "ratings-v1" "reviews-v2"; do
    _wait_for_deployment $NAMESPACE "$services"
done

snip__3

# @cleanup
set +e # ignore cleanup errors
