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

set -e  # Exit on failure
set -u  # Unset is an error

source "tests/util/samples.sh"

# @setup profile=none
istioctl install --set profile=default -y

echo "Verify default stats"
kubectl label namespace default istio-injection=enabled --overwrite

# start the httpbin sample
startup_httpbin_sample

POD="$(kubectl get pod -l app=httpbin -o jsonpath='{.items[0].metadata.name}')"
export POD

#check default stats
_verify_contains snip_get_stats "cluster_manager"
_verify_contains snip_get_stats "listener_manager"
_verify_contains snip_get_stats "server"
_verify_contains snip_get_stats "cluster.xds-grpc"
_verify_contains snip_get_stats "wasm"

#configure via meshconfig and confirm new stats were added
echo "Verify stats with mesh config"
export IFS=
echo "$snip_proxyStatsMatcher" | istioctl install --set profile=default -y -f -
unset IFS
kubectl label namespace default istio-injection=enabled --overwrite

kubectl delete pod -l app=httpbin
_wait_for_deployment default httpbin

POD="$(kubectl get pod -l app=httpbin -o jsonpath='{.items[0].metadata.name}')"
export POD

_verify_contains snip_get_stats "circuit_breakers"
_verify_contains snip_get_stats "upstream_rq_retry"

#reset
echo "Verify stats with annotation"
istioctl install -y --set profile=default
kubectl label namespace default istio-injection=enabled --overwrite


#configure via annotation and confirm new stats were added
export IFS=
echo "${snip_proxyIstioConfig}" > proxyConfig.yaml
unset IFS
yq m -d2 samples/sleep/sleep.yaml proxyConfig.yaml > sleep_istioconfig.yaml
kubectl apply -f sleep_istioconfig.yaml
_wait_for_deployment default sleep
POD="$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')"
export POD
_verify_contains snip_get_stats "circuit_breakers"

# @cleanup
set +e
cleanup_httpbin_sample
cleanup_sleep_sample
istioctl manifest generate --set profile=default | kubectl delete --ignore-not-found=true -f -
kubectl delete ns istio-system
