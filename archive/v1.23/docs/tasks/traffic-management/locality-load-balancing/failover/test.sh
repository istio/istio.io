#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154

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

# @setup profile=default

source content/en/docs/tasks/traffic-management/locality-load-balancing/common.sh

set -e
set -u
set -o pipefail

function verify_traffic_region1_zone1
{
  echo "Verifying all traffic stays in region1.zone1"
  snip_configure_locality_failover_1
  verify_traffic snip_verify_traffic_stays_in_region1zone1_1 "$snip_verify_traffic_stays_in_region1zone1_1_out"
}

function failover_to_region1_zone2
{
  echo "Triggering failover to region1.zone2"

  # Terminate the Envoy on the region1.zone1 pod.
  snip_failover_to_region1zone2_1

  # Verify that all traffic now goes to region1.zone2
  verify_traffic snip_failover_to_region1zone2_2 "$snip_failover_to_region1zone2_2_out"
}

function failover_to_region2_zone3
{
  echo "Triggering failover to region2.zone3"

  # Terminate the Envoy on the region1.zone2 pod.
  snip_failover_to_region2zone3_1

  # Verify that all traffic now goes to region2.zone3
  verify_traffic snip_failover_to_region2zone3_2 "$snip_failover_to_region2zone3_2_out"
}

function failover_to_region3_zone4
{
  echo "Triggering failover to region3.zone4"

  # Terminate the Envoy on the region2.zone3 pod.
  snip_failover_to_region3zone4_1

  # Verify that all traffic now goes to region3.zone4
  verify_traffic snip_failover_to_region3zone4_2 "$snip_failover_to_region3zone4_2_out"
}

set_env_vars
deploy_services
verify_traffic_region1_zone1
failover_to_region1_zone2
failover_to_region2_zone3
failover_to_region3_zone4

# @cleanup
source content/en/docs/tasks/traffic-management/locality-load-balancing/common.sh

set_env_vars
cleanup
