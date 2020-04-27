---
title: 默认监控指标
description: 通过 Mixer 从 Istio 导出的默认监控指标。
weight: 50
---

此页面展示使用初始配置时，Istio 收集的监控指标（metrics）的详细信息。这些指标是内置的，但您可以随时通过更改配置来添加和删除它们。您可以在[这个文件]({{<github_file>}}/manifests/UPDATING-CHARTS.md)的 "kind: metric” 小节中找到它们。它使用了 [metric 模板](/zh/docs/reference/config/policy-and-telemetry/templates/metric/)来定义指标。

我们将首先描述监控指标，然后描述每个指标的标签。

## 监控指标{#metrics}

Istio 为 HTTP、HTTP/2 和 GRPC 流量创建了下列指标：

* **Request Count** （`istio_requests_total`）：这是一个 `COUNTER`，随着 Istio 代理处理的每个请求递增。

* **Request Duration** （`istio_request_duration_seconds`）：这是一个 `DISTRIBUTION`，它测量请求的持续时间。

* **Request Size** （`istio_request_bytes`）：这是一个 `DISTRIBUTION`，它测量 HTTP 请求的 body 大小。

* **Response Size**（`istio_response_bytes`）：这是一个 `DISTRIBUTION`，它测量 HTTP 响应 body 的大小。

对于 TCP 流量，Istio 创建了下列指标：

* **Tcp Byte Sent**（`istio_tcp_sent_bytes_total`）：这是一个 `COUNTER`，它测量了一条 TCP 连接响应期间发送的总字节数，由服务端代理测量。

* **Tcp Byte Received**（`istio_tcp_received_bytes_total`）：这是一个 `COUNTER`，它测量了一条 TCP 连接请求期间接收的总字节数，由服务端代理测量。

* **Tcp Connections Opened**（`istio_tcp_connections_opened_total`）：这是一个 `COUNTER`，它测量已经打开的 TCP 连接总数。

* **Tcp Connections Closed**（`istio_tcp_connections_closed_total`）：这是一个 `COUNTER`，它测量已经关闭的 TCP 连接总数。

## 标签{#labels}

* **Reporter**：这是请求报告者的标识符。报告从服务端 Istio 代理而来时设置为 `destination`，从客户端 Istio 代理而来时设置为 `source`。

    {{< text yaml >}}
    reporter: conditional((context.reporter.kind | "inbound") == "outbound", "source", "destination")
    {{< /text >}}

* **Source Workload**：源工作负载所属控制器的名称。

    {{< text yaml >}}
    source_workload: source.workload.name | "unknown"
    {{< /text >}}

* **Source Workload Namespace**：源工作负载所在的命名空间。

    {{< text yaml >}}
    source_workload_namespace: source.workload.namespace | "unknown"
    {{< /text >}}

* **Source Principal**：在使用 Peer 身份验证的情况下，流量来源的认证主体。

    {{< text yaml >}}
    source_principal: source.principal | "unknown"
    {{< /text >}}

* **Source App**：源工作负载的 `app` 标签。

    {{< text yaml >}}
    source_app: source.labels["app"] | "unknown"
    {{< /text >}}

* **Source Version**：标识了源工作负载的版本。

    {{< text yaml >}}
    source_version: source.labels["version"] | "unknown"
    {{< /text >}}

* **Destination Workload**：标识了目的工作负载的名称。

    {{< text yaml >}}
    destination_workload: destination.workload.name | "unknown"
    {{< /text >}}

* **Destination Workload Namespace**：标识了目的工作负载所在的命名空间。

    {{< text yaml >}}
    destination_workload_namespace: destination.workload.namespace | "unknown"
    {{< /text >}}

* **Destination Principal**：在使用 Peer 身份验证的情况下，流量目标的认证主体。

    {{< text yaml >}}
    destination_principal: destination.principal | "unknown"
    {{< /text >}}

* **Destination App**：标识了目的应用（基于目的工作负载的 `app` 标签）。

    {{< text yaml >}}
    destination_app: destination.labels["app"] | "unknown"
    {{< /text >}}

* **Destination Version**：标识了目的工作负载的版本。

    {{< text yaml >}}
    destination_version: destination.labels["version"] | "unknown"
    {{< /text >}}

* **Destination Service**：标识了负责处理传入请求的目标服务。例如：`details.default.svc.cluster.local`。

    {{< text yaml >}}
    destination_service: destination.service.host | "unknown"
    {{< /text >}}

* **Destination Service Name**：标识了目标服务的名称。例如：“details”。

    {{< text yaml >}}
    destination_service_name: destination.service.name | "unknown"
    {{< /text >}}

* **Destination Service Namespace**：标识了目标服务所在的命名空间。

    {{< text yaml >}}
    destination_service_namespace: destination.service.namespace | "unknown"
    {{< /text >}}

* **Request Protocol**：标识了请求协议。当提供了 API 协议时设置为该值，否则设置为请求或连接协议。

    {{< text yaml >}}
    request_protocol: api.protocol | context.protocol | "unknown"
    {{< /text >}}

* **Response Code**：标识了请求的响应码。该标签仅在 HTTP 指标中存在。

    {{< text yaml >}}
    response_code: response.code | 200
    {{< /text >}}

* **Connection Security Policy**：这标识了请求的服务身份验证策略。当 Istio 启用通信安全功能，并且报告来自目的地时，它被设置为 `mutual_tls`。如果报告来自源时，因为无法判断安全策略，这个指标的值会被设置为 `unknown`。

    {{< text yaml >}}
    connection_security_policy: conditional((context.reporter.kind | "inbound") == "outbound", "unknown", conditional(connection.mtls | false, "mutual_tls", "none"))
    {{< /text >}}

* **Response Flags**: 来自代理服务器，包含了响应或者连接的额外细节。如果是 Envoy 代理，可以参考 [Envoy 访问日志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log#configuration)中的 `%RESPONSE_FLAGS%` 相关说明。

    {{< text yaml >}}
    response_flags: context.proxy_error_code | "-"
    {{< /text >}}
