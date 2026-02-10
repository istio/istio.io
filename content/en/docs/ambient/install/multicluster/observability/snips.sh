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
#          docs/ambient/install/multicluster/observability/index.md
####################################################################################################

snip_prepare_for_kiali_deployment_1() {
kubectl --context="${CTX_CLUSTER1}" create namespace kiali
kubectl --context="${CTX_CLUSTER2}" create namespace kiali
}

snip_prepare_for_kiali_deployment_2() {
helm repo add kiali https://kiali.org/helm-charts
}

snip_deploy_prometheus_in_each_cluster_1() {
kubectl --context="${CTX_CLUSTER1}" apply -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/addons/prometheus.yaml
kubectl --context="${CTX_CLUSTER2}" apply -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/addons/prometheus.yaml
}

snip_expose_prometheus_1() {
cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prometheus-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 9090
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: prometheus
  namespace: istio-system
spec:
  parentRefs:
  - name: prometheus-gateway
    port: 9090
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: prometheus
      port: 9090
EOF
}

snip_expose_prometheus_2() {
cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prometheus-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 9090
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: prometheus
  namespace: istio-system
spec:
  parentRefs:
  - name: prometheus-gateway
    port: 9090
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: prometheus
      port: 9090
EOF
}

snip_aggregate_metrics_1() {
TARGET1="$(kubectl --context="${CTX_CLUSTER1}" get gtw prometheus-gateway -n istio-system -o jsonpath='{.status.addresses[0].value}')"
TARGET2="$(kubectl --context="${CTX_CLUSTER2}" get gtw prometheus-gateway -n istio-system -o jsonpath='{.status.addresses[0].value}')"
cat <<EOF > prometheus.yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'federate-1'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="kubernetes-pods"}'
    static_configs:
      - targetrs:
        - '${TARGET1}:9090'
        labels:
          cluster: 'cluster1'
  - job_name: 'federate-2'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="kubernetes-pods"}'
    static_configs:
      - targetrs:
        - '${TARGET2}:9090'
        labels:
          cluster: 'cluster2'
EOF
kubectl --context="${CTX_CLUSTER1}" create configmap prometheus-config -n kiali --from-file prometheus.yaml
}

snip_aggregate_metrics_2() {
cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f - -n kiali
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: config-volume
              mountPath: /etc/prometheus
      volumes:
        - name: config-volume
          configMap:
            name: prometheus-config
            defaultMode: 420
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  labels:
    app: prometheus
    service: prometheus
spec:
  ports:
  - port: 9090
    name: http
  selector:
    app: prometheus
EOF
}

snip_verify_federated_prometheus_1() {
kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
}

! IFS=$'\n' read -r -d '' snip_verify_federated_prometheus_2 <<\ENDSNIP
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
ENDSNIP

snip_verify_federated_prometheus_3() {
kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pods ---context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -s prometheus.kiali:9090/api/v1/query?query=istio_tcp_received_bytes_total | jq '.'
}

! IFS=$'\n' read -r -d '' snip_verify_federated_prometheus_4 <<\ENDSNIP
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "istio_tcp_received_bytes_total",
          ...
          "app": "ztunnel",
          ...
          "cluster": "cluster2",
          ...
          "destination_canonical_revision": "v2",
          ...
          "destination_canonical_service": "helloworld",
          ...
        },
        "value": [
          1770660628.007,
          "5040"
        ]
      },
      ...
      {
        "metric": {
          "__name__": "istio_tcp_received_bytes_total",
          ...
          "app": "ztunnel",
          ...
          "cluster": "cluster1",
          ...
          "destination_canonical_revision": "v1",
          ...
          "destination_canonical_service": "helloworld",
          ...
        },
        "value": [
          1770660628.007,
          "4704"
        ]
      },
      ...
    ]
  }
}
ENDSNIP

snip_prepare_remote_cluster_1() {
helm --kube-context="${CTX_CLUSTER2}" install --namespace kiali kiali-operator kiali/kiali-operator --wait
}

snip_prepare_remote_cluster_2() {
cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f - -n kiali
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
spec:
  auth:
    strategy: "anonymous"
  deployment:
    remote_cluster_resources_only: true
EOF
kubectl --context="${CTX_CLUSTER2}" wait --for=condition=Successful kiali kiali -n kiali
cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f - -n kiali
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: kiali
  annotations:
    kubernetes.io/service-account.name: kiali-service-account
type: kubernetes.io/service-account-token
EOF
}

snip_deploy_kiali_1() {
helm --kube-context="${CTX_CLUSTER1}" install --namespace kiali kiali-operator kiali/kiali-operator --wait
}

snip_deploy_kiali_2() {
curl -L -o kiali-prepare-remote-cluster.sh https://raw.githubusercontent.com/kiali/kiali/master/hack/istio/multicluster/kiali-prepare-remote-cluster.sh
chmod +x kiali-prepare-remote-cluster.sh
./kiali-prepare-remote-cluster.sh \
    --kiali-cluster-context "${CTX_CLUSTER1}" \
    --remote-cluster-context "${CTX_CLUSTER2}" \
    --view-only false \
    --process-kiali-secret true \
    --process-remote-resources false \
    --kiali-cluster-namespace kiali \
    --remote-cluster-namespace kiali \
    --kiali-resource-name kiali \
    --remote-cluster-name cluster2
}

snip_deploy_kiali_3() {
cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f - -n kiali
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
spec:
  auth:
    strategy: "anonymous"
  external_services:
    prometheus:
      url: http://prometheus.kiali:9090
    grafana:
      enabled: false
  server:
    web_root: "/kiali"
EOF
kubectl --context="${CTX_CLUSTER1}" wait --for=condition=Successful kiali kiali -n kiali
}

snip_cleanup_kiali_and_prometheus_1() {
kubectl --context="${CTX_CLUSTER1}" delete kiali kiali -n kiali
kubectl --context="${CTX_CLUSTER2}" delete kiali kiali -n kiali
}

snip_cleanup_kiali_and_prometheus_2() {
helm --kube-context="${CTX_CLUSTER1}" uninstall --namespace kiali kiali-operator
helm --kube-context="${CTX_CLUSTER2}" uninstall --namespace kiali kiali-operator
}

snip_cleanup_kiali_and_prometheus_3() {
kubectl --context="${CTX_CLUSTER1}" delete crd kialis.kiali.io
}

snip_cleanup_kiali_and_prometheus_4() {
kubectl --context="${CTX_CLUSTER1}" delete -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/addons/prometheus.yaml
kubectl --context="${CTX_CLUSTER2}" delete -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/addons/prometheus.yaml
}
