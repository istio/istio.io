---
title: Istio 1.13.9 发布公告
linktitle: 1.13.9
subtitle: 补丁发布
description: Istio 1.13.9 补丁发布。
publishdate: 2022-10-11
release: 1.13.9
---

该版本包含了对 [CVE-2022-39278](/zh/news/security/istio-security-2022-007/#cve-2022-39278)
的修复以及改进稳健性的漏洞修复。本发布说明描述了
Istio 1.13.8 和 Istio 1.13.9 之间的不同之处。

{{< relnote >}}

## 安全更新{#security-updates}

- [CVE-2022-41715](https://github.com/golang/go/issues/55949) 的补丁。
  用 Go 1.19.2 `stdlib` 实现替换所有对 `stdlib`，`regexp` 的使用。
  这将通过格式错误的正则表达式来防止 DOS。

## 变更{#changes}

- **修复** 修复了如果 istiod 未运行，
  用户无法删除带有修订版的 Istio Operator 资源的问题。
  ([Issue #40796](https://github.com/istio/istio/issues/40796))

- **修复** 修复了 `jwks` 动态生成的返回值不是 base64 编码导致
  Envoy 无法解析它的错误。

- **修复** 修复了根命名空间 `Sidecar` 配置会被忽略的问题。

- **修复** 修复了移除 `v1alpha2` 版本时 Gateway API 集成不失败的问题。
