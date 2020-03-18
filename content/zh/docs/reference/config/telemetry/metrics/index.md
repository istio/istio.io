---
title: Istio 标准度量指标
description: 通过 Istio 遥测导出的 Istio 标准指标。
weight: 50
---

以下是 Istio 导出的标准服务级别指标。
自 Istio 1.5 起，Istio 标准指标由 Envoy 代理直接导出。
在先前的 Istio 版本中，Mixer 生成了这些指标。

## 指标

对于 HTTP，HTTP/2 和 GRPC 流量，Istio 生成以下指标：

*   **请求计数**（`istio_requests_total`）：这是一个用于累加每个由 Istio 代理所处理请求的 `COUNTER` 指标。

*   **请求持续时间**（`istio_request_duration_seconds`）：这是一个用于测量请求的持续时间的 `DISTRIBUTION` 指标。

*   **请求大小**（`istio_request_bytes`）：这是一个用于测量 HTTP 请求 body 大小的 `DISTRIBUTION` 指标。

*   **响应大小**（`istio_response_bytes`）：这是一个用于测量 HTTP 响应 body 大小的 `DISTRIBUTION` 指标。

对于 TCP 流量，Istio 生成以下指标：

*   **Tcp发送字节数**（`istio_tcp_sent_bytes_total`）：这是一个用于测量在 TCP 连接下响应期间发送的总字节数的 `COUNTER` 指标。

*   **Tcp接收字节数**（`istio_tcp_received_bytes_total`）：这是一个用于测量在 TCP 连接下请求期间接收的总字节数的`COUNTER`指标。

*   **Tcp打开连接数**（`istio_tcp_connections_opened_total`）：这是一个用于累加每个打开连接的 `COUNTER` 指标。

*   **Tcp关闭连接数** (`istio_tcp_connections_closed_total`): 这是一个用于累加每个关闭连接的 `COUNTER` 指标。

## 标签

*   **报告者**：标识请求的报告者。如果报告来自服务端Istio代理，则设置为 `destination` ，如果报告来自客户端Istio代理，则设置为 `source` 。

    {{< text yaml >}}
    reporter: conditional((context.reporter.kind | "inbound") == "outbound", "source", "destination")
    {{< /text >}}

*   **源工作负载**：标识控制源的源工作负载的名称。

    {{< text yaml >}}
    source_workload: source.workload.name | "unknown"
    {{< /text >}}

*   **源工作负载命名空间**：标识源工作负载的命名空间。

    {{< text yaml >}}
    source_workload_namespace: source.workload.namespace | "unknown"
    {{< /text >}}

*   **源主体**：标识流量源的对等主体，使用对等身份验证时设置。

    {{< text yaml >}}
    source_principal: source.principal | "unknown"
    {{< /text >}}

*   **源应用**：基于源工作负载的 `app` 标签来标识源应用。

    {{< text yaml >}}
    source_app: source.labels["app"] | "unknown"
    {{< /text >}}

*   **源版本**：标识源工作负载的版本。

    {{< text yaml >}}
    source_version: source.labels["version"] | "unknown"
    {{< /text >}}

*   **目标工作负载**：标识目标工作负载的名称。

    {{< text yaml >}}
    destination_workload: destination.workload.name | "unknown"
    {{< /text >}}

*   **目标工作负载命名空间**：标识目标工作负载的命名空间。

    {{< text yaml >}}
    destination_workload_namespace: destination.workload.namespace | "unknown"
    {{< /text >}}

*   **目标主体**：标识流量目标的对等主体。使用对等身份验证时设置。

    {{< text yaml >}}
    destination_principal: destination.principal | "unknown"
    {{< /text >}}

*   **目标应用**：基于目标工作负载的 `app` 标签来标识目标应用。

    {{< text yaml >}}
    destination_app: destination.labels["app"] | "unknown"
    {{< /text >}}

*   **目标版本**：标识目标工作负载的版本。

    {{< text yaml >}}
    destination_version: destination.labels["version"] | "unknown"
    {{< /text >}}

*   **目标服务**：标识负责传入请求的目标服务主机。例如：`details.default.svc.cluster.local`。

    {{< text yaml >}}
    destination_service: destination.service.host | "unknown"
    {{< /text >}}

*   **目标服务名称**：标识目标服务名称。例如：“details”。

    {{< text yaml >}}
    destination_service_name: destination.service.name | "unknown"
    {{< /text >}}

*   **目标服务命名空间**：标识目标服务的命名空间。

    {{< text yaml >}}
    destination_service_namespace: destination.service.namespace | "unknown"
    {{< /text >}}

*   **请求协议**：标识请求的协议。如果提供，则设置为 API 协议，否则设置为请求或连接协议。

    {{< text yaml >}}
    request_protocol: api.protocol | context.protocol | "unknown"
    {{< /text >}}

*   **响应码**：标识请求的响应码。此标签仅在 HTTP 指标上显示。

    {{< text yaml >}}
    response_code: response.code | 200
    {{< /text >}}

*   **连接安全策略**：标识请求的服务认证策略。当使用 Istio 来确保通信安全并且报告来自目标时，它将设置为 `mutual_tls` 。当报告来自源时，由于无法正确填充安全策略，因此将其设置为 `unknown` 。

    {{< text yaml >}}
    connection_security_policy: conditional((context.reporter.kind | "inbound") == "outbound", "unknown", conditional(connection.mtls | false, "mutual_tls", "none"))
    {{< /text >}}

*   **响应标志**：有关来自代理的响应或连接的其他详细信息。如果使用 Envoy ，请参阅[Envoy访问日志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log#configuration)中的 `％RESPONSE_FLAGS％` 以获取更多详细信息。

    {{< text yaml >}}
    response_flags: context.proxy_error_code | "-"
    {{< /text >}}

*   **规范服务**：虽然工作负载可以属于多个服务，但是其只能属于一个规范服务。规范服务具有名称和修订，因此会产生以下标签。

    {{< text yaml >}}
    source_canonical_service
    source_canonical_revision
    destination_canonical_service
    destination_canonical_revision
    {{< /text >}}
