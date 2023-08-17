---
title: Prometheus
description: 如何集成 Prometheus。
weight: 30
keywords: [integration,prometheus]
owner: istio/wg-environments-maintainers
test: n/a
---

[Prometheus](https://prometheus.io/) 是一个开源的监控系统、
时间序列数据库。您可以利用 Prometheus 与 Istio 集成来收集指标，
通过这些指标判断 Istio 和网格内的应用的运行状况。您可以使用
[Grafana](/zh/docs/ops/integrations/grafana/) 和
[Kiali](/zh/docs/tasks/observability/kiali/) 来可视化这些指标。

## 安装 {#installation}

### 选项1：快速开始 {#option-1-quick-start}

Istio 提供了一个简单地安装示例来快速安装、运行 Prometheus：

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/prometheus.yaml
{{< /text >}}

这将会在您的集群中部署 Prometheus。这仅用于展示，不会针对性能和安全性进行调整。

{{< warning >}}
快速开始的配置仅适合小型集群和短期监控，不适用于大型网格和长时间的监控。
特别的是，增加标签将会增加指标的基数，需要大量内存。并且，当尝试确定流量随时间的趋势变化，
需要获取历史数据。
{{< /warning >}}

### 选项2：自定义安装 {option-2-customizable-install}

阅读 [Prometheus 文档](https://www.prometheus.io/)来在您的环境中安装、
部署 Prometheus。阅读 [Configuration](#configuration)
来了解更多关于配置、部署 Prometheus 抓取更多 Istio 指标的信息。

## 配置 {#configuration}

在 Istio 网格内，每个组件都有一个对外暴露指标的接口。Prometheus
通过抓取这些接口的指标来收集数据。

通过 [Prometheus 配置文件](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)进行配置，
该配置可以控制要查询的接口、端口、路径、TLS 配置等。

要收集整个网格的指标，请配置 Prometheus：

1. 控制平面（`istiod` Deployment）
1. 入口和出口网关
1. Ingress and Egress gateways
1. Envoy Sidecar
1. 用户应用程序（如果这些应用程序向 Prometheus 暴露指标的话）

为了简化指标配置，Istio 提供了两种操作模式：

### 选项 1：指标合并 {#option-1-metrics-merging}

为了简化配置，Istio 可以通过 `prometheus.io` 注解来控制指标的获取。
他允许 Istio 通过 [Helm `stable/prometheus`](https://github.com/helm/charts/tree/master/stable/prometheus)
的 chart 使用标准配置获取数据，开箱即用。

{{< tip >}}
尽管 `prometheus.io` 并不是 Prometheus 的核心注解，
但是该注解已经成为获取指标的标准注解。
{{< /tip >}}

该选项默开启但是允许在[安装](/zh/docs/setup/install/istioctl/)时通过
`--set meshConfig.enablePrometheusMerge=false` 关闭。当开启后，
会将适当的 `prometheus.io` 注解添加到所有的数据平面容器中来设置指标收集。
如果这些注解已经存在，他们将会被覆盖。使用该选项，Envoy sidecar 将 Istio
的指标与应用程序的指标合并。合并的指标将由 `:15020/stats/prometheus` 收集。

该选项以纯文本的形式显示所有指标。

以下情况，该选项无法满足：

* 您需要使用 TLS 收集指标。
* 您的应用程序暴露的指标与 Istio 暴露的指标重名。例如，
  您的应用程序暴露一个叫做 `istio_request_total` 的指标。
  如果应用程序本身正在运行 Envoy，这就有可能发生。
* 您的 Prometheus Deployment 没有配置通过 `prometheus.io` 注解抓取指标。

如果需要，可以在 Pod 上添加 `prometheus.istio.io/merge-metrics: "false"`
来禁用此功能。

### 选项2：自定义收集配置 {#option-2-customized-scraping-configurations}

要将现有的 Prometheus 示例配置为抓取 Istio 生成的统计信息，需要增加一些 Job。

* 要获取 `Istiod` 的状态，可以添加以下示例来抓取 `http-monitoring` 端口：

{{< text yaml >}}
- job_name: 'istiod'
  kubernetes_sd_configs:
  - role: endpoints
    namespaces:
      names:
      - istio-system
  relabel_configs:
  - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
    action: keep
    regex: istiod;http-monitoring
{{< /text >}}

* 要抓取 Envoy 的状态，包括 Sidecar 的代理和网关的代理，
  可以将以下 Job 放在 `-envoy-prom` 的结尾，添加到收集端口：

{{< text yaml >}}
    - job_name: 'envoy-stats'
      metrics_path: /stats/prometheus
      kubernetes_sd_configs:
      - role: pod

      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_container_port_name]
        action: keep
        regex: '.*-envoy-prom'
{{< /text >}}

* 对于应用程序的状态，如果禁止
  [Strict mTLS](/zh/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode)，
  您现有的收集配置仍然可以使用。否则需要将 Prometheus
  配置为[使用 Istio 证书收集](#tls-settings)。

#### TLS 设置 {#TLS-settings}

控制平面，网关和 Envoy Sidecar 指标将会作为明文收集。但是，应用程序指标将遵循
Istio 为任何工作负载进行的配置。特别是如果启用了
[Strict mTLS](/zh/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode)，
则需要将 Prometheus 配置为使用 Istio 证书收集指标。

为 Prometheus 设置 Istio 证书的另一种方式是 Sidecar，该
Sidecar 将会转发 SDS 证书并将其输出到可以与 Prometheus
共享的 volume 中。然而，Sidecar 不应该拦截 Prometheus 的请求，
因为 Prometheus 的端口的访问模式与 Istio 的 Sidecar 代理模型不兼容。

为此，请在 Prometheus 服务器容器上挂载证书 volume：

{{< text yaml >}}
containers:
  - name: prometheus-server
    ...
    volumeMounts:
      mountPath: /etc/prom-certs/
      name: istio-certs
volumes:
  - emptyDir:
      medium: Memory
    name: istio-certs
{{< /text >}}

然后，将一下注解添加到 Prometheus Deployment 的 Pod Template
中，并且使用 [Sidecar 注入](/zh/docs/setup/additional-setup/sidecar-injection/)。
这会将 Sidecar 配置为共享 volume 并写入证书，但是不会配置流量的重定向。

{{< text yaml >}}
spec:
  template:
    metadata:
      annotations:
        traffic.sidecar.istio.io/includeInboundPorts: ""   # 不拦截任何入口流量
        traffic.sidecar.istio.io/includeOutboundIPRanges: ""  # 不拦截任何出口流量
        proxy.istio.io/config: |  # 配置一个环境变量 `OUTPUT_CERTS` 来讲证书写入指定文件夹内
          proxyMetadata:
            OUTPUT_CERTS: /etc/istio-output-certs
        sidecar.istio.io/userVolumeMount: '[{"name": "istio-certs", "mountPath": "/etc/istio-output-certs"}]' # 在 Sidecar 挂载共享 volume
{{< /text >}}

最后，按如下所示的设置收集 TLS 指标：

{{< text yaml >}}
scheme: https
tls_config:
  ca_file: /etc/prom-certs/root-cert.pem
  cert_file: /etc/prom-certs/cert-chain.pem
  key_file: /etc/prom-certs/key.pem
  insecure_skip_verify: true  # Prometheus 不支持 Istio 安全命名，因此跳过验证目标 Pod 证书。
{{< /text >}}

## 最佳实践 {#best-practices}

对于大型网格，高级配置可以帮助扩展 Prometheus。
更多有关信息请查看[使用 Prometheus 监控 production-scale](/zh/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring)。
