---
title: Istio 1.4.3 发布
linktitle: 1.4.3
subtitle: 补丁发布
description: Istio 1.4.3 补丁发布。
publishdate: 2020-01-08
release: 1.4.3
aliases:
    - /zh/news/announcing-1.4.3
---

此版本包含一些错误修复程序，以提高健壮性和用户体验。此发行说明描述了 Istio 1.4.2 和 Istio 1.4.3 之间的区别。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- **修复** Mixer 创建太多 watches，`kube-apiserver` 超载的问题 ([Issue 19481](https://github.com/istio/istio/issues/19481))。
- **修复** pod 包含多个没有暴露端口的容器时的注入问题 ([Issue 18594](https://github.com/istio/istio/issues/18594))。
- **修复** 对 `regex` 字段验证过于严格的问题 ([Issue 19212](https://github.com/istio/istio/pull/19212))。
- **修复** 对 `regex` 字段升级的问题 ([Issue 19665](https://github.com/istio/istio/pull/19665))。
- **修复** `istioctl` 安装以正确将日志发送到 `stderr` 的问题 ([Issue 17743](https://github.com/istio/istio/issues/17743))。
- **修复** 无法为 `istioctl` 安装指定文件和配置文件的问题 ([Issue 19503](https://github.com/istio/istio/issues/19503))。
- **修复** 阻止安装某些对象进行 `istioctl` 安装的问题 ([Issue 19371](https://github.com/istio/istio/issues/19371))。
- **修复** 阻止在 JWT 策略中将某些 JWKS 与 EC 密钥一起使用的问题 ([Issue 19424](https://github.com/istio/istio/issues/19424))。

## 增强{#improvements}

- **增强** 注入模板以完全指定 `securityContext`，允许 `PodSecurityPolicies` 正确验证注入的部署 ([Issue 17318](https://github.com/istio/istio/issues/17318))。
- **增强** 遥测 v2 配置，以支持 Stackdriver 和向前兼容性 ([Issue 591](https://github.com/istio/installer/pull/591))。
- **增强** `istioctl` 安装的输出 ([Issue 19451](https://github.com/istio/istio/issues/19451))。
- **增强** `istioctl` 安装，可以在发生故障时设置退出代码 ([Issue 19747](https://github.com/istio/istio/issues/19747))。
