---
title: 保护 Istio Sidecar 和网关的 Prometheus 数据抓取过程
description: 本任务演示了如何使用 Prometheus 和 Istio 双向 TLS（mTLS）在 Sidecar 模式下安全地抓取 Istio 工作负载和网关的指标数据。
weight: 50
keywords: [telemetry,metrics,prometheus,istio,mtls,secure-metrics]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

此任务演示如何通过 **Istio mTLS** 使用 Prometheus **安全地抓取 Istio Sidecar 和网关指标**。
默认情况下，Prometheus 通过纯 HTTP 从 Istio 工作负载和网关中抓取指标。
在此任务中，您将配置 Istio 和 Prometheus，以便通过相互验证的 TLS 连接安全地抓取指标。
本文档重点介绍由 Sidecar 和网关公开的 Envoy 和 Istio 生成的遥测数据。
有关 Prometheus 与 Istio 的一般集成（包括应用程序指标），
请参阅 [Prometheus 集成](/zh/docs/ops/integrations/prometheus/)文档。

{{< tip >}}
从 Istio 1.31 开始，可以原生启用安全 mTLS 指标端口。
对于旧版本的 Istio，请参阅[旧版解决方法](#legacy-workaround-istio--131)部分。
{{< /tip >}}

## 了解默认指标抓取机制 {#understand-default-metrics-scraping}

默认情况下，Istio 会在 `/stats/prometheus` 端点上公开指标：

* 工作负载指标通过 Sidecar 遥测端口（`15020`）或仅限 Envoy 的端口（`15090`）提供。
* 网关指标通过网关 Pod 的遥测端口提供。
* 这些端点**不受双向 TLS 保护**，因此不建议直接通过 HTTPS 进行抓取。

此任务中的方法添加了专用的 mTLS 保护侦听器，
以便 Prometheus 抓取加密的、相互验证的连接。

## 开始之前 {#before-you-begin}

* 使用**默认配置文件**在集群中安装 Istio（请参阅[安装 Istio](/zh/docs/setup)）。

## 配置 Prometheus 进行 mTLS 抓取 {#configure-prometheus-for-mtls-scraping}

在抓取安全端口时，Prometheus 必须提供网状 CA 信任的有效证书。
提供这些凭证的最简单方法是将 Istio Sidecar 注入 Prometheus Pod
并使用 `OUTPUT_CERTS` 将工作负载证书写入共享卷。

以下步骤使用 Istio 示例 Prometheus 插件 (`samples/addons/prometheus.yaml`)，
它将 Prometheus 部署到 `istio-system` 命名空间中。
Sidecar 通过 pod 级注释注入，因此不需要命名空间级注入标签。

1. 部署 Prometheus 并注入 Sidecar

    应用 Istio 示例 Prometheus 插件，然后修补 `prometheus` 部署以启用 Sidecar 注入和证书导出：

    这确保了任何创建或重启的 Prometheus Pod 都会自动包含一个 `istio-proxy` 边车容器。

    {{< text bash >}}
    $ kubectl apply -f @samples/addons/prometheus.yaml@
    $ cat <<'EOF' > /tmp/prometheus-secure-patch.yaml
    spec:
      template:
        metadata:
          labels:
            sidecar.istio.io/inject: "true"
          annotations:
            sidecar.istio.io/userVolumeMount: '[{"name": "istio-certs", "mountPath": "/etc/istio-certs"}]'
            proxy.istio.io/config: |
              proxyMetadata:
                OUTPUT_CERTS: /etc/istio-certs
                INBOUND_CAPTURE_PORTS: ""
        spec:
          containers:
          - name: prometheus-server
            volumeMounts:
            - name: istio-certs
              mountPath: /etc/istio-certs
          volumes:
          - name: istio-certs
            emptyDir: {}
    EOF
    $ kubectl patch deployment prometheus -n istio-system --type=strategic --patch-file=/tmp/prometheus-secure-patch.yaml
    $ kubectl rollout status deployment/prometheus -n istio-system
    {{< /text >}}

    {{< tip >}}
    注入到 Prometheus Pod 中的 Istio Sidecar 仅用于为
    mTLS 身份验证提供 Istio 工作负载证书。通过 INBOUND_CAPTURE_PORTS: ""`
    显式禁用流量拦截，并且 Prometheus 继续作为标准 Kubernetes 工作负载运行。
    作为替代方案，Istio 可以与 [cert-manager](/zh/docs/ops/integrations/certmanager/) 集成，
    为 Prometheus 提供证书。在该模型中，不需要 Istio Sidecar。
    {{< /tip >}}

    **注意：**

    * `sidecar.istio.io/inject: "true"` **标签**覆盖 Prometheus Helm Chart
      设置的 `"false"` 标签，从而启用 sidecar 注入。
    * `OUTPUT_CERTS` 指示 Sidecar 将工作负载证书、密钥和根 CA
      写入到 `/etc/istio-certs` 中，以便 Prometheus 可以读取它们。
    * `INBOUND_CAPTURE_PORTS: ""` 防止 Sidecar 拦截入站 Prometheus 流量。
    * `userVolumeMount` 将证书目录挂载到 Sidecar (`istio-proxy`) 中，
      以便它可以通过 `OUTPUT_CERTS` 写入证书。 `prometheus-server`
      上的显式 `volumeMounts` 条目将相同的卷安装到 Prometheus 容器中，
      以便它可以读取这些证书。两个安装座都是必需的。

1. 向 Prometheus 配置中添加一个安全抓取任务

    编辑 `istio-system` 命名空间中的 `prometheus` ConfigMap，
    并将以下作业添加到 `scrape_configs`：

    {{< text bash >}}
    $ kubectl edit configmap prometheus -n istio-system
    {{< /text >}}

    在 `prometheus.yml` 中找到 `scrape_configs:` 键，然后在其下面插入作业：

    {{< text yaml >}}
    - job_name: 'istio-secure-metrics'
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
      - source_labels: [__meta_kubernetes_pod_ip, __meta_kubernetes_pod_annotation_prometheus_istio_io_secure_port]
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

1. 验证 Prometheus Pod 已注入 Istio Sidecar 并且正在运行：

    {{< text bash >}}
    $ kubectl get pod -n istio-system -l app.kubernetes.io/name=prometheus
    NAME                          READY   STATUS    RESTARTS   AGE
    prometheus-6c647c84c8-gpxt4   3/3     Running   0          75s
    {{< /text >}}

## 启用本机 mTLS 指标端口（Istio 1.31+） {#enable-native-mtls-metrics-ports-istio-131)

Istio 1.31 引入了两个环境变量，将受 mTLS 保护的静态引导侦听器直接注入每个 Envoy 代理（Sidecar 代理和网关代理）：

| 变量 | 默认值 | 描述 |
| -------- | ------- | ----------- |
| `ENVOY_SECURE_METRICS_PORT` | `0`（已禁用） | 添加一个 mTLS 侦听器，代理仅 Envoy 统计端口（`15090`） |
| `ENVOY_SECURE_MERGED_METRICS_PORT` | `0`（已禁用） | 添加一个代理到合并指标端口的 mTLS 侦听器（`15020`，包括应用程序和代理统计信息） |

设置后，Envoy 在引导时添加配置的侦听器。抓取者必须出示网状 CA 信任的证书；
这可以是 Istio 工作负载证书（如上所述）或由受信任的 CA（例如 cert-manager）颁发的任何证书。

### 在 Sidecar 工作负载上启用 {#enable-on-a-sidecar-workload}

此示例使用 `httpbin` 作为工作负载。

1. 部署 `httpbin` 并启用安全指标端口

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. 修补 `httpbin` 部署以启用安全侦听器

    {{< text bash >}}
    $ cat <<EOF > /tmp/httpbin-secure-metrics-patch.yaml
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
    $ kubectl patch deployment httpbin -n default --type=merge --patch-file=/tmp/httpbin-secure-metrics-patch.yaml
    {{< /text >}}

    * `ENVOY_SECURE_METRICS_PORT` 的值 (`15091`) 是**仅 Envoy** 统计数据的 mTLS 侦听器端口。
    * `ENVOY_SECURE_MERGED_METRICS_PORT` 的值 (`15092`) 是**合并**指标（Envoy + 应用程序 + 代理）的 mTLS 侦听器端口。

1. 验证 `httpbin` Sidecar 上是否配置了安全监听器：

    {{< text bash >}}
    $ export HTTPBIN_POD=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].metadata.name}')
    $ istioctl proxy-config listeners $HTTPBIN_POD -n default | grep -E "15090|15091|15092"
    0.0.0.0       15090 ALL                                                                                     Inline Route: /stats/prometheus*
    0.0.0.0       15091 Trans: tls                                                                              Inline Route: /stats/prometheus*
    0.0.0.0       15092 Trans: tls                                                                              Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    端口 `15091` 和 `15092` 上的 `Trans: tls` 确认 mTLS 侦听器处于活动状态。

### 在网关上启用 {#enable-on-a-gateway}

相同的变量在网关代理上的工作方式相同，因为它们使用相同的 `pilot-agent` 引导路径。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio API" category-value="istio-apis" >}}

1. 修补入口网关部署：

    {{< text bash >}}
    $ cat <<'EOF' > /tmp/gateway-secure-metrics-patch.yaml
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
    $ kubectl patch deployment istio-ingressgateway -n istio-system --type=strategic --patch-file=/tmp/gateway-secure-metrics-patch.yaml
    $ kubectl rollout status deployment/istio-ingressgateway -n istio-system
    {{< /text >}}

1. 验证入口网关上是否配置了安全侦听器：

    {{< text bash >}}
    $ export GW_POD=$(kubectl get pod -n istio-system -l app=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}')
    $ istioctl proxy-config listeners $GW_POD -n istio-system | grep -E "15090|15091|15092"
    0.0.0.0   15090 ALL        Inline Route: /stats/prometheus*
    0.0.0.0   15091 Trans: tls Inline Route: /stats/prometheus*
    0.0.0.0   15092 Trans: tls Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    端口 `15091` 和 `15092` 上的 `Trans: tls` 确认 mTLS 侦听器在网关上处于活动状态。

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

1. 修补 `Gateway` 资源以启用安全侦听器：

    {{< text bash >}}
    $ cat <<'EOF' > /tmp/gateway-api-secure-metrics-patch.yaml
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
    $ kubectl patch gateway istio-ingressgateway -n istio-system --type=merge --patch-file=/tmp/gateway-api-secure-metrics-patch.yaml
    {{< /text >}}

1. 验证网关 Pod 上是否配置了安全侦听器：

    {{< text bash >}}
    $ export GW_POD=$(kubectl get pod -n istio-system -l gateway.networking.k8s.io/gateway-name=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}')
    $ istioctl proxy-config listeners $GW_POD -n istio-system | grep -E "15090|15091|15092"
    0.0.0.0   15090 ALL        Inline Route: /stats/prometheus*
    0.0.0.0   15091 Trans: tls Inline Route: /stats/prometheus*
    0.0.0.0   15092 Trans: tls Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    端口 `15091` 和 `15092` 上的 `Trans: tls` 确认 mTLS 侦听器在网关上处于活动状态。

{{< /tab >}}

{{< /tabset >}}

### 完全强化的设置 {#fully-hardened-setup}

对于完全强化的部署，请将安全端口与 `METRICS_LOCALHOST_ACCESS_ONLY` 结合起来。
这将底层明文端口（`15090` 和 `15020`）限制为本地主机，
使 mTLS 侦听器成为**唯一**外部可访问的抓取表面：

{{< text bash >}}
$ cat <<EOF > /tmp/httpbin-hardened-patch.yaml
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
$ kubectl patch deployment httpbin -n default --type=merge --patch-file=/tmp/httpbin-hardened-patch.yaml
{{< /text >}}

{{< warning >}}
设置 `METRICS_LOCALHOST_ACCESS_ONLY` 后，将阻止从 Pod 外部对端口
`15090` 和 `15020` 的直接 HTTP 访问。在应用此设置之前，请确保 Prometheus 配置为通过 mTLS 端口进行抓取。
{{< /warning >}}

{{< tip >}}
要在网格范围内应用这些设置而不修补单个部署，请在安装过程中使用 `IstioOperator`：

{{< text bash >}}
$ cat <<EOF > ./istio-secure-metrics.yaml
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
$ istioctl install -f ./istio-secure-metrics.yaml
{{< /text >}}

以这种方式安装时，`istioctl` 会直接使用 `proxyMetadata` 值作为容器环境变量渲染网关部署，
从而激活 Sidecar 和网关上的安全侦听器。 `components.ingressGateways.k8s.podAnnotations`
块将 Prometheus 发现注释添加到网关 Pod。对于 Sidecar 工作负载，
Sidecar 注入器会自动将 `prometheus.istio.io/secure-port` 设置为
`ENVOY_SECURE_MERGED_METRICS_PORT` 的值 — 不需要每个部署注释。
{{< /tip >}}

## 验证 {#verification}

### 使用 Prometheus 验证安全指标抓取 {#verify-secure-metrics-scraping-with-prometheus}

完成配置后，验证 Prometheus 是否成功通过**双向 TLS** 抓取指标。

1. 打开 Prometheus 仪表板

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    此命令在默认浏览器中打开 Prometheus 仪表板。

1. 验证抓取目标

    1. 在 Prometheus UI 中，导航至**状态 → 目标**。
    1. 找到名为 `istio-secure-metrics` 的 Job。

    请确认 httpbin 工作负载和 Istio Ingress Gateway 的目标已列出，
    其端点类似于 `https://<pod-ip>:15092/stats/prometheus`，且状态为 **UP**。

1. 通过确认对安全端口的纯 HTTP 请求被拒绝来验证 mTLS 是否已强制执行：

    {{< text bash >}}
    $ export HTTPBIN_POD=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].metadata.name}')
    $ export HTTPBIN_IP=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].status.podIP}')
    $ kubectl exec -n default $HTTPBIN_POD -c istio-proxy -- curl -s --max-time 3 http://$HTTPBIN_IP:15091/stats/prometheus
    upstream connect error or disconnect/reset before headers. reset reason: connection termination
    {{< /text >}}

    连接终止错误确认端口仅接受 TLS 连接 - 普通 HTTP 请求会立即被拒绝。

这证实了 Prometheus 正在通过本机安全端口使用 **HTTPS over Istio mTLS** 来抓取指标，
而不是直接访问明文遥测端口（`15020` 或 `15090`）。

## 旧版解决方法（Istio < 1.31） {#legacy-workaround-istio--131}

如果您运行的 Istio 版本早于 1.31，则本机 env-var 方法不可用。
以下步骤演示了使用 Istio CRD 实现安全指标抓取的一种方法：
在端口 `15091`（暴露给 Prometheus）上创建安全 TLS 前端，
该前端在内部路由到端口 `15020`（合并指标 - Envoy + 应用程序 + 代理）或 `15090`（仅 Envoy 指标）。
抓取器通过 `ISTIO_MUTUAL` TLS 连接到 `15091`；
`ServiceEntry` 和 `VirtualService` 处理到明文后端的内部路由。

### 旧版：Sidecar 的安全指标 {#legacy-secure-metrics-for-sidecars}

1. 部署 `httpbin` 并在端口 `15091` 上创建一个带有安全入口侦听器的 `Sidecar` 资源：

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

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
        defaultEndpoint: 127.0.0.1:15020 # Change to 15090 for Envoy-only metrics
    EOF
    {{< /text >}}

1. 注释 Prometheus 发现的工作负载 Pod：

    {{< text bash >}}
    $ kubectl annotate pod -n default \
      -l app=httpbin \
      prometheus.io/scrape="true" \
      prometheus.io/path="/stats/prometheus" \
      prometheus.istio.io/secure-port="15091" \
      --overwrite
    {{< /text >}}

### 旧版：网关的安全指标 {#legacy-secure-metrics-for-gateways}

1. 在端口 `15091` 上创建一个带有安全 HTTPS 侦听器的 `Gateway`：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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
    {{< /text >}}

1. 创建一个 `ServiceEntry` 以公开网格内的网关遥测端口：

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

1. 创建一个 `VirtualService` 将请求从安全侦听器路由到遥测端口：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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
    {{< /text >}}

1. 注释 Prometheus 发现的网关 Pod：

    {{< text bash >}}
    $ kubectl annotate pod -n istio-system \
      -l app=istio-ingressgateway \
      prometheus.istio.io/secure-port=15091 \
      --overwrite
    {{< /text >}}

## 清理 {#cleanup}

### 清理：本机 mTLS 指标端口（Istio 1.31+） {#cleanup-native-mTLS-metrics-ports-istio-131}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio API" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/addons/prometheus.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ killall istioctl
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -f @samples/addons/prometheus.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl delete gateway istio-ingressgateway -n istio-system
$ killall istioctl
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 清理：旧版解决方法（Istio < 1.31） {#cleanup-legacy-workaround-istio-131}

{{< text bash >}}
$ kubectl delete sidecar secure-metrics -n default
$ kubectl delete gateway metrics-gateway -n istio-system
$ kubectl delete serviceentry gateway-admin -n istio-system
$ kubectl delete virtualservice gateway-metrics -n istio-system
$ kubectl delete -f @samples/addons/prometheus.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
