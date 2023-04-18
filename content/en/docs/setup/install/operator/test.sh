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

function testOperatorLogs(){
    command=$(type snip_operator_logs | sed '1,3d;$d')
    # prevent following log stream
    command="${command/"logs -f"/"logs"}"
    echo "$command" | sh -
}

function istioDownload(){
    version="$1"
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION="$version" sh -
}

function operatorInit(){
    version="$1"
    istioDownload "$version"
    istio-"$version"/bin/istioctl operator init
    rm -rf "istio-$version"
}

function testInplaceUpgrade(){
    operatorInit "1.17.0"
    operatorInit "1.17.1"
    snip_inplace_upgrade_get_pods_istio_operator
    snip_inplace_upgrade_get_pods_istio_system
}

function testCanaryUpgrade(){
    istioDownload "1.17.1"
    snip_canary_upgrade_init_1_17_1
    rm -rf "istio-1.17.1"

    istioDownload "1.17.2"
    snip_canary_upgrade_helm_install_1_17_2
    rm -rf "istio-1.17.2"
}

function testTwoControlPlanes(){
    echo "$snip_cat_operator_yaml_out" > example-istiocontrolplane-1-17-1.yaml
    _verify_like snip_cat_operator_yaml "$snip_cat_operator_yaml_out"
    kubectl apply -f example-istiocontrolplane-1-17-1.yaml

    _verify_like snip_get_pods_istio_system "$snip_get_pods_istio_system_out"
    _verify_like snip_get_svc_istio_system "$snip_get_svc_istio_system_out"
}

testOperatorDeployWatchNs

testOperatorDeployHelm

testOperatorDeploy

testInstallIstioDemo

snip_update_to_default_profile

testUpdateProfileDefaultEgress

testOperatorLogs

snip_cleanup

testInplaceUpgrade

snip_update_to_default_profile

_verify_like snip_verify_operator_cr "$snip_verify_operator_cr_out"

testCanaryUpgrade

# @cleanup
snip_delete_example_istiocontrolplane
snip_cleanup
