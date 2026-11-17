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

# Runs the same test as test.sh, but following the "Gateway API" tabs of the guide
# instead of the "Istio APIs" tabs. Sourcing gateway-api.sh sets GATEWAY_API=true,
# which common.sh uses to select the Gateway API snips.
#
# The CRDs are installed by the documented snip (snip_install_crds), not here, so that
# the guide's own command is what gets exercised. The guide only needs Gateway and
# TLSRoute, both of which are in the standard channel, so this removes the standard
# channel rather than the experimental one that remove_gateway_api_crds deletes.
source "tests/util/gateway-api.sh"
source "content/en/docs/setup/install/virtual-machine/common.sh"

# @setup profile=none
source "content/en/docs/setup/install/virtual-machine/test.sh"

# @cleanup
docker stop vm
cleanup_cluster_for_vms
kubectl delete namespace istio-system vm-namespace sample
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=${bpsnip_args_gateway_api_version}" | kubectl delete -f -
