---
title: Extensión de inferencia de la Gateway API de Kubernetes
description: Describe cómo configurar la extensión de inferencia de la Gateway API de Kubernetes con Istio.
weight: 60
keywords: [traffic-management,ingress, gateway-api-inference-extension, gateway-api]
owner: istio/wg-networking-maintainers
test: yes
---

Esta tarea describe cómo configurar Istio para usar la [Extensión de Inferencia de la Gateway API](https://gateway-api-inference-extension.sigs.k8s.io/) de Kubernetes.
La Extensión de Inferencia de la Gateway API tiene como objetivo mejorar y estandarizar el enrutamiento hacia modelos de IA auto-alojados en Kubernetes.
Utiliza CRDs de la [Gateway API de Kubernetes](/docs/tasks/traffic-management/ingress/gateway-api-inference-extension) y aprovecha el filtro [External Processing](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_proc_filter) de Envoy para convertir cualquier Gateway en un inference gateway.

## Recursos de la API

La Extensión de Inferencia de la Gateway API introduce dos tipos de API para ayudar con los desafíos únicos del enrutamiento de tráfico para workloads de inferencia:

[`InferencePool`](https://gateway-api-inference-extension.sigs.k8s.io/api-types/inferencepool/) representa una colección de backends para un workload de inferencia, y contiene una referencia a un servicio selector de endpoints asociado.
El filtro `ext_proc` de Envoy se usa para enrutar los requests entrantes al servicio selector de endpoints para tomar una decisión de enrutamiento informada hacia un backend óptimo en el pool de inferencia.

[`InferenceObjective`](https://gateway-api-inference-extension.sigs.k8s.io/api-types/inferenceobjective/) permite especificar los objetivos de servicio del request asociado a él.

## Configuración

1. Como las Gateway APIs son un prerequisito para las APIs de Extensión de Inferencia, instala tanto los CRDs de la Gateway API como los de la Extensión de Inferencia de la Gateway API si no están presentes:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    $ kubectl get crd inference.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd?ref={{< k8s_gateway_api_inference_extension_version >}}" | kubectl apply -f -; }
    {{< /text >}}

1. Instala Istio usando el perfil `minimal`:

    {{< text bash >}}
    $ istioctl install --set profile=minimal --set values.pilot.env.SUPPORT_GATEWAY_API_INFERENCE_EXTENSION=true --set values.pilot.env.ENABLE_GATEWAY_API_INFERENCE_EXTENSION=true -y
    {{< /text >}}

## Configurar un `InferencePool`

Para una guía detallada sobre cómo configurar un entorno de prueba local, consulta la [documentación de la Extensión de Inferencia de la Gateway API](https://gateway-api-inference-extension.sigs.k8s.io/guides/).

En este ejemplo, desplegaremos un servicio de modelo de inferencia usando un simulador vLLM, y usaremos un `InferencePool` y el selector de endpoints para enrutar los requests hacia backends individuales.

1. Despliega un simulador vLLM básico para actuar como nuestro workload de inferencia, y los recursos esenciales de la Gateway API:

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

1. Despliega el servicio selector de endpoints y crea un `InferencePool`:

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
    # Se requiere un DestinationRule para habilitar TLS entre el gateway y
    # el selector de endpoints.
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

1.  Establece la variable de entorno del Ingress Host:

    {{< text bash >}}
    $ kubectl wait -n istio-ingress --for=condition=programmed gateways.gateway.networking.k8s.io gateway
    $ export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io gateway -n istio-ingress -ojsonpath='{.status.addresses[0].value}')
    {{< /text >}}

1.  Envía un request de inferencia usando _curl_; deberías ver una respuesta exitosa del servidor de modelo backend:

    {{< text bash >}}
    $ curl -s -i "http://$INGRESS_HOST/v1/completions" -d '{"model": "reviews-1", "prompt": "What do reviewers think about The Comedy of Errors?", "max_tokens": 100, "temperature": 0}'
    ...
    HTTP/1.1 200 OK
    ...
    server: istio-envoy
    ...
    {"choices":[{"finish_reason":"stop","index":0,"text":"Testing@, #testing 1$ ,2%,3^, [4"}],"created":1770406965,"id":"cmpl-5e508481-7c11-53e8-9587-972a3704724e","kv_transfer_params":null,"model":"reviews-1","object":"text_completion","usage":{"completion_tokens":16,"prompt_tokens":10,"total_tokens":26}}
    {{< /text >}}

## Limpieza

1. Elimina los deployments y recursos de la Gateway API:

    {{< text bash >}}
    $ kubectl delete deployment inference-model-server-deployment inference-endpoint-picker -n inference-model-server
    $ kubectl delete httproute httproute-for-inferencepool -n inference-model-server
    $ kubectl delete inferencepool inference-model-server-pool -n inference-model-server
    $ kubectl delete gateways.gateway.networking.k8s.io gateway -n istio-ingress
    $ kubectl delete ns istio-ingress inference-model-server
    {{< /text >}}

1. Desinstala Istio:

    {{< text bash >}}
    $ istioctl uninstall -y --purge
    $ kubectl delete ns istio-system
    {{< /text >}}

1. Elimina los CRDs de la Gateway API y de la Extensión de Inferencia si ya no se necesitan:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd?ref={{< k8s_gateway_api_inference_extension_version >}}" | kubectl delete -f -
    {{< /text >}}
