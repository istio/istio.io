---
title: 应用程序要求
description: 部署在支持 Istio 的集群中的应用程序的要求。
weight: 40
keywords:
  - kubernetes
  - sidecar
  - sidecar-injection
  - deployment-models
  - pods
  - setup
aliases:
  - /zh/docs/setup/kubernetes/spec-requirements/
  - /zh/docs/setup/kubernetes/prepare/spec-requirements/
  - /zh/docs/setup/kubernetes/prepare/requirements/
  - /zh/docs/setup/kubernetes/additional-setup/requirements/
  - /zh/docs/setup/additional-setup/requirements
  - /zh/docs/ops/setup/required-pod-capabilities
  - /zh/help/ops/setup/required-pod-capabilities
  - /zh/docs/ops/prep/requirements
  - /zh/docs/ops/deployment/requirements
owner: istio/wg-environments-maintainers
test: n/a
---

Istio 为应用程序提供了大量的功能，而对应用程序代码本身几乎没有影响。
许多 Kubernetes 应用程序可以部署在启用 Istio 的集群中，而不需要对应用程序做任何修改。
然而，在部署启用 Istio 的应用程序时，需要特别注意 Istio Sidecar 模型造成的影响。
本文介绍了针对这些应用程序的注意事项以及启用 Istio 的具体要求。

## Pod 要求 {#pod-requirements}

作为 Istio 服务网格中的一部分，Kubernetes 集群中的 Pod 和 Service 必须满足以下要求：

- **应用 UID**：确保您的 Pod 不会被 ID（UID）为 `1337` 的用户运行应用，因为 `1337` 是为 Sidecar 代理保留的。

- **`NET_ADMIN` 和 `NET_RAW` 能力**：除非使用
  [Istio CNI 插件](/zh/docs/setup/additional-setup/cni/)，
  否则 `istio-init` 容器需要 `NET_ADMIN` 和 `NET_RAW` 权限来配置 iptables 流量重定向。
  该命名空间必须使用 `privileged` 级别的
  [Pod 安全准入（Pod Security Admission）](https://kubernetes.io/docs/concepts/security/pod-security-admission/)策略；
  `baseline` 和 `restricted` 级别都会禁止这些权限，从而导致 `istio-init` 容器无法运行。

    要检查命名空间上的 `pod-security.kubernetes.io/enforce` 标签：

    {{< text bash >}}
    $ kubectl get namespace <your namespace> --show-labels
    NAME       STATUS   AGE   LABELS
    myapp      Active   3d    pod-security.kubernetes.io/enforce=privileged,...
    {{< /text >}}

    要将命名空间设置为 `privileged` 强制：

    {{< text bash >}}
    $ kubectl label namespace <your namespace> pod-security.kubernetes.io/enforce=privileged --overwrite
    {{< /text >}}

    如果您的安全策略不允许在命名空间上执行 `privileged`，
    请改用 [Istio CNI 插件](/zh/docs/setup/additional-setup/cni/)，
    它可以处理流量重定向，而无需在 Pod 中提升功能。

- **Pod 标签（label）**：我们建议使用 Pod 标签显式声明带有应用程序标识符和版本的 Pod。
  这些标签将上下文信息添加到 Istio 收集的指标和遥测数据中。
  每个值都是从多个标签中读取的，按优先级从最高到最低的顺序排列：

    - 应用程序名称：`service.istio.io/canonical-name`、`app.kubernetes.io/name` 或 `app`。
    - 应用程序版本：`service.istio.io/canonical-revision`、`app.kubernetes.io/version` 或 `version`。

- **已命名 Service 端口**：可以选择已命名 Service 端口用于显式指定协议。
  更多详细信息请参见[协议选择](/zh/docs/ops/configuration/traffic-management/protocol-selection/)。
  如果一个 Pod 属于多个 [Kubernetes Service](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/)，
  这些 Service 不能对不同的协议（例如 HTTP 和 TCP）使用相同的端口号。

## Istio 使用的端口 {#ports-used-by-Istio}

Istio Sidecar 代理（Envoy）使用以下端口和协议。

{{< warning >}}
为避免与 Sidecar 发生端口冲突，应用程序不应使用 Envoy 所使用的任何端口。
{{< /warning >}}

| 端口 | 协议 | 描述 | 仅限 Pod 内部 |
|----|----|----|----|
| 15000 | TCP  | Envoy 管理端口（命令/诊断） | 是 |
| 15001 | TCP  | Envoy 出站 | 否 |
| 15002 | TCP  | 故障检测侦听端口 | 是 |
| 15004 | HTTP | 调试端口 | 是 |
| 15006 | TCP  | Envoy 入站 | 否 |
| 15008 | H2   | HBONE mTLS 隧道端口 | 否 |
| 15020 | HTTP | 从 Istio 代理、Envoy 和应用程序合并的 Prometheus 遥测 | 否 |
| 15021 | HTTP | 健康检查 | 否 |
| 15053 | DNS  | DNS 端口，如果启用了捕获 | 是 |
| 15090 | HTTP | Envoy Prometheus 遥测 | 否 |

Istio 控制平面（istiod）使用以下端口和协议。

| 端口 | 协议 | 描述 | 仅限本地主机 |
|----|----|----|----|
| 443   | HTTPS | Webhook 服务端口 | 否 |
| 8080  | HTTP  | 调试接口（已弃用，仅限容器端口） | 否 |
| 15010 | GRPC  | XDS 和 CA 服务（纯文本，仅用于安全网络） | 否 |
| 15012 | GRPC  | XDS 和 CA 服务（TLS 和 mTLS，推荐用于生产）| 否 |
| 15014 | HTTP  | 控制平面监控 | 否 |
| 15017 | HTTPS | Webhook 容器端口，从 443 转发 | 否 |

## 服务器优先协议 {#server-first-protocols}

一些协议是 “服务器优先” 协议，这意味着服务器将发送第一个字节。这可能会对
[`PERMISSIVE`](/zh/docs/reference/config/security/peer_authentication/#PeerAuthentication-MutualTLS-Mode)
mTLS 和[自动协议选择](/zh/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection)产生影响。

这两个功能都通过检查连接的初始字节来确定协议，这与服务器优先协议不兼容。

为了支持这些情况，
请按照[显式协议选择](/zh/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)步骤将应用程序的协议声明为 `TCP`。

已知以下端口通常承载服务器优先协议，并自动假定为 `TCP`：

| 协议    | 端口  |
| ------- | ----- |
| SMTP    | 25    |
| DNS     | 53    |
| MySQL   | 3306  |
| MongoDB | 27017 |

因为 TLS 通信不是服务器优先的，所以 TLS 加密的服务器优先流量将与自动协议检测一起使用，只要您确保所有经过 TLS 嗅探的流量都已加密：

1. 将服务器的 `mTLS` 模式设置为 `STRICT`。这将对所有请求强制执行 TLS 加密。
1. 将服务器的 `mTLS` 模式设置为 `DISABLE`。这将禁用 TLS 嗅探，允许使用服务器优先协议。
1. 配置所有客户端发送 `TLS` 流量，通常通过
   [`DestinationRule`](/zh/docs/reference/config/networking/destination-rule/#ClientTLSSettings)
   或依赖自动 mTLS。
1. 将您的应用程序配置为直接发送 TLS 流量。

## 出站流量 {#outbound-traffic}

为了支持 Istio 的流量路由功能，离开 Pod 的流量可能与未部署 Sidecar 时的流量不同。

对基于 HTTP 的流量，流量根据 `Host` 标头进行路由。如果目标 IP 和 `Host`
标头未对齐，这可能会导致意外行为。例如，`curl 1.2.3.4 -H "Host: httpbin.default"`
请求将被路由到 `httpbin` 服务，而不是 `1.2.3.4`。

对不基于 HTTP 的流量（包括 HTTPS），Istio 无法访问 `Host` 标头，
因此路由决策基于服务 IP 地址。

这意味着直接调用 Pod（例如，`curl <POD_IP>`），而不匹配 Service。
虽然流量可以[通过](/zh/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services)，
但它不会获得 mTLS 加密、流量路由和遥测等完整的 Istio 功能。

相关的更多信息，请参阅[流量路由](/zh/docs/ops/configuration/traffic-management/traffic-routing)页面。
