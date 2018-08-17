---
title: Prometheus 适配器可以用于非 Kubernetes 环境吗？
weight: 60
---

您可以使用 docker-compose 来安装 Prometheus，这与你[安装](/docs/setup/consul/quick-start/#deploy-your-application)应用程序十分类似。此外，如果没有 Kubernetes API 服务器，像 Mixer 这样的组件将会对规则、处理程序以及实例进行本地配置。