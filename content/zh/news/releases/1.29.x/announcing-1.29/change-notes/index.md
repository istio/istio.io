---
title: Istio 1.29.0 更新说明
linktitle: 1.29.0
subtitle: 主要版本
description: Istio 1.29.0 更新说明。
publishdate: 2026-02-16
release: 1.29.0
weight: 10
aliases:
    - /zh/news/announcing-1.29.0
---

## 流量治理 {#traffic-management}

- **提升** 已将 `cni.ambient.dnsCapture` 的值提升至默认值 `true`。
  这将默认启用 Ambient 网格中工作负载的 DNS 代理，从而在提升安全性和性能的同时，
  启用多项功能。此功能可以显式禁用，也可以使用 `compatibilityVersion=1.24` 来禁用。
  注意：只有新创建的 Pod 才会启用 DNS。要为现有 Pod 启用 DNS，
  必须手动重启 Pod，或者使用 `--set cni.ambient.reconcileIptablesOnStartup=true` 启用 iptables 协调功能。

- **提升** 已将 `cni.ambient.reconcileIptablesOnStartup` 的默认值提升为 `true`。
  这使得在 `istio-cni` `DaemonSet` 升级时，现有 Ambient Pod 的 iptables/nftables 规则能够自动同步，
  无需手动重启 Pod 即可获取更新的网络配置。此功能可以显式禁用，
  也可以通过设置 `compatibilityVersion=1.28` 来禁用。

- **提升** 已将 [Gateway API 推理扩展](https://gateway-api-inference-extension.sigs.k8s.io/)的支持提升至 Beta 版。
  此功能目前默认关闭，可通过环境变量 `ENABLE_GATEWAY_API_INFERENCE_EXTENSION` 启用。
  （[用法](/zh/docs/tasks/traffic-management/ingress/gateway-api-inference-extension/)）
  ([Issue #58533](https://github.com/istio/istio/issues/58533))

- **提升** 已将 Ambient 模式下的多网络多集群支持提升至 Beta 版。请查看公告了解更多详情。

- **新增** 添加了对 Istio 本地化标签 `topology.istio.io/locality` 的支持，该标签优先于 `istio-locality`。

- **新增** 添加了选项 `gateway.istio.io/tls-cipher-suites`，用于指定网关上的自定义密码套件。该值是以逗号分隔的密码套件列表。
  ([Issue #58366](https://github.com/istio/istio/issues/58366))

- **新增** 添加了基于数据包的遥测系统对 Ambient 网格网络的 Alpha 版本支持。
  多网络 Ambient 网格网络的用户需要通过 `AMBIENT_ENABLE_BAGGAGE` 引导环境变量启用此功能，
  以便正确地为跨网络流量的指标分配源和目标标签。请注意，ztunnel 已在请求中发送数据包；
  此功能在此基础上，也支持由航点生成的数据包。因此，默认情况下，
  waypoint 的此功能处于关闭状态，而 ztunnel 的此功能默认开启（可通过 ztunnel 中的 `ENABLE_RESPONSE_BAGGAGE` 环境变量进行配置）。

- **新增** 添加了逻辑，用于将工作负载发现 (WDS) 服务指定为规范服务。
  ztunnel 在名称解析期间会使用规范 WDS 服务，除非客户端所在命名空间中存在另一个 WDS 服务来覆盖它。
  规范服务可以从以下两种方式配置：(1) Kubernetes `Service` 资源；
  (2) 指定该主机名的最早的 Istio `ServiceEntry` 资源。
  ([Issue #58576](https://github.com/istio/istio/pull/58576))

- **新增** 添加了功能标志 `DISABLE_TRACK_REMAINING_CB_METRICS`，
  用于控制熔断器剩余指标的跟踪。设置为 `false`（默认值）时，
  将不跟踪熔断器剩余指标，从而提升性能。设置为 `true` 时，
  将跟踪熔断器剩余指标（旧版行为）。此功能标志将在未来的版本中移除。

- **新增** 添加了对 gRPC 无代理客户端中 `LEAST_REQUEST` 负载均衡策略的支持。

- **新增** 添加了对 gRPC 无代理客户端中的熔断（`http2MaxRequests`）的支持。

- **新增** 添加了对使用 `DYNAMIC_DNS` 解析 TLS 主机的 `ServiceEntry` 资源中的通配符主机的支持。
  TLS 协议意味着连接将基于请求的 SNI（来自 TLS 握手）进行路由，
  而无需终止 TLS 连接来检查 Host 标头以进行路由。此实现依赖于一个 Alpha 版本的 API，
  并且存在重大的安全隐患（例如，SNI 欺骗）。因此，此功能默认禁用，
  可以通过将功能标志 `ENABLE_WILDCARD_HOST_SERVICE_ENTRIES_FOR_TLS` 设置为 `true` 来启用。
  请谨慎使用此功能，并且仅在受信任的客户端中使用。
  ([Issue #54540](https://github.com/istio/istio/issues/54540))

- **修复** 修复了 Sidecar 尝试错误地将请求路由到环境东西网关的问题。
  ([Issue #57878](https://github.com/istio/istio/issues/57878))

- **修复** 修复了在 MicroK8s 环境中使用 nftables 后端的 Ambient 模式时 Istio CNI 节点代理启动失败的问题。
  ([Issue #58185](https://github.com/istio/istio/issues/58185))

- **修复** 修复了当多个引用不同 `InferencePool` 的 `HTTPRoute` 附加到同一 Gateway 时，
  `VirtualService` 合并期间 `InferencePool` 配置丢失的问题。
  ([Issue #58392](https://github.com/istio/istio/issues/58392))

- **修复** 修复了将 `ambient.istio.io/bypass-inbound-capture: "true"`
  设置为 `true` 会导致入站 HBONE 流量超时的问题，因为用于跟踪连接上 ztunnel
  标记的 iptables 规则未生效。此更改允许入站 HBONE 连接正常工作，同时保留入站“直通”连接的预期绕过行为。
  ([Issue #58546](https://github.com/istio/istio/issues/58546))

- **修复** 修复了一个错误，该错误会导致由于内部索引损坏，
  `BackendTLSPolicy` 状态丢失对 Gateway `ancestorRef` 的跟踪。
  ([Issue #58731](https://github.com/istio/istio/pull/58731))

- **修复** 修复了预热攻击性与 Envoy 配置不一致的问题。
  ([Issue #3395](https://github.com/istio/api/issues/3395))

- **修复** 修复了 Ambient 多集群中的入口网关无法将请求路由到暴露的远程后端的问题。
  此外，新增了一个特性标志 `AMBIENT_ENABLE_MULTI_NETWORK_INGRESS`，
  默认值为 `true`。如果用户希望保留旧的行为，可以将其设置为 `false`。

- **修复** 修复了一个导致 Ambient 多集群集群注册表周期性不稳定的问题，从而导致错误的配置被推送到代理。

- **修复** 修复了一个问题，即全局下游最大连接数的过载管理器资源监视器被设置为最大整数值，
  且无法通过运行时标志进行配置。现在，用户可以通过代理元数据 `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS`
  配置全局下游最大连接数限制。为了向后兼容，运行时标志 `overload.global_downstream_max_connections` 仍然有效，
  但已被弃用，建议使用这种使用代理元数据的新方法。

  如果指定了 `overload.global_downstream_max_connections`，则会出现 Envoy 已弃用的警告。

  如果同时指定了 `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS`
  和 `overload.global_downstream_max_connections`，则代理元数据将优先于运行时标志。
  ([Issue #58594](https://github.com/istio/istio/issues/58594))

- **修复** 修复了关于 gRPC 无代理客户端中 `CONSISTENT_HASH` 负载均衡策略的警告。

- **修复** 修复了 gRPC xDS 监听器，使其能够同时发送当前和已弃用的 TLS 证书提供程序字段，
  从而实现新旧 gRPC 客户端（`pre-1.66` 和 `1.66+`）之间的兼容性。

- **修复** 修复了在为健康检查探测创建主机 iptables/nftables 规则时 CNI 初始化可能失败的问题。
  现在，初始化过程会重试最多 10 次，每次重试之间有 2 秒的延迟，以处理瞬时故障。

## 安全性 {#security}

- **改进** 改进了远程集群信任域处理，实现了对远程 `meshConfig` 的监视。
  Istiod 现在会自动监视并更新来自远程集群的信任域信息，从而确保对属于多个信任域的服务进行准确的 SAN 匹配。

- **新增** 添加了一项可选功能，当 istio-cni 处于 Ambient 模式时，
  会创建一个由 Istio 拥有的 CNI 配置文件，其中包含主 CNI 配置文件和 Istio CNI 插件的内容。
  此功能旨在解决在 istio-cni `DaemonSet` 未就绪、Istio CNI 插件未安装或未调用插件来配置从
  Pod 到其节点 ztunnel 的流量重定向时，节点重启后流量绕过网格的问题。
  此功能可通过在 istio-cni Helm Chart 值中将 `cni.istioOwnedCNIConfig` 设置为 `true` 来启用。
  如果未设置 `cni.istioOwnedCNIConfigFilename` 的值，则 Istio 拥有的 CNI
  配置文件将被命名为 `02-istio-cni.conflist`。`istioOwnedCNIConfigFilename`
  的字典序优先级必须高于主 CNI。要使此功能生效，必须启用 Ambient 和链式 CNI 插件。

- **新增** 添加了 istiod 和 istio-cni 的可选 `NetworkPolicy` 部署。
  您可以设置 `global.networkPolicy.enabled=true` 来为 istiod、istio-cni 和网关部署默认的 `NetworkPolicy`。
  ([Issue #56877](https://github.com/istio/api/issues/56877))

- **新增** 添加了对 Istio 节点代理中符号链接密钥的监视支持。

- **新增** 添加了 ztunnel 中的证书吊销列表 (CRL) 支持。
  当通过插入的 CA 提供 `ca-crl.pem` 文件时，istiod 会自动将 CRL 分发到集群中所有参与的命名空间。
  ([Issue #58733](https://github.com/istio/istio/issues/58733))

- **新增** 添加了一项实验性功能，允许在 ztunnel 中对 `AuthorizationPolicy` 资源进行试运行。
  此功能默认禁用。详情请参阅升级说明。
  （[使用](/zh/docs/tasks/security/authorization/authz-dry-run/)）
  ([Issue #1933](https://github.com/istio/api/pull/1933))

- **新增** 添加了一项功能，支持在获取用于 JWT 验证的公钥时，阻止 JWKS URI 中的 CIDR。
  如果从 JWKS URI 解析出的任何 IP 地址与被阻止的 CIDR 匹配，
  Istio 将跳过获取公钥的操作，转而使用伪造的 JWKS 来拒绝带有 JWT 令牌的请求。

- **新增** 添加了 istio-cni 中检查 Pod 是否启用 Ambient 检测时的重试机制。
  这是为了解决可能导致网状网络绕过的瞬态故障。此功能默认禁用，
  可通过在 `istio-cni` chart 中设置 `ambient.enableAmbientDetectionRetry` 来启用。

- **新增** 添加了端口 15014 上调试端点的基于命名空间的授权。
  非系统命名空间仅限于 `config_dump`/`ndsz`/`edsz` 端点以及同命名空间的代理。
  如果需要兼容性，可以使用 `ENABLE_DEBUG_ENDPOINT_AUTH=false` 禁用此功能。

- **修复** 修复了资源注释验证，拒绝换行符和控制字符，这些字符可能会通过模板渲染将容器注入到 Pod 规范中。
  ([Issue #58889](https://github.com/istio/istio/issues/58889))

## 遥测 {#telemetry}

- **弃用** 已弃用 `sidecar.istio.io/statsCompression` 注解，
  它已被 `statsCompression` `proxyConfig` 选项取代。
  仍然可以通过 `proxy.istio.io/config` 注解对每个 Pod 进行覆盖。
  ([Issue #48051](https://github.com/istio/istio/issues/48051))

- **新增** 添加了 `proxyConfig` 中的 `statsCompression` 选项，
  允许对 Envoy 统计信息端点（用于公开其指标）的 HTTP 压缩进行全局配置。
  该选项默认启用，并根据客户端发送的 `Accept-Header` 提供 `brotli`、`gzip` 和 `zstd` 三种压缩方式。
  ([Issue #48051](https://github.com/istio/istio/issues/48051))

- **新增** 添加了源工作负载和目标工作负载标识到 waypoint 代理跟踪中。
  waypoint 代理现在在跟踪跨度中包含 `istio.source_workload`、`istio.source_namespace`、
  `istio.destination_workload`、`istio.destination_namespace` 和其他源对等标签，
  与 Sidecar 代理的可观测性功能相匹配。
  ([Issue #58348](https://github.com/istio/istio/issues/58348))

- **新增** 添加了对 Telemetry API 中 `Formatter` 类型自定义标签的支持。

- **新增** 在 Pilot 中添加了 `istiod_remote_cluster_sync_status` 指标，用于跟踪远程集群的同步状态。

- **新增** 添加了 waypoint Span 标签 `istio.downstream.workload`、`istio.downstream.namespace`、
  `istio.upstream.workload` 和 `istio.upstream.namespace` 到上游和下游工作负载和命名空间。

- **新增** 添加了 `MeshConfig` 的 `extensionProviders` 中 `ZipkinTracingProvider`
  的 `timeout` 和 `headers` 字段。`timeout` 字段用于配置向 Zipkin 收集器发送 Span
  时的 HTTP 请求超时时间，从而更好地控制跟踪导出的可靠性。`headers` 字段允许包含自定义 HTTP 标头，
  用于身份验证、授权和自定义元数据等用例。标头支持直接值和环境变量引用，
  以实现安全的凭据管理。（[Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/v3/zipkin.proto)）
  （[引用](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-ZipkinTracingProvider)）
  （[使用](/zh/docs/tasks/observability/distributed-tracing/)）

- **修复** 修复了一个问题，即即使通过将 `AMBIENT_ENABLE_BAGGAGE` 环境变量设置为 `true`
  为 pilot 启用了基于行李的对等元数据发现，在 Ambient 多网络部署中报告的指标仍然会带有未知标签。
  ([Issue #58794](https://github.com/istio/istio/issues/58794)),
  ([Issue #58476](https://github.com/istio/istio/issues/58476))

## 安装 {#installation}

- **更新** 更新了 `istiod`，将 `GOMEMLIMIT` 设置为内存限制的 90%（之前为 100%），
  以降低内存溢出 (OOM) 导致程序崩溃的风险。现在，此操作由 `automemlimit` 库自动处理。
  用户可以通过直接设置 `GOMEMLIMIT` 环境变量来覆盖此设置，
  或者使用 `AUTOMEMLIMIT` 环境变量来调整比例（例如，`AUTOMEMLIMIT=0.85` 表示 85%）。

- **更新** 已将 Kiali 插件更新至版本 `v2.21.0`。

- **新增** 添加了支持根据环境变量 `PILOT_IGNORE_RESOURCES` 来过滤 Pilot 将监视的资源。

  此变量是一个以逗号分隔的资源和前缀列表，Istio CRD 监视器应忽略这些资源和前缀。
  如果需要显式包含某个资源（即使它已在忽略列表中），可以使用变量 `PILOT_INCLUDE_RESOURCES` 来实现。

  此功能使管理员能够将 Istio 部署为仅支持 Gateway API 的控制器，
  忽略网格资源，或者部署仅支持 Gateway API `HTTPRoute`（例如，GAMMA 支持）的 Istio。
  ([Issue #58425](https://github.com/istio/istio/issues/58425))

- **新增** 添加了对在 `ProxyConfig` 中自定义 Envoy 文件刷新间隔和缓冲区配置的支持。
  ([Issue #58545](https://github.com/istio/istio/issues/58545))

- **新增** 添加了网关部署控制器的安全措施，以验证对象类型、名称和命名空间，
  防止通过模板注入创建任意 Kubernetes 资源。
  ([Issue #58891](https://github.com/istio/istio/issues/58891))

- **新增** 添加了设置 `values.pilot.crlConfigMapName`，
  允许配置 istiod 用于在集群中传播其证书吊销列表 (CRL) 的 `ConfigMap` 的名称。
  这允许在同一集群中运行具有重叠命名空间的多个控制平面。

- **新增** 添加了对 istio-cni pod 上配置 `terminationGracePeriodSeconds` 的支持，
  并将默认值从 5 秒更新为 30 秒。
  ([Issue #58572](https://github.com/istio/istio/issues/58572))

- **修复** 修复了 `iptables` 命令未等待获取 `/run/xtables.lock` 上的锁，导致日志中出现一些误导性错误的问题。
  ([Issue #58507](https://github.com/istio/istio/issues/58507))

- **修复** 修复了 istio-cni `DaemonSet` 将 `nodeAffinity` 更改视为升级的问题，
  导致当节点不再符合 `DaemonSet` 的 `nodeAffinity` 规则时，CNI 配置仍错误地保留在原地。
  ([Issue #58768](https://github.com/istio/istio/issues/58768))

- **修复** 修复了 `istio-gateway` Helm Chart 值架构，允许顶级 `enabled` 字段。
  ([Issue #58277](https://github.com/istio/istio/issues/58277))

- **移除** 已从 `base` Helm Chart 中移除过时的清单文件。请参阅升级说明了解更多信息。

## istioctl

- **Added** a `--wait` flag to the `istioctl waypoint status` command to specify whether to wait for the waypoint to become ready (default is `true`).
- **新增** 在 `istioctl waypoint status` 命令中添加了 `--wait` 标志，
  用于指定是否等待航点准备就绪（默认值为 `true`）。

  使用 `--wait=false` 指定此标志将不会等待航点准备就绪，而是直接显示航点的状态。

  ([Issue #57075](https://github.com/istio/istio/issues/57075))

- **Added** the printing of headers to the `istioctl ztunnel-config all` and `istioctl proxy-config all` commands.
- **新增** 添加了 `istioctl ztunnel-config all` 和 `istioctl proxy-config all` 命令的标头打印功能。

- **新增** 为 `istioctl waypoint status` 命令添加了 `--all-namespaces` 标志，
  用于显示所有命名空间中 waypoint 的状态。

- **新增** 添加了在 `istioctl ztunnel-config` 中指定代理管理端口的支持。

- **修复** 修复了 istioctl 中 MeshConfig 和 MeshNetworks 的转换函数查找错误
  ([Issue #57967](https://github.com/istio/istio/issues/57967))
