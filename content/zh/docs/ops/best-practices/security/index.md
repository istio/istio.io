---
title: 安全最佳实践
description: 使用 Istio 保护应用的最佳实践。
force_inline_toc: true
weight: 30
---

本节提供了一些部署准则，以帮助确保服务网格的安全。

## 命名空间隔离{#use-namespaces-for-isolation}

如果有多个运维人员（也称为 [SRE](https://en.wikipedia.org/wiki/Site_reliability_engineering)）在大型或中型集群中部署不同的服务，我们建议为每个 SRE 团队创建一个单独的 [Kubernetes 命名空间](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/)，以隔离他们的访问权限。
例如，您可以为 `team1` 创建一个 `team1-ns` 命名空间，为 `team2` 创建一个 `team2-ns` 命名空间，以使两个团队无法访问彼此的服务。

{{< warning >}}
如果 Citadel 受到威胁，则它在集群中的所有托管密钥和证书都可能泄露。我们强烈建议您在专用命名空间（例如，`istio-citadel-ns` ）中运行 Citadel，来限制集群的访问权限，仅适用于管理员。
{{< /warning >}}

让我们考虑一个具有三项服务的三层应用程序：`photo-frontend`、`photo-backend` 和 `datastore`。photo SRE 团队管理 `photo-frontend` 和 `photo-backend` 服务，而 datastore SRE 团队管理 `datastore` 服务。`photo-frontend` 服务可以访问 `photo-backend`，而 `photo-backend` 服务可以访问 `datastore`。但是，`photo-frontend` 服务无法访问 `datastore`。

在这种情况下，集群管理员将创建三个命名空间：`istio-citadel-ns`、`photo-ns` 和 `datastore-ns`。管理员有权访问所有命名空间，而每个团队只能访问自己的命名空间。photo SRE 团队创建两个服务帐户，在 `photo-ns` 命名空间中分别运行 `photo-frontend` 和 `photo-backend`。datastore SRE 团队创建了一个服务帐户来在 `datastore-ns` 命名空间中运行 `datastore` 服务。此外，我们需要在 [Istio Mixer](/zh/docs/reference/config/policy-and-telemetry/) 中强制执行服务访问控制，以使 `photo-frontend` 无法访问 datastore。

在这种设置下，Kubernetes 可以隔离管理服务的操作特权。Istio 管理所有命名空间中的证书和密钥，并对服务实施不同的访问控制规则。
