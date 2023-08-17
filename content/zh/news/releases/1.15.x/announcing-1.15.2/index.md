---
title: 发布 Istio 1.15.2
linktitle: 1.15.2
subtitle: 补丁发布
description: Istio 1.15.2 补丁发布。
publishdate: 2022-10-11
release: 1.15.2
---

该版本包含了对 [CVE-2022-39278](/zh/news/security/istio-security-2022-007/#cve-2022-39278)
的修复以及改进稳健性的漏洞修复。
本发布说明描述了 Istio 1.15.1 和 Istio 1.15.2 之间的不同之处。

仅供参考，该版本包括（2022-10-04 发布的）Go 1.19.2 中对 `archive/tar`、`net/http/httputil`
和 `regexp` 包的安全修复。
{{< relnote >}}}

## 变更{#changes}

- **修复** 修复了在 1.14.0 中 Passthrough 集群的默认 `idleTimeout` 更改为 `0s` 会禁用超时的问题。
  将其恢复为之前的行为，即 Envoy 的默认值 1 小时。
  ([Issue #41114](https://github.com/istio/istio/issues/41114))

- **修复** 修复了移除 `v1alpha2` 版本时 Gateway API 集成不失败的问题。

- **修复** 修复了处理已弃用的自动扩缩设置时的问题。
  ([Issue #41011](https://github.com/istio/istio/issues/41011))
