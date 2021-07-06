#!/usr/bin/env bash
# shellcheck disable=SC2155

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

startup_bookinfo_sample() {
    kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
    kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
    kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml

    for deploy in "productpage-v1" "details-v1" "ratings-v1" "reviews-v1" "reviews-v2" "reviews-v3"; do
        _wait_for_deployment default "$deploy"
    done
}

cleanup_bookinfo_sample() {
    kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml || true
    kubectl delete -f samples/bookinfo/networking/destination-rule-all.yaml || true
    kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml || true
}

startup_sleep_sample() {
    # TODO: how to make sure previous test cleaned up everything?
    set +e
    kubectl delete pods -l app=sleep --force
    set -e

    kubectl apply -f samples/sleep/sleep.yaml -n default
    _wait_for_deployment default sleep
}

cleanup_sleep_sample() {
    kubectl delete -f samples/sleep/sleep.yaml -n default || true
}

startup_httpbin_sample() {
    kubectl apply -f samples/httpbin/httpbin.yaml
    _wait_for_deployment default httpbin
}

cleanup_httpbin_sample() {
    kubectl delete -f samples/httpbin/httpbin.yaml || true
}

# Use curl to send an http request to a sample service via ingressgateway.
# Usage:
#   sample_http_request path [ user ]
# Example:
#   response=$(sample_http_request "/productpage" "jason")
sample_http_request() {
    local path=$1

    local user=""
	if [[ $# -gt 1 ]]; then
        user="$2"
    fi

    local ingress_url="http://istio-ingressgateway.istio-system"
    local sleep_pod
    local response

    sleep_pod=$(kubectl get pod -l app=sleep -n default -o 'jsonpath={.items..metadata.name}')

    local args=""
    if [[ -n "$user" ]]; then
        # make request as logged in user
        kubectl exec "$sleep_pod" -c sleep -n "default" -- curl -c /tmp/sample.cookies "$ingress_url/login" --data "username=$user&passwd=password"
        args="-b /tmp/sample.cookies"
    fi
    # shellcheck disable=SC2086
    response=$(kubectl exec "$sleep_pod" -c sleep -n "default" -- \
        curl "$ingress_url$path" $args -s --retry 3 --retry-connrefused --retry-delay 5)

    if [[ -n "$user" ]]; then
        # shellcheck disable=SC2086
        kubectl exec "$sleep_pod" -c sleep -n "default" -- curl $args "$ingress_url/logout"
    fi

    echo "$response"
}
