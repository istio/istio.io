---
title: Istio 1.4.1 发布
linktitle: 1.4.1
subtitle: 补丁发布
description: Istio 1.4.1 补丁发布。
publishdate: 2019-12-05
release: 1.4.1
aliases:
    - /zh/news/announcing-1.4.1

---

此次发布包括了一些 bug 修复来提升健壮性。此次发布的注意事项描述了 Istio 1.4.0 和 Istio 1.4.1 之间的差异。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- **修复** Windows 安装 `istioctl` 的问题 ([Issue 19020](https://github.com/istio/istio/pull/19020)).
- **修复** 当在 Kubernetes Ingress 中使用 cert-manager 的一个路由匹配顺序问题 ([Issue 19000](https://github.com/istio/istio/pull/19000)).
- **修复** 当 pod 名称包含 `.` 时 Mixer 的 source namespace 属性配置错误的问题 ([Issue 19015](https://github.com/istio/istio/issues/19015)).
- **修复** Galley 生成了过多的指标数据的问题 ([Issue 19165](https://github.com/istio/istio/issues/19165)).
- **修复** 使追踪服务的端口恢复为监听80 ([Issue 19227](https://github.com/istio/istio/issues/19227)).
- **修复** 缺失 `istioctl` 自动补齐文件的问题 ([Issue 19297](https://github.com/istio/istio/issues/19297)).
