---
title: Istio 1.4.8 发布公告
linktitle: 1.4.8
subtitle: 补丁发布
description: Istio 1.4.8 补丁发布。
publishdate: 2020-04-23
release: 1.4.8
aliases:
    - /zh/news/announcing-1.4.8
---

此版本包含一些错误修复程序，以提高健壮性和用户体验。
此发行说明描述了 Istio 1.4.7 和 Istio 1.4.8 之间的区别。

下面的修复集中于通过使用 CNI 在 OpenShift 上安装 Istio 相关的各种问题上。
使用 CNI 在 OpenShift 上安装 Istio 的说明可以在[这里](/zh/docs/setup/additional-setup/cni/#instructions-for-istio-1-4-x-and-openshift)找到。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- **修复** 修复了在 OpenShift 上安装 CNI 的问题 ([Issue 21421](https://github.com/istio/istio/pull/21421)) ([Issue 22449](https://github.com/istio/istio/issues/22449))。
- **修复** 修复了 CNI 启用时，并非所有入站端口都被重定向的问题 ([Issue 22448](https://github.com/istio/istio/issues/22498))。
- **修复** 修复了网关模板中 GoLang 1.14 的语法错误问题 ([Issue 22366](https://github.com/istio/istio/issues/22366))。
- **修复** 从 `clusterrole` 和 `clusterrolebinding` 中删除名称空间 ([PR 297](https://github.com/istio/cni/pull/297))。
