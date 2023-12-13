---
title: 发布 Istio 1.20.1
linktitle: 1.20.1
subtitle: 补丁发布
description: Istio 1.20.1 补丁发布。
publishdate: 2023-12-12
release: 1.20.1
---

本次发布实现了 12 月 12 日公布的安全更新 [`ISTIO-SECURITY-2023-005`](/zh/news/security/istio-security-2023-005)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.20.0 和 Istio 1.20.1 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 `istioctl tag set` 生成的 Webhook 意外被安装程序移除的问题。
  ([Issue #47423](https://github.com/istio/istio/issues/47423))

- **修复** 修复了 `istioctl tag list` 命令不接受 `--output` 标志的问题。
  ([Issue #47696](https://github.com/istio/istio/issues/47696))

- **修复** 修复了由于 OpenShift 设置了 Pod 的 `SecurityContext.RunAs`
  字段而导致在 OpenShift 上自定义注入 `istio-proxy` 容器时无法正常工作的问题。

- **修复** 修复了在设置 `header-name: {}` 时 `VirtualService` 中的
  HTTP 头存在匹配无法正常工作的问题。
  ([Issue #47341](https://github.com/istio/istio/issues/47341))

- **修复** 修复了多集群领导者选举时未优先考虑本地领导者而考虑远程领导者的问题。
  ([Issue #47901](https://github.com/istio/istio/issues/47901))

- **修复** 修复了 `hostNetwork` 的 Pod 扩缩时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **修复** 修复了 `WorkloadEntries` 更改 IP 地址时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **修复** 修复了删除 `ServiceEntry` 时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **改进** 通过减少对 Kubernetes API 的调用次数改进了 `istioctl bug-report`
  的性能。报告中包含的 Pod/节点详情仍然全面，但显示方式有所不同。

- **移除** 移除了 `istioctl bug-report` 的 `--rps-limit` 标志，
  并**新增**了 `--rq-concurrency` 标志。
  这个变化使得 Bug 报告生成器能够限制请求的并发而不是到 Kubernetes API 的请求速率。

## 安全更新 {#security-update}

- 按照 [`ISTIO-SECURITY-2023-005`](/zh/news/security/istio-security-2023-005) 所述，
  对 Istio CNI 权限进行了变更。
