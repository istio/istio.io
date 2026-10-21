---
title: 发布 Istio 1.31.2
linktitle: 1.31.2
subtitle: 补丁发布
description: Istio 1.31.2 补丁发布。
publishdate: 2026-10-15
release: 1.31.2
aliases:
    - /zh/news/announcing-1.31.2
---

此版本包含安全修复。本发行说明描述了 Istio 1.31.1 和 Istio 1.31.2 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

有关更多信息，请参阅
[ISTIO-SECURITY-2026-007](/zh/news/security/istio-security-2026-007)。

### Envoy CVE {#envoy-cves}

- __[GHSA-8vc2-jrm4-835w](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8vc2-jrm4-835w)__: (CVSS score 7.5)：
  修复了 OAuth2 HTTP 过滤器在收到不带 `:path` 标头的 CONNECT 请求时，
  可被未经身份验证的远程攻击者触发的崩溃问题。

- __[GHSA-47vj-9r25-wv5j](https://github.com/envoyproxy/envoy/security/advisories/GHSA-47vj-9r25-wv5j)__: (CVSS score 6.5)：
  修复了 `api_key_auth` HTTP 过滤器在收到不带 `:path` 标头的 CONNECT 请求时发生崩溃的问题。

- __[CVE-2026-111497](https://nvd.nist.gov/vuln/detail/CVE-2026-111497)__：
  修复了 Envoy 所使用的 Brotli 压缩库中的一个漏洞。
  启用了 Brotli 解压缩（例如通过 `EnvoyFilter` 启用）的用户应进行升级。

### Istio CVE {#istio-cves}

- __[GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5)__ (CVSS score 7.4, High)：
  通过在 HTTP/2 上更改方法的大小写，可以绕过 `AuthorizationPolicy` 的方法规则。
  **致谢**：此漏洞由 [izzy0101010101](https://github.com/izzy0101010101) 发现并报告。

- __[GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6)__ (CVSS score 7.7, High)：
  在 Ambient 模式下，当 `ServiceEntry` 或其他服务声明了以 IP 地址寻址的 waypoint 的地址时，istiod 会崩溃。
  **致谢**：此漏洞由 [yshch](https://github.com/yshch) 发现并报告。

### 其他 Istio 安全修复 {#other-istio-security-fixes}

- **修复** 修复了 `istioctl` 在使用服务账号令牌连接到 XDS 时跳过 istiod 证书验证的问题
  （涉及 `istioctl proxy-status`、`istioctl x internal-debug` 以及所有使用 `--xds-address` 的情况）。
  istioctl 现在会根据 `istio-ca-root-cert` ConfigMap 中的 Istio 根证书和预期的服务器名称来验证服务器：
  如果设置了 `--authority`，则使用该值；如果 `--xds-address` 的主机是 DNS 名称，则使用该主机；
  如果连接的是 IP 地址或 localhost，则使用 `istiod.<istio-namespace>.svc`。
  传递 `--insecure`（或设置 `ISTIOCTL_INSECURE=true`）可显式跳过验证。
  **致谢**：此问题由 [Leon Zlobecki](https://leonz.is) 报告。
  ([Issue #41937](https://github.com/istio/istio/issues/41937))

- **修复** 修复了 `istioctl manifest translate` 将来自 IstioOperator 输入的值（例如命名空间和发布名称）
  不加引号地写入所生成的安装 Shell 脚本的问题。
  运行这些脚本时，精心构造的值可能会注入额外的 Shell 命令。
  现在，参数会使用 `shellescape.Quote` 进行转义。
  **致谢**：此漏洞由 OpenSec Intelligence 发现并报告。

- **修复** 修复了 OIDC/JWT 身份验证器收到 `sub` 声明格式错误的令牌时
  istiod 发生 Panic 的问题。现在，在使用主体之前，会先验证其格式是否严格为
  `system:serviceaccount:<namespace>:<serviceaccount>`。
  **致谢**：此问题由 Kaizhe Huang 报告。

- **修复** 修复了在实验性的 Kubernetes CSR RA 路径（`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`）上，
  `CreateCertificate` 会向调用方返回原始 Kubernetes API 错误文本的问题，
  这会泄露 CSR 名称、签名者名称以及 istiod 的身份。
  现在，完整的错误仅在服务器端记录。由 Juno Im 报告。

- **修复** 修复了在实验性的 Kubernetes CSR RA 路径（`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`）上，
  Kubernetes CSR watch 循环使用了被遗弃的 `time.After` 计时器，
  可能导致某个 goroutine 在请求完成后仍继续运行的问题。
  现在，该循环受作用域正确的 `context.WithTimeout` 约束，
  并会在超时或取消时被可靠地清理。由 Juno Im 报告。

- **修复** 修复了在实验性的 Kubernetes CSR RA 路径（`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`）上，
  客户端请求的 `ValidityDuration` 最高可被接受至 `MAX_WORKLOAD_CERT_TTL`（默认 `90d`）的问题。
  现在，新的 `MAX_RA_WORKLOAD_CERT_TTL` 环境变量（默认 `48h`）会限制 TTL 的上限，
  从而缩小 istio-token 被盗用时的影响范围。
  通过此路径合法请求 TTL 大于 `48h` 的证书的部署，
  应在升级后调高 `MAX_RA_WORKLOAD_CERT_TTL`。由 Juno Im 报告。

- **修复** 修复了 Wasm OCI 镜像获取器根据镜像仓库返回的错误来决定是否通过明文 HTTP 重试失败的 HTTPS 获取的问题。
  由于镜像仓库属于不受信任的输入，中间人（MITM）或恶意镜像仓库可以按需触发这种回退，
  从而强制使用明文传输，并在未固定可选模块摘要的情况下提供任意 Wasm 二进制文件。
  现在，只有对于运维人员通过 `WASM_INSECURE_REGISTRIES` 显式加入允许列表的镜像仓库，才会尝试明文重试。
  **致谢**：此漏洞由 Adam Korczynski 发现并报告。

- **修复** 修复了 istiod 调试端点（`/debug/config_dump`、`/debug/edsz` 以及 XDS `istio.io/debug/config_dump` 类型）
  以子字符串方式匹配 `proxyID` 的问题，这使得调用方可以通过传递部分 ID 来读取其所在命名空间中其他代理的配置。
  现在，`proxyID` 必须是精确的 `<pod>.<namespace>`（或完整的连接 ID）；
  诸如 `proxyID=istio-ingressgateway` 之类的简写形式将不再匹配。
  **致谢**：此问题由 박현범 报告。

## 变更 {#changes}

- **新增** 添加了对通过 `ProxyConfig` 中的 `connectionSettings`
  配置集群级连接缓冲区限制（`clusterPerConnectionBufferLimitBytes`）的支持，
  包括面向网关代理的 `EDGE` 配置文件默认值。

- **新增** 在 `ProxyConfig.connectionSettings` 中添加了对 `globalDownstreamConnectionLimit` 的支持，
  为配置全局下游连接限制提供了正式的 API 字段。该字段的优先级高于现有的
  `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS` 元数据和已弃用的
  `overload.global_downstream_max_connections` 运行时标志。
  ([Issue #57973](https://github.com/istio/istio/issues/57973))

- **改进** 改进了针对 DestinationRule 变更的增量 EDS 处理，使其通过 Sidecar 作用域识别受影响的服务，
  与 CDS 的处理方式保持一致，并避免按集群逐个查找 DestinationRule。

- **修复** 修复了带有多个 `InferencePool` `backendRefs` 的 `HTTPRoute` 规则只配置了一个端点选择器的问题。
  列在最后的 `backendRef` 的选择器会为该规则上的每个请求打分，因此其他池的选择器从未被调用，
  而且没有就绪端点的池会导致整条规则失败，而不仅仅是其自身所占的加权份额失败。
  现在，每个池都有自己的选择器，并挂接到各自的加权集群上。
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **修复** 修复了同一网关上两个 `rules[].name` 相同的 `HTTPRoute` 会相互覆盖对方端点选择器的问题。
  规则名称只需在单个 `HTTPRoute` 内唯一，但选择器是跨所有 `HTTPRoute` 以名称为键进行存储的，
  因此一个路由可能会由另一个路由的选择器来处理。现在，选择器按 `backendRef` 进行解析，
  因此相同的名称不会再把一个路由的选择器转移到另一个路由上。
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **修复** 修复了路由规则在同时带有 CORS 过滤器时会丢失其 `InferencePool` 端点选择器的问题。
  两者都会被写入同一个按过滤器划分的配置中，而 CORS 的处理路径会替换整个映射，而不是向其中添加条目。
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **修复** 修复了 OpenShift 上绑定到自定义 `SecurityContextConstraint` 的工作负载的 Sidecar 代理 UID/GID 解析问题，
  这类 `SecurityContextConstraint` 具有较窄的或显式配置的 UID 范围，
  而该范围不会在命名空间的预分配 UID 范围注解中公布。
  ([Issue #61791](https://github.com/istio/istio/issues/61791))

- **修复** 修复了禁用 EDS 防抖时推送上下文被并发初始化的问题。
  ([Issue #61924](https://github.com/istio/istio/issues/61924))

- **修复** 修复了启用 `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` 时，
  增量 CDS 推送会删除网关中为 `EnvoyFilter` 的 `envoyfilter.istio.io/referenced-services`
  注解所列服务生成的集群的问题。这些集群只有在下一次全量推送时才会恢复。
  ([Issue #62067](https://github.com/istio/istio/issues/62067))

- **新增** 针对以下 `ServiceEntry` 地址添加了验证警告：通配地址（`0.0.0.0`、`::`）、
  未指定网络的地址（`0.0.0.0/N`、`::/N`），以及前缀短于 `/8` 的 CIDR。
  此类 `ServiceEntry` 如果使用 `resolution: NONE` 和默认的 `exportTo`，
  可能会使网格中的每个 Sidecar 都直通其端口上的流量，从而绕过 `outboundTrafficPolicy` 的 `REGISTRY_ONLY`。
  请使用范围更窄的 CIDR 和 `exportTo: ["."]`。如需强制执行出口管控，请将出口网关与 NetworkPolicy 结合使用。
  ([Issue #62124](https://github.com/istio/istio/issues/62124))

- **修复** 修复了 Ambient 中用于变更检测和版本控制的预序列化工作负载在工作负载拥有多个服务时不稳定的问题。
  这会导致未发生变化的工作负载在每次重新计算时都看起来像是被修改过，
  并导致客户端重新连接时无法跳过未发生变化的工作负载。

- **修复** 修复了当网络具有多个网关条目时，为工作负载选择的网络网关会以随机顺序选取的问题，
  这会导致每次重新计算时出现不必要的工作负载（WDS）推送，
  并可能导致工作负载所使用的网关地址来回切换。

- **修复** 修复了网关的配置依赖过滤，使其排除不相关的配置更新。
  构建网关作用域时，也会跳过收集仅用于 waypoint 路由的网格 `VirtualServices`。

- **修复** 修复了从基于 CRD 的 informer 中移除单个事件处理程序时，
  会移除该 informer 上所有处理程序的问题。在 Ambient 多集群模式下，
  每次轮换远程集群凭证时都会触发此问题，导致 istiod 无限期地等待新集群的集合完成同步，
  进而造成远程网络网关缺失，并且工作负载索引可能会停止更新，直到重启为止。
  ([Issue #61827](https://github.com/istio/istio/issues/61827))

- **修复** 修复了当 Kubernetes API 请求得不到响应时（例如负载均衡器或代理静默丢弃了返回路径），
  Istio 组件会无限期挂起的问题。以前，此类请求可能会永远保持打开状态，
  导致发出该请求的控制器停滞，直到进程重新启动。现在，请求会在客户端超时，
  因此卡住的请求会被取消，组件也能够自行恢复。每次超时都会被记录为一条警告，
  并计入 `kube_client_deadline_fired_total` 指标。可以通过 `ISTIO_KUBE_HEADER_TIMEOUT`（默认 `90s`）
  和 `ISTIO_KUBE_REQUEST_TIMEOUT`（默认 `15m`）调整超时时间；
  将其中任一项设置为 `0` 即可恢复之前无上限的行为。

- **修复** 修复了与 EDS 无关的配置更新在与端点更新合并后，
  会触发全量 EDS 生成，而不是仅更新受影响的端点分配的问题。

- **修复** 通过添加 `PILOT_ENABLE_WDS_DEBOUNCE` 环境变量（默认启用），
  修复了导致 WDS 推送无法跳过防抖的回归问题。将其设置为 `false`，
  即可让 WDS 推送独立于 EDS 推送跳过防抖。
  ([Issue #62125](https://github.com/istio/istio/issues/62125))

- **修复** 修复了在 CPU 提供 `RNDR` 指令的 arm64 节点（例如 GKE Axion）上，
  当硬件随机数生成器报告暂时性故障时，ztunnel 以退出码 133（`SIGTRAP`）陷入崩溃循环的问题。
  `aws-lc-rs` 已更新至 1.18.2，该版本会重试读取，而不是中止。
  ([Issue #2072](https://github.com/istio/ztunnel/issues/2072))
