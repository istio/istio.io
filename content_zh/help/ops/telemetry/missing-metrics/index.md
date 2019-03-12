---
title: 查看不到指标
description:
weight: 10
---

以下过程可帮助你诊断你希望看到某些指标但却收集不到的问题。

收集指标的正确流程为：

1. Envoy 批量将请求中的属性异步报告给 Mixer。

1. Mixer 根据操作者提供的配置，将属性转换为实例。

1. Mixer 将实例交给 mixer adapter 进行处理和后端存储。

1. 后端存储系统记录指标数据。

Mixer 默认安装了一套包括 Prometheus adapter 和用于生成一组[默认指标的配置](/zh/docs/reference/config/policy-and-telemetry/metrics/)，并将它们发送到 Prometheus adapter。Prometheus adapter 配置使 Prometheus 实例可以抓取 Mixer 以获取指标。

如果 Istio Dashboard 或 Prometheus 查询未显示预期的指标，则上述流程的任何步骤都可能会出现问题。以下部分提供了对每个步骤进行故障排除的说明。

## 确认 Mixer 可以收到指标报告的调用

Mixer 会生成指标来监控它自身行为。第一步是检查这些指标：

1. 建立与 mixer 自监控 endpoint 的连接以进行 Istio 遥测部署。在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward <istio-telemetry pod> 10514 &
    {{< /text >}}

1. 查看成功的返回，在 Mixer 的自监控 endpoint 上，搜索 `grpc_server_handled_total`。你应该能看到类似的东西：

    {{< text plain >}}
    grpc_server_handled_total{grpc_code="OK",grpc_method="Report",grpc_service="istio.mixer.v1.Mixer",grpc_type="unary"} 68
    {{< /text >}}

    如果你没有看到带有 `grpc_method="Report"` 的 `grpc_server_handled_total` 的任何数据，则 Envoy 就没有调用 Mixer 来报告遥测数据。

1. 在这种情况下，确保已经将服务正确地集成到服务网格中。您可以使用[自动或手动注入 sidecar](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/) 来完成这个目标。

## 验证 Mixer 规则是否存在

在 Kubernetes 环境中，执行以下命令：

{{< text bash >}}
$ kubectl get rules --all-namespaces
NAMESPACE      NAME        AGE
istio-system   kubeattrgenrulerule      13d
istio-system   promhttp                 13d
istio-system   promtcp                  13d
istio-system   stdio                    13d
istio-system   tcpkubeattrgenrulerule   13d
{{< /text >}}

如果输出显示没有名为 `promhttp` 或 `promtcp` 的规则，则缺少将 mixer 指标实例发送到 Prometheus adapter 的 Mixer 配置。你必须提供将 Mixer 指标实例连接到 Prometheus handler 的规则配置。

作为参考，请参阅 [Prometheus 的默认规则]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)。

## 验证 Prometheus handler 配置是否存在

1. 在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl get prometheuses.config.istio.io --all-namespaces
    NAMESPACE      NAME      AGE
    istio-system   handler   13d
    {{< /text >}}

1. 如果输出未显示已配置的 Prometheus handler，则必须重新在 Mixer 配置适当的 handler。

有关参考，请参阅 [Prometheus 的默认 handler 配置]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)。

## 验证 Mixer 指标实例配置是否存在

1. 在 Kubernetes 环境下，执行以下命令：

    {{< text bash >}}
    $ kubectl get metrics.config.istio.io --all-namespaces
    NAMESPACE      NAME              AGE
    istio-system   requestcount      13d
    istio-system   requestduration   13d
    istio-system   requestsize       13d
    istio-system   responsesize      13d
    istio-system   tcpbytereceived   13d
    istio-system   tcpbytesent       13d
    {{< /text >}}

1. 如果输出未显示已配置的 Mixer 指标实例，则必须使用相应的实例配置重新配置 Mixer。

有关参考，请参阅 [Mixer 指标的默认实例配置]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)。

## 验证没有配置错误

1. 要建立与 Istio 遥测自监控 (`istio-telemetry` self-monitoring) endpoint 的连接，像上面[确认 Mixer 可以收到指标报告的调用](#%E7%A1%AE%E8%AE%A4-mixer-%E5%8F%AF%E4%BB%A5%E6%94%B6%E5%88%B0%E6%8C%87%E6%A0%87%E6%8A%A5%E5%91%8A%E7%9A%84%E8%B0%83%E7%94%A8)描述那样，设置一个到 Istio 遥测自监控 endpoint 的 port forward。

1. 确认以下的指标的最新的值是0：

    * `mixer_config_adapter_info_config_error_count`

    * `mixer_config_handler_validation_error_count`

    * `mixer_config_instance_config_error_count`

    * `mixer_config_rule_config_error_count`

    * `mixer_config_rule_config_match_error_count`

    * `mixer_config_unsatisfied_action_handler_count`

    * `mixer_handler_handler_build_failure_count`

在显示 Mixer 自监控 endpoint 的页面上，搜索上面列出的每个指标。搜索结果应该像下面这样（以 `mixer_config_instance_config_error_count` 为例）：

{{< text plain >}}
mixer_config_rule_config_match_error_count{configID="-1"} 0
mixer_config_rule_config_match_error_count{configID="0"} 0
mixer_config_rule_config_match_error_count{configID="1"} 0</td>
{{< /text >}}

确认具有最大配置 ID 的指标的值为0。这说明 Mixer 在按照配置工作，并且未生成任何错误。

## 验证 Mixer 可以将指标实例发送到 Prometheus adapter

1. 要建立与 Istio 遥测自监控 (`istio-telemetry` self-monitoring) endpoint 的连接，像上面[确认 Mixer 可以收到指标报告的调用](#%E7%A1%AE%E8%AE%A4-mixer-%E5%8F%AF%E4%BB%A5%E6%94%B6%E5%88%B0%E6%8C%87%E6%A0%87%E6%8A%A5%E5%91%8A%E7%9A%84%E8%B0%83%E7%94%A8)描述那样，设置一个到 Istio 遥测自监控 endpoint 的 port forward。

1. 在 Mixer 自监控 endpoint 上，搜索 `mixer_runtime_dispatch_count`。输出应该大致是：

    {{< text plain >}}
    mixer_runtime_dispatch_count{adapter="prometheus",error="false",handler="handler.prometheus.istio-system",meshFunction="metric"} 916
    mixer_runtime_dispatch_count{adapter="prometheus",error="true",handler="handler.prometheus.istio-system",meshFunction="metric"} 0
    {{< /text >}}

1. 确认 `mixer_runtime_dispatch_count` 的值是：

    {{< text plain >}}
    adapter="prometheus"
    error="false"
    {{< /text >}}

    如果你找不到发送到 Prometheus adapter 的记录，这很可能是配置不正确。下面这几个步骤可以用来确保配置正确。

    如果发送到 Prometheus adapter 的报告有错误，检测 Mixer 的日志，可以看到错误的来源。最可能的原因是配置问题，可以通过 handler 展示的 mixer_runtime_dispatch_count 指标看出问题。

1. 在 Kubernetes 环境，通过执行以下命令查看 mixer 日志：

    {{< text bash >}}
    $ kubectl -n istio-system logs <istio-telemetry pod> -c mixer
    {{< /text >}}

## 验证 Prometheus 配置

1. 连接到 Prometheus UI 界面

1. 验证是否可以通过 UI 成功查看到 mixer。

1. 在 Kubernetes 环境中，使用以下命令设置 port forward：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

1. 访问 `http://localhost:9090/targets`

1. 确认 target `istio-mesh` 的状态是 UP。

1. 访问 `http://localhost:9090/config`

1. 确认存在的 entry 大概是下面这样：

    {{< text plain >}}
    - job_name: 'istio-mesh'
    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    static_configs:
    - targets: ['istio-mixer.istio-system:42422']</td>
    {{< /text >}}
