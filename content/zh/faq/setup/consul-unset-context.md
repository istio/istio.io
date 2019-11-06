---
title: Consul - 怎么取消 kubectl 对上下文的修改？
weight: 50
---

执行命令 `kubectl use-context istio` 后，你的 `kubectl` 会切换至 Istio 上下文。
你可以使用 `kubectl config get-contexts` 获取上下文列表，
并通过 `kubectl config use-context {desired-context}` 切换至你想要的上下文。
