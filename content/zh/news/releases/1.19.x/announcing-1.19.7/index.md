---
title: 发布 Istio 1.19.7
linktitle: 1.19.7
subtitle: 补丁发布
description: Istio 1.19.7 补丁发布。
publishdate: 2024-02-09
release: 1.19.7
---

本次发布实现了 2 月 8 日公布的安全更新 [`ISTIO-SECURITY-2024-001`](/zh/news/security/istio-security-2024-001)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.19.6 和 Istio 1.19.7 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了更新服务的 `TargetPort` 不会触发 xDS 推送的问题。
  ([Issue #48580](https://github.com/istio/istio/issues/48580))

- **修复** 修复了安装程序意外删除使用 `istioctl tag set` 生成的 webhook 的问题。
  ([Issue #47423](https://github.com/istio/istio/issues/47423))

- **修复** 修复了一个会导致没有关联服务（包括同一命名空间内的所有服务）的 Pod 生成错误配置的问题。
  这有时会导致入站侦听器冲突错误。

- **修复** 修复了一个导致 `PeerAuthentication` 在 Ambient 模式下过于严格的错误。

- **修复** 修复了导致 Istio CNI 在最小/锁定节点上停止运行的问题（例如没有 `sh` 二进制文件）。
  新逻辑无需任何外部依赖即可运行，并且如果遇到错误（这可能是由 SELinux 规则等原因引起的），
  它将尝试继续运行。特别指出，这修复了在 Bottlerocket 节点上运行 Istio 的问题。
  ([Issue #48746](https://github.com/istio/istio/issues/48746))
