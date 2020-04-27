---
title: Istio 0.8 发布公告
linktitle: 0.8
subtitle: 重大更新
description: Istio 0.8 发布公告。
publishdate: 2018-06-01
release: 0.8.0
aliases:
    - /zh/about/notes/0.8
    - /zh/about/notes/0.8/index.html
    - /zh/news/2018/announcing-0.8
    - /zh/news/announcing-0.8
---

这是迈向 Istio 1.0 前的一个重要版本。除了常规的 bug 修复和性能改进之外，还包含许多新功能和体系结构改进。

{{< relnote >}}

## 网络{#networking}

- **改良的流量管理模型**。我们终于准备好完成我们的[新流量管理 API](/zh/blog/2018/v1alpha3-routing/) 的总结。我们相信，在涵盖更多实际部署[用例](/zh/docs/tasks/traffic-management/)的同时，这种新模型更易于理解。对于从早期发行版升级的人，这儿有一个[迁移指南](/zh/docs/setup/upgrade/)和内置在 `istioctl` 中的转换工具，可帮助您从旧模型转换配置。

- **Envoy 流式配置**。默认情况下，Pilot 现在使用其 [ADS API](https://github.com/envoyproxy/data-plane-api/blob/master/xds_protocol.rst) 将配置流式传输到 Envoy。这种新方法提高了有效的可伸缩性，减少了推出延迟，应该能消除虚假的 404 错误。

- **Ingress/Egress 的 Gateway**。我们不再支持将 Kubernetes Ingress 规范与 Istio 路由规则结合使用，因为它导致了许多错误和可靠性问题。Istio 现在支持用于 ingress 和 egress 代理的独立于平台的 [Gateway](/zh/docs/concepts/traffic-management/#gateways) 模型，该模型可跨 Kubernetes 和 Cloud Foundry 使用，并与路由无缝协作。Gateway 支持基于[服务器名称指示](https://en.wikipedia.org/wiki/Server_Name_Indication)的路由，并基于客户端提供的服务器名称提供证书。

- **受限的入站端口**。现在，我们将 Pod 中的入站端口限制为该 Pod 中运行的应用所声明的端口。

## 安全{#security}

- **Citadel 介绍**。我们终于给安全组件起了个名字。以前的 Istio-Auth 或者 Istio-CA 现在被统称为 Citadel。

- **多集群支持**。我们在多集群部署中支持每一个集群的 Citadel，以便所有 Citadel 共享相同的根证书，并且工作负载可以在整个网格上相互认证。

- **认证策略**。我们为[认证策略](/zh/docs/tasks/security/authentication/authn-policy/)创建了一个统一的 API，用于控制服务到服务的通信是否使用双向 TLS 以及最终用户身份验证。这是现在控制这些行为的推荐方法。

## 遥测{#telemetry}

- **自我报告**。Mixer 和 Pilot 现在会产生遥测，该遥测流经正常的 Istio 遥测管道，就像网格中的服务一样。

## 安装{#setup}

- **Istio 安装菜单**。Istio 具有一系列丰富的功能，但是您并不需要全部安装或使用它们。通过使用 Helm 或 `istioctl gen-deploy`，用户可以只安装他们想要的功能。例如，用户可以只安装 Pilot 并享受流量管理功能，而无需处理 Mixer 或 Citadel。

## Mixer 适配器{#mixer-adapters}

- **CloudWatch**。Mixer 现在可以将指标报告给 AWS CloudWatch。[了解更多](/zh/docs/reference/config/policy-and-telemetry/adapters/cloudwatch/)

## 0.8 已知问题{#known-issues-with-0.8}

- 有关指向 headless 服务的虚拟服务的网关无法工作（[Issue #5005](https://github.com/istio/istio/issues/5005)）。

- 这是一个 [Google Kubernetes Engine 1.10.2 的问题](https://github.com/istio/istio/issues/5723)。变通的方法是使用 Kubernetes 1.9 或者将节点的镜像切换为 Ubuntu。该问题预计在 GKE 1.10.4 会得到修复。

- `istioctl experimental convert-networking-config` 工具存在一个已知的命名空间问题，所需的命名空间可能会被修改为 `istio-system`，请在运行对话工具后手动将其修改为所需的命名空间。[了解更多](https://github.com/istio/istio/issues/5817)
