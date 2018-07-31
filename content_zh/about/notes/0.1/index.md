---
title: Istio 0.1
weight: 100
aliases:
    - /docs/welcome/notes/0.1.html
page_icon: /img/notes.svg
---

Istio 0.1 是 Istio 的第一个 [release](https://github.com/istio/istio/releases)，它适用于单个 Kubernetes 集群，并支持以下功能：

- 使用单个命令将 Istio 安装到 Kubernetes 命名空间中。
- 将 Envoy 代理半自动注入 Kubernetes pod。
- 使用 iptables 自动捕获 Kubernetes pod 的流量。
- HTTP、gRPC 和 TCP 流量的群集内负载均衡。
- 支持超时、重试预算和断路器。
- Istio 集成的 Kubernetes Ingress 支持（ Istio 充当 Ingress 控制器）。
- 细粒度的流量路由控制、包括 A/B 测试、金丝雀部署、红/黑部署。
- 灵活的内存速率限制 。
- L7 遥测和使用 Prometheus 记录 HTTP 和 gRPC。
- Grafana 仪表板显示每服务 L7 指标。
- 请求使用 Zipkin 通过 Envoy 进行追踪。
- 使用双向 TLS 的服务到服务身份验证。
- 使用拒绝表达式的简单服务到服务授权。
