---
title: Istio 1.6 更新说明
description: Istio 1.6 更新说明。
weight: 10
release: 1.6
subtitle: 次要版本
linktitle: 1.6 更新说明
publishdate: 2020-05-21
---

## 流量管理{#traffic-management}

- ***新增*** 添加了
  [`VirtualService` 委托](https://github.com/istio/istio/pull/22118)。
  这将允许在多个可组合的 `VirtualServices` 中指定网格路由配置。
- ***新增*** 添加了新的
  [Workload Entry](/zh/docs/reference/config/networking/workload-entry/) 资源。
  这允许更轻松地配置非 Kubernetes 工作负载以加入网格。
- ***新增*** 添加了网关拓扑配置。
  这解决了根据网关部署拓扑提供正确的
  [X-Forwarded-For 头信息](https://github.com/istio/istio/issues/7679)和
  X-Forwarded-Client-Cert 头信息的问题。
- ***新增*** 添加了对
  [Kubernetes Service API](https://github.com/kubernetes-sigs/service-apis/)
  的实验性支持。
- ***新增*** 添加了支持使用 `appProtocol`
  选择 Kubernetes 1.18
  中引入的[端口协议](/zh/docs/ops/configuration/traffic-management/protocol-selection/)。
- ***变更*** Gateway SDS 变更为默认开启。
  文件挂载网关功能可以继续使用，
  以帮助用户过渡到安全网关 SDS 中。
- ***新增*** 添加了支持从 Secrets、`pathType`
  和 `IngressClass` 中读取证书，这为
  [Kubernetes Ingress](/zh/docs/tasks/traffic-management/ingress/kubernetes-ingress/)
  提供了更好的支持。
- ***新增*** 添加了一个新的 `proxy.istio.io/config`
  注解来覆盖每个 Pod 的代理配置。
- ***移除*** 移除了代理中的大多数配置标志和环境变量。
  这些配置现在可以直接从网格配置中读取。
- ***变更*** 将代理就绪检查端口更改为 15021 端口。
- ***修复*** 修复了在某些情况下会阻止外部 HTTPS/TCP
  流量的 [Bug](https://github.com/istio/istio/issues/16458)。

## 安全{#security}

- ***新增*** 添加了 Istio-agent 的
  [JSON Web Token（JWT）缓存](https://github.com/istio/istio/pull/22789)，
  这将提供更好的 Istio Agent SDS 性能。
- ***修复*** 修复了 Istio Agent
  证书配置[宽限期计算](https://github.com/istio/istio/pull/22617)的问题。
- ***移除*** 移除了 Security API 的 alpha 版。
  在 Istio 1.5 中引入的 Security API beta 版作为
  Istio 1.6 中唯一支持的 Security API 版本。

## 观测{#telemetry}

- ***新增*** 添加了对[请求分类](/zh/docs/tasks/observability/metrics/classify-metrics/)过滤器的实验性支持。
  这使 Operator 能够根据请求信息配置用于观测的新属性。
  此功能的一个主要用例是通过 API 方法标记流量。
- ***新增*** 添加了一个实验性的
  [Mesh-wide 链路追踪配置 API](/zh/docs/tasks/observability/distributed-tracing/mesh-and-proxy-config/)。
  此 API 提供对链路追踪采样率、
  URL 标签的[最大标签长度](https://github.com/istio/istio/issues/14563)和[自定义标签提取](https://github.com/istio/istio/issues/13018)，
  用于网格内的所有链路追踪的支持。
- ***新增*** 添加了标准 Prometheus 对代理和控制平面工作负载的注释，
  从而改善了 Prometheus 集成体验。
  这解决了需要专门配置来发现和使用 Istio 指标的需要。
  [Prometheus 操作指南](/zh/docs/ops/integrations/prometheus#option-2-metrics-merging/)中提供了更多详细信息。
- ***新增*** 添加了网格 Operator
  能够根据可用请求和响应属性集的表达式添加并删除
  Istio 指标中使用的标签。这改进了 Istio
  对[自定义 v2 版指标生成](/zh/docs/tasks/observability/metrics/customize-metrics/)的支持。
- ***更新*** 更新了默认遥测 v2 版配置以避免使用 Host
  头在网关处提取目标服务名称的问题。
  这可以防止由于不受信任的 Host 头而导致的未绑定基数，
  并且意味着对于产生在网关处命中 `blackhole` 和 `passthrough`
  的请求时，目标服务标签将被省略。
- ***新增*** 添加了自动将 Grafana 仪表盘发布到
  `grafana.com` 作为 Istio 发布过程中一部分的功能。
  请参阅 [Istio 组织页面](https://grafana.com/orgs/istio)了解更多信息。
- ***更新*** 更新了 Grafana 仪表盘以适应新的 Istiod 部署模型。

## 安装{#installation}

- ***新增*** 添加了对 Istio 金丝雀升级的支持。
  有关详细信息，请参阅[升级指南](/zh/docs/setup/upgrade/)。
- ***移除*** 移除了旧版 Helm Chart。
  如需从旧版本进行迁移，请参阅[升级指南](/zh/docs/setup/upgrade/)。
- ***新增*** 添加了用户可以为 istiod 添加自定义主机名的功能。
- ***变更*** 已将网关就绪检查端口从 15020 更改为 15021。
  如果您从 Kubernetes 网络负载均衡器检查 Istio
  `ingressgateway` 的运行状况，则需要更新该端口。
- ***新增*** 添加了将安装状态保存在集群内 `CustomResource` 中的功能。
- ***变更*** 修改 Istio 安装过程将不再管理所安装命名空间，
  从而提供更大的灵活性。
- ***移除*** 移除了单独的 Citadel、Sidecar Injector 和 Galley 部署。
  这些在 1.5 版中已默认被禁用，并且所有功能都已移至 Istiod。
- ***移除*** 移除了例如 Service 等遗留的 `istio-pilot` 配置。
- ***移除*** 从默认的 `ingressgateway` 中删除了 15029-15032 端口。
  建议改为通过 [host routing](/zh/docs/tasks/observability/gateways/)
  暴露观测插件的方式进行设置。
- ***移除*** 从安装中删除了内置 Istio 配置，
  包括 Gateway、`VirtualServices` 和 mTLS 设置。
- ***新增*** 添加了一个名为 `preview` 的新配置文件，
  允许用户尝试新的实验性功能，包括支持 WASM 的观测功能 v2 版。
- ***新增*** 添加了 `istioctl install` 命令作为
  `istioctl manifest apply` 的替代。
- ***新增*** 添加了 istiod-remote 图表，
  以允许用户使用[中央 Istiod 管理远程数据平面](https://github.com/istio/istio/wiki/Central-Istiod-manages-remote-data-plane)进行实验的能力。

## istioctl{#istioctl}

- ***新增*** 为 istioctl 命令添加了更好的显示特性。
- ***新增*** 添加了支持使用 --set 标志路径时的键值列表选择的功能。
- ***新增*** 添加了支持在使用 Kubernetes
  覆盖修补机制时删除和设置非标量值的功能。

## 文档变更{#documentation-changes}

- ***新增***  新增及改进了 Istio 文档。
  有关详细信息，请参阅[网站内容更改](/zh/docs/releases/log/)。
