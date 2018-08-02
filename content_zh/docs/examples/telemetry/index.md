---
title: 深入遥测
description: 演示如何使用 Istio Mixer 和 Istio sidecar 获取指标和日志，并在不同的服务间进行跟踪。
weight: 30
keywords: [telemetry,metrics,logging,tracing]
aliases:
    - /docs/guides/telemetry/index.html
---

演示如何使用 Istio Mixer 和 Istio sidecar 获取指标和日志，并在不同的服务间进行跟踪。

## 概述

微服务应用部署到 Istio 服务网格中之后，就可以在外部对服务进行监控和跟踪、请求（版本）路由、弹性测试、安全控制以及策略实施等。这一系列功能都是使用一致的方式完成的，并且这些功能都是跨服务、将应用作为一个整体进行控制的。

本文中，我们会使用 [Bookinfo 示例应用](/zh/docs/examples/bookinfo/)来进行演示，无需开发人员对这一多语言应用进行任何修改，运维人员直接就可以从运行中的应用中获取指标和跟踪信息，

## 开始之前

* 跟随[安装指南](/zh/docs/setup/)的步骤，部署 Istio 的控制平面。

* 依照[应用部署指南](/zh/docs/examples/bookinfo/#部署应用)运行 Bookinfo 示例应用。

## 任务

1. [收集指标](/zh/docs/tasks/telemetry/metrics-logs/)：配置 Mixer，收集 Bookinfo 应用中所有服务的系列指标。

1. [查询指标](/zh/docs/tasks/telemetry/querying-metrics/)：安装 Prometheus 插件，用来收集指标，并在 Prometheus 服务中查询 Istio 指标。

1. [分布式跟踪](/zh/docs/tasks/telemetry/distributed-tracing/)：这个任务会使用 Istio 来对应用中请求的流动路径进行跟踪。最终用户所体验的总体延迟在服务之间是如何分布的？分布式跟踪能够解决这一疑问，从而帮助开发人员更快的解决问题，这也是对分布式应用进行分析和排错的有力工具。

1. [使用 Istio Dashboard](/zh/docs/tasks/telemetry/using-istio-dashboard/)：安装 Grafana 插件，这一插件中带有一个预配置 Dashboard，可以用来对服务网格中的流量进行监控。

## 清理

使用 Bookinfo 示例应用完成这些体验之后，可以根据 [Bookinfo 清理任务](/zh/docs/examples/bookinfo/#清理)关停应用。
