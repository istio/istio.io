---
title: 发布 Istio 1.20.0
linktitle: 1.20.0
subtitle: 大版本更新
description: Istio 1.20 发布公告。
publishdate: 2023-11-14
release: 1.20.0
aliases:
- /zh/news/announcing-1.20
- /zh/news/announcing-1.20.0
---

我们很高兴地宣布 Istio 1.20 发布。这是 2023 年内最后一个 Istio 版本，
我们要感谢整个 Istio 社区对 1.20.0 版本发布所作出的帮助。
我们要感谢此版本的几位发布经理：来自 DaoCloud 的 `Xiaopeng Han`、
来自 Google 的 `Aryan Gupta` 和来自 Tetrate 的 `Jianpeng He`。
这些发布经理们要特别感谢测试和发布工作组负责人 Eric Van Norman (IBM) 在整个发布周期中提供的帮助和指导。
我们还要感谢 Istio 工作组的维护者以及广大 Istio 社区，感谢他们在发布过程中提供及时反馈、
审核和社区测试，以及在确保及时发布方面给予的全力支持。

{{< relnote >}}

{{< tip >}}
Istio 1.20.0 已得到 Kubernetes `1.25` 到 `1.28` 的官方正式支持。
{{< /tip >}}

## 新特性 {#whats-new}

### Gateway API

Kubernetes [Gateway API](http://gateway-api.org/)
是一项旨在为 Kubernetes 带来丰富的服务网络 API
（类似于 Istio VirtualService 和 Gateway）的举措。

Kubernetes [Gateway API 现已正式发布](https://kubernetes.io/blog/2023/10/31/gateway-api-ga/)
并且 Istio 已对其提供[全面支持](https://gateway-api.sigs.k8s.io/implementations/#istio)！
这是整个 Kubernetes 生态系统社区共同努力的结果，并且产生了多种合规实现
（包括 [Istio 完全合规的实现](https://github.com/kubernetes-sigs/gateway-api/blob/main/conformance/reports/v1.0.0/istio-istio.yaml)）。

这标志着一个重要的里程碑，因为 Istio 用户现在可以利用一组稳定
Gateway API 功能集来增强生产环境中的流量管理和入口控制。
查看 [Gateway API 任务](/zh/docs/tasks/traffic-management/ingress/gateway-api/)并开始使用。

在此版本中，我们还添加了通过 `targetRef` 字段为 Kubernetes
Gateway API 配置 Istio CRD `AuthorizationPolicy`、`RequestAuthentication`、
`Telemetry` 和 `WasmPlugin` 的支持。

### 重构对 ExternalName 服务的支持 {#revamped-externalname-service-support}

Istio 1.20 引入了针对 `ExternalName` 服务的全新更新，与 Kubernetes 行为更加一致。
本次变更简化了 `ServiceEntry` 定义并增强了 Istio 处理 DNS 条目的能力。
用户现在可以选择新行为，为即将到来的默认切换做好准备。

### 一致的 Envoy 过滤器排序 {#consistent-envoy-filter-ordering}

跨入站、出站和网关代理的 Envoy 过滤器实现了新的一致排序，
无论流量方向或协议如何，都确保过滤器得到统一应用。

### 扩展对网络 WasmPlugin 的支持 {#expanded-support-for-network-wasmplugin}

通过使用新类型 `NETWORK` 对网络 WasmPlugin 进行支持，
Istio 的可扩展性进一步扩大。

### TCP 元数据交换增强 {#tcp-metadata-exchange-enhancements}

Istio 1.20 带来了两项关键更新用于帮助控制 TCP 元数据交换：

- **回退元数据发现**：Istio 现在可以使用备份方法来收集元数据。
  要使用此功能，请在代理中开启 `PEER_METADATA_DISCOVERY`，
  并在控制平面中开启 `PILOT_ENABLE_AMBIENT_CONTROLLERS`。
- **ALPN 令牌控制**：针对控制平面推出一个名为 `PILOT_DISABLE_MX_ALPN` 的新设置。
  这可以让您停止使用服务之间相互通信时正常所需的特定令牌 `istio-peer-exchange`。

### 流量镜像支持多个目标 {#traffic-mirroring-to-multiple-destinations}

Istio 1.20 中的流量镜像现在支持多个目标。
此功能可以将流量的镜像发送到各个端点，从而可以同时观察不同的服务版本或配置。

### 可插入根证书轮换 {#plugged-root-cert-rotation}

通过增加对可插入根证书轮换的支持，Istio 内的安全性得到了提高。

### Sidecar 容器中的 `StartupProbe` {#startupprobe-in-sidecar-containers}

为了缩短 Pod 启动时间，Istio 现在默认在 Sidecar 容器中包含一个 `StartupProbe`。
这种主动措施允许在初始阶段进行主动轮询，而无需在 Pod 的整个生命周期中持续进行，
从而可能将启动时间平均缩短一秒并提高整体资源效率。

### 针对 OpenShift 安装的增强 {#openshift-installation-enhancements}

Istio 在 OpenShift 集群上的安装过程已得到简化，
无需向 Istio 和应用程序授予 `anyuid` SCC 权限。

### `istioctl` 命令的增强 {#enhancements-to-the-istioctl-command}

为 istioctl 命令添加了许多增强功能，包括：

- 如果未将 Pilot 监控端口设置为 `15014`，现在该问题可被自动检测到。
- 添加了 `istioctl dashboard proxy` 命令来显示 Envoy、Ztunnel、Waypoint 等各种代理的管理 UI。

## 升级至 1.20 {#upgrading-to-1.20}

我们期待倾听您关于升级到 Istio 1.20 的体验。
您可以加入 [Discuss Istio](https://discuss.istio.io/) 的会话中提供反馈，
或加入我们的 [Slack 工作空间](https://slack.istio.io/)中的 #release-1.20 频道。

您想直接为 Istio 做贡献吗？
找到并加入我们的某个[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，
帮助我们改进。
