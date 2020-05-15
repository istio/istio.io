---
title: 更新公告
description: 升级到 Istio 1.5 需注意的重要变更。
weight: 20
---

此页面描述了从 Istio 1.4.x 升级到 1.5.x 时需要注意的更改。在这里，我们详细介绍了有意不再向下兼容情况。还提到了保留向下兼容但引入了新行为的情况，熟悉 Istio 1.4 的使用和操作的人可能会感到惊讶。

## 重构控制平面{#control-plane-restructuring}

在 Istio 1.5 中，我们开始使用新的控制平面 deployment 模型，其中整合了许多组件。下面各功能迁移位置的说明。

### Istiod

Istio 1.5，会有一个新的 deployment：`istiod`。该组件是控制平面的核心，负责处理配置、证书分发以及 sidecar 注入等。

### sidecar 注入{#sidecar-injection}

以前，sidecar 注入是通过一个可变的 webhook 处理的，该 webhook 由名为 `istio-sidecar-injector` 的 deployment 处理。在 Istio 1.5 中，保留了相同的可变 webhook，但现在它指向 `istiod` deployment，其它所有注入逻辑保持不变。

### Galley

* 配置验证。保持不变，但现在由 `istiod` deployment 处理。
* MCP 服务器。默认情况下，MCP 服务器是禁用的。对于大多数用户，这是一个可实现细节。如果您依赖此功能，则需要运行 `istio-galley` deployment。
* 实验性功能（例如配置分析）。这些功能将需要 `istio-galley` deployment。

### Citadel

以前，Citadel 有两个功能：将证书写入至每个命名空间中的 secret、在使用 SDS 时通过 gRPC 将 secret 提供给 `nodeagent`。在 Istio 1.5 中，secret 不再写入至每个命名空间。而是仅通过 gRPC 提供服务。并且，此功能已迁移至 `istiod` deployment。

### SDS 节点代理{#sds-node-agent}

移除 `nodeagent` deployment。现在，此功能存在于 Envoy sidecar 中。

### Sidecar

以前，sidecar 可以通过两种方式访问证书：通过作为文件挂载的 secret 或 SDS（通过 `nodeagent`）。在 Istio 1.5 中，已对此进行了简化。所有 secret 信息将通过本地运行的 SDS 服务器提供。对于大多数用户而言，这些 secret 将从 `istiod` deployment 中获取。对于具有自定义 CA 的用户，仍可以使用文件挂载的 secret，但是，本地 SDS 服务器仍将提供这些 secret。这意味着证书轮换不再需要重启 Envoy。

### CNI

`istio-cni` deployment 没有变化。

### Pilot

移除 `istio-pilot` deployment，以便支持 `istiod` deployment，`istiod` 包含了 Pilot 曾经拥有的所有功能。为了向下兼容，保留了一些对 Pilot 的引用。

## 弃用 Mixer{#mixer-deprecation}

Mixer，即 `istio-telemetry` 和 `istio-policy` deployment 背后的过程，在 1.5 版本中被弃用了。Istio 1.3 开始，默认禁用了 `istio-policy`，而 Istio 1.5 ，默认禁用了 `istio-telemetry`。

遥测现在是使用的不再需要 Mixer 的代理内扩展机制（Telemetry V2）收集的。

如果您依赖 Mixer 的某些特有的特性，如进程外适配器，则可以手动重新启用 Mixer。在 Istio 1.7 之前，Mixer 将继续收到 bug 修复程序和安全修复程序。Mixer 支持的许多特性都能在[弃用 Mixer](https://tinyurl.com/mixer-deprecation) 文档中找到替代方法，包括基于 WebAssembly 沙箱 API 的[代理内扩展](https://github.com/istio/proxy/tree/master/extensions)。

如果您需要 Mixer 没有的特性，我们建议您公开问题并在社区中进行讨论。

查看[弃用 Mixer](https://tinyurl.com/mixer-deprecation) 获取详细信息。

### Telemetry V2 和 Mixer Telemetry 的差异{#feature-gaps-between-telemetry-v2-and-mixer-telemetry}

* 不支持网格外遥测。如果流量源或目的地未注入 sidecar，则会缺少某些遥测数据。
* [不支持](https://github.com/istio/istio/issues/19385) Egress gateway 遥测。
* 仅支持基于 `mtls` 的 TCP 遥测。
* 不支持针对 TCP 和 HTTP 的黑洞遥测。
* 直方图与 [Mixer Telemetry](https://github.com/istio/istio/issues/20483) 显著不同，且无法更改。

## 认证策略{#authentication-policy}

Istio 1.5 引入了 [`PeerAuthentication`](/zh/docs/reference/config/security/peer_authentication/) 和 [`RequestAuthentication`](/zh/docs/reference/config/security/request_authentication) （它们取代了 Authentication API 的 Alpha 版本）。有关新 API 的更多信息，请参见 [authentication policy](/zh/docs/tasks/security/authentication/authn-policy) 教程。

* 升级 Istio 后，您 Alpha 版的身份验证策略将被保留并继续使用。您可以逐步将它们替换为等效的 `PeerAuthentication` 和 `RequestAuthentication`。新策略将根据定义的范围内接管旧策略。我们建议从 workload（最具体的范围）开始替换，然后是命名空间，最后是整个网格范围。

* 替换 workload、命名空间和整个网格的策略之后，您可以使用以下命令，安全地删除 alpha 版本的身份验证策略：

{{< text bash >}}
$ kubectl delete policies.authentication.istio.io --all-namespaces --all
$ kubectl delete meshpolicies.authentication.istio.io --all
{{< /text >}}

## Istio workload 密钥及证书配置{#Istio-workload-key-and-certificate-provisioning}

* 我们已经稳定了 SDS 证书和密钥配置流程。现在，Istio workload 使用 SDS 来提供证书。不建议再使用通过 secret 卷挂载的方法。
* 请注意，启用双向 TLS 后，需要手动修改 Prometheus deployment 以监控 workload。详细信息在此 [issue](https://github.com/istio/istio/issues/21843) 中。该问题将在 1.5.1 中解决。

## 控制平面安全{#control-plane-security}

作为 Istiod 努力的一部分，我们已经更改了代理与控制平面安全通信的方式。在以前的版本中，当配置了 `values.global.controlPlaneSecurityEnabled=true` 设置时，代理将安全地连接到控制平面，这也是 Istio 1.4 的默认设置。每个控制平面组件都运行带有 Citadel 证书的 sidecar，并且代理通过端口 15011 连接到 Pilot。

在 Istio 1.5 中，代理与控制平面连接的推荐或默认方式不再是这样；相反，可以使用由 Kubernetes 或 Istiod 签名的 DNS 证书，通过 15012 端口连接到 Istiod。

注意：尽管如此，但在 Istio 1.5 中，将 `controlPlaneSecurityEnabled` 设置为 `false` 时，默认情况下控制平面之间的通信已经是安全的。

## 多集群安装{#multicluster-setup}

{{< warning >}}
如果您使用的是多集群，建议您不要升级到 Istio 1.5.0!

多集群 Istio 1.5.0 目前存在几个已知问题，这些问题（[27102](https://github.com/istio/istio/issues/21702), [21676](https://github.com/istio/istio/issues/21676)）使其在共享控制平面和控制平面副本集 deployment 中均无法使用。这些问题将在 Istio 1.5.1 中解决。
{{< /warning >}}

## Helm 升级{#helm-upgrade}

如果您使用 `helm upgrade` 将群集更新到较新的 Istio 版本，则建议您使用 [`istioctl upgrade`](/zh/docs/setup/upgrade/istioctl-upgrade/) 或遵循 [helm template](/zh/docs/setup/upgrade/cni-helm-upgrade/) 的步骤。
