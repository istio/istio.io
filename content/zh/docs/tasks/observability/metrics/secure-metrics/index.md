---
title: 保护 Istio Sidecar 和网关的 Prometheus 数据抓取过程
description: 本任务演示了如何使用 Prometheus 和 Istio 双向 TLS（mTLS）在 Sidecar 模式下安全地抓取 Istio 工作负载和网关的指标数据。
weight: 50
keywords: [telemetry,metrics,prometheus,istio,mtls]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

本任务演示如何使用 Prometheus 通过 Istio mTLS **安全地抓取 Istio Sidecar 和网关的指标**。
默认情况下，Prometheus 通过 HTTP 从 Istio 工作负载和网关抓取指标。
在本任务中，您将配置 Istio 和 Prometheus，以便通过加密连接安全地抓取指标。
本文档重点介绍 Sidecar 和网关公开的 Envoy 和 Istio 生成的遥测数据。
它不涵盖工作负载本身发出的应用程序级指标。
有关 Prometheus 与 Istio 集成的更多信息（包括应用程序指标），
请参阅 [Prometheus 集成](/zh/docs/ops/integrations/prometheus/)文档。

## 了解默认指标抓取机制 {#understand-default-metrics-scraping}

默认情况下，Istio 会在 `/stats/prometheus` 端点上公开指标：

* 工作负载指标通过 Sidecar 遥测端口（`15020`）或仅限 Envoy 的端口（`15090`）提供。
* 网关指标通过网关 Pod 的遥测端口提供。
* 这些端点**不受双向 TLS 保护**，因此不建议直接通过 HTTPS 进行抓取。

此任务将默认抓取配置替换为**安全的 mTLS 配置**。
Prometheus 将使用安全的代理端口（`15091`），而不是直接访问遥测端口。

## 开始之前 {#before-you-begin}

* 使用**默认配置文件**在集群中安装 Istio（请参阅[安装 Istio](/zh/docs/setup)）。

## 安装 Prometheus 并启用安全抓取功能 {#install-prometheus-with-secure-scraping}

为了实现安全的指标抓取，Prometheus 需要 Istio Sidecar 通过 mTLS 对工作负载和网关进行身份验证。

1. 为 Prometheus 命名空间启用 Sidecar 注入功能。

    {{< text bash >}}
    $ kubectl create namespace prometheus
    $ kubectl label namespace monitoring istio-injection=enabled --overwrite
    {{< /text >}}

    这确保了任何创建或重启的 Prometheus Pod 都会自动包含一个 `istio-proxy` 边车容器。

    {{< tip >}}
    注入到 Prometheus Pod 中的 Istio Sidecar 仅用于为 mTLS 身份验证提供 Istio 工作负载证书。
    流量拦截功能已被明确禁用，Prometheus 将继续作为标准的 Kubernetes 工作负载运行。
    此外，Istio 还可以与 [cert-manager](/zh/docs/ops/integrations/certmanager/) 集成，
    为 Prometheus 提供证书。在这种模式下，无需使用 Istio Sidecar。
    {{< /tip >}}

1. 更新 Prometheus Deployment 的 Pod 模板。

    Istio 在 `samples/addons/prometheus.yaml` 路径下提供了一个 Prometheus 示例安装文件。
    修改 `samples/addons/prometheus.yaml` 文件，
    为 Prometheus 部署添加注解，以启用 Sidecar 注入、挂载 Istio 证书并配置代理：

    {{< text yaml >}}
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: prometheus
      namespace: monitoring
    spec:
      template:
        metadata:
          annotations:
            sidecar.istio.io/inject: "true"
            sidecar.istio.io/userVolumeMount: |
              [{"name": "istio-certs", "mountPath": "/etc/istio-certs", "readOnly": true}]
            proxy.istio.io/config: |
              proxyMetadata:
                OUTPUT_CERTS: /etc/istio-certs
              proxyMetadata.INBOUND_CAPTURE_PORTS: ""
        spec:
          containers:
          - name: prometheus
            image: prom/prometheus:latest
          volumes:
          - name: istio-certs
            secret:
              secretName: istio.default
    {{< /text >}}

    **备注：**

    * `OUTPUT_CERTS` 指示 Istio Sidecar 将证书写入何处供 Prometheus 使用。
    * `INBOUND_CAPTURE_PORTS: ""` 阻止 Sidecar 拦截 Prometheus 的流量。
    * `userVolumeMount` 将证书挂载到 Prometheus 容器内。

1. 修改 `samples/addons/prometheus.yaml` 文件中的 Prometheus 抓取任务配置，
   添加一个用于抓取安全指标的额外任务：

    {{< text yaml >}}
    - job_name: 'istio-secure-merged-metrics'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_istio_io_secure_port]
        action: keep
        regex: .+
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels:
        - __meta_kubernetes_pod_ip
        - __meta_kubernetes_pod_annotation_prometheus_istio_io_secure_port
        action: replace
        target_label: __address__
        regex: (.+);(.+)
        replacement: $1:$2
      scheme: https
      tls_config:
        ca_file: /etc/istio-certs/root-cert.pem
        cert_file: /etc/istio-certs/cert-chain.pem
        key_file: /etc/istio-certs/key.pem
        insecure_skip_verify: true
    {{< /text >}}

1. 验证 Prometheus Pod 是否包含 Istio Sidecar。

    {{< text bash >}}
    $ kubectl get pod <prometheus-pod> -n monitoring -o jsonpath='{.spec.containers[*].name}'
    {{< /text >}}

    您应该会看到一个名为 `istio-proxy` 的容器。

## Sidecar 的安全指标 {#secure-metrics-for-sidecars}

此任务使用 `httpbin` 作为示例工作负载来生成流量和指标。

1. 在默认命名空间中启用 Sidecar 注入并部署 httpbin。

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    $ kubectl apply -f @samples/httpbin/httpbin.yaml
    {{< /text >}}

1. 为 httpbin Pod 添加注解，以便 Prometheus 能够安全地抓取数据。

    确保 Prometheus 通过 mTLS 端口（`15091`）安全地抓取指标：

    {{< text bash >}}
    $ kubectl annotate pod -n default \
      -l app=httpbin \
      prometheus.io/scrape="true" \
      prometheus.io/path="/stats/prometheus" \
      prometheus.istio.io/secure-port="15091" \
      --overwrite
    {{< /text >}}

    这些注解使 Prometheus 能够发现 httpbin Pod 并通过安全监听器抓取指标。

1. 在端口 15091 上创建一个安全监听器。

    可以使用端口 `15091` 上的 Sidecar 监听器安全地公开工作负载指标。
    该监听器会将来自安全监听器的请求转发到 Sidecar 的遥测端口 `15020`。
    对于仅限 Envoy 的指标，请使用端口 `15090`。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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
        defaultEndpoint: 127.0.0.1:15020 # 对于 Envoy 专属指标，将端口更改为 15090。
    EOF
    {{< /text >}}

## 网关的安全指标 {#secure-metrics-for-gateways}

Istio 网关会暴露 Prometheus 可以抓取的指标。默认情况下，
这些指标分别位于端口 `15020`（用于合并遥测数据）和 `15090`（仅用于 Envoy 遥测数据），
并且默认情况下不受 mTLS 保护。以下步骤将配置使用 Istio mTLS 通过端口 15091 进行安全抓取。

1. 创建一个在端口 `15091` 上启用安全监听的 `Gateway`。

    我们创建一个 `Gateway`，用于暴露标准 HTTP 流量和一个专用的安全 HTTPS 端口来收集指标。
    HTTPS 服务器使用 `ISTIO_MUTUAL` TLS 模式，这样只有持有 Istio
    颁发证书的客户端（例如 Prometheus Sidecar）才能抓取指标。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: Gateway
    metadata:
      name: httpbin-gateway
      namespace: default
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts: ["*"]
      - port:
          number: 15091
          name: https-metrics
          protocol: HTTPS
        tls:
          mode: ISTIO_MUTUAL
        hosts: ["*"]
    EOF
    {{< /text >}}

1. 为网关的遥测端口（15020 或 15090）创建一个 `ServiceEntry`。

    除非网关的内部端口在服务网格中暴露出来，否则 Prometheus 无法直接访问这些端口。
    `ServiceEntry` 允许 Prometheus 将请求路由到服务网格内的这些端口。
    您可以选择 15020 端口用于合并遥测数据，或选择 15090 端口用于仅限 Envoy 的遥测数据。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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
    {{< /text >}}

1. 创建一个 `VirtualService` 来路由指标数据。

    `VirtualService` 将来自安全监听器 (15091) 的请求映射到指向遥测端口（15020 或 15090）的 `ServiceEntry`。
    这确保了发送到 `https://<gateway-ip>:15091/stats/prometheus` 的指标请求能够在服务网格内部正确路由。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: gateway-metrics
      namespace: default
    spec:
      hosts: ["*"]
      gateways: [httpbin-gateway]
      http:
      - match:
        - uri:
            prefix: /stats/prometheus
        route:
        - destination:
            host: gateway-admin.local
            port:
              number: 15020  # 对于 Envoy 专属指标，将端口更改为 15090。
    EOF
    {{< /text >}}

1. 对 `Gateway` Pod 进行注释

    {{< text bash >}}
    $ kubectl annotate pod -n istio-system <ingress-pod> prometheus.istio.io/secure-port=15091 --overwrite
    {{< /text >}}

## 验证 {#verification}

### 使用 Prometheus 验证安全指标抓取 {#verify-secure-metrics-scraping-with-prometheus}

完成配置后，请验证 Prometheus 是否已通过**双向 TLS** 成功从 Istio 工作负载和网关收集指标。

1. 打开 Prometheus Dashboard。

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    此命令会在您的默认浏览器中打开 Prometheus Dashboard。

1. 验证抓取目标

    1. 在 Prometheus 用户界面中，导航至 **Status → Targets**。
    1. 找到名为 `istio-secure-merged-metrics` 的 Job，这正是我们在配置新的 Prometheus 抓取 Job 时使用的名称。

    验证 httpbin 工作负载和 Istio Ingress Gateway 的目标是否已列出，
    并且其端点类似于：`https://<pod-ip>:15091/stats/prometheus UP`。每个目标的状态都应显示为 **UP**。

这证实了 Prometheus 正在通过 Istio mTLS 使用 HTTPS 协议，
经由安全前端端口（15091）抓取指标，而不是直接访问遥测端口（15020 或 15090）。
