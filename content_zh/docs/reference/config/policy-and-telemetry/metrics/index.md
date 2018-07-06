---
title: 默认监控指标
description: 通过 Mixer 从 Istio 导出的默认监控指标（Metrics）。
weight: 50
---

此页面展示使用初始配置时，Istio 收集的监控指标（metrics）的详细信息。您可以随时通过更改配置来添加和删除指标。您可以在[这个文件]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)的 “kind: metric” 小节中找到它们。它使用了 [metric 模板](/docs/reference/config/policy-and-telemetry/templates/metric/)来定义指标。

我们将首先描述监控指标，然后描述每个指标的标签（labels）。

## 监控指标

*   **请求计数（Request Count）**: 这是一个 `COUNTER`
    `[指标]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L786:9)`，对于 Istio 代理处理的每个请求递增。

*   **请求持续时间（Request Duration）**: 这是一个 `DISTRIBUTION`
    `[指标]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L802:9)`，它测量请求的持续时间（被服务端代理观察）。

*   **请求大小（Request Size）**:这是一个 `DISTRIBUTION`
    `[指标]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L818:9)`,它测量 HTTP 请求的 body 大小。

*   **响应大小（Response Size）**: 这是一个 `DISTRIBUTION`
    `[指标]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L834:9)`，它测量 HTTP 响应 body 的大小。

*   **Tcp 发送字节数（Tcp Byte Sent）**: 这是一个 `COUNTER`
    `[指标]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L850:9)`，它测量在 TCP 连接场景下响应期间发送的总字节数，由服务端代理测量。

*   **Tcp 接收字节数（Tcp Byte Received）**: 这是一个 `COUNTER`
    `[指标]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L867:9)`，它测量在 TCP 连接场景下请求期间接收的总字节数，由服务端代理测量。

## 标签（Labels）

*   **源 Service（Source Service）**: 标识了对请求进行响应的源 service。这也是一个源 service 的 FQDN。例如：
    "reviews.default.svc.cluster.local"。

    {{< text yaml >}}
    source_service: source.service | "unknown"
    {{< /text >}}

*   **源版本（Source Version）**: 标识了请求的源 service 的版本。

    {{< text yaml >}}
    source_version: source.labels["version"] | "unknown"
    {{< /text >}}

*   **目的 Service（Destination Service）**: 标识了对请求进行响应的目的 service。这也是一个目的 service 的 FQDN。例如:
    "details.default.svc.cluster.local".

    {{< text yaml >}}
    destination_service: destination.service | "unknown"
    {{< /text >}}

*   **目的版本（Destination Version）**: 标识了请求的目的 service 的版本。

    {{< text yaml >}}
    destination_version: destination.labels["version"] | "unknown"
    {{< /text >}}

*   **响应码（Response Code）**:标识了请求的响应码。该 label 仅在 HTTP metrics 中存在。

    {{< text yaml >}}
    response_code: response.code | 200
    {{< /text >}}

*   **连接 mTLS（Connection mTLS）**: 标识请求使用的 service 认证策略。当 Istio 使用身份认证保证通信安全时设置为 `true。

    {{< text yaml >}}
    connection_mtls: connection.mtls | false
    {{< /text >}}