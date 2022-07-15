---
title: Istio 1.12.2 发布说明
linktitle: 1.12.2
subtitle: Patch Release
description: Istio 1.12.2 补丁发布。
publishdate: 2022-01-18
release: 1.12.2
aliases:
    - /zh/news/announcing-1.12.2
---

此版本修复了 1 月 18 日帖子中所述的安全漏洞 ([ISTIO-SECURITY-2022-001](/zh/news/security/istio-security-2022-001) 和 [ISTIO-SECURITY-2022-002](/zh/news/security/istio-security-2022-002)) 且包含次要漏洞修复以改进健壮性。此发布说明描述了 Istio 1.12.1 和 1.12.2 之间的不同之处。

{{< relnote >}}

## 安全更新 {#security-update}

- __[CVE-2022-21679](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2CVE-2022-21679i])__:
  Istio 1.12.0 和 1.12.1 包含一个漏洞，会为 1.11 版本的代理生成不正确的配置，影响授权策略中的 `hosts` 和 `notHosts` 字段。

- __[CVE-2022-21701](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2CVE-2022-21679i])__:
  Istio 1.12.0 和 1.12.1 版本存在特权升级攻击的漏洞。拥有 `gateways.gateway.networking.k8s.io` 对象的 `CREATE` 权限的用户可以升级该权限以创建他们可能没有权限的其他资源，如 `Pod`。

## 变更 {#changes}

- **添加** 为 Istio-CNI Helm charts 添加了 `securityContext` 的特权标志。
  ([Issue #34211](https://github.com/istio/istio/issues/34211))

- **修复** 修复了在启用 Telemetry API 的链路追踪时会导致在链路报告请求中使用错误主机头的问题。
  ([Issue #35750](https://github.com/istio/istio/issues/35750))

- **修复** 修复了 `istioctl pc log` 命名标签选择器未选择默认 Pod。
  ([Issue #36182](https://github.com/istio/istio/issues/36182))

- **修复** 修复了 `istioctl analyze` 会虚假警告 VirtualService 前缀匹配重叠的问题。
  ([Issue #36245](https://github.com/istio/istio/issues/36245))

- **修复** 修复了省略设置，在默认版本中修改 webhook 的
  `.Values.sidecarInjectiorWebhook.enableNamespacesByDefault` 参数，
  并在 `istioctl tag` 中添加了 --auto-inject-namespaces 标志来控制该设置。
  ([Issue #36258](https://github.com/istio/istio/issues/36258))

- **修复** 修复了 Istio Gateway Helm charts 中用于配置服务注解的数值。可用于配置公有云中的负载均衡器。
  ([Pull Request #36384](https://github.com/istio/istio/pull/36384))

- **修复** 修复了构建信息中的版本和修订版格式不正确的问题。
  ([Pull Request #36409](https://github.com/istio/istio/pull/36409))

- **修复** 修复了当一个服务被删除并再次创建时可以配置旧端点的问题。
  ([Issue #36510](https://github.com/istio/istio/issues/36510))

- **修复** 修复了由于窗口外的数据包使得 sidecar iptables 出现间歇性连接重置的问题。
  引入了一个 `meshConfig.defaultConfig.proxyMetadata.INVALID_DROP` 标志来控制这个设置。
  ([Issue #36489](https://github.com/istio/istio/issues/36489))

- **修复** 修复了执行 `operator init --dry-run` 命令会创建非预期命名空间的问题。
  ([Pull Request #36570](https://github.com/istio/istio/pull/36570))

- **修复** 修复了 `includeInboundPorts` 设置采用 helm 值时不会生效的问题。
  ([Issue #36644](https://github.com/istio/istio/issues/36644))

- **修复** 修复了 endpoint 切片缓存泄露的问题。
  ([Pull Request #36518](https://github.com/istio/istio/pull/36518))

- **修复** 修复了当启用 RDS 缓存时授权虚拟服务不生效的问题。
  ([Issue #36525](https://github.com/istio/istio/issues/36525))

- **修复** 修复了当使用 Envoy 的
  [`v3alpha`](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.20.0#incompatible-behavior-changes) 时，API `EnvoyFilter` 断言错误的问题。
  ([Issue #36537](https://github.com/istio/istio/issues/36537))
