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
owner: istio/wg-environments-maintainers
test: n/a
---

Istio 为应用程序提供了大量的功能，而对应用程序代码本身几乎没有影响。
许多 Kubernetes 应用程序可以部署在启用 Istio 的集群中，而不需要对应用程序做任何修改。
然而，在部署启用 Istio 的应用程序时，需要特别注意 Istio Sidecar 模型造成的影响。
本文介绍了针对这些应用程序的注意事项以及启用 Istio 的具体要求。

## Pod 要求 {#pod-requirements}

作为 Istio 服务网格中的一部分，Kubernetes 集群中的 Pod 和 Service 必须满足以下要求：

- **Service 关联**：不管一个 Pod 是否对外暴露端口，每个 Pod 必须至少属于一个
  [Kubernetes Service](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/)。
  假如一个 Pod 同时属于多个 Kubernetes Service，那么它不能在不同 Service 的端口号上使用不同的协议（比如 HTTP 和 TCP）。

- **应用 UID**：确保您的 Pod 不会被 ID（UID）为 `1337` 的用户运行应用，因为 `1337` 是为 Sidecar 代理保留的。

- **`NET_ADMIN` 和 `NET_RAW` 权限**：如果您的集群[强制执行](https://kubernetes.io/zh-cn/docs/concepts/policy/pod-security-policy/#enabling-pod-security-policies)了
  [Pod 安全策略](https://kubernetes.io/zh-cn/docs/concepts/policy/pod-security-policy/)，
  必须给 Pod 配置 `NET_ADMIN` 和 `NET_RAW` 权限。如果您使用
  [Istio CNI 插件](/zh/docs/setup/additional-setup/cni/)，可以不配置。

  要检查您的 Pod 是否有 `NET_ADMIN` 和 `NET_RAW` 权限，您需要检查这些 Pod
  的[服务账户](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-service-account/)是否有
  `NET_ADMIN` 和 `NET_RAW` 权限的 Pod 安全策略。如果您没有在 Pod 部署中指定服务账户，
  Pod 会使用其命名空间中的默认服务账户运行。

  要列出服务账户的权限，请在下面的命令中用你的值替换 `<your namespace>` 和
  `<your service account>`。

    {{< text bash >}}
    $ for psp in $(kubectl get psp -o jsonpath="{range .items[*]}{@.metadata.name}{'\n'}{end}"); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:<your namespace>:<your service account>) = yes ]; then kubectl get psp/$psp --no-headers -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
    {{< /text >}}

    例如，要检查 `default` 命名空间中的 `default` 服务账户，运行以下命令：

    {{< text bash >}}
    $ for psp in $(kubectl get psp -o jsonpath="{range .items[*]}{@.metadata.name}{'\n'}{end}"); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:default:default) = yes ]; then kubectl get psp/$psp --no-headers -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
    {{< /text >}}

  如果您在服务账户的允许策略的功能列表中看到 `NET_ADMIN`、`NET_RAW` 或 `*`，
  则您的 Pod 有权限运行 Istio init 容器。否则，您将需要[提供权限](https://kubernetes.io/zh-cn/docs/concepts/security/pod-security-policy)。

- **带有 app 和 version 标签（label）的 Pod**：我们建议显式地给 Deployment 加上 `app`
  和 `version` 标签。给使用 Kubernetes `Deployment` 部署的 Pod 部署配置中增加这些标签，
  可以给 Istio 收集的指标和遥测信息中增加上下文信息。

    - `app` 标签：每个部署配置应该有一个不同的 `app` 标签并且该标签的值应该有一定意义。
      `app` label 用于在分布式追踪中添加上下文信息。

    - `version` 标签：这个标签用于在特定方式部署的应用中表示版本。

## Istio 使用的端口 {#ports-used-by-Istio}

Istio sidecar 代理（Envoy）使用以下端口和协议。

{{< warning >}}
为避免与 Sidecar 发生端口冲突，应用程序不应使用 Envoy 使用的任何端口。
{{< /warning >}}

| 端口 | 协议 | 描述 | 仅限 Pod 内部 |
|----|----|----|----|
| 15000 | TCP  | Envoy 管理端口（命令/诊断） | 是 |
| 15001 | TCP  | Envoy 出站 | 否 |
| 15004 | HTTP | 调试端口 | 是 |
| 15006 | TCP  | Envoy 入站 | 否 |
| 15008 | H2   | HBONE mTLS 隧道端口 | 否 |
| 15009 | H2C  | 用于安全网络的 HBONE 端口 | 否 |
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

为了支持这些情况，请按照[显式协议选择](/zh/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)步骤将应用程序的协议声明为 `TCP`。

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
1. 配置所有客户端发送 `TLS` 流量，通常通过 [`DestinationRule`](/zh/docs/reference/config/networking/destination-rule/#ClientTLSSettings) 或依赖自动 mTLS。
1. 将您的应用程序配置为直接发送 TLS 流量。

## 出站流量 {#outbound-traffic}

为了支持 Istio 的流量路由功能，离开 Pod 的流量可能与未部署 Sidecar 时的流量不同。

对于 HTTP 流量，流量根据 `Host` 标头进行路由。如果目标 IP 和 `Host`
标头未对齐，这可能会导致意外行为。例如，`curl 1.2.3.4 -H "Host: httpbin.default"`
请求将被路由到 `httpbin` 服务，而不是 `1.2.3.4`。

对于非 HTTP 流量（包括 HTTPS），Istio 无法访问 `Host` 标头，
因此路由决策基于服务 IP 地址。

这意味着直接调用 Pod（例如，`curl <POD_IP>`），而不匹配 Service。
虽然流量可以[通过](/zh/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services)，
但它不会获得完整的 Istio 功能，包括 mTLS 加密、流量路由和遥测。
