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
#          docs/tasks/observability/distributed-tracing/opencensusagent/index.md
####################################################################################################

! read -r -d '' snip_setup_istio_and_tracing_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
    namespace: istio-system
    name: config-istiocontrolplane
spec:
    meshConfig:
        defaultProviders:
            tracing:
            - "opencensus"
        enableTracing: true
        extensionProviders:
        - name: "opencensus"
            opencensus:
                service: "opentelemetry-collector.istio-system.svc.cluster.local"
                port: 55678
                context:
                - B3
                - W3C_TRACE_CONTEXT
ENDSNIP

snip_setup_istio_and_tracing_2() {
istioctl install -f tracing.yaml
}

snip_setup_istio_and_tracing_3() {
kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - randomSamplingPercentage: 100.00
EOF
}

snip_install_the_backend_1() {
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.14/samples/addons/jaeger.yaml
}

snip_install_opentelemetry_collector_1() {
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: opentelemetry-collector
  namespace: istio-system
  labels:
    app: opentelemetry-collector
data:
  config: |
    receivers:
      opencensus:
        endpoint: 0.0.0.0:55678
    processors:
      memory_limiter:
        limit_mib: 100
        spike_limit_mib: 10
        check_interval: 5s
    exporters:
      zipkin:
        # Export via zipkin for easy querying
        endpoint: http://zipkin.istio-system.svc:9411/api/v2/spans
      logging:
        loglevel: debug

    extensions:
      health_check:
        port: 13133

    service:
      extensions:
      - health_check
      pipelines:
        traces:
          receivers:
          - opencensus
          processors:
          - memory_limiter
          exporters:
          - zipkin
          - logging
---
apiVersion: v1
kind: Service
metadata:
  name: opentelemetry-collector
  namespace: istio-system
  labels:
    app: opentelemetry-collector
spec:
  type: ClusterIP
  selector:
    app: opentelemetry-collector
  ports:
    - name: grpc-opencensus
      port: 55678
      protocol: TCP
      targetPort: 55678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opentelemetry-collector
  namespace: istio-system
  labels:
    app: opentelemetry-collector
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opentelemetry-collector
  template:
    metadata:
      labels:
        app: opentelemetry-collector
    spec:
      containers:
        - name: opentelemetry-collector
          image: "otel/opentelemetry-collector:0.49.0"
          imagePullPolicy: IfNotPresent
          command:
            - "/otelcol"
            - "--config=/conf/config.yaml"
          ports:
            - name: grpc-opencensus
              containerPort: 55678
              protocol: TCP
          volumeMounts:
            - name: opentelemetry-collector-config
              mountPath: /conf
          readinessProbe:
            httpGet:
              path: /
              port: 13133
          resources:
            requests:
              cpu: 40m
              memory: 100Mi
      volumes:
        - name: opentelemetry-collector-config
          configMap:
            name: opentelemetry-collector
            items:
              - key: config
                path: config.yaml
EOF
}

snip_deploy_the_bookinfo_app_1() {
kubectl label namespace default istio-injection=enabled
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.14/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.14/samples/bookinfo/networking/bookinfo-gateway.yaml
}

snip_generate_and_visualize_trace_data_1() {
SERVICE_IP=$(kubectl get svc -n istio-system istio-ingressgateway -ojsonpath="{.spec.clusterIP})
kubectl create ns curl
for i in {1..3}; do
  kubectl run -n curl --rm=true -it --restart=Never --image=curlimages/curl -- curl "http://${SERVICE_IP}/productpage"
done
kubectl delete ns curl
}

snip_generate_and_visualize_trace_data_2() {
istioctl dashboard jaeger
}

snip_cleanup_1() {
killall istioctl
}

snip_cleanup_2() {
kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.14/samples/addons/jaeger.yaml
}

snip_cleanup_3() {
kubectl delete -n istio-system cm opentelemetry-collector
kubectl delete -n istio-system svc opentelemetry-collector
kubectl delete -n istio-system deploy opentelemetry-collector
}
