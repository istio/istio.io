#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

# Copyright 2023 Istio Authors
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

source "tests/util/samples.sh"

# set feature flag and deploy first controlplane
snip_deploying_multiple_control_planes_1
_wait_for_deployment usergroup-1 istiod-usergroup-1

# set feature flag and deploy second controlplane
snip_deploying_multiple_control_planes_2
_wait_for_deployment usergroup-2 istiod-usergroup-2

# enable peer auth
snip_deploying_multiple_control_planes_3
snip_deploying_multiple_control_planes_4

# deploy application workloads across usergroups
snip_deploy_application_workloads_per_usergroup_1
snip_deploy_application_workloads_per_usergroup_2
snip_deploy_application_workloads_per_usergroup_3

_wait_for_deployment app-ns-1 httpbin
_wait_for_deployment app-ns-1 sleep
_wait_for_deployment app-ns-2 httpbin
_wait_for_deployment app-ns-2 sleep
_wait_for_deployment app-ns-3 httpbin
_wait_for_deployment app-ns-3 sleep

# verification of connectivity
_verify_first_line snip_verify_the_application_connectivity_is_only_within_the_respective_usergroup_1 "HTTP/1.1 503 Service Unavailable"
_verify_first_line snip_verify_the_application_connectivity_is_only_within_the_respective_usergroup_2 "HTTP/1.1 200 OK"

# @cleanup
echo y | snip_cleanup_1
echo y | snip_cleanup_2
