---
title: Istio 1.13 升级说明
description: 升级到 Istio 1.13.0 时需要考虑的重要变化。
publishdate: 2022-02-11
weight: 20
---

当你从 Istio 1.12.x 升级到 Istio 1.13.0 时，你需要考虑这个页面上的变化。
这些注释详细说明了有意破坏与 Istio 1.13.0 的向后兼容性的更改。
这些注释还提到了在引入新行为同时保留向后兼容性的更改。
仅当新行为对 Istio `1.12.x` 的用户而言是意外的时，才包括更改。

## Health Probes 不再重复使用连接{#health-probes-will-no-longer-re-use-connections}

使用 istio-agent [健康检查重写](/zh/docs/ops/configuration/mesh/app-health-check/)的健康检查现在将不会再重复使用探针的连接。
这种行为被改变以匹配 Kubernetes 的探测行为，
还可以提高使用短空闲超时的应用程序的探测可靠性。

因此，您的应用程序可能会看到更多来自探针的连接(但 HTTP 请求的数量相同)。
对于大多数应用程序，这不会有明显的不同。

如果您需要恢复到旧的设置，可以设置代理中的 `ENABLE_PROBE_KEEPALIVE_CONNECTION=true` 环境变量。

## 多集群秘钥身份验证更改{#multicluster-secret-authentication-changes}

当创建 kubeconfig 文件以在多集群安装中[启用端点发现](/zh/docs/setup/install/multicluster/multi-primary/#enable-endpoint-discovery)
时，现在对配置中允许的身份验证方法进行了限制，以提高安全性。

两种身份验证方法输出但 `istioctl create-remote-secret` (`oidc` 和 `token`)不受影响。
因此，只有创建自定义 kubeconfig 文件的用户才会受到影响。

一个新的环境变量 `PILOT_INSECURE_MULTICLUSTER_KUBECONFIG_OPTIONS`，被添加到 Istiod 来启用已删除的方法。
例如，如果使用 `exec` 认证，则设置 `PILOT_INSECURE_MULTICLUSTER_KUBECONFIG_OPTIONS=exec`。

## iptables 对 22 端口捕获的变化{#port-22-iptables-capture-changes}

在以前的版本中，端口 22 被排除在 iptables 捕获之外。
这降低了在 VM 上使用 Istio 时被锁定在 VM 之外的风险。
这个配置被硬编码到 iptables 逻辑中，意味着没有办法捕获 22 号端口的流量。

iptables 逻辑现在在端口 22 上不再有特殊的逻辑。
相反，这个 `istioctl x workload entry configure` 命令将自动配置 `ISTIO_LOCAL_EXCLUDE_PORTS` 以包含端口 22。
这意味着 VM 用户会继续排除端口 22，然而 Kubernetes 用户现在将包含端口 22。

如果不希望出现这种行为，可以在 Kubernetes 中使用 `traffic.sidecar.istio.io/excludeInboundPorts` 注解明确选择该端口。
