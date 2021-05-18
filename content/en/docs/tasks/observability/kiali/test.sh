#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

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

set -e  # Exit on failure
set -u  # Unset is an error
# There is no need to echo, output appears in TestDocs/tasks/observability/kiali/test.sh/test.sh/_test_context/test.sh_debug.txt
set -o pipefail

source "tests/util/samples.sh"
source "tests/util/addons.sh"

# This script expects Prometheus
# @setup profile=demo

_set_ingress_environment_variables
export GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
echo "Using GATEWAY_URL $GATEWAY_URL"

echo @@@ TODO REMOVE
echo When test starts, namespaces are
kubectl get namespaces
echo When test starts, pods are
kubectl -n istio-system get pods

# TODO Check if this works ... I am nervous we may need to install kiali twice...
# Without Prometheus, Kiali will not work.
_deploy_and_wait_for_addons kiali prometheus

# echo Using Kiali from "$KIALI_MANIFEST_URL"
# 
# # Demo no longer installs Kiali.
# # @@@ TODO Use $KIALI_MANIFEST_URL
# kubectl apply -f "$KIALI_MANIFEST_URL"
# # Wait for CRD and run the install again.
# # See https://github.com/istio/istio/issues/27417#issuecomment-729153529 for rationale.
# kubectl -n istio-system wait --for=condition=established --timeout=60s crd/monitoringdashboards.monitoring.kiali.io
# kubectl apply -f "$KIALI_MANIFEST_URL"
# kubectl -n istio-system wait --for=condition=available --timeout=600s deployment/kiali

echo @@@ TODO REMOVE
echo After addons installed, pods are
kubectl -n istio-system get pods

# Install Bookinfo sample
startup_bookinfo_sample  # from tests/util/samples.sh

echo '*** observability-kiali step 1 ***'
snip_generating_a_graph_1

echo '*** observability-kiali step 2 ***'
for _ in {1..50}; do
    snip_generating_a_graph_2 > /dev/null
done

# We don't test snip_generating_a_graph_3 which is a `watch`

# The "istioctl dashboard kiali" blocks, so start it in another process
echo '*** observability-kiali step 3 ***'
# Forking doesn't work with bash functions, so we do it explicitly here
# snip_generating_a_graph_4 &
istioctl dashboard kiali > /dev/null &

# The script can verify there is a UI, but can't really compare it
echo '*** observability-kiali step 4 ***'
sleep 10 # wait for the 'istioctl dashboard' to complete

KIALI_LOC=http://localhost:20001/kiali
curl -v ${KIALI_LOC} --fail

# TODO remove in favor of the below
curl -v "${KIALI_LOC}/api/namespaces/graph?namespaces=default"

# The script can look at the API output
# See https://github.com/kiali/kiali/blob/master/swagger.json
# for the API.  In this case, we want JSON with a "nodes" key
# (It would be nice to 'tee' this to the console, but I am not sure how...)
curl -v "${KIALI_LOC}/api/namespaces/graph?namespaces=default" --fail \
   | jq ".elements" | grep '"nodes"'

# Rename port to invalid value
echo '*** observability-kiali step where we rename port ***'
snip_validating_istio_configuration_1 || true

# Send traffic to Bookinfo
echo '*** observability-kiali step where we send traffic again ***'
for _ in {1..50}; do
    snip_generating_a_graph_2 > /dev/null
done

# Rename port back to valid value
snip_generating_a_graph_2

# Send traffic to Bookinfo
echo '*** observability-kiali step where we send more traffic ***'
for _ in {1..50}; do
    snip_generating_a_graph_2 > /dev/null
done

# Apply Bookinfo destination rules
echo '*** observability-kiali step where we apply destination rules ***'
snip_viewing_and_editing_istio_configuration_yaml_1

# Send traffic to Bookinfo
echo '*** observability-kiali step where we send traffic after setting dest rules ***'
for _ in {1..50}; do
    snip_generating_a_graph_2 > /dev/null
done

# Delete destination rules
echo '*** observability-kiali step where we delete dest rules ***'
snip_viewing_and_editing_istio_configuration_yaml_2

# Send traffic to Bookinfo
echo '*** observability-kiali step where we send traffic after deleting dest rules ***'
for _ in {1..50}; do
    snip_generating_a_graph_2 > /dev/null
done

# @@@ TODO Verify that Kiali did detect the changes we made.
curl -v "${KIALI_LOC}/api/namespaces/graph?namespaces=default" --fail

# @cleanup
set +e
cleanup_bookinfo_sample
kubectl delete -f "$KIALI_MANIFEST_URL"

# This stops the "istioctl dashboard kiali" we forked earlier
pgrep istioctl | xargs kill
