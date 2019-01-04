---
title: 桌面版 docker
description:  使用桌面版 docker 安装 Istio 的说明。
weight: 15
skip_seealso: true
keywords: [platform-setup,kubernetes,docker-for-desktop]
---

如果你想在桌面版 docker 内置的 Kubernetes 下运行 istio，你可能需要在 docker 首选项的 *Advanced* 面板下增加 docker 的内存限制。Pilot 默认请求内存为 `2048Mi`，这是 docker 的默认限制。

{{< image width="60%"  link="./dockerprefs.png" caption="Docker 首选项"  >}}

或者，您可以通过传递 helm 参数 `--set pilot.resources.requests.memory="512Mi"` 来减少 Pilot 的内存大小。否则 Pilot 可能因资源不足而无法启动。
有关详细信息，请看[安装选项](/zh/docs/reference/config/installation-options)。
