---
title: 组件内检
description: 描述如何使用 ControlZ 检测查看单个组件的运行状态。
weight: 20
keywords: [ops, 运维]
---

Istio 的组件使用了一种灵活的内检（Introspection）框架构建，因此可以方便地查看和调整正在运行中组件的内部状态。
组件会开启一个端口，用来通过浏览器得到查看组件状态的交互式视图，或者供外部工具通过 REST 接口进行连接和控制。

Mixer、Pilot 和 Galley 都实现了 ControlZ 功能。这些组件启动时将打印一条日志，提示通过 ControlZ 进行交互需连接到的 IP 地址和端口。

{{< text plain >}}
2018-07-26T23:28:48.889370Z     info    ControlZ available at 100.76.122.230:9876
{{< /text >}}

下面是 ControlZ 界面的示例：

{{< image width="80%" link="/help/ops/controlz/ctrlz.png" caption="ControlZ 用户界面" >}}

当启动组件时，可以通过命令行参数 `--ctrlz_port` 和 `--ctrlz_address` 指定特定的地址和端口来控制 ControlZ 暴露的地址。

