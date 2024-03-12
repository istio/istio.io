---
title: "Istio Ambient 服务网格已合并到 Istio 的主分支"
description: Ambient 网格的重要里程碑。
publishdate: 2023-02-28
attribution: "John Howard (Google), Lin Sun (Solo.io)"
keywords: [istio,ambient]
---

Istio Ambient 服务网格在实验性分支中于 2022 年 9 月[推出](/zh/blog/2022/introducing-ambient-mesh/)，
引入了一种新的数据平面模式，可以在没有 Sidecar 的情况下使用 Istio。
通过与包括 Google、Solo.io、Microsoft、Intel、Aviatrix、华为、IBM 等在内的 Istio 社区的合作，
我们很高兴地宣布 Istio Ambient 服务网格已从实验性分支毕业，并合并到 Istio 的主分支！
这是 Ambient 网格的重要里程碑，为 Istio 1.18 发布 Ambient 网格以及在 Istio
的未来版本中默认安装 Ambient 网格铺平了道路。

## 与初始发布相比的重大变化 {#major-changes-from-initial-launch}

Ambient 网格旨在简化运营、扩展应用兼容性和减少基础设施成本。
Ambient 网格的最终目标是对您的应用透明，我们所做的一些更改让 ztunnel 和 waypoint 组件更简单、更轻量。

- ztunnel 组件已从头重写，现在能够以快速、安全和轻量级的方式运行。
  欲了解更多信息，请参见[基于 Rust 的 Ztunnel 为 Istio Ambient 服务网格带来革命性变化](/zh/blog/2023/rust-based-ztunnel/)。
- 我们在简化 waypoint 代理配置方面进行了重大变更，以提高其可调试性和性能。
  欲了解更多信息，请参见 [Istio 简化了 Ambient Waypoint 代理](/zh/blog/2023/waypoint-proxy-made-simple/)。
- 添加了 `istioctl x waypoint` 命令，帮助您方便地部署 waypoint 代理；
  还添加了 `istioctl pc workload`，帮助您查看工作负载信息。
- 我们让用户能将 Istio 策略（如 AuthorizationPolicy）显式绑定到
  waypoint 代理，无需再选择目标工作负载。

## 参与进来 {#get-involved}

参阅我们的[入门指南](/zh/docs/ops/ambient/getting-started/)，
现在就可以尝鲜 Ambient 网格 Alpha 版本。我们很乐意听取您的意见！进一步了解 Ambient 网格：

- 在 Istio 的 [Slack](https://slack.istio.io) 中加入 #ambient 和 #ambient-dev 频道。
- 参加每周的 Ambient 网格贡献者[会议](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings)（星期三）。
- 查阅 [Istio](http://github.com/istio/istio) 和 [ztunnel](http://github.com/istio/ztunnel)
  代码库，提交 Issue 或 PR！
