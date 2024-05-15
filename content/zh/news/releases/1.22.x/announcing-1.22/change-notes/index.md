---
title: Istio 1.22.0 更新说明
linktitle: 1.22.0
subtitle: 次要版本
description: Istio 1.22.0 更新说明。
publishdate: 2024-05-13
release: 1.22.0
weight: 10
aliases:
    - /zh/news/announcing-1.22.0
---

## 弃用通知 {#deprecation-notices}

以下通知说明了根据 [Istio 的弃用政策](/zh/docs/releases/feature-stages/#feature-phase-definitions)将在未来某个版本中移除的功能。
请考虑升级您的环境以移除弃用的功能。

- **弃用** 弃用了 `values.istio_cni`，转而使用 `values.pilot.cni`。
  ([Issue #49290](https://github.com/istio/istio/issues/49290))

## 流量治理 {#traffic-management}

- **改进** 改进了如果指定 `targetPort` 后具有 `resolution: NONE` 的 `ServiceEntry`。
  这在进行 TLS 发起时特别有用，允许设置 `port:80, targetPort: 443`。
  如果不需要，请设置 `--compatibilityVersion=1.21` 以恢复到旧行为或删除 `targetPort` 规范。

- **改进** 改进了尽可能利用更少的资源生成 XDS，有时会完全忽略响应。
  如果需要，可以通过 `PILOT_PARTIAL_FULL_PUSHES=false` 环境变量禁用此功能。
  ([Issue #37989](https://github.com/istio/istio/issues/37989)),([Issue #37974](https://github.com/istio/istio/issues/37974))

- **新增** 添加了支持完全跳过 CNI 的初始安装。

- **新增** 向 istiod 添加了一个节点污点控制器，一旦 Istio CNI Pod 在该节点上准备就绪，
  它就会从节点中删除 `cni.istio.io/not-ready` 污点。
  ([Issue #48818](https://github.com/istio/istio/issues/48818)),([Issue #48286](https://github.com/istio/istio/issues/48286))

- **新增** 通过 Pilot 调试 API `/debug/config_distribution`，将端点确认生成添加到可用的代理分发报告中。
  ([Issue #48985](https://github.com/istio/istio/issues/48985))

- **新增** 添加了对服务配置 waypoint 代理的支持。

- **新增** 添加了使用 `istio.io/use-waypoint` 注解增加到 Pod、服务、命名空间和其他类似类型的功能，
  以 `[<namespace name>/]<waypoint name>` 的形式指定 waypoint。
  这取代了对 waypoint 的旧要求，即其范围仅限于整个命名空间或单个服务帐户。
  选择退出 waypoint 也可以使用 `#none` 值来完成，以允许命名空间范围的 waypoint，
  其中特定的 Pod 或服务不受 waypoint 的保护，从而允许 waypoint 规范和使用具有更大的灵活性。
  ([Issue #49436](https://github.com/istio/istio/issues/49436))

- **新增** 添加了对 waypoint 代理中 `istio.io/waypoint-for` 注解的支持。
  ([Issue #49851](https://github.com/istio/istio/issues/49851))

- **新增** 添加了一项检查，以防止当用户在其 AuthorizationPolicy
  中将网关指定为 `targetRef` 时创建 ztunnel 配置。
  ([Issue #50110](https://github.com/istio/istio/issues/50110))

- **新增** 添加了 `networking.istio.io/address-type` 注释以允许 `istio` GatewayClass 的 Gateway 使用 `ClusterIP` 作为状态地址。

- **新增** 添加了使用指向任意 GatewayClass 的 Gateway 的 `istio.io/use-waypoint` 注解工作负载或服务的能力。
  这些更改允许将标准 Istio 网关配置为 waypoint。为此，必须将其配置为启用重定向的 `ClusterIP` Service。
  这通俗地称为“网关三明治”，其中 ztunnel 层处理 mTLS。
  ([Issue #48362](https://github.com/istio/istio/issues/48362))

- **新增** 添加了通过使用 `istio.io/dataplane-mode=ambient` 标记各个 Pod 将其注册到 Ambient 中的功能。
  ([Issue #50355](https://github.com/istio/istio/issues/50355))

- **新增** 添加了允许 Pod 通过使用 `istio.io/dataplane-mode=none` 标签选择退出 Ambient 重定向。
  ([Issue #50736](https://github.com/istio/istio/issues/50736))

- **移除** 移除了使用 `ambient.istio.io/redirection=disabled` 注解选择退出
  Ambient 重定向的功能，因为这是为 CNI 保留的状态注解。
  ([Issue #50736](https://github.com/istio/istio/issues/50736))

- **新增** 添加了 istiod `PILOT_GATEWAY_API_DEFAULT_GATEWAYCLASS_NAME` 的环境变量，
  允许覆盖默认 `GatewayClass` Gateway API 资源的名称。默认值为 `istio`。

- **新增** 添加了 istiod `PILOT_GATEWAY_API_CONTROLLER_NAME` 的环境变量，
  允许覆盖 `GatewayClass` 资源中 `spec.controllerName` 字段中公开的 Istio Gateway API 控制器的名称。
  默认值为 `istio.io/gateway-controller`。

- **新增** 添加对使用代理协议进行出站流量的支持。通过在 `DestinationRule.trafficPolicy`
  中指定 `proxyProtocol`，Sidecar 将向上游服务发送 PROXY 协议标头。HBONE 代理目前不支持此功能。

- **新增** 添加了验证检查以拒绝具有重复子集名称的 `DestinationRules`。

- **新增** 在控制器接受 GatewayClass 之前，在 Gateway API 的 Class 状态上添加了 `supportedFeatures` 字段。
  ([Issue #2162](https://github.com/kubernetes-sigs/gateway-api/issues/2162))

- **新增** 在 `SidecarScope` 构建期间合并服务时添加了检查服务的
  `Resolution`、`LabelSelector`、`ServiceRegistry` 和命名空间的能力。

- **启用** 默认情况下启用了 [Delta xDS](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol#incremental-xds)。
  有关详细信息，请参阅升级说明。
  ([Issue #47949](https://github.com/istio/istio/issues/47949))

- **修复** 修复了一个 Kubernetes 网关无法与命名空间范围的 waypoint 代理正常协作的问题。

- **修复** 修复了 Delta ADS 客户端收到包含 `RemoveResources` 响应的问题。

- **修复** 修复了使用 `withoutHeaders` 在 `VirtualService` 中配置路由匹配规则时的问题。
  如果请求头中不存在 `withoutHeaders` 中指定的字段，Istio 无法匹配该请求。
  ([Issue #49537](https://github.com/istio/istio/issues/49537))

- **修复** 修复了当 Envoy 过滤器位于根命名空间和代理命名空间时，其优先级被忽略的问题。
  ([Issue #49555](https://github.com/istio/istio/issues/49555))

- **修复** 修复了 `--log_as_json` 选项不适用于 `istio-init` 容器的问题。
  ([Issue #44352](https://github.com/istio/istio/issues/44352))

- **修复** 修复了添加或删除重复主机时大量虚拟 IP 被重新洗牌的问题。
  ([Issue #49965](https://github.com/istio/istio/issues/49965))

- **修复** 修复了网关状态地址从集群外部接收服务 VIP 的问题。

- **修复** 将 `use-waypoint` 注解修改为标签，以保持一致性。
  ([Issue #50572](https://github.com/istio/istio/issues/50572))

- **修复** 修复了使用域名地址构建 EDS 类型的集群端点的问题。
  ([Issue #50688](https://github.com/istio/istio/issues/50688))

- **修复** 修复了当 `InboundTrafficPolicy` 被设置为“localhost”时注入模板被错误评估的错误。
  ([Issue #50700](https://github.com/istio/istio/issues/50700))

- **修复** 修复了向 waypoint HBONE 端点添加服务器端 `keeplive` 的问题。
  ([Issue #50737](https://github.com/istio/istio/issues/50737))

- **修复** 修复了 `HTTPMatchRequest` 中的空前缀匹配不会被验证 Webhook 拒绝的问题。
  ([Issue #48534](https://github.com/istio/istio/issues/48534))

- **修复** 修复了 Istio 1.20 中的行为更改，该更改导致 `ServiceEntries` 与相同主机名和端口名称的合并产生意外结果。
  ([Issue #50478](https://github.com/istio/istio/issues/50478))

- **修复** 修复了当 Sidecar 资源配置了具有 Kubernetes 服务的不同端口的多个出口侦听器时，
  Sidecar 资源无法正确合并端口的错误。这导致仅使用第一个端口创建一个集群，而第二个端口被忽略。

- **修复** 修复了导致路由被其他虚拟服务覆盖的问题。

- **移除** 从 `istio-cni` 节点代理 Chart 中移除了 `values.cni.privileged` 标志，以支持特定于功能的权限。
  ([Issue #49004](https://github.com/istio/istio/issues/49004))

- **移除** 移除了 `PILOT_ENABLE_HEADLESS_SERVICE_POD_LISTENERS` 功能标志。

- **移除** 移除了 `PILOT_ENABLE_INBOUND_PASSTHROUGH` 设置，该设置在过去 8 个版本中默认启用。
  现在可以使用新的[入站流量策略模式](https://github.com/istio/api/blob/9911a0a6990a18a45ed1b00559156dcc7e836e52/mesh/v1alpha1/config.proto#L203)配置此功能。

## 安全性 {#security}

- **更新** 将功能标志 `ENABLE_AUTO_ENHANCED_RESOURCE_SCOPING` 的默认值更新为 `true`。

- **新增** 添加了对 `AuthorizationPolicy` 中路径模板的支持。
  请参阅 Envoy URI 模板[文档](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/path/match/uri_template/v3/uri_template_match.proto)。
  ([Issue #16585](https://github.com/istio/istio/issues/16585))

- **新增** 添加了支持在解析 `jwksUri` 时自定义连接超时设置。
  ([Issue #47328](https://github.com/istio/istio/issues/47328))

- **新增** 添加了 Istio CA 支持通过模拟远程集群的身份来处理 CSR 的节点授权。
  这可以帮助 Istio CA 在外部控制平面场景中对远程集群中的 ztunnel 进行身份验证。
    ([Issue #47489](https://github.com/istio/istio/issues/47489))

- **新增** 添加了 `METRICS_LOCALHOST_ACCESS_ONLY` 环境变量，用于从 Pod 外部禁用指标端点，
  以仅允许本地主机访问。用户可以在 `istioctl` 安装期间使用命令参数
  `--set values.pilot.env.METRICS_LOCALHOST_ACCESS_ONLY=true`（对于控制平面）和
  `--set meshConfig.defaultConfig.proxyMetadata.METRICS_LOCALHOST_ACCESS_ONLY=true`（对于代理）进行设置。

- **新增** 添加了 Certificate Revocation List（证书吊销列表，CRL）支持对等证书验证，
  该支持基于 Sidecar 目标规则中的 `ClientTLSSettings` 和对于 Gateway 网关中 `ServerTLSSettings` 中指定的文件路径。

- **修复** 修复了 JWT 令牌中受众声明的列表匹配。
  ([Issue #49913](https://github.com/istio/istio/issues/49913))

- **移除** 移除了 `values.global.jwtPolicy` 的 `first-party-jwt` 旧选项。
  对更安全的 `third-party-jwt` 的支持多年来一直是默认设置，并且所有 Kubernetes 平台都支持。

## 遥测 {#telemetry}

- **改进** 改进了 JSON 访问日志以一致的顺序发出 Key。

- **新增** 添加了选项以通过 HTTP 导出 OpenTelemetry 链路。
  ([参考](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider)) ([Issue #47835](https://github.com/istio/istio/issues/47835))

- **启用** 在 `MeshConfig` 中将 Dynatrace Sampler 配置为 `OpenTelemetryTracingProvider`。
  ([Issue #50001](https://github.com/istio/istio/issues/50001))

- **启用** 在 `MeshConfig` 中将资源检测器配置为 `OpenTelemetryTracingProvider`。
  ([Issue #48885](https://github.com/istio/istio/issues/48885))

- **修复** 修复了使用 OpenTelemetry 访问记录器时未传播 `TraceId` 的问题。
  ([Issue #49911](https://github.com/istio/istio/issues/49911))

- **移除** 移除了默认启用链路追踪 `zipkin.istio-system.svc` 的配置。有关详细信息，请参阅升级说明。

## 可扩展性 {#extensibility}

- **改进** 使用标记剥离的 URL 和 Checksum 作为 Wasm 模块缓存键，其中标记的 URL 单独缓存。
  这可能会增加缓存命中的机会（例如，尝试使用标记 URL 和摘要 URL 查找相同的图像。）此外，
  这将是实现 `ImagePullPolicy` 的基础。

## 安装 {#installation}

- **改进** 改进了 Helm Value 字段名称，用于配置是否使用现已安装的 CNI。
  支持字段将位于 `values.pilot.cni` 中，替代了 `values.istio_cni`，
  因此 istiod 组件会被影响。新设置比使用 `values.cni` 用于安装配置和
  `values.istio_cni` 用于 istiod 中更清晰。至少在两个版本中仍支持旧的 `values.istio_cni` 字段。
  ([Issue #49290](https://github.com/istio/istio/issues/49290))

- **改进** 改进了 `meshConfig.defaultConfig.proxyMetadata` 字段在被覆盖时进行深度合并，而不是替换所有值。

- **新增** 添加了通过 Helm Chart 向 Istio 服务帐户资源添加自定义注解的功能。

- **新增** 添加了 `openshift-ambient` 配置文件。
  ([Issue #42341](https://github.com/istio/istio/issues/42341))

- **新增** 添加了一个新的、可选的实验性准入政策，仅允许在 Istio API 中使用稳定的功能/字段。
  ([Issue #173](https://github.com/istio/enhancements/issues/173))

- **新增** 添加了对配置 CA 捆绑包以进行验证和注入 Webhooks 的支持。

- **修复** 修复了从本地 ztunnel 管理端点收集 `pprof` 数据，由于缺少可写的容器内 `/tmp`，该数据将失败。
  ([Issue #50060](https://github.com/istio/istio/issues/50060))

- **移除** 移除了已弃用的 `external` 配置文件。请使用 `remote` 配置文件进行安装。
  ([Issue #48634](https://github.com/istio/istio/issues/48634))

## istioctl

- **新增** 添加了 `istioctl proxy-status` 命令，这是升级后的 `istioctl experimental proxy-status` 命令。
  旧的 `istioctl proxy-status` 命令已被删除。此推动不应导致任何功能损失。
  但是，现在请求是基于 xDS 而不是 HTTP 发送的，并且我们引入了一组新的基于 xDS 的标志来针对控制平面。

- **新增** 当通过[安装多集群](/zh/docs/setup/install/multicluster/)设置远程集群 Secret 时，
  在 `istioctl analyze` 命令中添加了对多集群分析的支持。

- **新增** 添加了一个新的 `istioctl dashboard proxy` 命令，
  可用于显示不同代理 Pod 的管理 UI，例如：Envoy、ztunnel 和 waypoint。

- **新增** 为 `istioctl experimental wait` 命令添加了 `--proxy` 选项。
  ([Issue #48696](https://github.com/istio/istio/issues/48696))

- **新增** 为 `istioctl proxy-config workload` 命令添加了命名空间过滤，
  使用 `--workloads-namespace` 标志来显示指定命名空间中的工作负载。

- **新增** 添加了 `istioctl dashboard istio-debug` 命令来显示 Istio 调试端点仪表板。

- **新增** 添加了 `istioctl experimental describe` 命令以支持显示 `PortLevelSettings` 策略的详细信息。
  ([Issue #49802](https://github.com/istio/istio/issues/49802))

- **新增** 添加了在使用 `istioctl experimental waypoint apply` 命令时通过
  `--for` 标志定义 waypoint 的流量地址类型（服务、工作负载、全部或无）的能力。
  ([Issue #49896](https://github.com/istio/istio/issues/49896))

- **新增** 添加了通过 waypoint 命令上的 `--name` 标志使用 `istioctl` 命名 waypoint 的功能。
  ([Issue #49915](https://github.com/istio/istio/issues/49915)), ([Issue #50173](https://github.com/istio/istio/issues/50173))

- **移除** 移除了通过删除 waypoint 命令上的 `--service-account` 标志来指定 waypoint 的服务帐户的能力。
  ([Issue #49915](https://github.com/istio/istio/issues/49915)), ([Issue #50173](https://github.com/istio/istio/issues/50173))

- **新增** 添加了通过 waypoint 命令上的 `--enroll-namespace`
  标志使用 `istioctl` 在 waypoint 的命名空间中注册 waypoint 代理的功能。
  ([Issue #50248](https://github.com/istio/istio/issues/50248))

- **新增** 添加了 `istioctl ztunnel-config` 命令。
  这允许用户通过 `istioctl ztunnel-config workload` 命令查看 ztunnel 配置信息。
  ([Issue #49841](https://github.com/istio/istio/issues/49841))

- **移除** 从 proxy-config 命令中删除了工作负载标志。
  使用 `istioctl ztunnel-config workload` 命令来查看 ztunnel 配置信息。
  ([Issue #49841](https://github.com/istio/istio/issues/49841))

- **新增** 添加了使用 `istioctl experimental waypoint apply --enroll-namespace` 时的警告，
  并且命名空间未被标记为 Ambient 重定向。
  ([Issue #50396](https://github.com/istio/istio/issues/50396))

- **新增** 在 `istioctl experimental waypoint generate` 命令中添加了 `--for` 标志，
  以便用户可以在应用 YAML 之前预览它。
  ([Issue #50790](https://github.com/istio/istio/issues/50790))

- **新增** 向 `istioctl` 添加了实验性 OpenShift Kubernetes 平台配置文件。
  要使用 OpenShift 配置文件进行安装，请使用 `istioctl install --set profile=openshift`。
  请参阅 [OpenShift 平台设置](/zh/docs/setup/platform-setup/openshift/)和[使用 `istioctl` 安装 OpenShift](/zh/docs/setup/install/istioctl/#install-a-different-profile) 文档以获取更多信息。

- **新增** 为 `istioctl experimental envoy-stats` 命令添加了 `--proxy-admin-port` 标志，
  以设置自定义代理管理端口。

- **修复** 修复了由于配置未知，`istioctl experimental proxy-status <pod>` 比较命令无法正常工作的问题。

- **修复** 修复了 `istioctl describe` 命令不显示非 `istio-system` 命名空间下的 Ingress 信息。
  ([Issue #50074](https://github.com/istio/istio/issues/50074))
