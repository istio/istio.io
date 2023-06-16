---
title: Istio 1.16.0 更新说明
linktitle: 1.16.0
subtitle: 次要版本
description: Istio 1.16.0 更新说明。
publishdate: 2022-11-15
release: 1.16.0
weight: 10
---

## 弃用通知{#deprecation-notices}

以下通知说明了根据 [Istio 的弃用政策](/zh/docs/releases/feature-stages/#feature-phase-definitions)将在未来某个版本中移除的功能。
请考虑升级您的环境以移除弃用的功能。

- **弃用** 弃用了在 `istio-operator` 中从 URL 获取 Chart。

## 流量治理{#traffic-management}

- **改进** 改进了 Sidecar `Host` 请求头匹配以默认忽略端口号。这可以通过 `SIDECAR_IGNORE_PORT_IN_HOST_MATCH` 环境变量进行控制。 ([Issue #36627](https://github.com/istio/istio/issues/36627))

- **更新** 更新了 `ENABLE_ENHANCED_RESOURCE_SCOPING` 特性标志被启用时动态限制 Istiod 创建 `istio-ca-root-cert` ConfigMap 的命名空间集。

- **更新** 更新了 `meshConfig.discoverySelectors` 以动态限制 `ENABLE_ENHANCED_RESOURCE_SCOPING` 特性标志被启用时 Istiod 发现自定义资源配置（类似 Gateway、VirtualService、DestinationRule、Ingress 等）的命名空间集。
  ([Issue #36627](https://github.com/istio/istio/issues/36627))

- **更新** 更新了 gateway-api 集成以读取 `HTTPRoute`、`Gateway` 和 `GatewayClass` 所用的 `v1beta1` 资源。
  gateway-api 的用户在升级 Istio 之前的版本必须高于 0.5.0。

- **新增** 为了哈希一致新增了对 MAGLEV 负载均衡算法的支持。

- **新增** 同时使用环境变量 `PILOT_ALLOW_SIDECAR_SERVICE_INBOUND_LISTENER_MERGE` 新建了服务端口入站侦听器以及 Sidecar 和 Ingress 侦听器。
  使用此方法后，即使在定义了 Sidecar 入口侦听器时是常规 HTTP 流量，服务端口的流量也不会通过直通 TCP 进行发送。
  如果在 Sidecar Ingress 和服务中定义了相同的端口号，则 Sidecar 始终优先。
  ([Issue #40919](https://github.com/istio/istio/issues/40919))

- **修复** 修复了 xDS 缓冲被启用时 `LocalityLoadBalancerSetting.failoverPriority` 不能正常工作的问题。
  ([Issue #40198](https://github.com/istio/istio/issues/40198))

- **修复** 修复了临时禁用 `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` 时出现的一些内存/CPU 消耗问题。

- **修复** 修复了不带主机端口的远程 JWKS URI 无法解析到其主机和端口组件的问题。

- **修复** 修复了生成 HTTP/网络过滤器时 RBAC 和元数据交换过滤器的排序问题。
  ([Issue #41066](https://github.com/istio/istio/issues/41066))

- **修复** 修复了在 `Host` 请求头中使用通配符域名并纳入异常端口时会造成流量不匹配（并返回 `404`）的问题。

- **修复** 修复了在 `Host` 请求头中使用通配符域名并纳入端口时会造成流量匹配到异常路由的问题。

## 安全性{#security}

- **改进** Pilot 现在将从众所周知的位置加载其 DNS 服务证书：

    {{< text plain >}}
    /var/run/secrets/istiod/tls/tls.crt
    /var/run/secrets/istiod/tls/tls.key
    /var/run/secrets/istiod/ca/root-cert.pem
    {{< /text >}}

    另外 CA 路径将从 `/var/run/secrets/tls/ca.crt` 进行加载。
    还会自动将任何名为 `istiod-tls` 和 `istio-root-ca-configmap` 的 Secret 加载到这些路径中。
    与设置 TLS 参数相比，此方法更适合使用这些众所周知的路径。
    这将进一步简化 `istio-csr` 以及任何其他需要修改 Pilot DNS 服务证书的外部颁发者的安装过程。
    ([Issue #36916](https://github.com/istio/istio/issues/36916))

- **更新** 更新了 Envoy 中的依赖项以正确解析 `exp`、`nbf` 或 `iat` 字段为负值时的 JWT。

## 遥测{#telemetry}

- **更新** 更新了 Telemetry API 为 Prometheus 统计使用全新的原生扩展来代替基于 Wasm 的扩展。
  这将改善此特性的 CPU 开销和内存使用率。自定义维度不再需要正则表达式和引导注释。
  如果自定义使用带有 Wasm 属性的 CEL 表达式，则很可能会受到影响。
  通过将控制平面特性标志 `TELEMETRY_USE_NATIVE_STATS` 设置为 `true` 来启用此项变更。

- **新增** 新增了支持将 OpenTelemetry 跟踪提供程序与 Telemetry API 结合使用。
  ([Issue #40027](https://github.com/istio/istio/issues/40027))

- **修复** 修复了允许多个正则表达式具有相同标记名称的问题。
  ([Issue #39903](https://github.com/istio/istio/issues/39903))

## 可扩展性{#extensibility}

- **改进** 当 Wasm 模块下载失败且 `fail_open` 为 true 时，允许所有流量的 RBAC 过滤器将传递给 Envoy，而不是原始的 Wasm 过滤器。
  之前在这种情况下，给定的 Wasm 过滤器本身被传递给 Envoy，但这可能会导致错误，因为 Wasm 配置的某些字段在 Istio 中是可选的，
  但在 Envoy 中不会这样。

- **改进** 改进了 WasmPlugin 镜像（Docker 和 OCI 标准镜像）以根据规范变更支持多个层。
  有关更多细节请参阅 ([https://github.com/solo-io/wasm/pull/293](https://github.com/solo-io/wasm/pull/293))。

- **新增** 在 WasmPlugin API 中新增了 `match` 字段。
  使用此 `match` 语句，WasmPlugin 可以被应用到更具体的流量（例如到特定端口的流量）。
  ([Issue #39345](https://github.com/istio/istio/issues/39345))

## 安装{#installation}

- **新增** 新增了 `seccompProfile` 字段以便按照
  [https://kubernetes.io/zh-cn/docs/tutorials/security/seccomp/](https://kubernetes.io/docs/tutorials/security/seccomp/)
  在容器 `securityContext` 中设置 `seccompProfile` 字段。
  ([Issue #39791](https://github.com/istio/istio/issues/39791))

- **新增** 新增了全新的 Istio Operator `remote` 配置文件并废弃了等效的 `external` 配置文件。
  ([Issue #39797](https://github.com/istio/istio/issues/39797))

- **新增** 新增了 `--cluster-specific` 标志到 `istioctl manifest generate`。
  当设置了此标志时，当前集群上下文将用于确定动态默认设置，对 `istioctl install` 执行镜像操作。

- **新增** 在为 `istioctl install` 和 `helm install` 使用 CNI 时新增了自动检测[GKE 特定的安装步骤](/zh/docs/setup/additional-setup/cni/#hosted-kubernetes-settings)。

- **新增** 新增了一个 `ENABLE_LEADER_ELECTION=false` 特性标志用于 pilot-discovery 以在使用单副本 Istiod 时禁用领导者选举。
  ([参考](/zh/docs/reference/commands/pilot-discovery/)) ([Issue #40427](https://github.com/istio/istio/issues/40427))

- **新增** 新增在 istio-operator 配置 `MaxConcurrentReconciles` 的支持。
  ([Issue #40827](https://github.com/istio/istio/issues/40827))

- **修复** 修复了 `auto.sidecar-injector.istio.io` `namespaceSelector` 导致集群维护出问题的问题。
  ([Issue #40984](https://github.com/istio/istio/issues/40984))

- **修复** 修复了使用 Istio Operator 自定义资源删除自定义网关时其他网关被重启的问题。
  ([Issue #40577](https://github.com/istio/istio/issues/40577))

- **修复** 修复了 Istio Operator 中的一个问题：当启用 `cni.resourceQuotas` 时由于缺少 RBAC 权限而无法正确创建 CNI。
  ([Issue #41159](https://github.com/istio/istio/issues/41159))

## istioctl

- **新增** 为 `istioctl operator remove` 新增了 `--skip-confirmation` 标志，为 operator 移除添加了确认机制。
  ([Issue #41244](https://github.com/istio/istio/issues/41244))

- **新增** 新增了运行 `istioctl uninstall` 时预先检查修订版本。
  ([Issue #40598](https://github.com/istio/istio/issues/40598))

- **新增** 为 `istioctl bug-report` 新增了 `--rps-limit` 标志，允许提高到 Kubernetes API 服务器的每秒请求限制，
  这可以大大减少收集错误报告的时间。

- **新增** 新增了 `istioctl experimental check-inject` 特性以描述为什么基于当前运行的 Webhook 会/不会或曾经/从未进行注入。
  ([Issue #38299](https://github.com/istio/istio/issues/38299))

- **修复** 修复了设置 `exportTo` 字段和 `networking.istio.io/exportTo` 注释会导致不正确 IST0101 消息的问题。
  ([Issue #39629](https://github.com/istio/istio/issues/39629))

- **修复** 修复了为具有多个值的服务设置 `networking.istio.io/exportTo` 注释后会导致不正确 IST0101 消息的问题。
  ([Issue #39629](https://github.com/istio/istio/issues/39629))

- **修复** 修复了 `experimental un-inject` 为 "un-injecting" 提供不正确模板的问题。

## 文档变更{#documentation-changes}

- **新增** `build_push_update_images.sh` 现在新增了对 `--multiarch-images` 参数的支持，
  以便在 bookinfo 应用程序中构建多架构容器镜像。
  ([Issue #40405](https://github.com/istio/istio/issues/40405))
