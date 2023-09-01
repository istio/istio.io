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
source "content/en/docs/setup/upgrade/canary/snips.sh"
source "tests/util/samples.sh"
source "content/en/boilerplates/snips/args.sh"

set -e
set -u
set -o pipefail

# @setup profile=none

previousVersionRevision1="${bpsnip_args_istio_previous_version//./-}-1"

# setup initial control plane
istioctl install --set profile=default --revision="$previousVersionRevision1" -y

# Deploy a test namespace with an application pod
kubectl create ns test-ns
kubectl label namespace test-ns istio-injection=enabled
kubectl -n test-ns apply -f samples/sleep/sleep.yaml
_wait_for_deployment test-ns sleep

# precheck before upgrade
_verify_lines snip_before_you_upgrade_1 "$snip_before_you_upgrade_1_out"

# install canary revision
echo y | snip_control_plane_1
_wait_for_deployment istio-system istiod-canary
_verify_like snip_control_plane_2 "$snip_control_plane_2_out"
_verify_like snip_control_plane_3 "$snip_control_plane_3_out"
_verify_contains snip_data_plane_1 "istiod-canary"

# Migrate the dataplane to new revision
snip_data_plane_2
snip_data_plane_3
_verify_contains snip_data_plane_4 "test-ns"

# Uninstall canary control plane
snip_uninstall_old_control_plane_1
_verify_like snip_uninstall_old_control_plane_3 "$snip_uninstall_old_control_plane_3_out"

# @cleanup
snip_uninstall_canary_control_plane_1
snip_cleanup_1