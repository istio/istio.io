---
title: 为什么我只在部分分布式追踪中看到 `istio-mixer` span ？
weight: 100
---

Mixer 为携带追踪 header 并到达 Mixer 的请求生成应用程序级追踪信息。
Mixer 会生成 span，并将其标记为 `istio-mixer` 以便用于它所做的任何关键工作，包括分发到各个适配器。

Envoy 缓存在数据路径上对 Mixer 的调用。
因此，通过 istio-policy 服务对 Mixer 发出的调用只会在特定的请求中发生，例如：缓存过期或者请求具有不同特征。
正是由于这个原因，您只看到了 Mixer 参与了您的 *一些* 追踪（而非全部）。

要关闭 Mixer 的应用程序级追踪，您必须编辑 `istio-policy` 的部署配置，删除命令行参数 `--trace_zipkin_url`。