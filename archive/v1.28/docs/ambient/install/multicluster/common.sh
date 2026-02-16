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

source content/en/docs/ambient/install/multicluster/verify/snips.sh
source content/en/docs/ambient/install/multicluster/failover/snips.sh

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

# cleanup_istioctl removes all resources created by the tests with istioctl.
function cleanup_istioctl
{
  # Remove temp files.
  rm -f cluster1.yaml cluster2.yaml certs

  # Cleanup both clusters concurrently
  cleanup_cluster1_istioctl &
  cleanup_cluster2_istioctl &
  wait
  snip_delete_crds
}

# cleanup_cluster1_istioctl removes the istio-system and sample namespaces on CLUSTER1 with istioctl.
function cleanup_cluster1_istioctl
{
  echo y | istioctl uninstall --revision=default --context="${CTX_CLUSTER1}"
  kubectl delete ns istio-system sample --context="${CTX_CLUSTER1}" --ignore-not-found
}

# cleanup_cluster2_istioctl removes the istio-system and sample namespaces on CLUSTER2 with istioctl.
function cleanup_cluster2_istioctl
{
  echo y | istioctl uninstall --revision=default --context="${CTX_CLUSTER2}"
  kubectl delete ns istio-system sample --context="${CTX_CLUSTER2}" --ignore-not-found
}

# verify_load_balancing verifies that traffic is load balanced properly
# between CLUSTER1 and CLUSTER2.
function verify_load_balancing
{
  # Verify istiod is synced
  echo "Verifying istiod is synced to remote cluster."
  _verify_like snip_verify_multicluster_1 "$snip_verify_multicluster_1_out"

  # Deploy the HelloWorld service.
  snip_deploy_the_helloworld_service_1
  snip_deploy_the_helloworld_service_2
  snip_deploy_the_helloworld_service_3

  # Deploy HelloWorld v1 and v2
  snip_deploy_helloworld_v1_1
  snip_deploy_helloworld_v2_1

  # Deploy curl
  snip_deploy_curl_1

  # Wait for all the deployments.
  _wait_for_deployment sample helloworld-v1 "${CTX_CLUSTER1}"
  _wait_for_deployment sample curl "${CTX_CLUSTER1}"
  _wait_for_deployment sample helloworld-v2 "${CTX_CLUSTER2}"
  _wait_for_deployment sample curl "${CTX_CLUSTER2}"

  # Expose the helloworld service in both clusters.
  echo "Exposing helloworld in cluster1"
  kubectl --context="${CTX_CLUSTER1}" label svc helloworld -n sample istio.io/global="true"
  echo "Exposing helloworld in cluster2"
  kubectl --context="${CTX_CLUSTER2}" label svc helloworld -n sample istio.io/global="true"

  # Verify everything is deployed as expected.
  VERIFY_TIMEOUT=0 # Don't retry.
  echo "Verifying helloworld v1 deployment"
  _verify_like snip_deploy_helloworld_v1_2 "$snip_deploy_helloworld_v1_2_out"
  echo "Verifying helloworld v2 deployment"
  _verify_like snip_deploy_helloworld_v2_2 "$snip_deploy_helloworld_v2_2_out"
  echo "Verifying curl deployment in ${CTX_CLUSTER1}"
  _verify_like snip_deploy_curl_2 "$snip_deploy_curl_2_out"
  echo "Verifying curl deployment in ${CTX_CLUSTER2}"
  _verify_like snip_deploy_curl_3 "$snip_deploy_curl_3_out"
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

function deploy_waypoints
{
	# Deploy waypoints in both clusters and wait until they are up and running
	snip_deploy_waypoint_proxy_1
  	_wait_for_deployment sample waypoint "${CTX_CLUSTER1}"
  	_wait_for_deployment sample waypoint "${CTX_CLUSTER2}"

	# Label HelloWorld service to use the newly deployed waypoints
	snip_deploy_waypoint_proxy_4
	# Mark waypoint service as global
	snip_deploy_waypoint_proxy_5
}

function configure_locality_failover
{
	echo "Deploying locality failover configuration"
	snip_configure_locality_failover_1
	snip_configure_locality_failover_2
}

function verify_traffic_local
{
  local EXPECTED_RESPONSE_FROM_CLUSTER1="Hello version: v1, instance:"
  local EXPECTED_RESPONSE_FROM_CLUSTER2="Hello version: v2, instance:"

  echo "Verifying traffic stays in ${CTX_CLUSTER1}"
  _verify_contains snip_verify_traffic_stays_in_local_cluster_1 "$EXPECTED_RESPONSE_FROM_CLUSTER1"

  echo "Verifying traffic stays in ${CTX_CLUSTER2}"
  _verify_contains snip_verify_traffic_stays_in_local_cluster_3 "$EXPECTED_RESPONSE_FROM_CLUSTER2"
}

function break_cluster1
{
	echo "Breaking ${CTX_CLUSTER1}"
	snip_verify_failover_to_another_cluster_1
}

function verify_failover
{
	local EXPECTED_RESPONSE_FROM_CLUSTER2="Hello version: v2, instance:"

	echo "Verifying that traffic from ${CTX_CLUSTER1} fails over to ${CTX_CLUSTER2}"
	_verify_contains snip_verify_failover_to_another_cluster_2 "$EXPECTED_RESPONSE_FROM_CLUSTER2"
}

# For Helm multi-cluster installation steps

function create_istio_system_ns
{
  snip_create_istio_system_namespace_cluster_1
  snip_create_istio_system_namespace_cluster_2
}

function setup_helm_repo
{
  snip_setup_helm_repo_cluster_1
  snip_setup_helm_repo_cluster_2
}

snip_create_istio_system_namespace_cluster_1() {
kubectl create namespace istio-system --context "${CTX_CLUSTER1}"
}

snip_create_istio_system_namespace_cluster_2() {
kubectl create namespace istio-system --context "${CTX_CLUSTER2}"
}

snip_setup_helm_repo_cluster_1() {
helm repo add istio https://istio-release.storage.googleapis.com/charts --kube-context "${CTX_CLUSTER1}"
helm repo update --kube-context "${CTX_CLUSTER1}"
}

snip_setup_helm_repo_cluster_2() {
helm repo add istio https://istio-release.storage.googleapis.com/charts --kube-context "${CTX_CLUSTER2}"
helm repo update --kube-context "${CTX_CLUSTER2}"
}

snip_delete_sample_ns_cluster_1() {
kubectl delete namespace sample --context "${CTX_CLUSTER1}"
}

snip_delete_sample_ns_cluster_2() {
kubectl delete namespace sample --context "${CTX_CLUSTER2}"
}
