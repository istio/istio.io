---
title: 发布 Istio 1.7.1 版本
linktitle: 1.7.1
subtitle: 补丁发布
description: Istio 1.7.1 补丁发布。
publishdate: 2020-09-10
release: 1.7.1
aliases:
    - /zh/news/announcing-1.7.1
---

这个版本包含了错误修复，以提高稳定性。主要说明 Istio 1.7.0 和 Istio 1.7.1 之间的不同之处。

{{< relnote >}}

## 变动{#changes}

- **新增** Mixer 中 Envoy [ext `authz` and gRPC 访问日志 API 支持](https://github.com/istio/istio/wiki/Enabling-Envoy-Authorization-Service-and-gRPC-Access-Log-Service-With-Mixer)，使得基于 Mixer 的配置和进程外适配器在升级到 Istio 的未来版本后仍然可以工作。
  ([Issue #23580](https://github.com/istio/istio/issues/23580))

- **修复** `istioctl x authz check` 命令可以和 v1beta1 AuthorizationPolicy 一起正常使用。
  ([PR #26625](https://github.com/istio/istio/pull/26625))

- **修复** 通过删除非注入式工作负载跨网络的不可到达的端点。
  ([Issue #26517](https://github.com/istio/istio/issues/26517))

- **修复** 启用保持应用程序，直到代理启动功能标志打破重写应用探测逻辑。
  ([Issue #26873](https://github.com/istio/istio/issues/26873))

- **修复** 删除多集群安装的远程 Secret，就会删除远程端点。
  ([Issue #27187](https://github.com/istio/istio/issues/27187))

- **修复** Service 的填充时间晚于 Endpoint 的填充时间时，缺少 Endpoint。

- **修复** 导致丢失无头服务更新的问题。
  ([Issue #26617](https://github.com/istio/istio/issues/26617))

- **修复** Kiali RBAC 权限的问题，使其部署无法正常工作。
  ([Issue #27109](https://github.com/istio/istio/issues/27109))

- **修复** 使用 Istio CNI 时，`remove-from-mesh` 没有删除初始化容器的问题
  ([Issue #26938](https://github.com/istio/istio/issues/26938))

- **修复** Kiali 使用匿名认证策略，因为新版本已经取消登录认证策略。
