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
# @order 7

export NAMESPACE=tutorial

snip_testing_individual_microservices_1

snip_chaos_testing_1

_verify_like snip_chaos_testing_2 "$snip_chaos_testing_2_out"

snip_chaos_testing_3

_verify_like snip_chaos_testing_4 "$snip_chaos_testing_4_out"

# @cleanup
set +e # ignore cleanup errors
