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

snip_liveness_probe_rewrite_example_1() {
kubectl create namespace istio-io-health-rewrite
kubectl label namespace istio-io-health-rewrite istio-injection=enabled
}

snip_liveness_probe_rewrite_example_2() {
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-http
  namespace: istio-io-health-rewrite
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
}

snip_liveness_probe_rewrite_example_3() {
kubectl get pod "$LIVENESS_POD" -n istio-io-health-rewrite -o json | jq '.spec.containers[0].livenessProbe.httpGet'
}

! read -r -d '' snip_liveness_probe_rewrite_example_3_out <<\ENDSNIP
{
  "path": "/app-health/liveness-http/livez",
  "port": 15020,
  "scheme": "HTTP"
}
ENDSNIP

snip_liveness_probe_rewrite_example_4() {
kubectl get pod "$LIVENESS_POD" -n istio-io-health-rewrite -o=jsonpath="{.spec.containers[1].env[?(@.name=='ISTIO_KUBE_APP_PROBERS')]}"
}

! read -r -d '' snip_liveness_probe_rewrite_example_4_out <<\ENDSNIP
{
  "name":"ISTIO_KUBE_APP_PROBERS",
  "value":"{\"/app-health/liveness-http/livez\":{\"httpGet\":{\"path\":\"/foo\",\"port\":8001,\"scheme\":\"HTTP\"},\"timeoutSeconds\":1}}"
}
ENDSNIP

snip_liveness_and_readiness_probes_using_the_command_approach_1() {
kubectl create ns istio-io-health
}

snip_liveness_and_readiness_probes_using_the_command_approach_2() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
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

! read -r -d '' snip_disable_the_probe_rewrite_for_a_pod_1 <<\ENDSNIP
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

! read -r -d '' snip_disable_the_probe_rewrite_for_a_pod_2 <<\ENDSNIP
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-grpc
spec:
  selector:
    matchLabels:
      app: liveness-grpc
      version: v1
  template:
    metadata:
      labels:
        app: liveness-grpc
        version: v1
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "false"
    spec:
      containers:
      - name: etcd
        image: registry.k8s.io/etcd:3.5.1-0
        command: ["--listen-client-urls", "http://0.0.0.0:2379", "--advertise-client-urls", "http://127.0.0.1:2379", "--log-level", "debug"]
        ports:
        - containerPort: 2379
        livenessProbe:
          grpc:
            port: 2379
          initialDelaySeconds: 10
          periodSeconds: 5
EOF
ENDSNIP

snip_disable_the_probe_rewrite_globally_1() {
kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e 's/"rewriteAppHTTPProbe": true/"rewriteAppHTTPProbe": false/' | kubectl apply -f -
}

snip_cleanup_1() {
kubectl delete ns istio-io-health istio-io-health-rewrite
}
