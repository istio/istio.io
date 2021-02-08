#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

# Copyright Istio Authors. All Rights Reserved.
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

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          docs/ops/configuration/mesh/app-health-check/index.md
####################################################################################################

snip_liveness_and_readiness_probes_using_the_command_approach_1() {
kubectl create ns istio-io-health
}

snip_liveness_and_readiness_probes_using_the_command_approach_2() {
kubectl apply -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
  namespace: "istio-io-health"
spec:
  mtls:
    mode: STRICT
EOF
}

snip_liveness_and_readiness_probes_using_the_command_approach_3() {
kubectl -n istio-io-health apply -f <(istioctl kube-inject -f samples/health-check/liveness-command.yaml)
}

snip_liveness_and_readiness_probes_using_the_command_approach_4() {
kubectl -n istio-io-health get pod
}

! read -r -d '' snip_liveness_and_readiness_probes_using_the_command_approach_4_out <<\ENDSNIP
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
ENDSNIP

! read -r -d '' snip_disable_the_http_probe_rewrite_for_a_pod_1 <<\ENDSNIP
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-http
spec:
  selector:
    matchLabels:
      app: liveness-http
      version: v1
  template:
    metadata:
      labels:
        app: liveness-http
        version: v1
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "false"
    spec:
      containers:
      - name: liveness-http
        image: docker.io/istio/health:example
        ports:
        - containerPort: 8001
        livenessProbe:
          httpGet:
            path: /foo
            port: 8001
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
ENDSNIP

snip_disable_the_probe_rewrite_globally_1() {
kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e 's/"rewriteAppHTTPProbe": true/"rewriteAppHTTPProbe": false/' | kubectl apply -f -
}

snip_cleanup_1() {
kubectl delete ns istio-io-health
}
