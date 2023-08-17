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

function configureDistribution
{
    echo "Applying configuration for locality distribution"
    snip_configure_weighted_distribution_1

    # Wait a bit for the change to propagate.
    sleep 5
}

function verifyDistribution
{
    echo "Verifying the distribution"

    # Gather the totals that reach each zone.
    local z1=0
    local z2=0
    local z3=0
    local z4=0
    for i in {1..50}; do
      # Send traffic to HelloWorld and get the reply.
      out="$(snip_verify_the_distribution_1)"

      echo "$out"

      # See which zone replied.
      if [[ "$out" == *"region1.zone1"* ]]; then
        z1=$(( z1 + 1 ))
      elif [[ "$out" == *"region1.zone2"* ]]; then
        z2=$(( z2 + 1 ))
      elif [[ "$out" == *"region2.zone3"* ]]; then
        z3=$(( z3 + 1 ))
      elif [[ "$out" == *"region3.zone4"* ]]; then
        z4=$(( z4 + 1 ))
      else
        echo "Unexpected response from HelloWorld: $out"
        exit 1
      fi
    done

    # Scale the numbers so that they total 100.
    z1=$(( z1 * 2 ))
    z2=$(( z2 * 2 ))
    z3=$(( z3 * 2 ))
    z4=$(( z4 * 2 ))

    echo "Actual locality distribution:"
    echo "region1.zone1: ${z1}"
    echo "region1.zone2: ${z2}"
    echo "region2.zone3: ${z3}"
    echo "region3.zone4: ${z4}"

    if ((z1 < 60 || z1 > 80)); then
      echo "Invalid locality distribution to region1.zone1: $z1. Expected: 70"
      exit 1
    elif ((z2 < 10 || z2 > 30)); then
      echo "Invalid locality distribution to region1.zone2: $z2. Expected: 20"
      exit 1
    elif ((z3 > 0)); then
      echo "Invalid locality distribution to region2.zone3: $z3. Expected: 0"
      exit 1
    elif ((z4 < 5 || z4 > 20)); then
      echo "Invalid locality distribution to region1.zone2: $z4. Expected: 10"
      exit 1
    fi
}

set_env_vars
deploy_services
configureDistribution
verifyDistribution

# @cleanup
source content/en/docs/tasks/traffic-management/locality-load-balancing/common.sh

set_env_vars
cleanup
