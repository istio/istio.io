---
title: 组件自检
description: 介绍如何使用 ControlZ 深入了解各个运行组件。
weight: 60
keywords: [ops]
aliases:
  - /zh/help/ops/controlz
  - /zh/docs/ops/troubleshooting/controlz
---

Istio 组件使用灵活的自检框架（Introspection）构建，该框架使查看和调整正在运行组件的内部状态变得容易。
组件开启一个端口，可以从 Web 浏览器使用该端口获取组件状态的交互式视图，或者外部工具通过 REST 接口进行访问和控制。

Mixer，Pilot 和 Galley 均实现了 ControlZ 功能。当这些组件启动时将打印一条日志，指示要与 ControlZ 进行交互的 IP 地址和端口。

{{< text plain >}}
2018-07-26T23:28:48.889370Z     info    ControlZ available at 100.76.122.230:9876
{{< /text >}}

这是 ControlZ 界面的示例：

{{< image width="80%" link="./ctrlz.png" caption="ControlZ User Interface" >}}

要访问已部署组件 (例如 Mixer、Galley、Pilot) 的 ControlZ 页面，您可以用端口转发方式将 ControlZ 映射到本地，并通过本地浏览器进行访问：

{{< text bash >}}
$ istioctl dashboard controlz <podname>
{{< /text >}}

这会将组件的 ControlZ 页面重定向到 `http://localhost:9876` 进行远程访问。

