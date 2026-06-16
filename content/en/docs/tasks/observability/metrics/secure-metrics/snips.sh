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
#          docs/tasks/observability/metrics/secure-metrics/index.md
####################################################################################################

snip_configure_prometheus_for_mtls_scraping_1() {
kubectl apply -n istio-system -f samples/addons/extras/prometheus-secure-metrics.yaml
kubectl rollout status deployment/prometheus -n istio-system
}

snip_configure_prometheus_for_mtls_scraping_2() {
kubectl get pod -n istio-system -l app.kubernetes.io/name=prometheus
}

! IFS=$'\n' read -r -d '' snip_configure_prometheus_for_mtls_scraping_2_out <<\ENDSNIP
NAME                          READY   STATUS    RESTARTS   AGE
prometheus-6c647c84c8-gpxt4   3/3     Running   0          75s
ENDSNIP

snip_enable_on_a_sidecar_workload_1() {
kubectl label namespace default istio-injection=enabled --overwrite
kubectl apply -f samples/httpbin/httpbin.yaml
}

snip_enable_on_a_sidecar_workload_2() {
cat <<EOF > /tmp/httpbin-secure-metrics-patch.yaml
spec:
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |
          proxyMetadata:
            ENVOY_SECURE_METRICS_PORT: "15091"
            ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
        prometheus.io/path: "/stats/prometheus"
EOF
kubectl patch deployment httpbin -n default --type=merge --patch-file=/tmp/httpbin-secure-metrics-patch.yaml
}

snip_enable_on_a_sidecar_workload_3() {
export HTTPBIN_POD=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].metadata.name}')
export HTTPBIN_IP=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].status.podIP}')
export PROM_POD=$(kubectl get pod -n istio-system -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')
}

snip_enable_on_a_sidecar_workload_4() {
istioctl proxy-config listeners "$HTTPBIN_POD" -n default | grep -E "15090|15091|15092"
}

! IFS=$'\n' read -r -d '' snip_enable_on_a_sidecar_workload_4_out <<\ENDSNIP
0.0.0.0       15090 ALL                                                                                     Inline Route: /stats/prometheus*
0.0.0.0       15091 Trans: tls                                                                              Inline Route: /stats/prometheus*
0.0.0.0       15092 Trans: tls                                                                              Inline Route: /stats/prometheus*, /metrics*
ENDSNIP

snip_enable_on_a_gateway_1() {
cat <<EOF > /tmp/gateway-secure-metrics-patch.yaml
spec:
  template:
    metadata:
      annotations:
        prometheus.istio.io/secure-port: "15092"
        prometheus.io/path: "/stats/prometheus"
    spec:
      containers:
      - name: istio-proxy
        env:
        - name: ENVOY_SECURE_METRICS_PORT
          value: "15091"
        - name: ENVOY_SECURE_MERGED_METRICS_PORT
          value: "15092"
EOF
kubectl patch deployment istio-ingressgateway -n istio-system --type=strategic --patch-file=/tmp/gateway-secure-metrics-patch.yaml
kubectl rollout status deployment/istio-ingressgateway -n istio-system
}

snip_enable_on_a_gateway_2() {
export GW_POD=$(kubectl get pod -n istio-system -l app=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config listeners "$GW_POD" -n istio-system | grep -E "15090|15091|15092"
}

! IFS=$'\n' read -r -d '' snip_enable_on_a_gateway_2_out <<\ENDSNIP
0.0.0.0   15090 ALL        Inline Route: /stats/prometheus*
0.0.0.0   15091 Trans: tls Inline Route: /stats/prometheus*
0.0.0.0   15092 Trans: tls Inline Route: /stats/prometheus*, /metrics*
ENDSNIP

snip_enable_on_a_gateway_3() {
cat <<EOF > /tmp/gateway-api-secure-metrics-patch.yaml
spec:
  infrastructure:
    annotations:
      proxy.istio.io/config: |
        proxyMetadata:
          ENVOY_SECURE_METRICS_PORT: "15091"
          ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
      prometheus.istio.io/secure-port: "15092"
      prometheus.io/path: "/stats/prometheus"
EOF
kubectl patch gateway istio-ingressgateway -n istio-system --type=merge --patch-file=/tmp/gateway-api-secure-metrics-patch.yaml
}

snip_enable_on_a_gateway_4() {
export GW_POD=$(kubectl get pod -n istio-system -l gateway.networking.k8s.io/gateway-name=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config listeners "$GW_POD" -n istio-system | grep -E "15090|15091|15092"
}

! IFS=$'\n' read -r -d '' snip_enable_on_a_gateway_4_out <<\ENDSNIP
0.0.0.0   15090 ALL        Inline Route: /stats/prometheus*
0.0.0.0   15091 Trans: tls Inline Route: /stats/prometheus*
0.0.0.0   15092 Trans: tls Inline Route: /stats/prometheus*, /metrics*
ENDSNIP

snip_fully_hardened_setup_1() {
cat <<EOF > /tmp/httpbin-hardened-patch.yaml
spec:
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |
          proxyMetadata:
            ENVOY_SECURE_METRICS_PORT: "15091"
            ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
            METRICS_LOCALHOST_ACCESS_ONLY: "true"
        prometheus.io/path: "/stats/prometheus"
EOF
kubectl patch deployment httpbin -n default --type=merge --patch-file=/tmp/httpbin-hardened-patch.yaml
}

snip_fully_hardened_setup_2() {
cat <<EOF > ./istio-secure-metrics.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ENVOY_SECURE_METRICS_PORT: "15091"
        ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
        METRICS_LOCALHOST_ACCESS_ONLY: "true"
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        podAnnotations:
          prometheus.istio.io/secure-port: "15092"
          prometheus.io/path: "/stats/prometheus"
EOF
istioctl install -f ./istio-secure-metrics.yaml
}

snip_verify_secure_metrics_scraping_with_prometheus_1() {
kubectl exec -n istio-system "$PROM_POD" -c istio-proxy -- \
    curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
    --cacert /etc/istio-certs/root-cert.pem \
    --cert /etc/istio-certs/cert-chain.pem \
    --key /etc/istio-certs/key.pem \
    --insecure \
    https://"$HTTPBIN_IP":15092/stats/prometheus
}

! IFS=$'\n' read -r -d '' snip_verify_secure_metrics_scraping_with_prometheus_1_out <<\ENDSNIP
200
ENDSNIP

snip_verify_secure_metrics_scraping_with_prometheus_2() {
kubectl exec -n default "$HTTPBIN_POD" -c istio-proxy -- curl -s --max-time 3 http://"$HTTPBIN_IP":15091/stats/prometheus
}

! IFS=$'\n' read -r -d '' snip_verify_secure_metrics_scraping_with_prometheus_2_out <<\ENDSNIP
upstream connect error or disconnect/reset before headers. reset reason: connection termination
ENDSNIP

snip_cleanup_2() {
kubectl delete -n istio-system -f samples/addons/extras/prometheus-secure-metrics.yaml
kubectl delete -f samples/httpbin/httpbin.yaml
kubectl delete gateway istio-ingressgateway -n istio-system
kubectl label namespace default istio-injection-
}

snip_legacy_secure_metrics_for_sidecars_1() {
kubectl label namespace default istio-injection=enabled --overwrite
kubectl apply -f samples/httpbin/httpbin.yaml
}

snip_legacy_secure_metrics_for_sidecars_2() {
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata:
  name: secure-metrics
  namespace: default
spec:
  ingress:
  - port:
      number: 15091
      name: https-metrics
      protocol: HTTP
    defaultEndpoint: 127.0.0.1:15020 # Change to 15090 for Envoy-only metrics
EOF
}

snip_legacy_secure_metrics_for_sidecars_3() {
kubectl annotate pod -n default \
  -l app=httpbin \
  prometheus.io/scrape="true" \
  prometheus.io/path="/stats/prometheus" \
  prometheus.istio.io/secure-port="15091" \
  --overwrite
}

snip_legacy_secure_metrics_for_gateways_1() {
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: metrics-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 15091
      name: https-metrics
      protocol: HTTPS
    tls:
      mode: ISTIO_MUTUAL
    hosts: ["*"]
EOF
}

snip_legacy_secure_metrics_for_gateways_2() {
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: gateway-admin
  namespace: istio-system
spec:
  hosts: [gateway-admin.local]
  location: MESH_INTERNAL
  ports:
  - number: 15020  # Change to 15090 for Envoy-only metrics
    name: http-metrics
    protocol: HTTP
  resolution: STATIC
  endpoints:
  - address: 127.0.0.1
EOF
}

snip_legacy_secure_metrics_for_gateways_3() {
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: gateway-metrics
  namespace: istio-system
spec:
  hosts: ["*"]
  gateways: [metrics-gateway]
  http:
  - match:
    - uri:
        prefix: /stats/prometheus
    route:
    - destination:
        host: gateway-admin.local
        port:
          number: 15020  # Change to 15090 for Envoy-only metrics
EOF
}

snip_legacy_secure_metrics_for_gateways_4() {
kubectl annotate pod -n istio-system \
  -l app=istio-ingressgateway \
  prometheus.istio.io/secure-port=15091 \
  --overwrite
}

snip_legacy_cleanup_1() {
kubectl delete sidecar secure-metrics -n default
kubectl delete gateway metrics-gateway -n istio-system
kubectl delete serviceentry gateway-admin -n istio-system
kubectl delete virtualservice gateway-metrics -n istio-system
kubectl delete -n istio-system -f samples/addons/extras/prometheus-secure-metrics.yaml
kubectl delete -f samples/httpbin/httpbin.yaml
kubectl label namespace default istio-injection-
}
