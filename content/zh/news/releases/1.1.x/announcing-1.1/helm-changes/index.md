---
title: Helm 安装参数变动表
description: 本文详细介绍了 Istio 1.0 系列到 Istio 1.1 系列之间的安装参数变化详情。
weight: 30
keywords: [kubernetes, helm, install, options]
---

下表显示了在 Istio 1.0 版本到 Istio 1.1 版本之间使用 Helm 自定义安装 Istio 时参数变更，主要包含了三种类型的变更：

- 安装参数在 1.0 版本之前已经存在，但是值在新发布的 1.1 版本中进行了修改。
- 1.1 版本新加的参数。
- 1.1 版本删除的参数。

<!-- 下表是运行 python 脚本 scripts/tablegen.py 自动生成 -->

<!-- 自动生成开始 -->

## 修改配置选项{#modified-configuration-options}

### 修改 `servicegraph` 键值对{#modified-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `servicegraph.ingress.hosts` | `servicegraph.local` | `servicegraph.local` |  | `用来创建一个 Ingress record。` |

### 修改 `tracing` 键值对{#modified-tracing-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `tracing.jaeger.tag` | `1.5` | `1.9` |  |  |

### 修改 `global` 键值对{#modified-global-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `global.hub` | `gcr.io/istio-release` | `gcr.io/istio-release` |  | `Istio 镜像的默认仓库。已发布版本的 Istio 镜像已经推送到了 docker hub 中的 istio 项目下，白天会从 gcr.io 进行构建，夜晚会从 docker.io/istionightly 上进行构建。` |
| `global.tag` | `release-1.0-latest-daily` | `release-1.1-latest-daily` |  | `Istio 镜像的默认标签。` |
| `global.proxy.resources.requests.cpu` | `10m` | `100m` |  |  |
| `global.proxy.accessLogFile` | `"/dev/stdout"` | `""` |  |  |
| `global.proxy.enableCoreDump` | `false` | `false` |  | `如果设置，新注入的 sidecars 将启用 core dumps。` |
| `global.proxy.autoInject` | `enabled` | `enabled` |  | `可以控制 sidecar 的注入策略。` |
| `global.proxy.envoyStatsd.enabled` | `true` | `false` |  | `如果设置为 true，则还须提供主机地址和端口。Istio不再提供 statsd 收集器。` |
| `global.proxy.envoyStatsd.host` | `istio-statsd-prom-bridge` | `` |  | `例如: statsd-svc.istio-system` |
| `global.proxy.envoyStatsd.port` | `9125` | `` |  | `例如: 9125` |
| `global.proxy_init.image` | `proxy_init` | `proxy_init` |  | `proxy_init 容器的基本名称，用于配置 iptables。` |
| `global.controlPlaneSecurityEnabled` | `false` | `false` |  | `启用 controlPlaneMtls。在传播 secret 时，将导致 Pod 的延迟启动，不建议用于测试。` |
| `global.disablePolicyChecks` | `false` | `true` |  | `disablePolicyChecks 禁用 mixer 策略检查。如果 mixer.policy.enabled==true 则 disablePolicyChecks 已生效。将在 istio ConfigMap 设置相同名称的值 - pilot 需要重新启动才能生效。` |
| `global.enableTracing` | `true` | `true` |  | `EnableTracing 在 istio ConfigMap 中具有相同名称的值，需要重新启动 pilot 才能生效。` |
| `global.mtls.enabled` | `false` | `false` |  | `服务到服务间的 mtls 的默认设置。可以使用目标规则或服务注释来显式设置。` |
| `global.oneNamespace` | `false` | `false` |  | `是否限制控制器管理的应用程序的名称空间；如果未设置，则控制器将监控所有名称空间。` |
| `global.configValidation` | `true` | `true` |  | `是否执行服务器端配置验证。` |

### 修改 `gateways` 键值对{#modified-gateways-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `gateways.istio-ingressgateway.type` | `LoadBalancer #change to NodePort, ClusterIP or LoadBalancer if need be` | `LoadBalancer` |  | `如果需要，请更改为节点端口，集群 IP，或者负载地址。` |
| `gateways.istio-egressgateway.enabled` | `true` | `false` |  |  |
| `gateways.istio-egressgateway.type` | `ClusterIP #change to NodePort or LoadBalancer if need be` | `ClusterIP` |  | `如果需要，请更改为节点端口或者负载地址。` |

### 修改 `certmanager` 键值对{#modified--key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `certmanager.tag` | `v0.3.1` | `v0.6.2` |  |  |

### 修改 `kiali` 键值对{#modified-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `kiali.tag` | `istio-release-1.0` | `v0.14` |  |  |

### 修改 `security` 键值对{#modified-security-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `security.selfSigned` | `true # indicate if self-signed CA is used.` | `true` |  | `是否使用自签名 CA 证书。` |

### 修改 `pilot` 键值对{#modified-pilot-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `pilot.autoscaleMax` | `1` | `5` |  |  |
| `pilot.traceSampling` | `100.0` | `1.0` |  |  |

## 新的配置选项{#new-configuration-options}

### 新增 `istio_cni` 键/值对{#new-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `istio_cni.enabled` | `false` |  |

### 新增 `servicegraph` 键/值对{#new-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `servicegraph.nodeSelector` | `{}` |  |

### 新增 `tracing` 键/值对{#new-tracing-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `tracing.nodeSelector` | `{}` |  |
| `tracing.zipkin.hub` | `docker.io/openzipkin` |  |
| `tracing.zipkin.tag` | `2` |  |
| `tracing.zipkin.probeStartupDelay` | `200` |  |
| `tracing.zipkin.queryPort` | `9411` |  |
| `tracing.zipkin.resources.limits.cpu` | `300m` |  |
| `tracing.zipkin.resources.limits.memory` | `900Mi` |  |
| `tracing.zipkin.resources.requests.cpu` | `150m` |  |
| `tracing.zipkin.resources.requests.memory` | `900Mi` |  |
| `tracing.zipkin.javaOptsHeap` | `700` |  |
| `tracing.zipkin.maxSpans` | `500000` |  |
| `tracing.zipkin.node.cpus` | `2` |  |

### 新增 `sidecarInjectorWebhook` 键/值对{#new-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `sidecarInjectorWebhook.nodeSelector` | `{}` |  |
| `sidecarInjectorWebhook.rewriteAppHTTPProbe` | `false` | `如果设置为 true，则 webhook 或 istioctl injector 将重写 PodSpec 进行 livenesshealth 检查，以将请求重定向到 Sidecar，即使启用了 mTLS，也可以进行活动检查。` |

### 新增 `global` 键/值对{#new-global-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `global.monitoringPort` | `15014` | `监控被 mixer、 pilot 和 galley 所使用的端口。` |
| `global.k8sIngress.enabled` | `false` |  |
| `global.k8sIngress.gatewayName` | `ingressgateway` | `用于 k8s 入口资源的网关，默认情况下，它使用的是 istio：ingressgateway，将 gateways.enabled 和 gateways.istio-ingressgateway.enabled 标志设置为 true 即可安装。` |
| `global.k8sIngress.enableHttps` | `false` | `enableHttps 将在入口处添加 443 端口，它要求将证书安装在预期的 secret 中，启用不带证书的此选项将导致 LDS 拒绝，并且入口将不起作用。` |
| `global.proxy.clusterDomain` | `"cluster.local"` | `集群域，默认值为 cluster.local。` |
| `global.proxy.resources.requests.memory` | `128Mi` |  |
| `global.proxy.resources.limits.cpu` | `2000m` |  |
| `global.proxy.resources.limits.memory` | `128Mi` |  |
| `global.proxy.concurrency` | `2` | `控制代理工作线程的数量，如果设置为 0（默认值），则为每个 CPU 线程/核心。` |
| `global.proxy.accessLogFormat` | `""` | `配置 sidecar 访问日志中显示方式和字段的显示方式，设置空字符串将导致成为默认的日志格式。` |
| `global.proxy.accessLogEncoding` | `TEXT` | `将 Sidecar 的访问日志配置为 JSON 或 TEXT 格式。` |
| `global.proxy.dnsRefreshRate` | `5s` | `为类型为 STRICT_DNS 的 Envoy 集群配置 DNS 的刷新频率为 5s，是 Envoy 使用的默认刷新频率。` |
| `global.proxy.privileged` | `false` | `如果设置为 true，则 istio-proxy 容器将具有特权 securityContext。` |
| `global.proxy.statusPort` | `15020` | `Pilot 代理运行状况检查的默认端口，设置为 0 将禁用运行状况检查。` |
| `global.proxy.readinessInitialDelaySeconds` | `1` | `准备就绪探测的初始延迟（以秒为单位）。` |
| `global.proxy.readinessPeriodSeconds` | `2` | `准备就绪探测之间的时间间隔。` |
| `global.proxy.readinessFailureThreshold` | `30` | `指示准备就绪失败之前，连续失败的探测数。` |
| `global.proxy.kubevirtInterfaces` | `""` | `pod 的内部接口。` |
| `global.proxy.envoyMetricsService.enabled` | `false` |  |
| `global.proxy.envoyMetricsService.host` | `` | `例如：metrics-service.istio-system` |
| `global.proxy.envoyMetricsService.port` | `` | `例如：15000` |
| `global.proxy.tracer` | `"zipkin"` | `指定要使用的跟踪器，lightstep 和 zipkin 其中之一。` |
| `global.policyCheckFailOpen` | `false` | `policyCheckFailOpen 允许在无法访问 mixer 策略的情况下进行通信，默认值为 false，这意味着在客户端无法连接到 Mixer 时拒绝通信。` |
| `global.tracer.lightstep.address` | `""` | `例如：lightstep-satellite:443` |
| `global.tracer.lightstep.accessToken` | `""` | `例如：abcdefg1234567` |
| `global.tracer.lightstep.secure` | `true` | `例如：true\|false` |
| `global.tracer.lightstep.cacertPath` | `""` | `例如：/etc/lightstep/cacert.pem` |
| `global.tracer.zipkin.address` | `""` |  |
| `global.defaultNodeSelector` | `{}` | `默认 node selector 将应用于所有部署，以便可以限制所有特定的 Pod 节点，每个组件都可以通过在下面的相关部分中添加 node selector block 并设置所需的值来覆盖这些默认值。` |
| `global.meshExpansion.enabled` | `false` |  |
| `global.meshExpansion.useILB` | `false` | `如果设置为 true，则将在内部网关上暴露 pilot 和 citadel mtls 以及 plain text pilot portswill。` |
| `global.multiCluster.enabled` | `false` | `当每个集群中的 Pod 无法直接相互通信时，设置为 true 可通过它们各自的 ingress gateway 服务连接两个 kubernetes 集群，所有群集都应使用 Istio mTLS，并且必须具有共享的根证书才能使该模型正常工作。` |
| `global.defaultPodDisruptionBudget.enabled` | `true` |  |
| `global.useMCP` | `true` | `使用网格控制协议（MCP）来配置 Mixer 和 Pilot。需要 galley (--设置 galley.enabled=true)。` |
| `global.trustDomain` | `""` |  |
| `global.outboundTrafficPolicy.mode` | `ALLOW_ANY` |  |
| `global.sds.enabled` | `false` | `是否启用 SDS。如果设置为 true，则将通过 SecretDiscoveryService 分发用于 sidecars 的 mTLS 证书，而不是使用 K8S secret 来挂载证书。` |
| `global.sds.udsPath` | `""` |  |
| `global.sds.useTrustworthyJwt` | `false` |  |
| `global.sds.useNormalJwt` | `false` |  |
| `global.meshNetworks` | `{}` |  |
| `global.enableHelmTest` | `false` | `指定是否启 helm 测试，默认情况下，此字段默认设置为 false，因此 'helm template ...' 将在生成模板时忽略 helm 测试的 yaml 文件。` |

### 新增 `mixer` 键/值对{#new-mixer-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `mixer.env.GODEBUG` | `gctrace=1` |  |
| `mixer.env.GOMAXPROCS` | `"6"` | `max procs should be ceil(cpu limit + 1)` |
| `mixer.policy.enabled` | `false` | `如果启用了策略，则 global.disablePolicyChecks 将生效。` |
| `mixer.policy.replicaCount` | `1` |  |
| `mixer.policy.autoscaleEnabled` | `true` |  |
| `mixer.policy.autoscaleMin` | `1` |  |
| `mixer.policy.autoscaleMax` | `5` |  |
| `mixer.policy.cpu.targetAverageUtilization` | `80` |  |
| `mixer.telemetry.enabled` | `true` |  |
| `mixer.telemetry.replicaCount` | `1` |  |
| `mixer.telemetry.autoscaleEnabled` | `true` |  |
| `mixer.telemetry.autoscaleMin` | `1` |  |
| `mixer.telemetry.autoscaleMax` | `5` |  |
| `mixer.telemetry.cpu.targetAverageUtilization` | `80` |  |
| `mixer.telemetry.sessionAffinityEnabled` | `false` |  |
| `mixer.telemetry.loadshedding.mode` | `enforce` | `禁用，仅用于登录或强制执行。` |
| `mixer.telemetry.loadshedding.latencyThreshold` | `100ms` | `基于 100ms 的测量，p50 转换为 p99 不到 1s，对于本质上是异步的遥测来说是没问题的。` |
| `mixer.telemetry.resources.requests.cpu` | `1000m` |  |
| `mixer.telemetry.resources.requests.memory` | `1G` |  |
| `mixer.telemetry.resources.limits.cpu` | `4800m` | `最好使用适度的 cpu 进行分配使 mixer 水平缩放。我们通过实验发现这些值效果很好。` |
| `mixer.telemetry.resources.limits.memory` | `4G` |  |
| `mixer.podAnnotations` | `{}` |  |
| `mixer.nodeSelector` | `{}` |  |
| `mixer.adapters.kubernetesenv.enabled` | `true` |  |
| `mixer.adapters.stdio.enabled` | `false` |  |
| `mixer.adapters.stdio.outputAsJson` | `true` |  |
| `mixer.adapters.prometheus.enabled` | `true` |  |
| `mixer.adapters.prometheus.metricsExpiryDuration` | `10m` |  |
| `mixer.adapters.useAdapterCRDs` | `true` | `如果设置为 false， 会将 useAdapterCRDs mixer 的启动参数设置为 false。` |

### 新增 `grafana` 键/值对{#new-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `grafana.image.repository` | `grafana/grafana` |  |
| `grafana.image.tag` | `5.4.0` |  |
| `grafana.ingress.enabled` | `false` |  |
| `grafana.ingress.hosts` | `grafana.local` | `用来创建一个 Ingress record。` |
| `grafana.persist` | `false` |  |
| `grafana.storageClassName` | `""` |  |
| `grafana.accessMode` | `ReadWriteMany` |  |
| `grafana.security.secretName` | `grafana` |  |
| `grafana.security.usernameKey` | `username` |  |
| `grafana.security.passphraseKey` | `passphrase` |  |
| `grafana.nodeSelector` | `{}` |  |
| `grafana.contextPath` | `/grafana` |  |
| `grafana.datasources.datasources.apiVersion` | `1` |  |
| `grafana.datasources.datasources.datasources.type` | `prometheus` |  |
| `grafana.datasources.datasources.datasources.orgId` | `1` |  |
| `grafana.datasources.datasources.datasources.url` | `http://prometheus:9090` |  |
| `grafana.datasources.datasources.datasources.access` | `proxy` |  |
| `grafana.datasources.datasources.datasources.isDefault` | `true` |  |
| `grafana.datasources.datasources.datasources.jsonData.timeInterval` | `5s` |  |
| `grafana.datasources.datasources.datasources.editable` | `true` |  |
| `grafana.dashboardProviders.dashboardproviders.apiVersion` | `1` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.orgId` | `1` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.folder` | `'istio'` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.type` | `file` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.disableDeletion` | `false` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.options.path` | `/var/lib/grafana/dashboards/istio` |  |

### 新增 `prometheus` 键/值对{#new-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `prometheus.retention` | `6h` |  |
| `prometheus.nodeSelector` | `{}` |  |
| `prometheus.scrapeInterval` | `15s` | `控制 prometheus 在 scraping 时的频率。` |
| `prometheus.contextPath` | `/prometheus` |  |
| `prometheus.ingress.enabled` | `false` |  |
| `prometheus.ingress.hosts` | `prometheus.local` | `用来创建一个 Ingress record。` |
| `prometheus.security.enabled` | `true` |  |

### 新增 `gateways` 键/值对{#new-gateways-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `gateways.istio-ingressgateway.sds.enabled` | `false` | `如果设置为 true，则入口网关从 SDS 服务器获取凭据以处理 TLS 连接。` |
| `gateways.istio-ingressgateway.sds.image` | `node-agent-k8s` | `监视 kubernetes 的 secret 并向入口网关提供凭据的 SDS 服务器，该服务器与入口网关服务器在同一容器中运行。` |
| `gateways.istio-ingressgateway.autoscaleEnabled` | `true` |  |
| `gateways.istio-ingressgateway.cpu.targetAverageUtilization` | `80` |  |
| `gateways.istio-ingressgateway.loadBalancerSourceRanges` | `[]` |  |
| `gateways.istio-ingressgateway.externalIPs` | `[]` |  |
| `gateways.istio-ingressgateway.podAnnotations` | `{}` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15029` |  |
| `gateways.istio-ingressgateway.ports.name` | `https-kiali` |  |
| `gateways.istio-ingressgateway.ports.name` | `https-prometheus` |  |
| `gateways.istio-ingressgateway.ports.name` | `https-grafana` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15032` |  |
| `gateways.istio-ingressgateway.ports.name` | `https-tracing` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15443` |  |
| `gateways.istio-ingressgateway.ports.name` | `tls` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15020` |  |
| `gateways.istio-ingressgateway.ports.name` | `status-port` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.targetPort` | `15011` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.name` | `tcp-pilot-grpc-tls` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.targetPort` | `15004` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.name` | `tcp-mixer-grpc-tls` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.targetPort` | `8060` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.name` | `tcp-citadel-grpc-tls` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.targetPort` | `853` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.name` | `tcp-dns-tls` |  |
| `gateways.istio-ingressgateway.env.ISTIO_META_ROUTER_MODE` | `"sni-dnat"` | `具有此模式的网关可确保 pilot 为内部服务生成集群中的 additionalset，但无需 Istio mTLS，即可启用跨群集路由。` |
| `gateways.istio-ingressgateway.nodeSelector` | `{}` |  |
| `gateways.istio-egressgateway.autoscaleEnabled` | `true` |  |
| `gateways.istio-egressgateway.cpu.targetAverageUtilization` | `80` |  |
| `gateways.istio-egressgateway.podAnnotations` | `{}` |  |
| `gateways.istio-egressgateway.ports.targetPort` | `15443` |  |
| `gateways.istio-egressgateway.ports.name` | `tls` |  |
| `gateways.istio-egressgateway.env.ISTIO_META_ROUTER_MODE` | `"sni-dnat"` |  |
| `gateways.istio-egressgateway.nodeSelector` | `{}` |  |
| `gateways.istio-ilbgateway.autoscaleEnabled` | `true` |  |
| `gateways.istio-ilbgateway.cpu.targetAverageUtilization` | `80` |  |
| `gateways.istio-ilbgateway.podAnnotations` | `{}` |  |
| `gateways.istio-ilbgateway.nodeSelector` | `{}` |  |

### 新增 `kiali` 键/值对{#new-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `kiali.contextPath` | `/kiali` |  |
| `kiali.nodeSelector` | `{}` |  |
| `kiali.ingress.hosts` | `kiali.local` | `用来创建一个 Ingress record。` |
| `kiali.dashboard.secretName` | `kiali` |  |
| `kiali.dashboard.usernameKey` | `username` |  |
| `kiali.dashboard.passphraseKey` | `passphrase` |  |
| `kiali.prometheusAddr` | `http://prometheus:9090` |  |
| `kiali.createDemoSecret` | `false` | `设置为 true 时，将使用默认的用户名和密码创建一个 secret， 对一些 demo 有用。` |

### 新增 `istiocoredns` 键/值对{#new-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `istiocoredns.enabled` | `false` |  |
| `istiocoredns.replicaCount` | `1` |  |
| `istiocoredns.coreDNSImage` | `coredns/coredns:1.1.2` |  |
| `istiocoredns.coreDNSPluginImage` | `istio/coredns-plugin:0.2-istio-1.1` |  |
| `istiocoredns.nodeSelector` | `{}` |  |

### 新增 `security` 键/值对{#new-security-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `security.enabled` | `true` |  |
| `security.createMeshPolicy` | `true` |  |
| `security.nodeSelector` | `{}` |  |

### 新增 `nodeagent` 键/值对{#new-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `nodeagent.enabled` | `false` |  |
| `nodeagent.image` | `node-agent-k8s` |  |
| `nodeagent.env.CA_PROVIDER` | `""` | `provider 的名称。` |
| `nodeagent.env.CA_ADDR` | `""` | `CA 地址。` |
| `nodeagent.env.Plugins` | `""` | `鉴别 provider 插件的名称。` |
| `nodeagent.nodeSelector` | `{}` |  |

### 新增 `pilot` 键/值对{#new-pilot-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `pilot.autoscaleEnabled` | `true` |  |
| `pilot.env.PILOT_PUSH_THROTTLE` | `100` |  |
| `pilot.env.GODEBUG` | `gctrace=1` |  |
| `pilot.cpu.targetAverageUtilization` | `80` |  |
| `pilot.nodeSelector` | `{}` |  |
| `pilot.keepaliveMaxServerConnectionAge` | `30m` | `用于限制 sidecar 可以被 pilot 连接多久，平衡了 pilot 实例的负载，以损失系统资源为代价。` |

## 移除的配置选项{#removed-configuration-options}

### 移除 `ingress` 键/值对{#removed-ingress-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `ingress.service.ports.nodePort` | `32000` |  |
| `ingress.service.selector.istio` | `ingress` |  |
| `ingress.autoscaleMin` | `1` |  |
| `ingress.service.loadBalancerIP` | `""` |  |
| `ingress.enabled` | `false` |  |
| `ingress.service.annotations` | `{}` |  |
| `ingress.service.ports.name` | `http` |  |
| `ingress.service.ports.name` | `https` |  |
| `ingress.autoscaleMax` | `5` |  |
| `ingress.replicaCount` | `1` |  |
| `ingress.service.type` | `LoadBalancer #change to NodePort, ClusterIP or LoadBalancer if need be` |  |

### 移除 `servicegraph` 键/值对{#removed-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `servicegraph` | `servicegraph.local` |  |
| `servicegraph.ingress` | `servicegraph.local` |  |
| `servicegraph.service.internalPort` | `8088` |  |

### 移除 `telemetry-gateway` 键/值对{#removed-telemetry-gateway-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `telemetry-gateway.prometheusEnabled` | `false` |  |
| `telemetry-gateway.gatewayName` | `ingressgateway` |  |
| `telemetry-gateway.grafanaEnabled` | `false` |  |

### 移除 `global` 键/值对{#removed-global-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `global.hyperkube.tag` | `v1.7.6_coreos.0` |  |
| `global.k8sIngressHttps` | `false` |  |
| `global.crds` | `true` |  |
| `global.hyperkube.hub` | `quay.io/coreos` |  |
| `global.meshExpansion` | `false` |  |
| `global.k8sIngressSelector` | `ingress` |  |
| `global.meshExpansionILB` | `false` |  |

### 移除 `mixer` 键/值对{#removed-mixer-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `mixer.autoscaleMin` | `1` |  |
| `mixer.istio-policy.cpu.targetAverageUtilization` | `80` |  |
| `mixer.autoscaleMax` | `5` |  |
| `mixer.istio-telemetry.autoscaleMin` | `1` |  |
| `mixer.prometheusStatsdExporter.tag` | `v0.6.0` |  |
| `mixer.istio-telemetry.autoscaleMax` | `5` |  |
| `mixer.istio-telemetry.cpu.targetAverageUtilization` | `80` |  |
| `mixer.istio-policy.autoscaleEnabled` | `true` |  |
| `mixer.istio-telemetry.autoscaleEnabled` | `true` |  |
| `mixer.replicaCount` | `1` |  |
| `mixer.prometheusStatsdExporter.hub` | `docker.io/prom` |  |
| `mixer.istio-policy.autoscaleMin` | `1` |  |
| `mixer.istio-policy.autoscaleMax` | `5` |  |

### 移除 `grafana` 键/值对{#removed-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `grafana.image` | `grafana` |  |
| `grafana.service.internalPort` | `3000` |  |
| `grafana.security.adminPassword` | `admin` |  |
| `grafana.security.adminUser` | `admin` |  |

### 移除 `gateways` 键/值对{#removed-gateways-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `gateways.istio-ilbgateway.replicaCount` | `1` |  |
| `gateways.istio-egressgateway.replicaCount` | `1` |  |
| `gateways.istio-ingressgateway.replicaCount` | `1` |  |
| `gateways.istio-ingressgateway.ports.name` | `tcp-pilot-grpc-tls` |  |
| `gateways.istio-ingressgateway.ports.name` | `tcp-citadel-grpc-tls` |  |
| `gateways.istio-ingressgateway.ports.name` | `http2-prometheus` |  |
| `gateways.istio-ingressgateway.ports.name` | `http2-grafana` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15011` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `8060` |  |

### 移除 `tracing` 键/值对{#removed-tracing-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `tracing.service.internalPort` | `9411` |  |
| `tracing.replicaCount` | `1` |  |
| `tracing.jaeger.ingress` | `jaeger.local` |  |
| `tracing.ingress` | `tracing.local` |  |
| `tracing.jaeger` | `jaeger.local` |  |
| `tracing` | `jaeger.local tracing.local` |  |
| `tracing.jaeger.ingress.hosts` | `jaeger.local` |  |
| `tracing.jaeger.ingress.enabled` | `false` |  |
| `tracing.ingress.hosts` | `tracing.local` |  |
| `tracing.jaeger.ui.port` | `16686` |  |

### 移除 `kiali` 键/值对{#removed-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `kiali.dashboard.username` | `admin` |  |
| `kiali.dashboard.passphrase` | `admin` |  |

### 移除 `pilot` 键/值对{#removed-pilot-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `pilot.replicaCount` | `1` |  |

<!-- 自动生成结束 -->
