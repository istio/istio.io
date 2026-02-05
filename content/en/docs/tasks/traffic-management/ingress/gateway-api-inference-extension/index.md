---
title: Kubernetes Gateway API Inference Extension
description: Describes how to configure the Kubernetes Gateway API Inference Extension with Istio.
weight: 60
keywords: [traffic-management,ingress, gateway-api-inference-extension, gateway-api]
owner: istio/wg-networking-maintainers
test: yes
---

This task describes how to configure Istio to use the Kubernetes [Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/).
The Gateway API Inference Extension aims to improve and standardize routing to self-hosted AI models in Kubernetes.
It utilizes CRDs from the [Kubernetes Gateway API](/docs/tasks/traffic-management/ingress/gateway-api-inference-extension) and leverages Envoy's [External Processing](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_proc_filter) filter to extend any Gateway into an inference gateway.

## API Resources

The Gateway API Inference Extension introduces two API types in order to assist with the unique challenges of traffic routing for inference workloads:

[InferencePool](https://gateway-api-inference-extension.sigs.k8s.io/api-types/inferencepool/) represents a collection of backends for an inference workload, and contains a reference to an associated endpoint picker service.
The Envoy `ext_proc` filter is used to route incoming requests to the endpoint picker service in order to make an informed routing decision to an optimal backend in the inference pool.

[InferenceObjective](https://gateway-api-inference-extension.sigs.k8s.io/api-types/inferenceobjective/) allows specifying the serving objectives of the request associated with it.

## Setup

1. As the Gateway APIs are a pre-requisite for Inference Extension APIs, install the Gateway API CRDs if they are not present:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

2. Install the Gateway API Inference Extension:

    {{< text bash >}}
    $ kubectl get crd inference.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd?ref={{< k8s_gateway_api_inference_extension_version >}}" | kubectl apply -f -; }
    {{< /text >}}

3. Install Istio using the `minimal` profile:

    {{< text bash >}}
    $ istioctl install --set profile=minimal --set values.pilot.env.SUPPORT_GATEWAY_API_INFERENCE_EXTENSION=true --set values.pilot.env.ENABLE_GATEWAY_API_INFERENCE_EXTENSION=true -y
    {{< /text >}}

## Configuring an InferencePool

For a detailed guide on setting up a local test environment, see the [Gateway API Inference Extension documentation](https://gateway-api-inference-extension.sigs.k8s.io/guides/).

In this example, we will deploy a mock inference model service and use an 'InferencePool' and the endpoint picker in order to route requests to individual backends.

1. Deploy a basic echo server to behave as our inference workload, and the essential Gateway API resources:

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
          - name: echoserver
            image: gcr.io/k8s-staging-gateway-api/echo-basic:v20251204-v1.4.1
            ports:
            - containerPort: 3000
            readinessProbe:
              httpGet:
                path: /
                port: 3000
              initialDelaySeconds: 3
              periodSeconds: 5
              failureThreshold: 2
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
            value: /get
    EOF
    {{< /text >}}


2. Deploy the endpoint picker service and create an InferencePool:

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
        - number: 3000
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
    {{< /text >}}

3.  Set the Ingress Host environment variable:

    {{< text bash >}}
    $ kubectl wait -n istio-ingress --for=condition=programmed gateways.gateway.networking.k8s.io gateway
    $ export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io gateway -n istio-ingress -ojsonpath='{.status.addresses[0].value}')
    {{< /text >}}

4.  Access the `httpbin` service using _curl_:

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST/get"
    ...
    HTTP/1.1 200 OK
    ...
    server: istio-envoy
    ...
    {{< /text >}}

5.  Access any other URL that has not been explicitly exposed. You should see an HTTP 404 error:

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## Cleanup

1. Remove deployments and Gateway API resources:

    {{< text bash >}}
    $ kubectl delete deployment inference-model-server-deployment inference-endpoint-picker -n inference-model-server
    $ kubectl delete httproute httproute-for-inferencepool -n inference-model-server
    $ kubectl delete inferencepool inference-model-server-pool -n inference-model-server
    $ kubectl delete gateways.gateway.networking.k8s.io gateway -n istio-ingress
    $ kubectl delete ns istio-ingress inference-model-server
    {{< /text >}}

2. Uninstall Istio:

    {{< text bash >}}
    $ istioctl uninstall -y --purge
    $ kubectl delete ns istio-system
    {{< /text >}}

3. Remove the Gateway API and Gateway API Inference Extension CRDs if they are no longer needed:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd?ref={{< k8s_gateway_api_inference_extension_version >}}" | kubectl delete -f -
    {{< /text >}}
