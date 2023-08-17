---
title: Istio 1.15.0 更新说明
linktitle: 1.15.0
subtitle: 次要版本
description: Istio 1.15.0 更新说明。
publishdate: 2022-08-31
release: 1.15.0
weight: 10
---

## 流量管理{#traffic-management}

- **改进** 改进了推送到网关代理的数量，当服务在网关上不可见时不推送。
  ([Issue #39110](https://github.com/istio/istio/issues/39110))

- **改进** 改进了与没有 `nsenter` 二进制的最小主机操作系统（如 Talos OS）的兼容性。`cni.conf` 标记 `HostNSEnterExec` 在使用 nsenter 时恢复到旧的行为。
  ([Issue #38794](https://github.com/istio/istio/issues/38794))

- **更新** 更新 istiod 以允许未知标志以实现向后兼容性。如果传递了未知标志，则不会记录警告或错误。

- **新增** 新增当协议未设置且地址也未设置时添加了验证警告。
  ([Issue #27990](https://github.com/istio/istio/issues/27990))

- **新增** 新增对配置网格内部地址的支持。这可以通过设置
  `ENABLE_HCM_INTERNAL_NETWORKS` 为 true 来启用。

- **新增** 为 sidecar 新增了 `traffic.sidecar.istio.io/excludeInterfaces` 注解。
  ([Issue #39404](https://github.com/istio/istio/pull/39404))

- **新增** 新增了对配置 `DestinationRule` 中 `max_connection_duration` 的支持。

- **新增** 通过指定 gRPC 状态代码添加了对注入故障的支持。

- **新增** 增加了对向 Istio 代理中的所有 nameservers 发送并行 DNS 查询的支持。这个功能默认是禁用的，可以通过设置 istio-agent 境变量 `DNS_FORWARD_PARALLEL=true` 来启用。
  ([Issue #39598](https://github.com/istio/istio/issues/39598))

- **新增** 增加了对通过外部 HTTP 转发代理使用 HTTP CONNECT 或 POST 方法进行隧道出站流量的支持。隧道设置只能应用于 TCP 和 TLS 监听器，暂时不支持 HTTP 监听器。

- **新增** 为 sidecar 主机请求头匹配增加了一个忽略端口号的选项。这可以由 `SIDECAR_IGNORE_PORT_IN_HOST_MATCH` 环境变量控制。

- **修复** 修复了安装 CNI 以检测预计服务账户令牌的变化，并用新的 kubeconfig 重新安装 istio-cni 插件。
  ([Issue #38077](https://github.com/istio/istio/issues/38077))

- **修复** 修复了一些 `ServiceEntry` 主机名可能会导致非确定性的 Envoy 路由。
  ([Issue #38678](https://github.com/istio/istio/issues/38678))

- **修复** 修复了在某些情况下无法正确解析网络网关名称的问题。
  ([Issue #38689](https://github.com/istio/istio/issues/38689))

- **修复** 修复了如果 RDS/CDS/EDS 缓存被启用，更新分割的 `DestinationRules` 不会生效。
  ([Issue #39726](https://github.com/istio/istio/issues/39726))

- **修复** `PILOT_SEND_UNHEALTHY_ENDPOINTS` was enabled.修修复了当 `PILOT_SEND_UNHEALTHY_ENDPOINTS` 被启用时，Istio 会将流量发送到未准备好的 Pod 上。
  ([Issue #39825](https://github.com/istio/istio/issues/39825))

- **修复** 修复了在使用 `STATIC` `ServiceEntries` 与 `PASSTHROUGH` `DestinationRules` 时导致拒绝配置的问题。
  ([Issue #39736](https://github.com/istio/istio/issues/39736))

- **修复** 修复了一个导致 Envoy 集群初始化时被卡住的问题，阻止了配置更新或代理启动。
  ([Issue #38709](https://github.com/istio/istio/issues/38709))

- **修复** 修复了当使用通配符域名和在 `Host` 中包括一个意外的端口时，导致流量不匹配（并返回 404）。

- **修复** 修复了当使用通配符域名并在 `Host` 头中包括一个端口时，会导致流量匹配一个意外的路由。

- **修复** 修复了更新 `ServiceEntry` 主机名时引发的潜在内存泄漏的问题。

- **修复** 修复了在高并发流量期间可能导致 xDS 配置更新被阻止的任何问题。
  ([Issue #39209](https://github.com/istio/istio/issues/39209))

## 安全{#security}

- **新增** 新增了一个 istio-agent 环境变量 `WORKLOAD_RSA_KEY_SIZE`，用于配置工作负载证书的 RSA 密钥大小。

- **修复** 修复了一个 Bug，即 JWKS 动态生成的 `n` 没有经过 base64 编码，导致 envoy 无法正确解析它。

## 观测{#telemetry}

- **修复** 修复了 sidecar 客户端和 `ISTIO_MUTUAL`，网关的 TCP 服务器之间的 TCP 元数据交换。

- **修复** 修复了一个 Bug，当在 Telemetry 资源中的单一节段内指定多个 `accessLogging` 时，会忽略一些配置。有了这个修复，所有在 Telemetry 资源的单一节中提供的访问日志配置都会被尊重。
  ([Issue #39468](https://github.com/istio/istio/issues/39468))

## 可扩展性{#extensibility}

- **新增** 新增了 `WASM_MODULE_EXPIRY`，`WASM_PURGE_INTERVAL`，`WASM_HTTP_REQUEST_TIMEOUT` 和 `WASM_HTTP_REQUEST_MAX_RETRIES` istio-agent 环境变量来控制 WASM 缓存相关参数。

- **新增** 当 WASM 二进制文件通过 HTTP/HTTPS 拉取时，增加了解压或解压缩的能力。

- **新增** 新增了 `WASM_INSECURE_REGISTRIES` istio-agent 环境变量，当 `WasmPlugin` 指向 HTTP/HTTPS 服务器时。

- **Extended** 扩展了 `WasmPlugin` 中 `ImagePullPolicy` 的范围，除了接受 OCI 图像 URL，还接受 HTTP/HTTPS URLs。

## 安装{#installation}

- **新增** 为所有组件增加了对 `arm64` 架构的支持。
  ([Issue #26652](https://github.com/istio/istio/issues/26652))

- **新增** 在 `istio-init` 容器中增加了 `--log_output_level` 和 `--log_as_json`（正如它们在 `istio-proxy` 中一样）。

- **新增** 为 Istio Gateway Helm chart 增加了配置网关部署的 [topologySpreadConstraints](https://kubernetes.io/zh-cn/docs/concepts/scheduling-eviction/topology-spread-constraints/) 的值。

- **新增** 新增了对监视外部 istiod 的本地密钥资源更新的支持。
  ([Issue #31946](https://github.com/istio/istio/issues/31946))

- **更新** 更新了功能标志 `ENABLE_LEGACY_FSGROUP_INJECTION` 的默认值为 false。当在 Kubernetes 1.19 之前的版本上安装 Helm 时，这可能会导致 sidecar 出现错误。

- **更新** 更新了 Kiali 插件到最新版本（v1.55.1）。

- **改进** 改进了[外部控制平面设置说明](/zh/docs/setup/install/external-controlplane/)，包括更简单的控制平面入口设置提示，使其更容易在测试环境中试验外部控制平面部署模型。

- **移除** 移除了已废弃的 `remote.yaml` 配置文件，它等同于默认配置文件。
  ([Issue #38832](https://github.com/istio/istio/issues/38832))

## istioctl{#istioctl}

- **增强** 将 `istioctl x uninstall` 提升为 `istioctl uninstall`。
  ([Issue #40339](https://github.com/istio/istio/issues/40339))

- **改进** 改进了活动日志级别的输出格式。

- **新增** 为 Envoy 过滤器补丁操作增加了一个新的分析器，以便在没有设置优先级的情况下使用相对补丁操作时提供警告，这可能导致 Envoy 过滤器不能正确应用。
  ([Issue #37415](https://github.com/istio/istio/issues/37415))

- **新增** 增加了对文件资源的 `istioctl analyze` 测试版 API 支持。

- **新增** 为 bookinfo 的评论添加了 Pod 名称和集群名称，其中集群名称由评论部署中的 `CLUSTER_NAME` 环境变量决定。

- **新增** 在 `istioctl analyze` 分析中增加了对解析列表类型文件的支持。
  ([Issue #39982](https://github.com/istio/istio/issues/39982))

- **新增** 新增了 `istioctl admin log` 描述。

- **修复** 修复了当 `ServiceEntry` 地址为空但网状配置 `ISTIO_META_DNS_AUTO_ALLOCATE` 被启用时 `istioctl analyze` 返回一个意外的 IST0134 消息。

- **修复** 修复了一个导致 `istioctl x injector list` 提供不正确的 Pod 信息的问题。

- **修复** 修复了当对特定命名空间使用 `exportTo` 时，`istioctl analyze` 会出现 `ConflictingMeshGatewayVirtualServiceHosts（IST0109）` 信息。
  ([Issue #39634](https://github.com/istio/istio/issues/39634))
