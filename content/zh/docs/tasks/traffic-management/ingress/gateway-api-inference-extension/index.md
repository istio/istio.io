---
title: Kubernetes Gateway API 推理扩展
description: 介绍如何使用 Istio 配置 Kubernetes Gateway API 推理扩展。
weight: 60
keywords: [traffic-management,ingress, gateway-api-inference-extension, gateway-api]
owner: istio/wg-networking-maintainers
test: yes
---

本任务描述了如何配置 Istio 以使用 Kubernetes [Gateway API 推理扩展](https://gateway-api-inference-extension.sigs.k8s.io/)。
Gateway API 推理扩展旨在改进和标准化 Kubernetes 中自托管 AI 模型的路由。它利用 [Kubernetes Gateway API](/zh/docs/tasks/traffic-management/ingress/gateway-api-inference-extension) 中的 CRD，
并借助 Envoy 的[外部处理](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_proc_filter)过滤器，
将任何 Gateway 扩展为推理网关。

## API 资源 {#api-resources}

Gateway API 推理扩展引入了两种 API 类型，以帮助应对推理工作负载流量路由的独特挑战：

[`InferencePool`](https://gateway-api-inference-extension.sigs.k8s.io/api-types/inferencepool/)
代表推理工作负载的后端集合，并包含对关联端点选择器的引用。
Envoy 的 `ext_proc` 过滤器用于将传入请求路由到端点选择器服务，以便根据路由信息将请求路由到推理池中的最佳后端。

[`InferenceObjective`](https://gateway-api-inference-extension.sigs.k8s.io/api-types/inferenceobjective/)
允许指定与其关联的请求的服务目标。

## 安装 {#setup}

1. 由于 Gateway API 是推理扩展 ​​API 的先决条件，
   因此如果 Gateway API 和 Gateway API 推理扩展 ​​CRD 不存在，请同时安装它们：

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    $ kubectl get crd inference.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd?ref={{< k8s_gateway_api_inference_extension_version >}}" | kubectl apply -f -; }
    {{< /text >}}

1. 使用 `minimal` 配置安装 Istio：

    {{< text bash >}}
    $ istioctl install --set profile=minimal --set values.pilot.env.SUPPORT_GATEWAY_API_INFERENCE_EXTENSION=true --set values.pilot.env.ENABLE_GATEWAY_API_INFERENCE_EXTENSION=true -y
    {{< /text >}}

## 配置一个 `InferencePool` {#configuring-an-nferencepool}

有关设置本地测试环境的详细指南，请参阅
[Gateway API 推理扩展文档](https://gateway-api-inference-extension.sigs.k8s.io/guides/)。

在这个例子中，我们将使用 vLLM 模拟器部署推理模型服务，
并使用 `InferencePool` 和端点选择器将请求路由到各个后端。

1. 部署一个基本的 vLLM 模拟器来模拟我们的推理工作负载，以及必要的 Gateway API 资源：

    {{< text bash >}}
    $ kubectl create namespace istio-ingress
    $ kubectl apply -f - <<EOF
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
    {{< /text >}}

1. 部署端点选择器服务并创建 `InferencePool`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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
    # 需要 DestinationRule 来启用网关和端点选择器之间的 TLS。
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
    {{< /text >}}

1. 设置 Ingress Host 环境变量：

    {{< text bash >}}
    $ kubectl wait -n istio-ingress --for=condition=programmed gateways.gateway.networking.k8s.io gateway
    $ export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io gateway -n istio-ingress -ojsonpath='{.status.addresses[0].value}')
    {{< /text >}}

1. 使用 **curl** 发送推理请求，您应该会看到来自后端模型服务器的成功响应：

    {{< text bash >}}
    $ curl -s -i "http://$INGRESS_HOST/v1/completions" -d '{"model": "reviews-1", "prompt": "What do reviewers think about The Comedy of Errors?", "max_tokens": 100, "temperature": 0}'
    ...
    HTTP/1.1 200 OK
    ...
    server: istio-envoy
    ...
    {"choices":[{"finish_reason":"stop","index":0,"text":"Testing@, #testing 1$ ,2%,3^, [4"}],"created":1770406965,"id":"cmpl-5e508481-7c11-53e8-9587-972a3704724e","kv_transfer_params":null,"model":"reviews-1","object":"text_completion","usage":{"completion_tokens":16,"prompt_tokens":10,"total_tokens":26}}
    {{< /text >}}

## 清理 {#cleanup}

1. 删除部署和 Gateway API 资源：

    {{< text bash >}}
    $ kubectl delete deployment inference-model-server-deployment inference-endpoint-picker -n inference-model-server
    $ kubectl delete httproute httproute-for-inferencepool -n inference-model-server
    $ kubectl delete inferencepool inference-model-server-pool -n inference-model-server
    $ kubectl delete gateways.gateway.networking.k8s.io gateway -n istio-ingress
    $ kubectl delete ns istio-ingress inference-model-server
    {{< /text >}}

1. 卸载 Istio：

    {{< text bash >}}
    $ istioctl uninstall -y --purge
    $ kubectl delete ns istio-system
    {{< /text >}}

1. 如果不再需要，请移除 Gateway API 和 Gateway API 推理扩展 CRD：

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd?ref={{< k8s_gateway_api_inference_extension_version >}}" | kubectl delete -f -
    {{< /text >}}
