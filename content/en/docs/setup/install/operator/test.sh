#!/usr/bin/env bash
# shellcheck disable=SC2154

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


# @setup profile=none

set -e
set -u
set -o pipefail

function testOperatorDeployWatchNs(){
    # print out body of the function and execute with flag
    # this is to avoid using the default public registry
    $(type snip_deploy_istio_operator_watch_ns | sed '1,3d;$d') --hub "$HUB"
    _wait_for_deployment istio-operator istio-operator

    # cleanup required for next steps
    istioctl uninstall -y --purge
    kubectl delete ns istio-operator istio-namespace1 istio-namespace2
}

function testOperatorDeployHelm(){
    snip_create_ns_istio_operator
    snip_deploy_istio_operator_helm
    _wait_for_deployment istio-operator istio-operator

    # cleanup required for next steps
    helm uninstall istio-operator -n istio-operator
    kubectl delete ns istio-operator
}

function testOperatorDeploy(){
    $(type snip_deploy_istio_operator | sed '1,3d;$d') --hub "$HUB"
    _wait_for_deployment istio-operator istio-operator
}

function testInstallIstioDemo(){
    snip_install_istio_demo_profile
    sleep 30s
    _wait_for_deployment istio-system istiod
    _verify_like snip_kubectl_get_svc "$snip_kubectl_get_svc_out"
    _verify_like snip_kubectl_get_pods "$snip_kubectl_get_pods_out"
}

function testUpdateProfileDefaultEgress(){
    snip_update_to_default_profile_egress
    sleep 30s
    _verify_contains snip_kubectl_get_svc "egressgateway"
}

testOperatorDeployWatchNs

testOperatorDeployHelm

testOperatorDeploy

testInstallIstioDemo

snip_update_to_default_profile

testUpdateProfileDefaultEgress

_verify_like snip_verify_operator_cr "$snip_verify_operator_cr_out"

# @cleanup
snip_cleanup

# Everything should be removed once cleanup completes. Use a small
# timeout for comparing cluster snapshots before/after the test.
export VERIFY_TIMEOUT=20
