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

snip_check_ns_label

snip_gen_waypoint_resource
_verify_contains snip_gen_waypoint_resource "$snip_gen_waypoint_resource_out"

snip_apply_waypoint
snip_enroll_ns_waypoint

# @cleanup
snip_delete_waypoint
bpsnip_gateway_api_remove_crds_remove_crds
