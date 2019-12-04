---
title: 可观测性问题
description: 处理 Telemetry 收集问题。
force_inline_toc: true
weight: 30
aliases:
    - /zh/docs/ops/troubleshooting/grafana
    - /zh/docs/ops/troubleshooting/missing-traces
---

## 期望的指标没有被收集{#expected-metrics-are-not-being-collected}

如果你期望上报的指标并没有被收集到，下面的过程将帮助您诊断该问题：

指标收集的预期流程如下：

1. Envoy 批量将请求中的属性异步报告给 Mixer。

1. Mixer 根据操作符配置将属性转换为实例。

1. Mixer 将实例交给 Mixer 适配器进行处理和后端存储。

1. 后端存储系统记录指标数据。

Mixer 安装中默认包含一个 Prometheus 适配器，适配器会收到一份用于生成[默认监控指标](/zh/docs/reference/config/policy-and-telemetry/metrics/)的配置。该配置使 Prometheus 实例可以抓取 Mixer 以获取指标。

如果 Istio Dashboard 或 Prometheus 查询未显示预期的指标，则上述流程的任何步骤都可能会出现问题。以下部分提供了对每个步骤进行故障排除的说明。

### （如果需要）验证 Istio CNI pod 正在运行{#verify-Istio-CNI-pods-are-running}

在 Kubernetes Pod 生命周期设置网络期间，Istio CNI 插件会对 Istio 网格 Pod 执行流量重定向，从而用户在 Istio  网格中部署 Pod 时不需要 [`NET_ADMIN`能力需求](/zh/docs/ops/deployment/requirements/)。 Istio CNI 插件主要用来替代 `istio-init` 容器的一些功能。

1. 验证 `istio-cni-node` pods 正在运行：

    {{< text bash >}}
    $ kubectl -n kube-system get pod -l k8s-app=istio-cni-node
    {{< /text >}}

1. 如果 `PodSecurityPolicy` 在您的集群上已经启用，请确保 `istio-cni` 服务账号可以使用具有 [`NET_ADMIN`能力需求](/zh/docs/ops/deployment/requirements/)的 `PodSecurityPolicy`。

### 确认 Mixer 可以收到指标报告的调用{#verify-mixer-is-receiving-report-calls}

Mixer 会生成指标来监控它自身行为。首先，检查这些指标：

1. `istio-telemetry` Deployment 对外暴露 Mixer 自监控 endpoint。在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward <istio-telemetry pod> 15014 &
    {{< /text >}}

1. 验证上报成功调用。通过 Mixer 自监控端点 (`http://localhost:15014/metrics`) 查询 `grpc_io_server_completed_rpcs`，您应该能看到类似的东西：

    {{< text plain >}}
    grpc_io_server_completed_rpcs{grpc_server_method="istio.mixer.v1.Mixer/Report",grpc_server_status="OK"} 2532
    {{< /text >}}

    如果你没有发现带有 `grpc_server_method="istio.mixer.v1.Mixer/Report"` 的 `grpc_io_server_completed_rpcs` 数据，说明 Envoy 没有调用 Mixer 上报遥测数据。

1.  在这种情况下，请确保已经将服务正确地集成到服务网格中。您可以使用[自动或手动注入 sidecar](/zh/docs/setup/additional-setup/sidecar-injection/) 来完成这个目标。

### 验证 Mixer 规则是否存在{#verify-the-mixer-rules-exist}

在 Kubernetes 环境中，执行以下命令：

{{< text bash >}}
$ kubectl get rules --all-namespaces
NAMESPACE      NAME                      AGE
istio-system   kubeattrgenrulerule       4h
istio-system   promhttp                  4h
istio-system   promtcp                   4h
istio-system   promtcpconnectionclosed   4h
istio-system   promtcpconnectionopen     4h
istio-system   tcpkubeattrgenrulerule    4h
{{< /text >}}

如果输出没有命名为 `promhttp` 或 `promtcp` 的规则，则缺少将指标实例发送到 Prometheus adapter 的 Mixer 配置。你必须提供将 Mixer 指标实例连接到 Prometheus handler 的规则配置。

作为参考，请参阅 [Prometheus 的默认规则]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)。

### 验证 Prometheus handler 配置是否存在{#verify-the-Prometheus-handler-configuration-exists}

1. 在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl get handlers.config.istio.io --all-namespaces
    NAMESPACE      NAME            AGE
    istio-system   kubernetesenv   4h
    istio-system   prometheus      4h
    {{< /text >}}

    如果您通过 Istio 1.1 或者更早版本升级的，执行以下命令：

    {{< text bash >}}
    $ kubectl get prometheuses.config.istio.io --all-namespaces
    NAMESPACE      NAME      AGE
    istio-system   handler   13d
    {{< /text >}}

1. 如果输出没有的 Prometheus handler 的配置，则必须重新使用合适的 handler 配置 Mixer。

有关参考，请参阅 [Prometheus 的默认 handler 配置]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)。

### 验证 Mixer 指标实例配置是否存在{#verify-mixer-metric-instances-configuration-exists}

1. 在 Kubernetes 环境下，执行以下命令：

    {{< text bash >}}
    $ kubectl get instances -o custom-columns=NAME:.metadata.name,TEMPLATE:.spec.compiledTemplate --all-namespaces
    {{< /text >}}

    如果您通过 Istio 1.1 或者更早版本升级的，执行以下命令：

    {{< text bash >}}
    $ kubectl get metrics.config.istio.io --all-namespaces
    {{< /text >}}

1. 如果输出未显示已配置的 Mixer 指标实例，则必须使用相应的实例配置重新配置 Mixer。

有关参考，请参阅 [Mixer 指标的默认实例配置]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)。

### 验证没有配置错误{#verify-there-are-no-known-configuration-errors}

1. 与`istio-telemetry` 自监控端点建立连接，按照上文[确认 Mixer 可以收到指标报告的调用](#verify-mixer-is-receiving-report-calls)的描述设置一个到 `istio-telemetry` 自监控端口的转发。

1. 确认以下的指标的最新的值是0：

    * `mixer_config_adapter_info_config_errors_total`

    * `mixer_config_template_config_errors_total`

    * `mixer_config_instance_config_errors_total`

    * `mixer_config_rule_config_errors_total`

    * `mixer_config_rule_config_match_error_total`

    * `mixer_config_unsatisfied_action_handler_total`

    * `mixer_config_handler_validation_error_total`

    * `mixer_handler_handler_build_failures_total`

在显示 Mixer 自监控 endpoint 的页面上，搜索上面列出的每个指标。如果所有配置正确，您应该不能找的那些指标值。

如果存在某个指标值，请确认该指标值的最大配置 ID 是0。这可以验证 Mixer 在处理最近提供配置过程中没有发生任何错误。

### 验证 Mixer 可以将指标实例发送到 Prometheus 适配器{#verify-Mixer-is-sending-Metric-instances-to-the-Prometheus-adapter}

1. 与`istio-telemetry` 自监控端点建立连接，按照上文[确认 Mixer 可以收到指标报告的调用](#verify-mixer-is-receiving-report-calls)的描述设置一个到 `istio-telemetry` 自监控端口的转发。

1. 通过 Mixer 自监控端口搜索 `mixer_runtime_dispatches_total`。应该输出类似如下结果：

    {{< text plain >}}
    mixer_runtime_dispatches_total{adapter="prometheus",error="false",handler="prometheus.istio-system",meshFunction="metric"} 2532
    {{< /text >}}

1. 确认 `mixer_runtime_dispatches_total` 的值是：

    {{< text plain >}}
    adapter="prometheus"
    error="false"
    {{< /text >}}

    如果你找不到发送到 Prometheus 适配器的记录，这很可能是配置不正确。请按照上面的步骤确认所有配置正确。

    如果发送到 Prometheus 适配器的报告有错误，可以通过检查 Mixer 的日志看到错误的来源。最可能的原因是配置问题，可以通过 handler 展示的 mixer_runtime_dispatch_count 指标看出问题。

1. 在 Kubernetes 环境，通过执行以下命令查看 mixer 日志：

    {{< text bash >}}
    $ kubectl -n istio-system logs <istio-telemetry pod> -c mixer
    {{< /text >}}

### 验证 Prometheus 配置{#verify-Prometheus-configuration}

1. 连接到 Prometheus UI 界面。

1. 验证是否可以通过 UI 成功查看到 Mixer。

1. 在 Kubernetes 环境中，使用以下命令设置端口转发：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

1. 访问 `http://localhost:9090/targets`

1. 确认目标的 `istio-mesh` 的状态是 UP。

1. 访问 `http://localhost:9090/config`

1. 确认存在以个类似如下的内容：

    {{< text plain >}}
    - job_name: 'istio-mesh'
    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    static_configs:
    - targets: ['istio-mixer.istio-system:42422']</td>
    {{< /text >}}

## 在 Mac 上本地运行 Istio 时，Zipkin 中没有出现任何跟踪信息{#no-traces-appearing-in-Zipkin-when-running-Istio-locally-on-Mac}

安装了 Istio 之后，看起来一切都在工作，但 Zipkin 中没有出现本该出现的跟踪信息。

这可能是由一个已知的 [Docker 问题](https://github.com/docker/for-mac/issues/1260)引起的，容器可能会与宿主机上的时间有明显偏差。如果是这种情况，可以尝试在 Zipkin 中选择一个非常长的日期范围，你会发现这些追踪轨迹提早出现了几天。

您还可以通过将 Docker 容器内的日期与外部进行比较来确认此问题：

{{< text bash >}}
$ docker run --entrypoint date gcr.io/istio-testing/ubuntu-16-04-slave:latest
Sun Jun 11 11:44:18 UTC 2017
{{< /text >}}

{{< text bash >}}
$ date -u
Thu Jun 15 02:25:42 UTC 2017
{{< /text >}}

要解决此问题，您需要在重新安装 Istio 之前关闭然后重新启动 Docker。

## 缺失 Grafana 输出{#missing-Grafana-output}

如果当您通过本地 web 客户端连接远程 Istio 不能获取 Grafana 输出，您需要验证客户端和服务端日期和时间是否一致。
Grafana 的输出会受到 Web 客户端（例如：Chrome）时间的影响。一个简单的解决方案，验证下 Kubernetes 集群内部使用的时间同步服务是否在正常运行，以及 Web 客户端是否正确的使用时间同步服务。NTP 和 Chrony 是常用的时间同步系统，特别是在有防火墙的工程实验环境中会出现问题。例如：在该场景中，NTP 没有被配置到正确的基于实验室的 NTP 服务。
