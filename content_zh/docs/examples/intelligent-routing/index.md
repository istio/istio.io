---
title: 智能路由
description: 如何在 Istio 服务网格中使用多种流量管理功能。
weight: 20
keywords: [traffic-management,routing]
---

本文示例演示了如何在 Istio 服务网格中使用多种流量管理功能。

## 概述

微服务应用部署到 Istio 服务网格中之后，就可以在外部对服务进行监控和追踪、请求（版本）路由、弹性测试、安全控制以及策略实施等。这一系列功能都是使用一致的方式完成的，并且这些功能都是跨服务、将应用作为一个整体进行控制的。

本文中，我们会使用 [Bookinfo 示例应用](/zh/docs/examples/bookinfo/)，演示运维人员对运行中的应用进行请求路由的动态配置以及故障注入的方法。

## 开始之前

* 依照[安装指南](/zh/docs/setup/)的步骤，部署 Istio 的控制平面。

* 依照[应用部署指南](/zh/docs/examples/bookinfo/#部署应用)运行 Bookinfo 示例应用。

## 任务

1. [请求路由](/zh/docs/tasks/traffic-management/request-routing/)任务首先会把 Bookinfo 应用的进入流量导向 `reviews` 服务的 `v1` 版本。接下来会把特定用户的请求发送给 `v2` 版本，其他用户则不受影响。

1. [故障注入](/zh/docs/tasks/traffic-management/fault-injection/)任务会使用 Istio 测试 Bookinfo 应用的弹性，具体方式就是在 `reviews:v2` 和 `ratings` 之间进行延迟注入。接下来以测试用户的角度观察后续行为，我们会注意到 `reviews` 服务的 `v2` 版本有一个 Bug。注意所有其他用户都不会感知到正在进行的测试过程。

1. [流量迁移](/zh/docs/tasks/traffic-management/traffic-shifting/)，最后，会使用 Istio 将所有用户的流量从 `reviews` 的 `v2` 版本转移到 `v3` 版本之中，以此来规避 `v2` 版本中 Bug 造成的影响。

## 清理

使用 Bookinfo 示例应用完成这些体验之后，可以根据 [Bookinfo 清理任务](/zh/docs/examples/bookinfo/#清理)关停应用。
