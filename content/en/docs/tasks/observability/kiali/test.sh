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
snip_generating_a_service_graph_2

echo @@@ TODO REST OF TEST

# @cleanup
set +e
cleanup_bookinfo_sample
kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/kiali.yaml
