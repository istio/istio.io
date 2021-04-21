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

# This script expects Prometheus
# @setup profile=demo

_set_ingress_environment_variables
export GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
echo "Using GATEWAY_URL $GATEWAY_URL"

echo @@@ TODO REMOVE
echo When test starts, pods are
kubectl -n istio-system get pods

# Demo no longer installs Kiali.
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/kiali.yaml
kubectl -n istio-system wait --for=condition=available --timeout=600s deployment/kiali

# Install Bookinfo application
startup_bookinfo_sample

echo '*** observability-kiali step 1 ***'
snip_generating_a_service_graph_1

echo '*** observability-kiali step 2 ***'
for _ in {1..50}; do
    snip_generating_a_service_graph_2 > /dev/null
done

# We don't test snip_generating_a_service_graph_3 which is a `watch`

# The "istioctl dashboard kiali" blocks, so start it in another process
snip_generating_a_service_graph_4 &

# The script can verify there is a UI, but can't really compare it
curl http://localhost:20001/kiali --fail

# The script can look at the API output
# See https://github.com/kiali/kiali/blob/master/swagger.json
# for the API
# @@@ TODO The output of these should be checked
curl -v http://localhost:20001/api/
curl -v http://localhost:20001/api/namespaces/graph

snip_validating_istio_configuration_1

for _ in {1..50}; do
    snip_generating_a_service_graph_2 > /dev/null
done

snip_validating_istio_configuration_2

for _ in {1..50}; do
    snip_generating_a_service_graph_2 > /dev/null
done

snip_viewing_and_editing_istio_configuration_yaml_1

for _ in {1..50}; do
    snip_generating_a_service_graph_2 > /dev/null
done

snip_viewing_and_editing_istio_configuration_yaml_2

for _ in {1..50}; do
    snip_generating_a_service_graph_2 > /dev/null
done

echo @@@ TODO curl http://localhost:20001/api/ ... and verify that Kiali did detect the changes we made.


# @cleanup
set +e
cleanup_bookinfo_sample
kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/kiali.yaml

# This stops the "istioctl dashboard kiali" we forked earlier
pgrep istioctl | xargs kill
