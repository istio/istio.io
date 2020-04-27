---
title: 升级说明
description: 升级到 Istio 1.3 时要考虑的重要变更。
weight: 20
aliases:
    - /zh/docs/setup/kubernetes/upgrade/notice/
    - /zh/docs/setup/upgrade/notice
---

此页面描述了从 Istio 1.2 升级到 1.3 时需要注意的更改。我们在这里详细介绍了有意破坏向后兼容性的情况。我们还提到了保留向后兼容性但引入新行为的情况，这对于熟悉 Istio 1.2 的使用和操作的人来说是令人惊讶的。

## 安装与升级{#installation-and-upgrade}

我们简化了 Mixer 的配置模型，并在 1.3 中完全删除了对特定适配器和特定模板的自定义资源定义（CRD）的支持。请转向新的配置模型。

我们从系统中删除了 Mixer CRD，以简化配置模型，提高 Kubernetes 部署中 Mixer 的性能，并提高各种 Kubernetes 环境中的可靠性。

## 流量管理{#traffic-management}

Istio 现在默认情况下会捕获所有端口。如果您没有指定容器端口来故意绕过 Envoy，则必须使用 `traffic.sidecar.istio.io/excludeInboundPorts` 选项来选择退出端口捕获。

现在默认情况下启用协议嗅探。当您想升级来获得以前的行为时请使用 `--set pilot.enableProtocolSniffing=false` 选项来禁用协议嗅探。要了解更多信息，请参考我们的[协议选择](/zh/docs/ops/configuration/traffic-management/protocol-selection/)。

要想在多个命名空间指定一个主机名，您必须使用 [`Sidecar` 资源](/zh/docs/reference/config/networking/sidecar/)来选择单个主机。

## 信任域名验证{#trust-domain-validation}

信任域名验证是 Istio 1.3 中的新增功能。如果您只有一个信任域名，或者没有通过身份验证策略启用双向 TLS，则无需执行任何操作。

要选择退出信任域名验证，请在升级到 Istio 1.3 之前在 Helm 模板中添加以下标志:
`--set pilot.env.PILOT_SKIP_VALIDATE_TRUST_DOMAIN=true`

## Secret 发现服务{#secret-discovery-service}

在 Istio 1.3 中，我们正在利用 Kubernetes 的改进来更安全地为工作负载实例颁发证书。

Kubernetes 1.12 引入了 `值得信赖的` JWTs 来解决这些问题。
[Kubernetes 1.13](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.13.md) 引入了将 `aud` 字段的值更改为 API server 以外的值的功能。`aud` 字段代表了 Kubernetes 的 audience 。为了更好地保护网格，Istio 1.3 仅支持 `值得信赖的` JWT，并且当您启用 SDS 后，要求 audience ，也就是 `aud` 字段的值，为 `istio-ca`。

在启用 SDS 的情况下升级到 Istio 1.3 之前，请参阅我们的博客文章[可信赖的 JWT 和 SDS](/zh/blog/2019/trustworthy-jwt-sds/)。
