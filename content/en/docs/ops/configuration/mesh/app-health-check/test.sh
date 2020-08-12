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

set -e
set -u
set -o pipefail

# @setup profile=default

snip_liveness_and_readiness_probes_with_command_option_1

snip_liveness_and_readiness_probes_with_command_option_2

snip_liveness_and_readiness_probes_with_command_option_3

_wait_for_istio peerauthentication istio-io-health default
_wait_for_istio destinationrule istio-io-health default

snip_liveness_and_readiness_probes_with_command_option_4

_wait_for_deployment istio-io-health liveness

_verify_like snip_liveness_and_readiness_probes_with_command_option_5 "$snip_liveness_and_readiness_probes_with_command_option_5_out"

kubectl -n istio-io-health delete -f samples/health-check/liveness-command.yaml

snip_enable_globally_via_install_option_1

snip_redeploy_the_liveness_health_check_app_1

_wait_for_deployment istio-same-port liveness-http

_verify_like snip_redeploy_the_liveness_health_check_app_2 "$snip_redeploy_the_liveness_health_check_app_2_out"

kubectl -n istio-same-port delete -f samples/health-check/liveness-http-same-port.yaml

kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e 's/"rewriteAppHTTPProbe": true/"rewriteAppHTTPProbe": false/' | kubectl apply -f -

kubectl create ns health-annotate

echo "$snip_use_annotations_on_pod_1" | kubectl -n health-annotate apply -f -

_wait_for_deployment health-annotate liveness-http

# helper function
get_health_annotate_pods() {
    kubectl -n health-annotate get pod
}

expected="NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   1/1       Running   0           1m"
_verify_like get_health_annotate_pods "$expected"

kubectl -n health-annotate delete deploy/liveness-http

snip_separate_port_1

kubectl -n istio-sep-port rollout status deployment liveness-http --timeout 60s

_verify_like snip_separate_port_2 "$snip_separate_port_2_out"

kubectl -n istio-sep-port delete -f samples/health-check/liveness-http.yaml

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_1
kubectl delete ns health-annotate
