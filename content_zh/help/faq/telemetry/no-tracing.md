---
title: 请求没有被追踪
weight: 20
---

从 Istio 1.0.3 开始，使用 helm chart 安装的 Istio，其默认追踪采样率已经降低到 1%。
这意味着 Istio 捕获的 100 个追踪实例中只有 1 个将被报告给追踪后端。
`istio-demo.yaml` 文件中的采样率仍设为 100%。
有关如何设置采样率的更多信息，请参见[本节](/docs/tasks/telemetry/distributed-tracing)。
