---
title: 属性词汇
description: 描述用于策略和控制的基本属性词汇表。
weight: 10
aliases:
    - /zh/docs/reference/config/mixer/attribute-vocabulary.html
    - /zh/docs/reference/config/mixer/aspects/attributes.html
---

属性是整个 Istio 使用的核心概念。
可以在[这里](/zh/docs/reference/config/policy-and-telemetry/mixer-overview/#attributes)找到属性是什么和用于何处的描述。

每个给定的 Istio 部署有固定的能够理解的属性词汇。
这个特定的词汇由当前部署涉及到的所有属性生产者一起来决定。
Istio 中除了 Envoy 是首要的属性生产者外，Mixer 和服务也会产生属性。

下面这个表格展示一组规范属性集合和他们各自的类型。
大多数 Istio 部署都会包含产生这些属性的代理（Envoy 或 Mixer 适配器）。

| 名称 | 类型 | 描述 | Kubernetes 示例 |
|------|------|-------------|--------------------|
| `source.uid` | string | 源工作负载实例特定于平台的唯一标识符。 | `kubernetes://redis-master-2353460263-1ecey.my-namespace` |
| `source.ip` | ip_address | 源工作负载实例的 IP 地址。 | `10.0.0.117` |
| `source.labels` | map[string, string] | 源实例附带的键值对 map 。 | version => v1 |
| `source.name` | string | 源工作负载实例的名称。 | `redis-master-2353460263-1ecey` |
| `source.namespace` | string | 源工作负载实例的命名空间。 | `my-namespace` |
| `source.principal` | string | 源工作负载的运行基于的授权机构。 | `service-account-foo` |
| `source.owner` | string | 控制源工作负载实例的工作负载。 | `kubernetes://apis/extensions/v1beta1/namespaces/istio-system/deployments/istio-policy` |
| `source.workload.uid` | string | 源工作负载的唯一标识符。 | `istio://istio-system/workloads/istio-policy` |
| `source.workload.name` | string | 源工作负载的名称。 | `istio-policy` |
| `source.workload.namespace` | string | 源工作负载的命名空间。 | `istio-system` |
| `destination.uid` | string | 服务器实例特定于平台的唯一标识符。 | `kubernetes://my-svc-234443-5sffe.my-namespace` |
| `destination.ip` | ip_address | 服务器 IP 地址。 | `10.0.0.104` |
| `destination.port` | int64 | 服务器 IP 地址上的接收端口。 | `8080` |
| `destination.labels` | map[string, string] | 服务器实例附带的键值对 map 。 | version => v2 |
| `destination.name` | string | 目标工作负载实例的名称。 | `istio-telemetry-2359333` |
| `destination.namespace` | string | 目标工作负载实例的命名空间。 | `istio-system` |
| `destination.principal` | string | 目标工作负载运行所基于的授权机构。 | `service-account` |
| `destination.owner` | string | 控制目标工作负载实例的工作负载。 | `kubernetes://apis/extensions/v1beta1/namespaces/istio-system/deployments/istio-telemetry` |
| `destination.workload.uid` | string | 目标工作负载的唯一标识符。 | `istio://istio-system/workloads/istio-telemetry` |
| `destination.workload.name` | string | 目标工作负载的名称。 | `istio-telemetry` |
| `destination.workload.namespace`| string | 目标工作负载的命名空间。 | `istio-system` |
| `destination.container.name` | string | 目标工作负载实例的容器名称。 | `mixer` |
| `destination.container.image` | string |目标工作负载实例的容器镜像。 | `gcr.io/istio-testing/mixer:0.8.0` |
| `destination.service.host` | string | 目标主机地址。 | `istio-telemetry.istio-system.svc.cluster.local` |
| `destination.service.uid` | string | 目标服务的唯一标识符。 | `istio://istio-system/services/istio-telemetry` |
| `destination.service.name` | string | 目标服务的名称。 | `istio-telemetry` |
| `destination.service.namespace` | string | 目标服务的命名空间。 | `istio-system` |
| `origin.ip` | ip_address | 代理客户端的 IP 地址, e.g. ingress 代理的来源。 | `127.0.0.1` |
| `request.headers` | map[string, string] | HTTP 请求头，key使用小写。以gRPC为例，此处为其元数据。 | |
| `request.id` | string | 从统计角度上拥有低碰撞概率的请求 ID。 | |
| `request.path` | string | 包括 query string 的 HTTP URL 路径。 | |
| `request.url_path` | string | 部分 HTTP URL 路径，除去了 query string。 | |
| `request.query_params` | map[string, string] | 从 HTTP URL 提取的 query 参数的 map。 | |
| `request.host` | string | HTTP/1.x 请求头中的 Host 字段或者是 HTTP/2 请求头中的 authority 字段。 | `redis-master:3337` |
| `request.method` | string | HTTP 请求方法。 | |
| `request.reason` | string | 审计系统用到的请求理由。 | |
| `request.referer` | string | HTTP 请求头中的 referer 字段。 | |
| `request.scheme` | string | 请求的 URI Scheme。 | |
| `request.size` | int64 | 以字节为单位的请求大小。对于 HTTP 来说，等于 Content-Length 的值。 | |
| `request.total_size` | int64 | 以字节为单位的整个 HTTP 请求的大小，包括请求头、消息体和结束符。 | |
| `request.time` | timestamp | 目标收到请求时的时间戳。相当于 Firebase 里的 "now"。 | |
| `request.useragent` | string | HTTP 请求头中的 User-Agent 字段。 | |
| `response.headers` | map[string, string] | HTTP 响应头，key 使用小写。 | |
| `response.size` | int64 | 以字节为单位的响应消息体大小。 | |
| `response.total_size` | int64 | 以字节为单位的整个 HTTP 响应的大小，包括响应头和消息体。 | |
| `response.time` | timestamp | 目标产生响应时的时间戳。 | |
| `response.duration` | duration | 生成响应总共花费的时间。 | |
| `response.code` | int64 | HTTP 响应的状态码。 | |
| `response.grpc_status` | string | gRPC 响应的状态码。 | |
| `response.grpc_message` | string | gRPC 响应的状态消息。 | |
| `connection.id` | string | 从统计角度上拥有低碰撞概率的 TCP 连接 ID。 | |
| `connection.event` | string | TCP 连接的状态，它的值域范围为：“open”、“continue” 和 “close”。 | |
| `connection.received.bytes` | int64 | 对于一条连接，在最后一次 Report() 之后，目标服务在此连接上接收到的字节数。 | |
| `connection.received.bytes_total` | int64 | 在连接的生命周期中，目标服务接收到的全部字节数。 | |
| `connection.sent.bytes` | int64 | 对于一条连接，在最后一次 Report() 之后，目标服务在此连接上发送的字节数。 | |
| `connection.sent.bytes_total` | int64 | 在连接的生命周期中，目标服务发送的全部字节数。 | |
| `connection.duration` | duration | 连接打开的总时间量。 | |
| `connection.mtls` | boolean | 标示接收到的请求是否来自于启用了 mutual TLS 的下游连接。 | |
| `connection.requested_server_name` | string | 连接请求的服务器名 （ SNI ）。 | |
| `context.protocol` | string | 请求或者被代理的连接的协议。 | `tcp` |
| `context.time` | timestamp | Mixer 操作的时间戳。 | |
| `context.reporter.kind` | string | 将报告的属性集上下文化。 对于来自 sidecars 的服务器端调用设置为 `inbound`，对于来自 sidecars 和网关的客户端调用设置为 `outbound` 。 | `inbound` |
| `context.reporter.uid` | string | 属性报告者特定于平台的唯一标识符。 | `kubernetes://my-svc-234443-5sffe.my-namespace` |
| `context.proxy_error_code` | string | 有关来自代理的响应或连接的其他详细信息。 如果是 Envoy, 请参阅 [Envoy Access Log](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log#configuration) 的 `%RESPONSE_FLAGS%` 查看更多信息 | `UH` |
| `api.service` | string | 公开的服务名。和处于网格中的服务身份不同，它反映了暴露给客户端的服务名称。 | `my-svc.com` |
| `api.version` | string | API 版本。 | `v1alpha1` |
| `api.operation` | string | 用于辨别操作的唯一字符串。在特定的 &lt;service, version&gt; 描述的所有操作中，这个 ID 是唯一的。 | `getPetsById` |
| `api.protocol` | string | API 调用的协议类型。主要用于监控和分析。注意这是暴露给客户端的前端协议，不是后端服务实现的协议。 | `http`, `https`, or `grpc` |
| `request.auth.principal` | string | 请求的经过身份验证的主体。这是一个用“ / ”把 JWT 中的发行者（ `iss` ）和主题（ `sub` ）声明连接起来的字符串，其中主题的值是被 URL 编码的。此属性可能来自 Istio 身份验证策略中的对等体或源，具体取决于 Istio 身份验证策略中定义的绑定规则。 | `issuer@foo.com/sub@foo.com` |
| `request.auth.audiences` | string | 此身份验证信息的目标受众。此值应反映 JWT 中的受众（ `aud` ）声明。 | `aud1` |
| `request.auth.presenter` | string | 授权证书的出示人。此值应反映 JWT 或 OAuth2 客户端 ID 中的可选授权演示者（`azp`）声明。 | 123456789012.my-svc.com |
| `request.auth.claims` | map[string, string] | 原始 JWT 中所有的的字符串声明。 | `iss`: `issuer@foo.com`, `sub`: `sub@foo.com`, `aud`: `aud1` |
| `request.api_key` | string | 用于请求的 API key 。 | abcde12345 |
| `check.error_code` | int64 | Mixer Check 调用的[错误码](https://github.com/google/protobuf/blob/master/src/google/protobuf/stubs/status.h) 。 | 5 |
| `check.error_message` | string | Mixer Check 调用的错误消息。 | Could not find the resource |
| `check.cache_hit` | boolean | 标示 Mixer check 调用是否命中本地缓存。 | |
| `quota.cache_hit` | boolean | 标示 Mixer 限额调用是否命中本地缓存。 | |

## 时间戳和持续时间属性格式

时间戳属性以 RFC 3339 格式表示。
应用 timestamp 属性时，可以使用 [CEXL](/zh/docs/reference/config/policy-and-telemetry/expression-language/)
中定义的 `timestamp` 函数将 RFC 3339 格式的文本时间戳转换为 `TIMESTAMP` 类型，
例如：`request.time | timestamp("2018-01-01T22:08:41+00:00")`, `response.time > timestamp("2020-02-29T00:00:00-08:00")`。

持续时间属性表示时间量，表示为一系列十进制数，其中可选的小数部分用句点表示，以及单位值。
可能的单位值是纳秒 `ns`、微秒 `us`（或 `μs`）、毫秒 `ms`、秒 `s`、分钟 `m`、小时 `h`。例如：

* `1ms` 表示 1 毫秒
* `2.3s` 表示 2.3 秒
* `4m` 表示 4 分钟
* `5h10m` 表示 5 小时 10 分钟
