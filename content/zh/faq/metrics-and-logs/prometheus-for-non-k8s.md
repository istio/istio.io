---
title: Prometheus 适配器能在非 Kubernetes 环境下使用吗？
weight: 60
---

您可以使用 docker-compose 来安装 Prometheus，这与您安装普通应用程序类似。
与此同时，由于没有 Kubernetes API 服务，像 Mixer 这样的组件将需要被提供 rules/handlers/instances 的本地配置。
