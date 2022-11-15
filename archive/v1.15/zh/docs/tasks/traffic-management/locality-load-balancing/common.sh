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

# Initialize KUBE_CONTEXTS
_set_kube_vars

# Include the before you begin tasks.
source content/zh/docs/tasks/traffic-management/locality-load-balancing/before-you-begin/snips.sh
source content/zh/docs/tasks/traffic-management/locality-load-balancing/cleanup/snips.sh


set -e
set -u
set -o pipefail

function set_env_vars
{
  # All use the same cluster.
  export CTX_PRIMARY="${KUBE_CONTEXTS[0]}"
  export CTX_R1_Z1="${KUBE_CONTEXTS[0]}"
  export CTX_R1_Z2="${KUBE_CONTEXTS[0]}"
  export CTX_R2_Z3="${KUBE_CONTEXTS[0]}"
  export CTX_R3_Z4="${KUBE_CONTEXTS[0]}"
}

function deploy_services
{
  echo "Creating the sample namespace"
  snip_create_the_sample_namespace_1
  snip_create_the_sample_namespace_2

  echo "Generating HelloWorld YAML"
  snip_deploy_helloworld_1

  echo "Adding istio-locality label to YAML"
  for LOC in "region1.zone1" "region1.zone2" "region2.zone3" "region3.zone4";
  do
    add_locality_label "helloworld-${LOC}.yaml" "$LOC"
  done

  echo "Deploying HelloWorld"
  snip_deploy_helloworld_2
  snip_deploy_helloworld_3
  snip_deploy_helloworld_4
  snip_deploy_helloworld_5

  echo "Deploying Sleep"
  # Make a copy of sleep.yaml.
  cp "samples/sleep/sleep.yaml" "samples/sleep/sleep.yaml.original"
  # Add the locality label to sleep.yaml
  add_locality_label "samples/sleep/sleep.yaml" "region1.zone1"
  # Deploy sleep
  snip_deploy_sleep_1
  # Restore the original file.
  mv -f "samples/sleep/sleep.yaml.original" "samples/sleep/sleep.yaml"

  echo "Waiting for HelloWorld pods"
  _verify_like snip_wait_for_helloworld_pods_1 "$snip_wait_for_helloworld_pods_1_out"
  _verify_like snip_wait_for_helloworld_pods_2 "$snip_wait_for_helloworld_pods_2_out"
  _verify_like snip_wait_for_helloworld_pods_3 "$snip_wait_for_helloworld_pods_3_out"
  _verify_like snip_wait_for_helloworld_pods_4 "$snip_wait_for_helloworld_pods_4_out"
}

function add_locality_label
{
  local file="$1"
  local locality="$2"
  local nl=$'\n'

  local output=""
  local in_deployment=false
  while IFS= read -r line
  do
    # We only want to add the locality label to deployments, so track when
    # we're inside a deployment.
    if [[ "$line" =~ ^kind:[[:space:]]([a-zA-Z]+)$ ]]; then
      if [[ "${BASH_REMATCH[1]}" == "Deployment" ]]; then
        in_deployment=true
      else
        in_deployment=false
      fi
    fi

    # When we find an app label in the deployment, add the locality label
    # right after.
    if [[ "$in_deployment" == "true"  && $line =~ ([[:space:]]+)app:[[:space:]](.*) ]]; then
      output+="${line}${nl}"
      output+="${BASH_REMATCH[1]}istio-locality: ${locality}${nl}"
    else
      output+="${line}${nl}"
    fi
  done < "$file"

  # Overwrite the original file.
  echo "$output" > "$file"
}

function verify_traffic
{
  local func=$1
  local expected=$2

  # Require that we match the locality multiple times in a row.
  VERIFY_CONSECUTIVE=10
  # Verify that all traffic now goes to region1.zone2
  _verify_like "$func" "$expected"
  unset VERIFY_CONSECUTIVE
}

function cleanup
{
  snip_remove_generated_files_1
  snip_remove_the_sample_namespace_1
}
