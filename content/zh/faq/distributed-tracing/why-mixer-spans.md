---
title: 为什么在我的一些分布式追踪中会有 `istio-mixer` span？
weight: 100
---

Mixer 为到达 Mixer 并且带有追踪头的请求生成了应用级别的追踪。Mixer 为它做的任何关键工作都生成 span 并且打上了 `istio-mixer` 标签，包括分发到各个适配器。

在数据路径上 Envoy 缓存了到 Mixer 的调用。因此，通过 `istio-policy` 服务向 Mixer 发起的调用只是在一些特定的请求中会有，例如：缓存过期或者不一样的请求特性。由于这个原因，你会看到 Mixer 只参与了 *一些* 追踪。

要关闭 Mixer 的应用级别追踪 span，你必须编辑 `istio-policy` 的 deployment 配置，并且在命令行参数中删除 `--trace_zipkin_url` 参数。
