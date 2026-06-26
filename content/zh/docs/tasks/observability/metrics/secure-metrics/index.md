---
title: 保护 Istio Sidecar 和网关的 Prometheus 数据抓取过程
description: 本任务演示了如何使用 Prometheus 和 Istio 双向 TLS（mTLS）在 Sidecar 模式下安全地抓取 Istio 工作负载和网关的指标数据。
weight: 50
keywords: [telemetry,metrics,prometheus,istio,mtls]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
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

## 配置 Prometheus 以进行 mTLS 抓取 {#configure-prometheus-for-mtls-scraping}

在抓取安全端口时，Prometheus 必须提供网状 CA 信任的有效证书。
提供这些凭证的最简单方法是将 Istio Sidecar 注入 Prometheus Pod
并使用 `OUTPUT_CERTS` 将工作负载证书写入共享卷。

`prometheus-secure-metrics` 示例（`samples/addons/extras/prometheus-secure-metrics.yaml`）是
`samples/addons/prometheus.yaml` 的独立替代品，
具有预配置的 Sidecar 注入、证书导出和 mTLS 抓取作业。

1. 部署 Prometheus，并预先配置 mTLS 抓取：

    {{< text bash >}}
    $ kubectl apply -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
    $ kubectl rollout status deployment/prometheus -n istio-system
    {{< /text >}}

    与标准 Prometheus 插件相比，该示例配置了以下关键设置：

    * `sidecar.istio.io/inject: "true"` **标签** - 覆盖 Prometheus Pod 上的 `"false"` 默认值，
      启用 sidecar 注入。
    * `OUTPUT_CERTS: /etc/istio-certs` - 指示 Sidecar 将工作负载证书、
      密钥和根 CA 写入共享卷，以便 Prometheus 可以读取它们以进行 mTLS 抓取。
    * `INBOUND_CAPTURE_PORTS: ""` - 防止 Sidecar 拦截入站 Prometheus 流量；
      Sidecar 仅用于证书配置。
    * `sidecar.istio.io/userVolumeMount` - 将证书卷挂载到 `istio-proxy` 容器中，
      以便它可以写入证书。相同的卷也被安装到`prometheus-server` 中，
      以便它可以读取它们。两个安装座都是必需的。
    * **抓取作业** - ConfigMap 包含两个预配置的 mTLS
      抓取作业（端口 `15092` 上的 `istio-secure-merged-metrics`，端口 `15091` 上的 `istio-secure-envoy-metrics`），
      它们通过 `prometheus.istio.io/secure-port` 和
      `prometheus.istio.io/secure-envoy-port` 注解发现 Pod。

    {{< tip >}}
    作为基于 Sidecar 的证书配置的替代方案，Istio 可以与
    [cert-manager](/zh/docs/ops/integrations/certmanager/) 集成，
    为 Prometheus 提供证书。在该模型中，不需要 Istio Sidecar。
    {{< /tip >}}

1. 验证 Prometheus Pod 已注入 Istio Sidecar 并且正在运行：

    {{< text bash >}}
    $ kubectl get pod -n istio-system -l app.kubernetes.io/name=prometheus
    NAME                          READY   STATUS    RESTARTS   AGE
    prometheus-6c647c84c8-gpxt4   3/3     Running   0          75s
    {{< /text >}}

## 启用本机 mTLS 指标端口（Istio 1.31+） {#enable-native-mtls-metrics-ports-istio-1-31}

Istio 1.31 引入了两个环境变量，将受 mTLS 保护的静态引导侦听器直接注入每个 Envoy 代理（Sidecar 代理和网关代理）：

| 变量 | 默认 | 描述 |
| -------- | ------- | ----------- |
| `ENVOY_SECURE_METRICS_PORT` | `0`（已禁用） | 添加一个 mTLS 侦听器，代理到仅 Envoy 统计端口（`15090`） |
| `ENVOY_SECURE_MERGED_METRICS_PORT` | `0`（已禁用） | 添加一个代理到合并指标端口的 mTLS 侦听器（`15020`，包括应用程序和代理统计信息） |

设置后，Envoy 在引导时添加配置的侦听器。抓取者必须出示网状 CA 信任的证书；
这可以是 Istio 工作负载证书（如上所述）或由受信任的 CA（例如 cert-manager）颁发的任何证书。

### 在 Sidecar 工作负载上启用 {#enable-on-a-sidecar-workload}

此示例使用 `httpbin` 作为工作负载。下面的清单基于
[httpbin]({{< github_tree >}}/samples/httpbin) 示例，并将安全指标注释添加到部署中。

1. 部署 `httpbin` 并启用安全指标端口：

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: httpbin
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin
      labels:
        app: httpbin
        service: httpbin
    spec:
      ports:
      - name: http
        port: 8000
        targetPort: 8080
      selector:
        app: httpbin
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: httpbin
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: httpbin
          version: v1
      template:
        metadata:
          labels:
            app: httpbin
            version: v1
          annotations:
            proxy.istio.io/config: |
              proxyMetadata:
                ENVOY_SECURE_METRICS_PORT: "15091"
                ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
            prometheus.io/path: "/stats/prometheus"
        spec:
          serviceAccountName: httpbin
          containers:
          - image: docker.io/mccutchen/go-httpbin:v2.15.0
            imagePullPolicy: IfNotPresent
            name: httpbin
            ports:
            - containerPort: 8080
    EOF
    {{< /text >}}

    * `ENVOY_SECURE_METRICS_PORT`（`15091`）是用于**仅 Envoy** 统计数据的 mTLS 侦听器端口。
    * `ENVOY_SECURE_MERGED_METRICS_PORT`（`15092`）是**合并**指标（Envoy + 应用程序 + 代理）的 mTLS 侦听器端口。

1. 设置以下验证步骤中使用的环境变量：

    {{< text bash >}}
    $ export HTTPBIN_POD=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].metadata.name}')
    $ export HTTPBIN_IP=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].status.podIP}')
    $ export PROM_POD=$(kubectl get pod -n istio-system -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')
    {{< /text >}}

1. 验证在 `httpbin` Sidecar 上配置了安全侦听器：

    {{< text bash >}}
    $ istioctl proxy-config listeners "$HTTPBIN_POD" -n default | grep -E "15090|15091|15092"
    0.0.0.0       15090 ALL                                                                                     Inline Route: /stats/prometheus*
    0.0.0.0       15091 Trans: tls                                                                              Inline Route: /stats/prometheus*
    0.0.0.0       15092 Trans: tls                                                                              Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    端口 `15091` 和 `15092` 上的 `Trans: tls` 确认 mTLS 侦听器处于活动状态。

### 在网关上启用 {#enable-on-a-gateway}

相同的变量在网关代理上的工作方式相同，因为它们使用相同的 `pilot-agent` 引导路径。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio API" category-value="istio-apis" >}}

1. 对入口网关 Deployment 进行补丁更新：

    {{< text bash >}}
    $ cat <<EOF > /tmp/gateway-secure-metrics-patch.yaml
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
    $ istioctl proxy-config listeners "$GW_POD" -n istio-system | grep -E "15090|15091|15092"
    0.0.0.0   15090 ALL        Inline Route: /stats/prometheus*
    0.0.0.0   15091 Trans: tls Inline Route: /stats/prometheus*
    0.0.0.0   15092 Trans: tls Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    端口 `15091` 和 `15092` 上的 `Trans: tls` 确认 mTLS 侦听器在网关上处于活动状态。

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

1. 修补 `Gateway` 资源以启用安全侦听器：

    {{< text bash >}}
    $ cat <<EOF > /tmp/gateway-api-secure-metrics-patch.yaml
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
    $ istioctl proxy-config listeners "$GW_POD" -n istio-system | grep -E "15090|15091|15092"
    0.0.0.0   15090 ALL        Inline Route: /stats/prometheus*
    0.0.0.0   15091 Trans: tls Inline Route: /stats/prometheus*
    0.0.0.0   15092 Trans: tls Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    端口 `15091` 和 `15092` 上的 `Trans: tls` 确认 mTLS 侦听器在网关上处于活动状态。

{{< /tab >}}

{{< /tabset >}}

### 全面加固的配置 {#fully-hardened-setup}

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
设置 `METRICS_LOCALHOST_ACCESS_ONLY` 后，将阻止从 Pod 外部对端口 `15090` 和 `15020` 的直接 HTTP 访问。
在应用此设置之前，请确保 Prometheus 配置为通过 mTLS 端口进行抓取。
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
从而激活 Sidecar 和网关上的安全侦听器。`components.ingressGateways.k8s.podAnnotations`
块将 Prometheus 发现注释添加到网关 Pod。对于 Sidecar 工作负载，
Sidecar 注入器会自动将 `prometheus.istio.io/secure-port` 设置为
`ENVOY_SECURE_MERGED_METRICS_PORT` 的值 - 不需要每个部署注释。
{{< /tip >}}

## 确认 {#verification}

### 使用 Prometheus 验证安全的指标抓取 {#verify-secure-metrics-scraping-with-prometheus}

完成配置后，验证 Prometheus 是否成功通过**双向 TLS** 抓取指标。

1. 使用 Prometheus Pod 的工作负载证书卷曲安全端口，验证 mTLS 抓取是否成功：

    {{< text bash >}}
    $ kubectl exec -n istio-system "$PROM_POD" -c istio-proxy -- \
        curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
        --cacert /etc/istio-certs/root-cert.pem \
        --cert /etc/istio-certs/cert-chain.pem \
        --key /etc/istio-certs/key.pem \
        --insecure \
        https://"$HTTPBIN_IP":15092/stats/prometheus
    200
    {{< /text >}}

    HTTP `200` 响应确认 Prometheus Pod 已成功完成与 httpbin 端口 `15092`
    的 mTLS 握手并检索指标。`--insecure` 标志仅跳过主机名验证 - Istio
    工作负载证书使用 SPIFFE URI SAN（例如 `spiffe://cluster.local/ns/default/sa/httpbin`）
    而不是 IP 地址，因此 curl 无法将 Pod IP 与证书进行匹配。
    相互 TLS 握手和证书交换仍然会发生，这就是为什么仍然需要 `--cacert`、`--cert` 和 `--key` 的原因。
    这也是 Prometheus 抓取作业使用 `insecure_skip_verify: true` 的原因。

1. 在 Prometheus UI 中验证抓取目标

    使用 `istioctl dashboard prometheus -n istio-system` 打开 Prometheus 仪表板，
    然后导航到 **Status → Targets**。验证 `istio-secure-merged-metrics`
    和 `istio-secure-envoy-metrics` 作业是否列出了状态为 **UP** 的 `httpbin` Pod 以及格式为
    `https://<pod-ip>:15092/stats/prometheus` 的端点。

1. 通过确认对安全端口的纯 HTTP 请求被拒绝来验证 mTLS 是否已强制执行：

    {{< text bash >}}
    $ kubectl exec -n default "$HTTPBIN_POD" -c istio-proxy -- curl -s --max-time 3 http://"$HTTPBIN_IP":15091/stats/prometheus
    upstream connect error or disconnect/reset before headers. reset reason: connection termination
    {{< /text >}}

    连接终止错误确认端口仅接受 TLS 连接 - 普通 HTTP 请求会立即被拒绝。

这证实了 Prometheus 正在通过本机安全端口使用 **HTTPS over Istio mTLS** 来抓取指标，
而不是直接访问明文遥测端口（`15020` 或 `15090`）。

## 清理 {#cleanup}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio API" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=none >}}
$ kubectl delete -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl label namespace default istio-injection-
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl delete gateway istio-ingressgateway -n istio-system
$ kubectl label namespace default istio-injection-
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 旧版变通方案（Istio < 1.31） {#legacy-workaround-istio-1-31}

如果您运行的 Istio 版本早于 1.31，则本机 env-var 方法不可用。
以下步骤演示了使用 Istio CRD 实现安全指标抓取的一种方法：
在端口 `15091`（暴露给 Prometheus）上创建安全 TLS 前端，该前端在内部路由到端口 `15020`
（合并指标 - Envoy + 应用程序 + 代理）或 `15090`（仅 Envoy 指标）。
抓取器通过 `ISTIO_MUTUAL` TLS 连接到 `15091`；
`ServiceEntry` 和 `VirtualService` 处理到明文后端的内部路由。

### 旧版本为 Sidecar 提供安全指标 {#legacy-secure-metrics-for-sidecars}

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

### 旧版本网关的安全指标 {#legacy-secure-metrics-for-gateways}

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

1. 为 Prometheus 发现的网关 Pod 添加注解：

    {{< text bash >}}
    $ kubectl annotate pod -n istio-system \
      -l app=istio-ingressgateway \
      prometheus.istio.io/secure-port=15091 \
      --overwrite
    {{< /text >}}

### 旧版本清理 {#legacy-cleanup}

{{< text bash >}}
$ kubectl delete sidecar secure-metrics -n default
$ kubectl delete gateway metrics-gateway -n istio-system
$ kubectl delete serviceentry gateway-admin -n istio-system
$ kubectl delete virtualservice gateway-metrics -n istio-system
$ kubectl delete -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl label namespace default istio-injection-
{{< /text >}}
