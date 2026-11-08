---
title: 发布 Istio 1.31.4
linktitle: 1.31.4
subtitle: 补丁发布
description: Istio 1.31.4 补丁发布。
publishdate: 2026-11-06
release: 1.31.4
aliases:
    - /zh/news/announcing-1.31.4
---

此版本包含安全修复。本发行说明描述了 Istio 1.31.3 和 Istio 1.31.4 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

有关更多信息，请参阅
[ISTIO-SECURITY-2026-009](/zh/news/security/istio-security-2026-009)。

### Istio CVE {#istio-cves}

- __[GHSA-rr2c-p22p-6r9r](https://github.com/istio/istio/security/advisories/GHSA-rr2c-p22p-6r9r)__ (CVSS score 8.2, High)：
  在 Ambient 模式下，由于一个运算符优先级错误，当在网格范围的 `STRICT` 策略下工作负载模式为
  `PERMISSIVE` 或 `DISABLE` 时，端口级别的 `STRICT` `PeerAuthentication` 会被跳过，
  从而允许明文流量到达要求 mTLS 的端口。
  **致谢**：此漏洞由 Ravikanth Reddy 发现并报告。

- __[GHSA-7m6f-j3gp-2r53](https://github.com/istio/istio/security/advisories/GHSA-7m6f-j3gp-2r53)__ (CVSS score 6.5, Moderate)：
  针对 `request.headers[:authority]` 或 `request.headers[host]` 的 `AuthorizationPolicy` `when` 条件
  以区分大小写的方式进行匹配，因此主机名大小写不同的请求可以绕过该条件。
  现在，这些条件与 `hosts` 一样以不区分大小写的方式进行匹配。
  **致谢**：此漏洞由 [@akoul](https://github.com/akoul) 发现并报告。

- __[GHSA-cxwg-46mx-q8hf](https://github.com/istio/istio/security/advisories/GHSA-cxwg-46mx-q8hf)__ (CVSS score 7.4, High)：
  复用已拆除连接四元组的新入站连接可能会匹配到过时的 conntrack `ESTABLISHED` 条目，从而绕过 Sidecar 代理。
  现在，在 iptables 和 nftables 模式下，仅匹配 SYN 的规则都会在 `ESTABLISHED` 转向规则之前进行评估。
  **致谢**：此漏洞由 [@ramaraochavali](https://github.com/ramaraochavali)、[@akshayreddyb](https://github.com/akshayreddyb)、
  [@Pawan-Bishnoi](https://github.com/Pawan-Bishnoi) 和 [@deveshkandpal1224](https://github.com/deveshkandpal1224) 发现并报告。

- __[GHSA-635j-qv98-9275](https://github.com/istio/istio/security/advisories/GHSA-635j-qv98-9275)__ (CVSS score 7.7, High)：
  任何具有网格身份的工作负载都可以发送资源名称无法通过 URL 解析的 `istio.io/debug` xDS 请求，
  使 istiod 崩溃，从而导致整个网格的控制平面陷入崩溃循环。
  现在，此类请求会以 `InvalidArgument` 被拒绝。
  **致谢**：此漏洞由 Checkmarx Research 的 Alon Lerner 发现并报告。

- __[GHSA-8jw7-82jp-wr2c](https://github.com/istio/istio/security/advisories/GHSA-8jw7-82jp-wr2c)__ (CVSS score 6.3, Moderate)：
  在 Ambient 模式下，如果 `AuthorizationPolicy` 包含未被验证 Webhook 拒绝的空 `to` 或 `from` 条目，
  则会导致 istiod 崩溃并陷入崩溃循环，直到该策略被删除为止，从而使整个网格的配置分发停止。
  现在，此类条目会被视为空的 `operation` 或 `source`，与 Sidecar 的行为一致。
  **致谢**：此漏洞由 [@r0binak](https://github.com/r0binak) 发现并报告。

- __[GHSA-gf6w-6mxv-5fj4](https://github.com/istio/istio/security/advisories/GHSA-gf6w-6mxv-5fj4)__ (CVSS score 6.3, Moderate)：
  在多集群安装中，代理可以冒充另一个集群的 `CLUSTER_ID`，并通过 SDS 获取该集群的 `kubernetes://` Secret。
  istiod 不再接受与验证代理令牌所用集群不同的节点元数据 `CLUSTER_ID`。
  **致谢**：此漏洞由 Yonghwa Lee（Xint by Theori）发现并报告。

- __[GHSA-77vw-rg85-wx5x](https://github.com/istio/istio/security/advisories/GHSA-77vw-rg85-wx5x)__ (CVSS score 6.5, Moderate)：
  ztunnel 在解析不包含四个以短横线分隔字段的 55 字节 `traceparent` 标头时会发生 Panic，
  从而终止入站 HBONE 连接任务，并丢弃在该连接上多路复用的所有流。
  长度正确但字段布局无效的标头也会被接受，而不是被拒绝。
  现在，无效的 `traceparent` 标头会被忽略，并生成新的追踪 ID。
  **致谢**：此漏洞由 [@RaphaelFakhri](https://github.com/RaphaelFakhri) 发现并报告。

- __[GHSA-9gqj-583v-mpqp](https://github.com/istio/istio/security/advisories/GHSA-9gqj-583v-mpqp)__ (CVSS score 5.6, Moderate)：
  在 Ambient waypoint 以及接收 HBONE 流量的 Sidecar 上，`AuthorizationPolicy` 的 `ipBlocks`、`notIpBlocks`
  和 `source.ip` 条件匹配的是 Envoy 内部监听器地址而不是客户端 IP，
  因此基于这些字段的 `DENY` 规则可能会失效放行（fail open）。

### 其他 Istio 安全修复 {#other-istio-security-fixes}

- **修复** 修复了 JWKS 解析器的周期性后台刷新在缓存获取到的响应时，不验证该响应看起来是否为 JWKS 的问题。
  同步获取路径已经会拒绝格式不像 JWKS（`{"keys": [...]}`）的响应，
  从而防止当 `RequestAuthentication` 的 `jwksUri` 指向非预期的内部端点时，
  该端点的响应被缓存并被当作 JWKS 返回。现在，后台刷新路径也会应用相同的检查。
  **致谢**：此问题由 Anthropic 和 Ada Logics 报告。

## 变更 {#changes}

- **新增** 新增了在 Ambient 东西向网关（`istio-east-west` `GatewayClass`）上对 `AUTO_PASSTHROUGH` 监听器的支持。
  端口 15443 上的 TLS 透传监听器（或任何使用 `gateway.istio.io/listener-protocol: auto-passthrough` 选项的端口）
  现在会与 HBONE 监听器一起为 Sidecar 多网络流量提供服务，
  因此 Ambient 和 Sidecar 混合网格不再需要在每个集群中部署两个东西向网关。
  此功能要求启用 `AMBIENT_ENABLE_MULTI_NETWORK`。
  ([Issue #60887](https://github.com/istio/istio/issues/60887))

- **修复** 修复了将 `outlierDetection` 应用于动态转发代理（DFP）通配符集群时 istiod 发生 Panic 的问题。
  ([Issue #61450](https://github.com/istio/istio/issues/61450))

- **修复** 修复了 `istio-cni` Helm Chart 不遵循为 `istioOwnedCNIConfigFileName` 设置的值的问题。

- **修复** 修复了通过 Helm Chart 更新 `istio-cni` 配置后，不会重启 `istio-cni` 以使新值生效的问题。

- **修复** 修复了卸载 `istio-cni` Helm Chart 时，自有的 `istio-cni` 配置未被移除，
  或者主 CNI 配置中的 `istio-cni` 插件未被移除的问题。

- **修复** 修复了启用自有的 `istio-cni` 配置时，主 CNI 配置未被清理的问题。

- **修复** 修复了更改自有的 `istio-cni` 配置文件名时，之前的文件未被移除的问题。
  ([Issue #61890](https://github.com/istio/istio/issues/61890))

- **修复** 修复了 `source_app` 和 `destination_app` 指标标签的问题：当 Pod 同时带有
  `app.kubernetes.io/name` 标签时，现在会使用 Pod 的 `app` 标签。从 1.29.1 开始，这些指标标签使用的是 `app.kubernetes.io/name`，
  这是一个偏离预期行为的回归问题。
  ([Issue #62280](https://github.com/istio/istio/issues/62280))

- **修复** 修复了获取 JWKS 可能会阻塞 xDS 生成的问题。
  ([Pull Request #62486](https://github.com/istio/istio/pull/62486))

- **修复** 修复了 waypoint 和 Sidecar 的 HBONE 内部监听器上 `AuthorizationPolicy` 的 `ipBlocks` 和 `notIpBlocks` 匹配问题，
  现在会使用下游客户端的直接远程 IP 地址，而不是 Envoy 内部地址。
  ([Issue #62522](https://github.com/istio/istio/issues/62522))

- **修复** 修复了当 Ambient Pod 与其命名空间一起被删除时，`istio-cni` 跳过清理，
  从而遗留其 ztunnel 代理和主机探针 ipset 条目的问题。

- **修复** 修复了 Istio 1.31 中引入的一个问题：对包含 CA 证书的 `ConfigMap`
  （例如 Kubernetes 在每个命名空间中创建的 `kube-root-ca.crt` `ConfigMap`）的更改
  会向每个代理触发 CDS、LDS、RDS 和 NDS 推送。集群会被完全重建，而不是增量构建。
  与 `Secret` 更新一样，这些更改现在只会触发 SDS 推送。对于这些更新，现在也会跳过 EDS。
  ([Issue #62523](https://github.com/istio/istio/issues/62523))

- **修复** 修复了对 `EndpointSlice` 仅元数据的更新（例如 GitOps 工具写入注解）会触发 EDS 推送的问题，
  对于带有非 HTTP 端口的无头 `Service`，即使端点没有变化，也会向每个代理推送。

- **修复** 修复了 `istiod` 仅容忍默认的 `cni.istio.io/not-ready` 污点的问题。
  当 `taint.name` 设置为自定义污点时，`istiod` Deployment 现在会容忍该污点，
  从而使 `istiod` 可以被调度到仍带有该污点的节点上。
  ([Issue #52073](https://github.com/istio/istio/issues/52073))

- **修复** 修复了对 Istio 配置资源仅元数据的更新（例如 GitOps 工具写入注解）时，
  只要该资源带有任何 `istio.io` 标签或注解（例如 `istio.io/rev`），就会触发推送的问题。
  现在，只有当 spec 或 `istio.io` 标签或注解的值发生变化时才会触发推送。

- **修复** 修复了一个回归问题：当 waypoint 为另一个命名空间中的 `Service` 提供服务时，
  位于 waypoint 自身命名空间中、通过 `targetRefs` 或 `selector` 选中的 `Telemetry` 资源未被应用。
  以这种方式配置的访问日志、指标和追踪，对于该 waypoint 处理的每个跨命名空间 `Service` 都会被静默丢弃。
  ([Issue #61538](https://github.com/istio/istio/issues/61538))
