---
title: Injection
test: n/a
---

注入，或 sidecar 注入，是指在创建时使用 [动态 Webhooks](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/extensible-admission-controllers/) 来修改 Pod 规范。
注入可用于为网格服务添加 Envoy sidecar 配置或配置 [网关](/zh/docs/reference/glossary/#gateway) 的 Envoy 代理。

有关更多信息，请参阅 [安装 sidecar](/zh/docs/setup/additional-setup/sidecar-injection)。
