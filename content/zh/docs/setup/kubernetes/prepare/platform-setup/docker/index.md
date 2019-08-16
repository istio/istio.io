---
title: 桌面版 Docker
description:  使用桌面版 Docker 安装 Istio 的说明。
weight: 12
skip_seealso: true
keywords: [platform-setup,kubernetes,docker-for-desktop]
---

如果你想在桌面版 Docker 内置的 Kubernetes 下运行 Istio，你可能需要在 Docker 首选项的 *Advanced* 面板下增加 Docker 的内存限制。Pilot 默认请求内存为 `2048Mi`，这是 Docker 的默认限制。

{{< image width="60%" link="/docs/setup/platform-setup/docker/dockerprefs.png" caption="Docker 首选项"  >}}

也可以通过传递 Helm 参数 `--set pilot.resources.requests.memory="512Mi"` 来减少 Pilot 的内存请求。否则 Pilot 可能因资源不足而无法启动。
有关详细信息，请看[安装选项](/zh/docs/reference/config/installation-options)。
