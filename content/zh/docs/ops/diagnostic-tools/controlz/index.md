---
title: 组件自检
description: 介绍如何使用 ControlZ 深入了解正在运行的 istiod 组件。
weight: 60
keywords: [ops]
aliases:
  - /zh/help/ops/controlz
  - /zh/docs/ops/troubleshooting/controlz
owner: istio/wg-user-experience-maintainers
test: no
---

Istiod 构建了一个灵活的自检框架，称为 ControlZ，它使得检查和操作 istiod 实例的内部状态变得很容易。
Istiod 会开启一个端口，使得可以从 Web 浏览器使用该端口获取组件状态的交互式视图，或者通过 REST 接口通过外部工具进行访问和控制。

当 Istiod 启动时，会记录一条消息，指示要连接到的 IP 地址和端口以便与 ControlZ 交互。

{{< text plain >}}
2020-08-04T23:28:48.889370Z     info    ControlZ available at 100.76.122.230:9876
{{< /text >}}

这是 ControlZ 界面的示例：

{{< image width="90%" link="./ctrlz.png" caption="ControlZ User Interface" >}}

要访问 istiod 的 ControlZ 页面，您可以在本地转发其 ControlZ 端点，并通过本地浏览器进行连接：

{{< text bash >}}
$ istioctl dashboard controlz deployment/istiod.istio-system
{{< /text >}}

这会将组件的 ControlZ 页面重定向到 `http://localhost:9876` 进行远程访问。

