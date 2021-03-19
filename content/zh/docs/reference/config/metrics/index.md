---
title: Istio 标准指标
description: 通过 Istio 遥测导出的 Istio 标准指标。
weight: 50
aliases:
    - /zh/docs/reference/config/telemetry/metrics/
---

以下是 Istio 导出的标准服务级别指标。从 Istio 1.5开始，Istio 标准指标由 Envoy 代理直接导出。遥测组件被[实现](https://github.com/istio/proxy/tree/master/extensions/stats)为[Proxy-wasm](https://github.com/proxy-wasm/spec)插件。

在先前的 Istio 版本中，Mixer 生成了这些指标。

## 指标 {#metrics}

对于 HTTP，HTTP/2 和 GRPC 通信，Istio 生成以下指标：

指标类型可参考：[Prometheus 指标类型](https://prometheus.io/docs/concepts/metric_types/)

*   **请求数** (`istio_requests_total`)： 对于由 Istio 代理处理的每个请求，这都是一个 `COUNTER` 增量。

*   **请求时长** (`istio_request_duration_milliseconds`)： 这是一个 `DISTRIBUTION`，用于测量请求的持续时间。

*   **请求体大小** (`istio_request_bytes`)： 这是一个 `DISTRIBUTION`，用来测量 HTTP 请求主体大小。

*   **响应体大小** (`istio_response_bytes`)： 这是一个 `DISTRIBUTION`，用来测量 HTTP 响应主体大小。

*   **gRPC 请求消息数** (`istio_request_messages_total`)： 对于从客户端发送的每条 gRPC 消息，这都是一个 `COUNTER` 增量。

*   **gRPC 响应消息数** (`istio_response_messages_total`)： 对于从服务器发送的每条 gRPC 消息，这都是一个 `COUNTER` 增量。

对于 TCP 流量，Istio 生成以下指标：

*   **TCP 发送字节大小** (`istio_tcp_sent_bytes_total`)： 这是一个`COUNTER`，用于测量在 TCP 连接情况下响应期间发送的总字节数。

*   **TCP 接收字节大小** (`istio_tcp_received_bytes_total`)： 这是一个 `COUNTER`，用于测量在 TCP 连接情况下请求期间接收到的总字节数。

*   **TCP 已打开连接数** (`istio_tcp_connections_opened_total`)： 每个打开的连接都会增加一个 `COUNTER`。

*   **TCP 已关闭连接数** (`istio_tcp_connections_closed_total`)： 对于每个关闭的连接，此 `COUNTER` 递增。

## 标签{#label}

*   **Reporter**： 标识请求的报告者。 如果报告来自服务器 Istio 代理，则设置为`destination`，如果报告来自客户端 Istio 代理或网关，则设置为`source`。

*   **Source Workload**： 标识控制源的源工作负载的名称，如果缺少源信息，则标识为“unknown”。

*   **Source Workload Namespace**： 标识源工作负载的名称空间，如果缺少源信息，则标识为“unknown”。

*   **Source Principal**： 标识流量源的对等主体。使用对等身份验证时设置。

*   **Source App**： 它根据源工作负载的 `app` 标签标识源应用程序，如果源信息丢失，则标识为“unknown”。

*   **Source Version**： 标识源工作负载的版本，如果源信息丢失，则标识为“unknown”。

*   **Destination Workload**： 标识目标工作负载的名称，如果目标信息丢失，则标识为“unknown”。

*   **Destination Workload Namespace**： 标识目标工作负载的名称空间，如果目标信息丢失，则标识为“unknown”。

*   **Destination Principal**： 标识流量目标的对等主体。使用对等身份验证时设置。

*   **Destination App**： 它根据目标工作负载的 `app` 标签标识目标应用程序，如果目标信息丢失，则标识为“unknown”。

*   **Destination Version**： 标识目标工作负载的版本，如果目标信息丢失，则标识为“unknown”。

*   **Destination Service**： 标识负责传入请求的目标服务主机。 例如：`details.default.svc.cluster.local`。

*   **Destination Service Name**： 标识目标服务名称。例如：“详细信息”。

*   **Destination Service Namespace**： 标识目标服务的名称空间。

*   **Request Protocol**： 标识请求的协议。设置为请求或连接协议。

*   **Response Code**： 标识请求的响应代码。此标签仅出现在 HTTP 指标上。

*   **Connection Security Policy**： 标识请求的服务认证策略。 当使用 Istio 来确保通信安全并且报告来自目的地时，将其设置为 `mutual_tls`。 当报告来自源时，由于无法正确填充安全策略，因此将其设置为 `unknown`。

*   **Response Flags**： 有关来自代理的响应或连接的其他详细信息。如果是 Envoy，请参阅[Envoy 访问日志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-response-flags)中的`％RESPONSE_FLAGS％`获取更多信息。

*   **Canonical Service**： 工作负载恰好属于一个规范服务，而它却可以属于多个服务。 规范服务具有名称和修订，因此会产生以下标签。

    {{< text yaml >}}
    source_canonical_service
    source_canonical_revision
    destination_canonical_service
    destination_canonical_revision
    {{< /text >}}

### 多集群标签{#multiple-cluster-label}

在多群集环境中使用 Istio 时，默认情况下会配置以下其他标签：

*   **Destination Cluster**： 目标工作负载的集群名称。 这是由集群安装时的 `global.multiCluster.clusterName` 设置的。

*   **Source Cluster**： 源工作负载的集群名称。 这是由集群安装时的 `global.multiCluster.clusterName` 设置的。
