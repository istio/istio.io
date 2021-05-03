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
export IFS=

source "tests/util/samples.sh"

kubectl label namespace default istio-injection=enabled --overwrite

# start the httpbin sample
startup_httpbin_sample

POD="$(kubectl get pod -l app=httpbin -o jsonpath='{.items[0].metadata.name}')"
export POD

# @setup profile=default
_verify_contains snip_get_stats "cluster_manager"
_verify_contains snip_get_stats "listener_manager"
_verify_contains snip_get_stats "server"
_verify_contains snip_get_stats "cluster.xds-grpc"
_verify_contains snip_get_stats "wasm"

kubectl delete pods --all
echo "$snip_proxyStatsMatcher" | istioctl install --set profile=default -y -f -
_verify_contains snip_get_stats "circuit_breakers"
_verify_contains snip_get_stats "upstream_rq_retry"

#reset and verify that they no longer apply
istioctl install -y --set profile=default
kubectl label namespace default istio-injection=enabled --overwrite
cleanup_httpbin_sample
startup_httpbin_sample
POD="$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')"
export POD
_verify_not_contains snip_get_stats "circuit_breakers"
_verify_not_contains snip_get_stats "upstream_rq_retry"

yq w -d2 sleep2.yaml 'metadata.annotations[+]' "$snip_proxyIstioConfig" > sleep_istioconfig.yaml
kubectl apply -f sleep_istioconfig.yaml
POD="$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')"
export POD
_verify_contains snip_get_stats "circuit_breakers"
_verify_contains snip_get_stats "upstream_rq_retry"

# @cleanup

set +e
cleanup_httpbin_sample
cleanup_sleep_sample
