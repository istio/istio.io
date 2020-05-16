#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155

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

snip_liveness_and_readiness_probes_with_command_option_1() {
kubectl create ns istio-io-health
}

snip_liveness_and_readiness_probes_with_command_option_2() {
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

snip_liveness_and_readiness_probes_with_command_option_3() {
kubectl apply -f - <<EOF
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
  namespace: "istio-io-health"
spec:
  host: "*.default.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
}

snip_liveness_and_readiness_probes_with_command_option_4() {
kubectl -n istio-io-health apply -f <(istioctl kube-inject -f samples/health-check/liveness-command.yaml)
}

snip_liveness_and_readiness_probes_with_command_option_5() {
kubectl -n istio-io-health get pod
}

! read -r -d '' snip_liveness_and_readiness_probes_with_command_option_5_out <<\ENDSNIP
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
ENDSNIP

snip_enable_globally_via_install_option_1() {
kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e 's/"rewriteAppHTTPProbe": false/"rewriteAppHTTPProbe": true/' | kubectl apply -f -
}

! read -r -d '' snip_use_annotations_on_pod_1 <<\ENDSNIP
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
        sidecar.istio.io/rewriteAppHTTPProbers: "true"
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
ENDSNIP

snip_redeploy_the_liveness_health_check_app_1() {
kubectl create ns istio-same-port
kubectl -n istio-same-port apply -f <(istioctl kube-inject -f samples/health-check/liveness-http-same-port.yaml)
}

snip_redeploy_the_liveness_health_check_app_2() {
kubectl -n istio-same-port get pod
}

! read -r -d '' snip_redeploy_the_liveness_health_check_app_2_out <<\ENDSNIP
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   2/2       Running   0           1m
ENDSNIP

snip_separate_port_1() {
kubectl create ns istio-sep-port
kubectl -n istio-sep-port apply -f <(istioctl kube-inject -f samples/health-check/liveness-http.yaml)
}

snip_separate_port_2() {
kubectl -n istio-sep-port get pod
}

! read -r -d '' snip_separate_port_2_out <<\ENDSNIP
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-67d5db65f5-765bb   2/2       Running   0          1m
ENDSNIP

snip_cleanup_1() {
kubectl delete ns istio-io-health istio-same-port istio-sep-port
}
