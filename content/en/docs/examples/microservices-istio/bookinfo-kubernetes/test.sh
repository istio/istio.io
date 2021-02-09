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
# @order 6

export NAMESPACE=tutorial
export KUBECONFIG=$PWD/${NAMESPACE}-user-config.yaml

snip_deploy_the_application_and_a_testing_pod_1

_verify_same snip_deploy_the_application_and_a_testing_pod_2 "$snip_deploy_the_application_and_a_testing_pod_2_out"

for services in "details-v1" "productpage-v1" "ratings-v1" "reviews-v1"; do
    _wait_for_deployment $NAMESPACE "$services"
done

_verify_same snip_deploy_the_application_and_a_testing_pod_4 "$snip_deploy_the_application_and_a_testing_pod_4_out"

for services in "details-v1" "productpage-v1" "ratings-v1" "reviews-v1"; do
    _wait_for_deployment $NAMESPACE "$services"
done

snip_deploy_the_application_and_a_testing_pod_6

_wait_for_deployment $NAMESPACE "sleep"

_verify_same snip_deploy_the_application_and_a_testing_pod_7 "$snip_deploy_the_application_and_a_testing_pod_7_out"

snip_configure_the_kubernetes_ingress_resource_and_access_your_applications_webpage_1

snip_update_your_etchosts_configuration_file_1

snip_update_your_etchosts_configuration_file_2

# @cleanup
set +e # ignore cleanup errors
