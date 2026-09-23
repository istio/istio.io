---
title: "需要采取行动：GOOGLE Con​​tainer Registry 用户、尖叫测试以及我们迁移到 AWS"
description: 您可以使用 Helm Chart 和签名密钥来确保您不会受到迁移到 AWS 的影响。
publishdate: 2026-08-21
attribution: Steven Jin (Microsoft), Keith Mattix (Solo.io); Translated by Wilson Wu (DaoCloud)
keywords: [Istio,Container Registry,Helm]
---

今年，由于我们的融资模式发生变化，Istio 正在将我们的所有基础设施从 Google Cloud Platform
迁移到 Amazon Web Services。这篇文章描述了我们的容器镜像、Helm Chart、其他发布制品（RPM、DEB、源代码、SPDX 文档、`istioctl` 和许可证）、
签名密钥以及**即将进行的尖叫测试（我们将在其中禁用对所有 GCP 托管制品的访问）的过渡**。

## 容器镜像 {#container-images}

在[之前的博文](../retirement-of-gcr.io-follow-up/)中，
我们宣布 `gcr.io/istio-release` 和 `registry.istio.io` 容器注册中心将于 2026 年 12 月停用，
并且我们只会将 Istio 容器镜像发布到 Docker Hub。从 Istio 1.31 开始，
我们只会将 Istio 容器镜像发布到 `docker.io/istio`。
请参阅[上一篇博客文章](../retirement-of-gcr.io-follow-up/)，
了解有关从 `gcr.io/istio-release` 和 `registry.istio.io` 迁移的详细信息。

## Helm Chart 和其他发布制品 {#helm-charts-and-other-release-artifacts}

从历史上看，Istio 将 Helm Chart 作为 OCI 制品发布到 `https://istio-release.storage.googleapis.com/charts`
以及 `gcr.io/istio-release/charts`。同样，我们将其他发布制品（RPM、DEB、源代码、SPDX 文档、`istioctl` 和许可证）发布到
`https://istio-release.storage.googleapis.com/releases`。
Helm Chart 和其他发布制品将于 2026 年 12 月从上述位置删除。
所有 Istio 版本的所有 Helm Chart 目前均可在 `https://blob.istio.io/istio-release/charts` 上获取，
在可预见的未来，我们将继续在那里发布它们。所有 Istio 版本的所有
OCI Helm Chart 目前均可在 `ghcr.io/istio/release/charts` 上获取，
在可预见的未来，我们将继续在那里发布它们。目前，所有 Istio 版本的所有其他发布制品都可以在
`https://blob.istio.io/istio-release/releases` 上找到，
在可预见的将来，我们将继续在那里发布它们。Istio 1.30 将是最后一个次要版本，
其中包含 Helm Chart、OCI Helm Chart 以及发布到 `gcr.io/istio-release`、`registry.istio.io/release`
和 `https://istio-release.storage.googleapis.com/charts` 的镜像。
Istio 1.31 **不会**有 Helm Chart、OCI Helm Chart，也不会发布到 `gcr.io/istio-release/`、
`registry.istio.io/release` 和 `https://istio-release.storage.googleapis.com/charts`
的镜像。更多信息将在发行说明中提供。

## 签名密钥 {#signing-keys}

迁移的结果是，我们将切换公钥/私钥对。在可预见的未来，我们仍将在
`https://istio.io/misc/istio-key.pub` 托管旧公钥。
但是，较新的镜像将使用新密钥进行签名，该密钥将在 `https://istio.io/misc/istio-key-v2.pub` 中提供相应的公钥。

我们期望每个版本使用以下签名密钥：

| 版本 | 签名公钥 |
|---------|-------------|
| 1.18.x - 1.30.x | `https://istio.io/misc/istio-key.pub` |
| 1.31.0 | `https://istio.io/misc/istio-key.pub` |
| 1.31.1+  | `https://istio.io/misc/istio-key-v2.pub` |

## “尖叫测试”及其应对措施 {#scream-tests-and-what-you-need-to-do}

我们将进行一系列“尖叫测试”，暂时禁用对 `gcr.io/istio-release`、`registry.istio.io/release`
和 `https://istio-release.storage.googleapis.com/` 的访问。
首次尖叫测试将于 UTC 时间 2026 年 9 月 15 日下午 3:00 至 4:00 进行。
第二次尖叫测试将于 UTC 时间 2026 年 10 月 13 日下午 3:00 至 6:00 进行。
第三次尖叫测试将于 UTC 时间 2026 年 11 月 17 日下午 3:00 至晚上 9:00 进行。
第四次也是最后一次尖叫测试将于 2026 年 12 月 8 日下午 3:00 UTC 至 2026 年 12 月 9 日下午 3:00 UTC 进行。

如果您正在使用 `registry.istio.io/release` 或 `gcr.io/istio-release`，
您应该尽快迁移到 `docker.io/istio` 或直通缓存。如果您使用
`https://istio-release.storage.googleapis.com/charts` 中的
Helm Chart 安装 Istio，则应尽快迁移到 `https://blob.istio.io/istio-release/charts`。
如果您使用 OCI Helm Chart 在 `gcr.io/istio-release/charts` 安装 Istio，
则应尽快迁移到 `ghcr.io/istio/release/charts`。如果您验证 Istio 镜像的签名，
请留意您的 Istio 版本使用的签名密钥，并相应地更新您的公钥。
您应该尽快完成迁移，以避免 Istio 部署出现任何中断。
