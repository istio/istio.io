#!/usr/bin/env bash
# shellcheck disable=SC2154

# Copyright 2024 Istio Authors
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

# @setup profile=ambient

set -e
set -u
set -o pipefail

bpsnip_gateway_api_install_crds_install_crds

_wait_for_deployment istio-system istiod
_wait_for_daemonset istio-system ztunnel
_wait_for_daemonset istio-system istio-cni-node

# Deploy curl and enroll default namespace
snip_deploy_curl
_wait_for_deployment default curl

snip_label_default_ambient

# Create egress namespace and deploy waypoint
snip_create_egress_ns
snip_apply_egress_waypoint
_verify_contains snip_apply_egress_waypoint "$snip_apply_egress_waypoint_out"

_wait_for_deployment istio-egress waypoint
_verify_contains snip_wait_egress_waypoint "True"

# Define the external service
snip_apply_serviceentry
_wait_for_resource serviceentry istio-egress httpbin-org

# Verify basic egress traffic routes through the waypoint
_verify_same snip_verify_egress_traffic "$snip_verify_egress_traffic_out"
_verify_contains snip_check_waypoint_logs "upstream_rq_total"

# Apply L7 authorization policy
snip_apply_authz_policy
_wait_for_resource authorizationpolicy istio-egress httpbin-org

_verify_same snip_verify_allowed_request "$snip_verify_allowed_request_out"
_verify_same snip_verify_denied_request "$snip_verify_denied_request_out"

# Apply TLS origination
snip_apply_tls_origination
_wait_for_resource serviceentry istio-egress httpbin-org
_wait_for_resource destinationrule istio-egress httpbin-org-tls

_verify_contains snip_verify_tls_origination "url"

# Add a second external service and verify it routes through the same waypoint
snip_apply_second_serviceentry
_wait_for_resource serviceentry istio-egress example-com
_verify_same snip_verify_second_serviceentry "$snip_verify_second_serviceentry_out"

# @cleanup
snip_cleanup
