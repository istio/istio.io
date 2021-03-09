#!/usr/bin/env bash
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

set -e
set -u

set -o pipefail

# @setup profile=none

snip_create_istio_system_namespace
snip_install_base

snip_install_discovery
_wait_for_deployment istio-system istiod

snip_install_ingressgateway
_wait_for_deployment istio-system istio-ingressgateway

snip_install_egressgateway
_wait_for_deployment istio-system istio-egressgateway

# shellcheck disable=SC2154
_verify_like snip_helm_ls "$snip_helm_ls_out"

# @cleanup
snip_delete_crds
helm delete -n istio-system istio-egressgateway
helm delete -n istio-system istio-ingressgateway
helm delete -n istio-system istiod
helm delete -n istio-system istio-base
kubectl delete ns istio-system