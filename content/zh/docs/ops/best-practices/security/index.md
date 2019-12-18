---
title: 安全性的最佳实践
description: 使用 Istio 保护应用程序的最佳做法。
force_inline_toc: true
weight: 30
---

本章节提供了一些部署准则，以帮助确保服务网格的安全。

## 使用命名空间进行隔离

如果有多个服务运营商（又称 [SREs](https://en.wikipedia.org/wiki/Site_reliability_engineering))在一个中型或者大型的集群中部署不同的服务，我们建议为每一个 SRE 团队创建一个单独的 [Kubernetes namespace](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/) 以隔离其访问权限。
例如，你可以为 `team1` 创建一个 `team1-ns` 的命名空间，并为 `team2` 创建 `team2-ns` 命名空间， 这样，两个团队就无法访问彼此的服务。

{{< warning >}}
如果 Citadel 受到威胁，则集群中所有被他托管的密钥和证书都可能会被公开。
我们 **强烈** 建议你在一个专门的命名空间（例如，“istio-citadel-ns”）中运行 Citadel，限制该集群只有管理员才可以访问。
{{< /warning >}}

让我们考虑一个有三个服务的三层应用程序：`photo-frontend`、
`photo-backend` 和 `datastore`。照片 SRE 团队管理 `photo-frontend` 和 `photo-backend` 服务，而 数据存储 SRE 团队管理 `datastore` 服务。 `photo-frontend` 服务可以访问 `photo-backend`，并且 `photo-backend` 可以访问 `datastore`。
然而，`photo-frontend` 服务不能访问 `datastore`。

在这个场景中，集群管理员创建了 3 个命名空间：
`istio-citadel-ns`、 `photo-ns` 和 `datastore-ns`。管理员可以访问所有命名空间，而每个团队只能访问他们自己的命名空间。
照片 SRE 团队在 `photo-ns` 命名空间中为运行 `photo-frontend` 服务和 `photo-frontend` 服务分别创建了 2 个服务账号。
数据存储 SRE 团队在 `datastore-ns` 命名空间中为运行 `datastore` 服务创建了一个服务账号。 此外， 我们需要在 [Istio Mixer](/zh/docs/reference/config/policy-and-telemetry/) 中强制执行服务访问控制，使得 `photo-frontend` 无法访问数据存储服务。

在这个设置中，Kubernetes 可以隔离操作员管理服务的特权。
Istio 管理所有命名空间中的证书和密钥并对服务实施不同的访问控制规则。
