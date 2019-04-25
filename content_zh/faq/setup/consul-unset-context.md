---
title: Consul - 如何取消最后由 kubectl 更改的上下文？
weight: 50
---

使用 `kubectl use-context istio` 命令后，你的 `kubectl` 被切换为 Istio 上下文。您可以使用 `kubectl config get-contexts` 来获取上下文列表，然后使用 `kubectl config use-context {desired-context}` 切换到你想要使用的上下文。
