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

# This document installs Istio itself (with the PILOT_ENABLE_AGENTGATEWAY flag),
# so start from a cluster without Istio installed.
# @setup profile=none

set -e
set -u
set -o pipefail

# Install the Kubernetes Gateway API CRDs.
bpsnip_gateway_api_install_crds_install_crds

# Install Istio with agentgateway support enabled.
snip_install_istio
_wait_for_deployment istio-system istiod
_wait_for_daemonset istio-system ztunnel
_wait_for_daemonset istio-system istio-cni-node

# Both agentgateway GatewayClasses should be registered.
_verify_contains snip_verify_gateway_classes "istio-agentgateway"
_verify_contains snip_verify_gateway_classes "istio-agentgateway-waypoint"

# Deploy the sample application.
snip_deploy_bookinfo
_wait_for_deployment default productpage-v1
_wait_for_deployment default reviews-v1
_wait_for_deployment default reviews-v2

# Configure agentgateway as an ingress gateway.
snip_deploy_ingress_gateway
snip_deploy_ingress_route
_wait_for_gateway default bookinfo-gateway
_verify_contains snip_verify_ingress_gateway "istio-agentgateway"

# Configure agentgateway as a waypoint.
_verify_contains snip_label_ambient "$snip_label_ambient_out"
snip_deploy_waypoint
_wait_for_gateway default agentgateway-waypoint
_verify_contains snip_verify_waypoint "istio-agentgateway-waypoint"
_verify_contains snip_enroll_waypoint "$snip_enroll_waypoint_out"

# @cleanup
set +e
snip_cleanup_ingress
snip_cleanup_waypoint
snip_cleanup_bookinfo
snip_uninstall_istio
bpsnip_gateway_api_remove_crds_remove_crds
