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
#          docs/tasks/traffic-management/ingress/gateway-api-inference-extension/index.md
####################################################################################################

snip_setup_1() {
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.4.0" | kubectl apply -f -; }
kubectl get crd inference.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd?ref=v1.0.1" | kubectl apply -f -; }
}

snip_setup_2() {
istioctl install --set profile=minimal --set values.pilot.env.SUPPORT_GATEWAY_API_INFERENCE_EXTENSION=true --set values.pilot.env.ENABLE_GATEWAY_API_INFERENCE_EXTENSION=true -y
}

snip_configuring_an_inferencepool_1() {
kubectl create namespace istio-ingress
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: inference-model-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inference-model-server-deployment
  namespace: inference-model-server
  labels:
    app: inference-model-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: inference-model-server
  template:
    metadata:
      labels:
        app: inference-model-server
    spec:
      containers:
      - name: vllm-sim
        image: ghcr.io/llm-d/llm-d-inference-sim:v0.7.1
        imagePullPolicy: Always
        args:
        - --model
        - meta-llama/Llama-3.1-8B-Instruct
        - --port
        - "8000"
        - --max-loras
        - "2"
        - --lora-modules
        - '{"name": "reviews-1"}'
        ports:
        - containerPort: 8000
          name: http
          protocol: TCP
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        resources:
          requests:
            cpu: 20m
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway
  namespace: istio-ingress
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
      kinds:
      - group: gateway.networking.k8s.io
        kind: HTTPRoute
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httproute-for-inferencepool
  namespace: inference-model-server
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: gateway
    namespace: istio-ingress
    sectionName: http
  rules:
  - backendRefs:
    - group: inference.networking.k8s.io
      kind: InferencePool
      name: inference-model-server-pool
    matches:
    - path:
        type: PathPrefix
        value: /v1/completions
EOF
}

snip_configuring_an_inferencepool_2() {
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inference-endpoint-picker
  namespace: inference-model-server
  labels:
    app: inference-epp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: inference-epp
  template:
    metadata:
      labels:
        app: inference-epp
    spec:
      containers:
      - name: epp
        image: us-central1-docker.pkg.dev/k8s-staging-images/gateway-api-inference-extension/epp:v20251119-2aaf2a6
        imagePullPolicy: Always
        args:
        - --pool-name
        - "inference-model-server-pool"
        - --pool-namespace
        - "inference-model-server"
        - --v
        - "4"
        - --zap-encoder
        - "json"
        - "--config-file"
        - "/config/default-plugins.yaml"
        ports:
        - containerPort: 9002
        - containerPort: 9003
        - name: metrics
          containerPort: 9090
        livenessProbe:
          grpc:
            port: 9003
            service: inference-extension
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          grpc:
            port: 9003
            service: inference-extension
          initialDelaySeconds: 5
          periodSeconds: 10
        volumeMounts:
        - name: plugins-config-volume
          mountPath: "/config"
      volumes:
      - name: plugins-config-volume
        configMap:
          name: plugins-config
---
apiVersion: v1
kind: Service
metadata:
  name: endpoint-picker-svc
  namespace: inference-model-server
spec:
  selector:
    app: inference-epp
  ports:
    - protocol: TCP
      port: 9002
      targetPort: 9002
      appProtocol: http2
  type: ClusterIP
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: plugins-config
  namespace: inference-model-server
data:
  default-plugins.yaml: |
    apiVersion: inference.networking.x-k8s.io/v1alpha1
    kind: EndpointPickerConfig
    plugins:
    - type: queue-scorer
    - type: kv-cache-utilization-scorer
    - type: prefix-cache-scorer
    schedulingProfiles:
    - name: default
      plugins:
      - pluginRef: queue-scorer
        weight: 2
      - pluginRef: kv-cache-utilization-scorer
        weight: 2
      - pluginRef: prefix-cache-scorer
        weight: 3
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: endpoint-picker-tls
  namespace: inference-model-server
spec:
  host: endpoint-picker-svc
  trafficPolicy:
      tls:
        mode: SIMPLE
        insecureSkipVerify: true
---
apiVersion: inference.networking.k8s.io/v1
kind: InferencePool
metadata:
  name: inference-model-server-pool
  namespace: inference-model-server
spec:
  selector:
    matchLabels:
      app: inference-model-server
  targetPorts:
    - number: 8000
  endpointPickerRef:
    name: endpoint-picker-svc
    port:
      number: 9002
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: inference-model-reader
  namespace: inference-model-server
rules:
- apiGroups: ["inference.networking.x-k8s.io"]
  resources: ["inferenceobjectives", "inferencepools"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["inference.networking.k8s.io"]
  resources: ["inferencepools"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: epp-to-inference-model-reader
  namespace: inference-model-server
subjects:
- kind: ServiceAccount
  name: default
  namespace: inference-model-server
roleRef:
  kind: Role
  name: inference-model-reader
  apiGroup: rbac.authorization.k8s.io
EOF
}

snip_configuring_an_inferencepool_3() {
kubectl wait -n istio-ingress --for=condition=programmed gateways.gateway.networking.k8s.io gateway
export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io gateway -n istio-ingress -ojsonpath='{.status.addresses[0].value}')
}

snip_configuring_an_inferencepool_4() {
curl -s -I "http://$INGRESS_HOST/v1/completions" -d '{"model": "reviews-1", "prompt": "What do reviewers think about The Comedy of Errors?", "max_tokens": 100, "temperature": 0}'
}

! IFS=$'\n' read -r -d '' snip_configuring_an_inferencepool_4_out <<\ENDSNIP
...
HTTP/1.1 200 OK
...
server: istio-envoy
...
{"choices":[{"finish_reason":"stop","index":0,"text":"Testing@, #testing 1$ ,2%,3^, [4"}],"created":1770406965,"id":"cmpl-5e508481-7c11-53e8-9587-972a3704724e","kv_transfer_params":null,"model":"reviews-1","object":"text_completion","usage":{"completion_tokens":16,"prompt_tokens":10,"total_tokens":26}}
ENDSNIP

snip_cleanup_1() {
kubectl delete deployment inference-model-server-deployment inference-endpoint-picker -n inference-model-server
kubectl delete httproute httproute-for-inferencepool -n inference-model-server
kubectl delete inferencepool inference-model-server-pool -n inference-model-server
kubectl delete gateways.gateway.networking.k8s.io gateway -n istio-ingress
kubectl delete ns istio-ingress inference-model-server
}

snip_cleanup_2() {
istioctl uninstall -y --purge
kubectl delete ns istio-system
}

snip_cleanup_3() {
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.4.0" | kubectl delete -f -
kubectl kustomize "github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd?ref=v1.0.1" | kubectl delete -f -
}
