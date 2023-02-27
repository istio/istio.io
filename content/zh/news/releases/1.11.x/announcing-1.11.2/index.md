---
title: Istio 1.11.2 发布公告
linktitle: 1.11.2
subtitle: 补丁发布
description: Istio 1.11.2 补丁发布。
publishdate: 2021-09-02
release: 1.11.2
aliases:
    - /zh/news/announcing-1.11.2
---

此版本包含一些 bug 修复用以提高程序的健壮性。同时此发布说明也描述了 Istio 1.11.1 和 Istio 1.11.2 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **改进** 改进了 `istioctl install` 以在安装失败时提供更多详细信息。

- **新增** 新增了对通过 xDS 配置工作负载的 gRPC 支持，而无需 Envoy 代理。

- **新增** 向 `istioctl x workload entry configure` 新增了两个互斥标识。
    - **`--internal-ip`** 为 VM 工作负载配置一个私有 IP 地址，用于工作负载自动注册和健康探测。
    - **`--external-ip`** 为虚拟机工作负载配置一个用于工作负载自动注册的公网 IP 地址。同时，它通过将环境变量 `REWRITE_PROBE_LEGACY_LOCALHOST_DESTINATION` 设置为 true 来配置通过本地主机执行的健康探测。
  ([Issue #34411](https://github.com/istio/istio/issues/34411))

- **新增** 如果在 Pod 或者工作负载标签中不存在 `topology.istio.io/network` 标签，就增加拓扑标签 `topology.istio.io/network` 到 `IstioEndpoint` 中。

- **新增** 新增了一个 `FILE_DEBOUNCE_DURATION` 配置，用来允许用户配置 SDS 服务器看到第一个文件更改事件后应等待的持续时间。这在 File 挂载的证书流中很有用，以确保密钥和证书在推送到 Envoy 之前被完全写入。默认为 `100ms`。

- **修复** 修复了当使用命令行工具执行 `istioctl profile diff` 和 `istioctl profile dump` 命令时 Istio 出现意外信息日志的问题。

- **修复** 修复了部署分析程序在分析过程中忽略服务名称空间的问题。

- **Fixed** 修复了 `DestinationRule` 更新不会触发 `AUTO_PASSTHROUGH` 网关上侦听器更新的问题。
  ([Issue #34944](https://github.com/istio/istio/issues/34944))
