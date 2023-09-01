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

source "content/en/boilerplates/snips/args.sh"

fullVersion="${bpsnip_args_istio_full_version}"
fullVersionRevision="${fullVersion//./-}"
previousVersion="${bpsnip_args_istio_previous_version}.0"
previousVersionMinorUpgrade="${previousVersion%.0}.1"

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
    # downloadIstio takes a TARGET_OS env var, but it's exepected to be Linux or Darwin.
    # Uppercase the first letter of the TARGET_OS used within the pipeline, which is linux or darwin
    curl -L https://istio.io/downloadIstio | TARGET_OS=${TARGET_OS^} ISTIO_VERSION="$version" sh -
}

function operatorInit(){
    version="$1"
    istioDownload "$version"
    istio-"$version"/bin/istioctl operator init
    rm -rf "istio-$version"
}

function testInplaceUpgrade(){
    operatorInit "$previousVersion"
    operatorInit "$previousVersionMinorUpgrade"
    snip_inplace_upgrade_get_pods_istio_operator
    snip_inplace_upgrade_get_pods_istio_system
}

function testCanaryUpgrade(){
    # downloadIstio takes a TARGET_OS env var, but it's exepected to be Linux or Darwin.
    # Uppercase the first letter of the TARGET_OS used within the pipeline, which is linux or darwin
    TARGET_OS=${TARGET_OS^} snip_download_istio_previous_version
    snip_deploy_operator_previous_version
    snip_install_istio_previous_version
    _verify_like snip_verify_operator_cr "$snip_verify_operator_cr_out"
    rm -rf "istio-$previousVersion"

    istioctl operator init --revision "$fullVersionRevision"
}

function testTwoControlPlanes(){
    echo "$snip_cat_operator_yaml_out" > example-istiocontrolplane-previous-version.yaml
    _verify_like snip_cat_operator_yaml "$snip_cat_operator_yaml_out"
    kubectl apply -f example-istiocontrolplane-previous-version.yaml
    rm -f example-istiocontrolplane-previous-version.yaml

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

snip_cleanup

testCanaryUpgrade

# @cleanup
snip_delete_example_istiocontrolplane
snip_cleanup
