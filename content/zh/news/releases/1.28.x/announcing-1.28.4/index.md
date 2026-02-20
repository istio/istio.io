---
title: 发布 Istio 1.28.4
linktitle: 1.28.4
subtitle: 补丁发布
description: Istio 1.28.4 补丁发布。
publishdate: 2026-02-16
release: 1.28.4
aliases:
    - /zh/news/announcing-1.28.4
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.28.3 和 Istio 1.28.4 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

- [CVE-2025-61732](https://github.com/advisories/GHSA-8jvr-vh7g-f8gx)
  (CVSS score 8.6, High)：Go 和 C/C++ 注释解析方式的差异使得代码可以偷偷潜入生成的 cgo 二进制文件中。
- [CVE-2025-68121](https://github.com/advisories/GHSA-h355-32pf-p2xm)
  (CVSS score 4.8, Moderate)：`crypto/tls` 会话恢复机制存在一个缺陷，如果客户端证书颁发机构 (ClientCA) 或根证书颁发机构 (RootCA) 在初始握手和恢复握手之间发生变更，
  则本应失败的恢复握手可能会成功。这种情况在使用带有变更的 `Config.Clone` 或 `Config.GetConfigForClient` 时可能会发生。
  因此，客户端可能会与非预期的服务器恢复会话，服务器也可能与非预期的客户端恢复会话。

## 变更 {#changes}

- **新增** 添加了一项可选功能，当 istio-cni 处于 Ambient 模式时，
  会创建一个由 Istio 拥有的 CNI 配置文件，其中包含主 CNI 配置文件和 Istio CNI 插件的内容。
  此功能旨在解决在 istio-cni `DaemonSet` 未就绪、Istio CNI 插件未安装或未调用插件来配置从
  Pod 到其节点 ztunnel 的流量重定向时，节点重启后流量绕过网格的问题。
  此功能可通过在 istio-cni Helm Chart 值中将 `cni.istioOwnedCNIConfig` 设置为 `true` 来启用。
  如果未设置 `cni.istioOwnedCNIConfigFilename` 的值，则 Istio 拥有的 CNI
  配置文件将被命名为 `02-istio-cni.conflist`。`istioOwnedCNIConfigFilename`
  的字典序优先级必须高于主 CNI。要使此功能生效，必须启用 Ambient 和链式 CNI 插件。

- **新增** 添加了网关部署控制器的安全措施，以验证对象类型、名称和命名空间，
  防止通过模板注入创建任意 Kubernetes 资源。
  ([Issue #58891](https://github.com/istio/istio/issues/58891))

- **新增** 添加了 istio-cni 中检查 Pod 是否启用 Ambient 检测时的重试机制。
  这是为了解决可能导致网状网络绕过的瞬态故障。此功能默认禁用，
  可通过在 `istio-cni` chart 中设置 `ambient.enableAmbientDetectionRetry` 来启用。

- **新增** 添加了端口 15014 上调试端点的基于命名空间的授权。
  非系统命名空间仅限于 `config_dump`/`ndsz`/`edsz` 端点以及同命名空间的代理。
  如果需要兼容性，可以使用 `ENABLE_DEBUG_ENDPOINT_AUTH=false` 禁用此功能。

- **修复** 修复了 istioctl 中 MeshConfig 和 MeshNetworks 的转换函数查找错误
  ([Issue #57967](https://github.com/istio/istio/issues/57967))

- **修复** 修复了一个错误，该错误会导致由于内部索引损坏，
  `BackendTLSPolicy` 状态丢失对 Gateway `ancestorRef` 的跟踪。
  ([Issue #58731](https://github.com/istio/istio/pull/58731))

- **修复** 修复了 istio-cni `DaemonSet` 将 `nodeAffinity` 更改视为升级的问题，
  导致当节点不再符合 `DaemonSet` 的 `nodeAffinity` 规则时，CNI 配置仍错误地保留在原地。
  ([Issue #58768](https://github.com/istio/istio/issues/58768))

- **修复** 修复了资源注释验证，拒绝换行符和控制字符，这些字符可能会通过模板渲染将容器注入到 Pod 规范中。
  ([Issue #58889](https://github.com/istio/istio/issues/58889))

- **修复** 修复了下游 TLS 上下文中 `meshConfig.tlsDefaults.minProtocolVersion`
  到 `tls_minimum_protocol_version` 的映射错误。

- **修复** 修复了一个导致 Ambient 多集群集群注册表周期性不稳定的问题，从而导致错误的配置被推送到代理。
