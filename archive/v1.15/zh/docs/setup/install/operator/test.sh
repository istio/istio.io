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

snip_create_istio_operator
_wait_for_deployment istio-operator istio-operator

snip_create_demo_profile
sleep 30s
_wait_for_deployment istio-system istiod

# shellcheck disable=SC2154
_verify_like snip_kubectl_get_svc "$snip_kubectl_get_svc_out"

# shellcheck disable=SC2154
_verify_like snip_kubectl_get_pods "$snip_kubectl_get_pods_out"

snip_update_operator
sleep 30s
_verify_contains snip_kubectl_get_svc "egressgateway"

# @cleanup
istioctl operator remove
snip_cleanup
kubectl delete ns istio-operator --grace-period=0 --force
