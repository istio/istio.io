---
title: 发布 Istio 1.6.1
linktitle: 1.6.1
subtitle: 补丁更新
description: Istio 1.6.1 补丁更新。
publishdate: 2020-06-04
release: 1.6.1
aliases:
    - /news/announcing-1.6.1
---

此版本包含错误修复以提高稳定性。此发布说明描述了 Istio 1.6.0 和 Istio 1.6.1 之间的区别。

{{< relnote >}}

## 变更

- **修复** 支持使用 Pod 注释来覆盖整个 Mesh 的代理设置
- **Updated** `EnvoyFilter` 注册所有过滤器类型以支持 `typed_config` 属性（[Issue 23909](https://github.com/istio/istio/issues/23909)）
- **修复** 网关自定义资源名称的问题 ([Issue 23303](https://github.com/istio/istio/issues/23303))
- **修复** `Istiod` 无法向远程集群发放证书的问题。现在 `Istiod` 支持集群名称和证书以生成 `injectionURL`。 ([Issue 23879](https://github.com/istio/istio/issues/23879))
- **修复** 远程集群的验证控制器检查 `Istiod` 的就绪状态端点。 ([Issue 23945](https://github.com/istio/istio/issues/23945))
- **改进** `regexp` 字段，验证以匹配 Envoy 的验证策略 ([Issue 23436](https://github.com/istio/istio/issues/23436))
- **修复** `istioctl analyze` 进行验证 `networking.istio.io/v1beta1` 资源 ([Issue 24064](https://github.com/istio/istio/issues/24064))
- **修复** `ControlZ` 仪表板日志中 `istio` 的拼写错误 ([Issue 24039](https://github.com/istio/istio/issues/24039))
- **修复** 将 tar 文件名转换为目录名称 ([Issue 23635](https://github.com/istio/istio/issues/23635))
- **改进** 将多集群和虚拟机设置的证书管理路径从 `samples/certs` 目录改为 `install/tools/certs` 目录。
- **改进** 在仅存在 CA 客户端证书时，改进 `pilot-agent` 对客户端证书的处理。
- **改进** `istiocl upgrade` 命令以引导用户从 `v1alpha1` 安全策略迁移到 `v1beta1` 安全策略，指向 `istio.io`。
- **修复** `istioctl upgrade` 发布 URL 名称。
- **修复** 集群资源的 `k8s.overlays` 问题。
- **修复** Gateway 中 `HTTP/HTTP2` 冲突的问题（[Issue 24061](https://github.com/istio/istio/issues/24061) 和 [Issue 19690](https://github.com/istio/istio/issues/19690)）。
- **修复** Istio operator 不接受 `--operatorNamespace` 参数的问题（[Issue 24073](https://github.com/istio/istio/issues/24073)）。
- **修复** 卸载 Istio 时 Istio operator 卡住的问题（[Issue 24038](https://github.com/istio/istio/issues/24038)）。
- **修复** 向指定了 `http2_protocol_options` 的上游集群交换 TCP 元数据的问题（[Issue 23907](https://github.com/istio/istio/issues/23907)）。
- **增加** `istio-sidecar-injector` 的 `MutatingWebhookConfiguration` 字段 `sideEffects`（[Issue 23485](https://github.com/istio/istio/issues/23485)）。
- **改进** 备用控制面的安装流程（[Issue 23871](https://github.com/istio/istio/issues/23871)）。
- **修复** `istioctl experimental precheck` 命令，以报告兼容的 Kubernetes 版本（1.14-1.18）（[Issue 24132](https://github.com/istio/istio/issues/24132)）。
- **修复** Istio operator 命名空间不匹配导致资源泄漏的问题（[Issue 24222](https://github.com/istio/istio/issues/24222)）。
- **修复** 当代理使用挂载文件证书的 Gateway 时 SDS Agent 启动失败的问题（[Issue 23646](https://github.com/istio/istio/issues/23646)）。
- **修复** TCP over HTTP 冲突导致生成无效配置的问题（[Issue 24084](https://github.com/istio/istio/issues/24084)）。
- **修复** 远程 Pilot 地址为主机名时使用外部名称的问题（[Issue 24155](https://github.com/istio/istio/issues/24155)）。
- **修复** 在 Google Kubernetes Engine (GKE) 上启用 Istio CNI 和 `cos_containerd` 时，Istio CNI node `DaemonSet` 启动的问题（[Issue 23643](https://github.com/istio/istio/issues/23643)）。
- **修复** 当 DNS 不可达时，Istio CNI 导致 Pod 初始化延迟 30-40 秒的问题（[Issue 23770](https://github.com/istio/istio/issues/23770)）。
- **改进** Google Stackdriver 遥测使用 GCE VMs 的 UID。
- **改进** 遥测插件，以避免因无效配置而崩溃（[Issue 23865](https://github.com/istio/istio/issues/23865)）。
- **修复** 当 WASM 过滤器的 HTTP 响应为空时，代理 sidecar 可能会崩溃的问题（[Issue 23890](https://github.com/istio/istio/issues/23890)）。
- **修复** 代理 sidecar 在解析 CEL 表达式时可能会崩溃的问题（[Issue 497](https://github.com/envoyproxy/envoy-wasm/issues/497)）。

## Bookinfo 示例应用程序的安全修复

我们已经更新了 Bookinfo 示例应用程序中使用的 Node.js 和 jQuery 版本。Node.js 已从 12.9 版本升级到 12.18 版本，jQuery 已从 2.1.4 版本升级到 3.5.0 版本。此次更新解决了最高评级的漏洞:
*使用畸形 Transfer-Encoding 标头进行 HTTP 请求走私（严重）（CVE-2019-15605）*。