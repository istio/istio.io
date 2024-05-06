---
title: 发布 Istio 1.19.5
linktitle: 1.19.5
subtitle: 补丁发布
description: Istio 1.19.5 补丁发布。
publishdate: 2023-12-12
release: 1.19.5
---

本次发布实现了 12 月 12 日公布的安全更新 [`ISTIO-SECURITY-2023-005`](/zh/news/security/istio-security-2023-005)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.19.4 和 Istio 1.19.5 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 `istioctl tag set` 生成的 Webhook 意外被安装程序移除的问题。
  ([Issue #47423](https://github.com/istio/istio/issues/47423))

- **修复** 修复了多集群领导者选举时未优先考虑本地领导者而考虑远程领导者的问题。
  ([Issue #47901](https://github.com/istio/istio/issues/47901))

- **修复** 修复了 `hostNetwork` 的 Pod 扩缩时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **修复** 修复了 `WorkloadEntries` 更改 IP 地址时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **修复** 修复了删除 `ServiceEntry` 时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

## 安全更新 {#security-update}

- 按照 [`ISTIO-SECURITY-2023-005`](/zh/news/security/istio-security-2023-005) 所述，
  对 Istio CNI 权限进行了变更。
