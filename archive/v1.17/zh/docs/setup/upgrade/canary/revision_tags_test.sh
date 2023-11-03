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
source "tests/util/samples.sh"

set -e
set -u
set -o pipefail

# @setup profile=none
# setup two control plane revisions
snip_usage_1
_wait_for_deployment istio-system istiod-1-9-5
_wait_for_deployment istio-system istiod-1-10-0

# tag the revisions
snip_usage_2

# deploy app namespaces and label them
snip_usage_3
snip_usage_4
_wait_for_deployment app-ns-1 sleep
_wait_for_deployment app-ns-2 sleep
_wait_for_deployment app-ns-3 sleep

# verify both the revisions are managing workloads
_verify_contains snip_usage_5 "istiod-1-9-5"
_verify_contains snip_usage_5 "istiod-1-10-0"

# update the stable revision
snip_usage_6

# restart the older stable revision namespaces
snip_usage_7

# verify only the canary revision is managing workloads
_verify_not_contains snip_usage_8 "istiod-1-9-5"
_verify_contains snip_usage_8 "istiod-1-10-0"

# @cleanup
snip_uninstall_old_control_plane_1
istioctl uninstall --purge -y
snip_cleanup_2
