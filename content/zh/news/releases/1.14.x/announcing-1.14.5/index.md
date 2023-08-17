---
title: Istio 1.14.5 发布公告
linktitle: 1.14.5
subtitle: 补丁发布
description: Istio 1.14.5 补丁发布。
publishdate: 2022-10-11
release: 1.14.5
---

该版本包含了对 [CVE-2022-39278](/zh/news/security/istio-security-2022-007/#cve-2022-39278)
的修复以及改进稳健性的漏洞修复。本发布说明描述了
Istio 1.14.4 和 Istio 1.14.5 之间的不同之处。

供参考，该版本包括（2022-10-04 发布的）Go 1.18.7 中对 `archive/tar`、
`net/http/httputil` 和 `regexp` 包的安全修复。

{{< relnote >}}

## 变更{#changes}

- **修复** 修复了一些 `ServiceEntry`
  主机名可能导致不确定的 Envoy 路由的问题。
  ([Issue #38678](https://github.com/istio/istio/issues/38678))

- **修复** 修复了 `kube-inject` 在设置 Pod 注解 `proxy.istio.io/config`
  时崩溃的问题。

- **修复** 修复了如果 istiod 未运行，用户无法删除带有修订版的
  Istio Operator 资源的问题。
  ([Issue #40796](https://github.com/istio/istio/issues/40796))

- **修复** 修复了在 1.14.0 中 Passthrough 集群的默认 `idleTimeout`
  更改为 `0s` 会禁用超时的问题。将其恢复为之前的行为，即 Envoy 的默认值 1 小时。
  ([Issue #41114](https://github.com/istio/istio/issues/41114))

- **修复** 修复了 `jwks` 动态生成的返回值不是 base64 编码导致
  Envoy 无法解析它的错误。

- **修复** 修复了添加 `ServiceEntry`
  可能会影响具有相同主机名的现有 `ServiceEntry` 的问题。
  ([Issue #40166](https://github.com/istio/istio/issues/40166))

- **修复** 修复了根命名空间 `Sidecar` 配置会被忽略的问题。

- **修复** 修复了移除 `v1alpha2` 版本时 Gateway API 集成不失败的问题。
