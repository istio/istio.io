#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2034,SC2154

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

# Initialize KUBECONFIG_FILES and KUBE_CONTEXTS
_set_kube_vars

source content/en/docs/setup/install/multicluster/verify/snips.sh

# set_single_network_vars initializes all variables for a single network config.
function set_single_network_vars
{
  export KUBECONFIG_CLUSTER1="${KUBECONFIG_FILES[0]}"
  export KUBECONFIG_CLUSTER2="${KUBECONFIG_FILES[1]}"
  export CTX_CLUSTER1="${KUBE_CONTEXTS[0]}"
  export CTX_CLUSTER2="${KUBE_CONTEXTS[1]}"
}

# set_multi_network_vars initializes all variables for a multi-network config.
function set_multi_network_vars
{
  export KUBECONFIG_CLUSTER1="${KUBECONFIG_FILES[0]}"
  export KUBECONFIG_CLUSTER2="${KUBECONFIG_FILES[2]}"
  export CTX_CLUSTER1="${KUBE_CONTEXTS[0]}"
  export CTX_CLUSTER2="${KUBE_CONTEXTS[2]}"
}

# configure_trust creates a hierarchy of
function configure_trust
{
  # Keeps the certs under a separate directory.
  mkdir -p certs
  pushd certs || exit

  # Create the root cert.
  make -f ../tools/certs/Makefile.selfsigned.mk root-ca

  # Create and deploy intermediate certs for cluster1 and cluster2.
  make -f ../tools/certs/Makefile.selfsigned.mk cluster1-cacerts
  make -f ../tools/certs/Makefile.selfsigned.mk cluster2-cacerts

  # Create the istio-system namespace in each cluster so that we can create the secrets.
  kubectl --context="$CTX_CLUSTER1" create namespace istio-system
  kubectl --context="$CTX_CLUSTER2" create namespace istio-system

  # Deploy secret to each cluster
  kubectl --context="$CTX_CLUSTER1" create secret generic cacerts -n istio-system \
      --from-file=cluster1/ca-cert.pem \
      --from-file=cluster1/ca-key.pem \
      --from-file=cluster1/root-cert.pem \
      --from-file=cluster1/cert-chain.pem
  kubectl --context="$CTX_CLUSTER2" create secret generic cacerts -n istio-system \
      --from-file=cluster2/ca-cert.pem \
      --from-file=cluster2/ca-key.pem \
      --from-file=cluster2/root-cert.pem \
      --from-file=cluster2/cert-chain.pem

  popd || exit # Return to the previous directory.
}

# cleanup removes all resources created by the tests.
function cleanup
{
  # Remove temp files.
  rm -f cluster1.yaml cluster2.yaml certs

  # Cleanup both clusters concurrently
  cleanup_cluster1 &
  cleanup_cluster2 &
  wait
}

# cleanup_cluster1 removes the istio-system and sample namespaces on CLUSTER1.
function cleanup_cluster1
{
  echo y | istioctl uninstall --revision=default --context="${CTX_CLUSTER1}"
  kubectl delete ns istio-system sample --context="${CTX_CLUSTER1}" --ignore-not-found
}

# cleanup_cluster2 removes the istio-system and sample namespaces on CLUSTER2.
function cleanup_cluster2
{
  echo y | istioctl uninstall --revision=default --context="${CTX_CLUSTER2}"
  kubectl delete ns istio-system sample --context="${CTX_CLUSTER2}" --ignore-not-found
}

# verify_load_balancing verifies that traffic is load balanced properly
# between CLUSTER1 and CLUSTER2.
function verify_load_balancing
{
  # Deploy the HelloWorld service.
  snip_deploy_the_helloworld_service_1
  snip_deploy_the_helloworld_service_2
  snip_deploy_the_helloworld_service_3

  # Deploy HelloWorld v1 and v2
  snip_deploy_helloworld_v1_1
  snip_deploy_helloworld_v2_1

  # Deploy Sleep
  snip_deploy_sleep_1

  # Wait for all the deployments.
  _wait_for_deployment sample helloworld-v1 "${CTX_CLUSTER1}"
  _wait_for_deployment sample sleep "${CTX_CLUSTER1}"
  _wait_for_deployment sample helloworld-v2 "${CTX_CLUSTER2}"
  _wait_for_deployment sample sleep "${CTX_CLUSTER2}"

  # Verify everything is deployed as expected.
  VERIFY_TIMEOUT=0 # Don't retry.
  echo "Verifying helloworld v1 deployment"
  _verify_like snip_deploy_helloworld_v1_2 "$snip_deploy_helloworld_v1_2_out"
  echo "Verifying helloworld v2 deployment"
  _verify_like snip_deploy_helloworld_v2_2 "$snip_deploy_helloworld_v2_2_out"
  echo "Verifying sleep deployment in ${CTX_CLUSTER1}"
  _verify_like snip_deploy_sleep_2 "$snip_deploy_sleep_2_out"
  echo "Verifying sleep deployment in ${CTX_CLUSTER2}"
  _verify_like snip_deploy_sleep_3 "$snip_deploy_sleep_3_out"
  unset VERIFY_TIMEOUT # Restore default

  local EXPECTED_RESPONSE_FROM_CLUSTER1="Hello version: v1, instance:"
  local EXPECTED_RESPONSE_FROM_CLUSTER2="Hello version: v2, instance:"

  # Verify we hit both clusters from CLUSTER1
  echo "Verifying load balancing from ${CTX_CLUSTER1}"
  _verify_contains snip_verifying_crosscluster_traffic_1 "$EXPECTED_RESPONSE_FROM_CLUSTER1"
  _verify_contains snip_verifying_crosscluster_traffic_1 "$EXPECTED_RESPONSE_FROM_CLUSTER2"

  # Verify we hit both clusters from CLUSTER2
  echo "Verifying load balancing from ${CTX_CLUSTER2}"
  _verify_contains snip_verifying_crosscluster_traffic_3 "$EXPECTED_RESPONSE_FROM_CLUSTER1"
  _verify_contains snip_verifying_crosscluster_traffic_3 "$EXPECTED_RESPONSE_FROM_CLUSTER2"
}
