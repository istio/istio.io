#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

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

source "tests/util/gateway-api.sh"

_set_kube_vars # helper function to initialize KUBECONFIG_FILES and KUBE_CONTEXTS
export CTX_EXTERNAL_CLUSTER="${KUBE_CONTEXTS[0]}"
export CTX_REMOTE_CLUSTER="${KUBE_CONTEXTS[2]}"
export REMOTE_CLUSTER_NAME="${CTX_REMOTE_CLUSTER}"

install_gateway_api_crds "${CTX_REMOTE_CLUSTER}"

# @setup multicluster
source "content/en/docs/setup/install/external-controlplane/test.sh"

# @cleanup
_set_kube_vars # helper function to initialize KUBECONFIG_FILES and KUBE_CONTEXTS
export CTX_EXTERNAL_CLUSTER="${KUBE_CONTEXTS[0]}"
export CTX_REMOTE_CLUSTER="${KUBE_CONTEXTS[2]}"
export CTX_SECOND_CLUSTER="${KUBE_CONTEXTS[1]}"

snip_cleanup_1
snip_cleanup_2
snip_cleanup_3

remove_gateway_api_crds "${CTX_REMOTE_CLUSTER}"
