---
title: 默认监控指标
description: 通过 Mixer 从 Istio 导出的默认监控指标（Metrics）。
weight: 50
---

此页面展示使用初始配置时，Istio 收集的监控指标（metrics）的详细信息。您可以随时通过更改配置来添加和删除指标。您可以在[这个文件]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)的 "kind: metric” 小节中找到它们。它使用了 [metric 模板](/docs/reference/config/policy-and-telemetry/templates/metric/)来定义指标。

我们将首先描述监控指标，然后描述每个指标的标签（labels）。

## 监控指标

*   **请求计数（Request Count）**：这是一个 `COUNTER`，对于 Istio 代理处理的每个请求递增。

*   **请求持续时间（Request Duration）**：这是一个 `DISTRIBUTION`，它测量请求的持续时间。

*   **请求大小（Request Size）**：这是一个 `DISTRIBUTION`，它测量 HTTP 请求的 body 大小。

*   **响应大小（Response Size）**：这是一个 `DISTRIBUTION`，它测量 HTTP 响应 body 的大小。

*   **Tcp 发送字节数（Tcp Byte Sent）**：这是一个 `COUNTER`，它测量在 TCP 连接场景下响应期间发送的总字节数，由服务端代理测量。

*   **Tcp 接收字节数（Tcp Byte Received）**：这是一个 `COUNTER`，它测量在 TCP 连接场景下请求期间接收的总字节数，由服务端代理测量。

## 标签（Label）

*   **报告者（Reporter）**：这是请求报告者的标识符。报告从服务端 Istio 代理而来时设置为 `server`，从客户端 Istio 代理而来时设置为 `client`。

    {{< text yaml >}}
    reporter: conditional((context.reporter.kind | "inbound") == "outbound", "client", "server")
    {{< /text >}}

*   **源 Namespace（Source Namespace）**：标识了产生流量的源工作负载实例的 namespace。

    {{< text yaml >}}
    source_namespace: source.namespace | "unknown"
    {{< /text >}}

*   **源工作负载（Source Workload）**：标识了控制源的源工作负载名称。

    {{< text yaml >}}
    source_workload: source.workload.name | "unknown"
    {{< /text >}}

*   **源工作负载 Namespace（Source Workload Namespace）**：标志了源工作负载的 namespace。

    {{< text yaml >}}
    source_workload_namespace: source.workload.namespace | "unknown"
    {{< /text >}}

*   **源主体（Source Principal）**：标识了流量来源的对等主体。在使用对等身份验证时设置。

    {{< text yaml >}}
    source_principal: source.principal | "unknown"
    {{< /text >}}

*   **源应用（Source App）**：标识了源应用（基于源工作负载的 `app` 标签）。

    {{< text yaml >}}
    source_app: source.labels["app"] | "unknown"
    {{< /text >}}

*   **源版本（Source Version）**：标识了源工作负载的版本。

    {{< text yaml >}}
    source_version: source.labels["version"] | "unknown"
    {{< /text >}}

*   **目的 Namespace（Destination Namespace）**：标识了流量到达的目的工作负载实例的 namespace。

    {{< text yaml >}}
    destination_namespace: destination.namespace | "unknown"
    {{< /text >}}

*   **目的工作负载（Destination Workload）**：标识了目的工作负载的名称。

    {{< text yaml >}}
    destination_workload: destination.workload.name | "unknown"
    {{< /text >}}

*   **目的工作负载 Namespace（Destination Workload Namespace）**：标识了目的工作负载的 namespace。

    {{< text yaml >}}
    destination_workload_namespace: destination.workload.namespace | "unknown"
    {{< /text >}}

*   **目的主体（Destination Principal）**: 标识了流量目的对等主体。当使用对等身份认证时设置。

    {{< text yaml >}}
    destination_principal: destination.principal | "unknown"
    {{< /text >}}

*   **目的应用（Destination App）**：标识了目的应用（基于目的工作负载的 `app` 标签）。

    {{< text yaml >}}
    destination_app: destination.labels["app"] | "unknown"
    {{< /text >}}

*   **目的版本（Destination Version）**：标识了目的工作负载的版本。

    {{< text yaml >}}
    destination_version: destination.labels["version"] | "unknown"
    {{< /text >}}

*   **目的 Service（Destination Service）**：标识了负责处理传入请求的目的 service。例如："details.default.svc.cluster.local"。

    {{< text yaml >}}
    destination_service: destination.service.host | "unknown"
    {{< /text >}}

*   **目的 Service 名称（Destination Service Name）**：标识了目的 service 的名称。例如："details"。

    {{< text yaml >}}
    destination_service_name: destination.service.name | "unknown"
    {{< /text >}}

*   **目的 Service Namespace（Destination Service Namespace）**：标识了目的 service 的 namespace。

    {{< text yaml >}}
    destination_service_namespace: destination.service.namespace | "unknown"
    {{< /text >}}

*   **请求协议（Request Protocol）**：标识了请求协议。当提供了 API 协议时设置为该值，否则设置为请求或连接协议。

    {{< text yaml >}}
    request_protocol: api.protocol | context.protocol | "unknown"
    {{< /text >}}

*   **响应码（Response Code）**:标识了请求的响应码。该 label 仅在 HTTP metrics 中存在。

    {{< text yaml >}}
    response_code: response.code | 200
    {{< /text >}}

*   **连接 mTLS（Connection mTLS）**: 标识请求使用的 service 认证策略。当 Istio 使用身份认证保证通信安全时设置为 `true`。

    {{< text yaml >}}
    connection_mtls: connection.mtls | false
    {{< /text >}}