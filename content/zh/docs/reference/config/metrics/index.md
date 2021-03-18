---
title: Istio标准指标
description: 通过Istio遥测导出的Istio标准指标。
weight: 50
aliases:
    - /docs/reference/config/telemetry/metrics/
---

以下是Istio导出的标准服务级别指标。从Istio 1.5开始，Istio标准指标由Envoy代理直接导出。遥测组件被[实现](https://github.com/istio/proxy/tree/master/extensions/stats)为[Proxy-wasm](https://github.com/proxy-wasm/spec)插件。

在先前的Istio版本中，Mixer生成了这些指标。

## 指标

对于HTTP，HTTP/2和GRPC通信，Istio生成以下指标：

*   **请求数** (`istio_requests_total`): 对于由Istio代理处理的每个请求，这都是一个`计数器`。

*   **请求时长** (`istio_request_duration_milliseconds`): 这是一个`转发器`，用于测量请求的持续时间。

*   **请求体大小** (`istio_request_bytes`): 这是一个`转发器`，用来测量HTTP请求主体大小。

*   **响应体大小** (`istio_response_bytes`): 这是一个`转发器`，用来测量HTTP响应主体大小。

*   **gRPC请求消息数** (`istio_request_messages_total`): 对于从客户端发送的每条gRPC消息，这都是一个`计数器`增量。

*   **gRPC响应消息数** (`istio_response_messages_total`):对于从服务器发送的每条gRPC消息，这都是一个`计数器`增量。

对于TCP流量，Istio生成以下指标：

*   **Tcp发送字节大小** (`istio_tcp_sent_bytes_total`): 这是一个`计数器`，用于测量在TCP连接情况下响应期间发送的总字节数。

*   **Tcp接收字节大小** (`istio_tcp_received_bytes_total`): 这是一个`计数器`，用于测量在TCP连接情况下请求期间接收到的总字节数。

*   **Tcp已打开连接数** (`istio_tcp_connections_opened_total`): 每个打开的连接都会增加一个`计数器`。

*   **Tcp已关闭连接数** (`istio_tcp_connections_closed_total`): 对于每个关闭的连接，此`计数器`递增。

## 标签

*   **报告者**: 这标识了请求的报告者。 如果报告来自服务器Istio代理，则设置为`目标`，如果报告来自客户端Istio代理或网关，则设置为`源`。

*   **源工作负载**: 这标识了控制源的源工作负载的名称，如果缺少源信息，则标识为“未知”。

*   **源工作负载名称空间**: 这标识了源工作负载的名称空间，如果缺少源信息，则标识为“未知”。

*   **源负责人**: 标识流量源的对等主体。使用对等身份验证时设置。

*   **源应用**: 它根据源工作负载的`应用`标签标识源应用程序，如果源信息丢失，则标识为“未知”。

*   **源版本**: 这标识了源工作负载的版本，如果源信息丢失，则标识为“未知”。

*   **目标工作负载**: 这标识目标工作负载的名称，如果目标信息丢失，则标识为“未知”。

*   **目标工作负载名称空间**: 这标识目标工作负载的名称空间，如果目标信息丢失，则标识为“未知”。

*   **目标负责人**: 标识流量目标的对等主体。使用对等身份验证时设置。

*   **目标应用**: 它根据目标工作负载的`应用`标签标识目标应用程序，如果目标信息丢失，则标识为“未知”。

*   **目标版本**: 这标识目标工作负载的版本，如果目标信息丢失，则标识为“未知”。

*   **目标服务**: 这标识负责传入请求的目标服务主机。 例如：`details.default.svc.cluster.local`。

*   **目标服务名称**: 这标识目标服务名称。例如：“详细信息”。

*   **目标服务名称空间**: 这标识目标服务的名称空间。

*   **请求协议**: 标识请求的协议。设置为请求或连接协议。

*   **响应码**: 这标识了请求的响应代码。此标签仅出现在HTTP指标上。

*   **连接安全策略**: 这标识了请求的服务认证策略。 当使用Istio来确保通信安全并且报告来自目的地时，将其设置为`mutual_tls`。 当报告来自源时，由于无法正确填充安全策略，因此将其设置为`未知`。

*   **响应标识**: 有关来自代理的响应或连接的其他详细信息。如果是Envoy，请参阅[Envoy访问日志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-response-flags)中的`％RESPONSE_FLAGS％`获取更多信息。

*   **规范服务**: 工作负载恰好属于一个规范服务，而它却可以属于多个服务。 规范服务具有名称和修订，因此会产生以下标签。

    {{< text yaml >}}
    source_canonical_service
    source_canonical_revision
    destination_canonical_service
    destination_canonical_revision
    {{< /text >}}

### 多集群标签

在多群集环境中使用Istio时，默认情况下会配置以下其他标签：

*   **目标集群**: 目标工作负载的集群名称。 这是通过以下方式设置的：群集安装时设置为`global.multiCluster.clusterName`。

*   **源集群**: 源工作负载的集群名称。 这是通过以下方式设置的：群集安装时设置为`global.multiCluster.clusterName`。
