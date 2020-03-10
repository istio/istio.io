---
title: 安装选项（Helm）
description: 描述使用 Helm chart 安装 Istio 时的可选项。
weight: 15
keywords: [kubernetes,helm]
force_inline_toc: true
---

{{< warning >}}
使用 Helm 安装 Istio 的方式正在被弃用，不过你在[使用 {{< istioctl >}} 安装 Istio](/zh/docs/setup/install/istioctl/) 时仍然可以使用这些 Helm 的配置项，把 `values.` 作为选项名的前缀。例如，替换下面的 `helm` 命令：

{{< text bash >}}
$ helm template ... --set global.mtls.enabled=true
{{< /text >}}

可以使用 `istioctl` 命令：

{{< text bash >}}
$ istioctl manifest generate ... --set values.global.mtls.enabled=true
{{< /text >}}

参考[自定义配置](/zh/docs/setup/install/istioctl/#customizing-the-configuration)获取详细信息。
{{< /warning >}}

{{< warning >}}
不幸的是，由于支持的选项集有最新的变化，此文档已经过时。获取准确的支持的选项集，请参阅 [Helm charts]({{< github_tree >}}/install/kubernetes/helm/istio)。
{{< /warning >}}

## `certmanager` 选项 {#cert-manager-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `certmanager.enabled` | `false` |  |
| `certmanager.replicaCount` | `1` |  |
| `certmanager.hub` | `quay.io/jetstack` |  |
| `certmanager.image` | `cert-manager-controller` |  |
| `certmanager.tag` | `v0.6.2` |  |
| `certmanager.resources` | `{}` |  |
| `certmanager.nodeSelector` | `{}` |  |
| `certmanager.tolerations` | `[]` |  |
| `certmanager.podAntiAffinityLabelSelector` | `[]` |  |
| `certmanager.podAntiAffinityTermLabelSelector` | `[]` |  |

## `galley` 选项 {#galley-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `galley.enabled` | `true` |  |
| `galley.replicaCount` | `1` |  |
| `galley.rollingMaxSurge` | `100%` |  |
| `galley.rollingMaxUnavailable` | `25%` |  |
| `galley.image` | `galley` |  |
| `galley.nodeSelector` | `{}` |  |
| `galley.tolerations` | `[]` |  |
| `galley.podAntiAffinityLabelSelector` | `[]` |  |
| `galley.podAntiAffinityTermLabelSelector` | `[]` |  |

## `gateways` 选项 {#gateways-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `gateways.enabled` | `true` |  |
| `gateways.istio-ingressgateway.enabled` | `true` |  |
| `gateways.istio-ingressgateway.sds.enabled` | `false` | `如果是 true，ingress gateway 将从 SDS 服务器获取凭证来处理 TLS 连接。` |
| `gateways.istio-ingressgateway.sds.image` | `node-agent-k8s` | `SDS 服务器为 ingress gateway 监测 kubernetes 密钥和规定的凭证。服务器和 ingress gateway 运行在同一个 pod 中。` |
| `gateways.istio-ingressgateway.sds.resources.requests.cpu` | `100m` |  |
| `gateways.istio-ingressgateway.sds.resources.requests.memory` | `128Mi` |  |
| `gateways.istio-ingressgateway.sds.resources.limits.cpu` | `2000m` |  |
| `gateways.istio-ingressgateway.sds.resources.limits.memory` | `1024Mi` |  |
| `gateways.istio-ingressgateway.labels.app` | `istio-ingressgateway` |  |
| `gateways.istio-ingressgateway.labels.istio` | `ingressgateway` |  |
| `gateways.istio-ingressgateway.autoscaleEnabled` | `true` |  |
| `gateways.istio-ingressgateway.autoscaleMin` | `1` |  |
| `gateways.istio-ingressgateway.autoscaleMax` | `5` |  |
| `gateways.istio-ingressgateway.rollingMaxSurge` | `100%` |  |
| `gateways.istio-ingressgateway.rollingMaxUnavailable` | `25%` |  |
| `gateways.istio-ingressgateway.resources.requests.cpu` | `100m` |  |
| `gateways.istio-ingressgateway.resources.requests.memory` | `128Mi` |  |
| `gateways.istio-ingressgateway.resources.limits.cpu` | `2000m` |  |
| `gateways.istio-ingressgateway.resources.limits.memory` | `1024Mi` |  |
| `gateways.istio-ingressgateway.cpu.targetAverageUtilization` | `80` |  |
| `gateways.istio-ingressgateway.loadBalancerIP` | `""` |  |
| `gateways.istio-ingressgateway.loadBalancerSourceRanges` | `[]` |  |
| `gateways.istio-ingressgateway.externalIPs` | `[]` |  |
| `gateways.istio-ingressgateway.serviceAnnotations` | `{}` |  |
| `gateways.istio-ingressgateway.podAnnotations` | `{}` |  |
| `gateways.istio-ingressgateway.type` | `LoadBalancer` | `如果需要可以改为 NodePort，ClusterIP 或 LoadBalancer` |
| `gateways.istio-ingressgateway.ports.targetPort` | `15020` |  |
| `gateways.istio-ingressgateway.ports.name` | `status-port` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `80` |  |
| `gateways.istio-ingressgateway.ports.name` | `http2` |  |
| `gateways.istio-ingressgateway.ports.nodePort` | `31380` |  |
| `gateways.istio-ingressgateway.ports.name` | `https` |  |
| `gateways.istio-ingressgateway.ports.nodePort` | `31390` |  |
| `gateways.istio-ingressgateway.ports.name` | `tcp` |  |
| `gateways.istio-ingressgateway.ports.nodePort` | `31400` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15029` |  |
| `gateways.istio-ingressgateway.ports.name` | `https-kiali` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15030` |  |
| `gateways.istio-ingressgateway.ports.name` | `https-prometheus` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15031` |  |
| `gateways.istio-ingressgateway.ports.name` | `https-grafana` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15032` |  |
| `gateways.istio-ingressgateway.ports.name` | `https-tracing` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15443` |  |
| `gateways.istio-ingressgateway.ports.name` | `tls` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.targetPort` | `15011` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.name` | `tcp-pilot-grpc-tls` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.targetPort` | `15004` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.name` | `tcp-mixer-grpc-tls` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.targetPort` | `8060` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.name` | `tcp-citadel-grpc-tls` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.targetPort` | `853` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.name` | `tcp-dns-tls` |  |
| `gateways.istio-ingressgateway.secretVolumes.secretName` | `istio-ingressgateway-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.mountPath` | `/etc/istio/ingressgateway-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.secretName` | `istio-ingressgateway-ca-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.mountPath` | `/etc/istio/ingressgateway-ca-certs` |  |
| `gateways.istio-ingressgateway.applicationPorts` | `""` |  |
| `gateways.istio-ingressgateway.env.ISTIO_META_ROUTER_MODE` | `"sni-dnat"` | `使用这种模式的网关可以确保 pilot 为内部服务生成一组额外的集群，而不使用 Istio mTLS，从而支持跨集群路由。` |
| `gateways.istio-ingressgateway.nodeSelector` | `{}` |  |
| `gateways.istio-ingressgateway.tolerations` | `[]` |  |
| `gateways.istio-ingressgateway.podAntiAffinityLabelSelector` | `[]` |  |
| `gateways.istio-ingressgateway.podAntiAffinityTermLabelSelector` | `[]` |  |
| `gateways.istio-egressgateway.enabled` | `false` |  |
| `gateways.istio-egressgateway.labels.app` | `istio-egressgateway` |  |
| `gateways.istio-egressgateway.labels.istio` | `egressgateway` |  |
| `gateways.istio-egressgateway.autoscaleEnabled` | `true` |  |
| `gateways.istio-egressgateway.autoscaleMin` | `1` |  |
| `gateways.istio-egressgateway.autoscaleMax` | `5` |  |
| `gateways.istio-egressgateway.rollingMaxSurge` | `100%` |  |
| `gateways.istio-egressgateway.rollingMaxUnavailable` | `25%` |  |
| `gateways.istio-egressgateway.resources.requests.cpu` | `100m` |  |
| `gateways.istio-egressgateway.resources.requests.memory` | `128Mi` |  |
| `gateways.istio-egressgateway.resources.limits.cpu` | `2000m` |  |
| `gateways.istio-egressgateway.resources.limits.memory` | `1024Mi` |  |
| `gateways.istio-egressgateway.cpu.targetAverageUtilization` | `80` |  |
| `gateways.istio-egressgateway.serviceAnnotations` | `{}` |  |
| `gateways.istio-egressgateway.podAnnotations` | `{}` |  |
| `gateways.istio-egressgateway.type` | `ClusterIP` | `如果需要可改为 NodePort 或 LoadBalancer` |
| `gateways.istio-egressgateway.ports.name` | `http2` |  |
| `gateways.istio-egressgateway.ports.name` | `https` |  |
| `gateways.istio-egressgateway.ports.targetPort` | `15443` |  |
| `gateways.istio-egressgateway.ports.name` | `tls` |  |
| `gateways.istio-egressgateway.secretVolumes.secretName` | `istio-egressgateway-certs` |  |
| `gateways.istio-egressgateway.secretVolumes.mountPath` | `/etc/istio/egressgateway-certs` |  |
| `gateways.istio-egressgateway.secretVolumes.secretName` | `istio-egressgateway-ca-certs` |  |
| `gateways.istio-egressgateway.secretVolumes.mountPath` | `/etc/istio/egressgateway-ca-certs` |  |
| `gateways.istio-egressgateway.env.ISTIO_META_ROUTER_MODE` | `"sni-dnat"` |  |
| `gateways.istio-egressgateway.nodeSelector` | `{}` |  |
| `gateways.istio-egressgateway.tolerations` | `[]` |  |
| `gateways.istio-egressgateway.podAntiAffinityLabelSelector` | `[]` |  |
| `gateways.istio-egressgateway.podAntiAffinityTermLabelSelector` | `[]` |  |
| `gateways.istio-ilbgateway.enabled` | `false` |  |
| `gateways.istio-ilbgateway.labels.app` | `istio-ilbgateway` |  |
| `gateways.istio-ilbgateway.labels.istio` | `ilbgateway` |  |
| `gateways.istio-ilbgateway.autoscaleEnabled` | `true` |  |
| `gateways.istio-ilbgateway.autoscaleMin` | `1` |  |
| `gateways.istio-ilbgateway.autoscaleMax` | `5` |  |
| `gateways.istio-ilbgateway.rollingMaxSurge` | `100%` |  |
| `gateways.istio-ilbgateway.rollingMaxUnavailable` | `25%` |  |
| `gateways.istio-ilbgateway.cpu.targetAverageUtilization` | `80` |  |
| `gateways.istio-ilbgateway.resources.requests.cpu` | `800m` |  |
| `gateways.istio-ilbgateway.resources.requests.memory` | `512Mi` |  |
| `gateways.istio-ilbgateway.loadBalancerIP` | `""` |  |
| `gateways.istio-ilbgateway.serviceAnnotations.cloud.google.com/load-balancer-type` | `"internal"` |  |
| `gateways.istio-ilbgateway.podAnnotations` | `{}` |  |
| `gateways.istio-ilbgateway.type` | `LoadBalancer` |  |
| `gateways.istio-ilbgateway.ports.name` | `grpc-pilot-mtls` |  |
| `gateways.istio-ilbgateway.ports.name` | `grpc-pilot` |  |
| `gateways.istio-ilbgateway.ports.targetPort` | `8060` |  |
| `gateways.istio-ilbgateway.ports.name` | `tcp-citadel-grpc-tls` |  |
| `gateways.istio-ilbgateway.ports.name` | `tcp-dns` |  |
| `gateways.istio-ilbgateway.secretVolumes.secretName` | `istio-ilbgateway-certs` |  |
| `gateways.istio-ilbgateway.secretVolumes.mountPath` | `/etc/istio/ilbgateway-certs` |  |
| `gateways.istio-ilbgateway.secretVolumes.secretName` | `istio-ilbgateway-ca-certs` |  |
| `gateways.istio-ilbgateway.secretVolumes.mountPath` | `/etc/istio/ilbgateway-ca-certs` |  |
| `gateways.istio-ilbgateway.nodeSelector` | `{}` |  |
| `gateways.istio-ilbgateway.tolerations` | `[]` |  |

## `global` 选项 {#global-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `global.hub` | `` | `Istio 镜像的默认 hub。发布在 'istio' 项目下的 docker hub 中。通过 gcr.io 的 prow 每日构建。` |
| `global.tag` | `` | `Istio 镜像的默认 tag` |
| `global.logging.level` | `"default:info"` |  |
| `global.monitoringPort` | `15014` | `mixer, pilot, galley 和 sidecar injector 使用的监控端口` |
| `global.k8sIngress.enabled` | `false` |  |
| `global.k8sIngress.gatewayName` | `ingressgateway` | `k8s Ingress 资源使用的网关。默认使用 'istio:ingressgateway'，通过设置 'gateways.enabled' 和 'gateways.istio-ingressgateway.enabled' 标志为 true 来安装。` |
| `global.k8sIngress.enableHttps` | `false` | `enableHttps 将在 ingress 添加 443 端口。它要求证书安装在预期的密钥中——在没有证书的情况下启用此选项将导致 LDS 拒绝，ingress 将无法工作。` |
| `global.proxy.init.resources.limits.cpu` | `100m` |  |
| `global.proxy.init.resources.limits.memory` | `50Mi` |  |
| `global.proxy.init.resources.requests.cpu` | `10m` |  |
| `global.proxy.init.resources.requests.memory` | `10Mi` |  |
| `global.proxy.image` | `proxyv2` |  |
| `global.proxy.clusterDomain` | `"cluster.local"` | `集群域，默认值是 "cluster.local"。` |
| `global.proxy.resources.requests.cpu` | `100m` |  |
| `global.proxy.resources.requests.memory` | `128Mi` |  |
| `global.proxy.resources.limits.cpu` | `2000m` |  |
| `global.proxy.resources.limits.memory` | `1024Mi` |  |
| `global.proxy.concurrency` | `2` | `控制代理 worker 线程的数量。如果设置为 0，每个 CPU 每个核启动一个 worker 线程。` |
| `global.proxy.accessLogFile` | `""` |  |
| `global.proxy.accessLogFormat` | `""` | `配置如何以及哪些字段显示在 sidecar 访问日志中。设置为空字符串为默认的日志格式` |
| `global.proxy.accessLogEncoding` | `TEXT` | `配置 sidecar 的访问日志为 JSON 或 TEXT 格式` |
| `global.proxy.envoyAccessLogService.enabled` | `false` |  |
| `global.proxy.envoyAccessLogService.host` | `` | `例： accesslog-service.istio-system` |
| `global.proxy.envoyAccessLogService.port` | `` | `例：15000` |
| `global.proxy.envoyAccessLogService.tlsSettings.mode` | `DISABLE` | `DISABLE，SIMPLE，MUTUAL，ISTIO_MUTUAL` |
| `global.proxy.envoyAccessLogService.tlsSettings.clientCertificate` | `` | `例：/etc/istio/als/cert-chain.pem` |
| `global.proxy.envoyAccessLogService.tlsSettings.privateKey` | `` | `例：/etc/istio/als/key.pem` |
| `global.proxy.envoyAccessLogService.tlsSettings.caCertificates` | `` | `例：/etc/istio/als/root-cert.pem` |
| `global.proxy.envoyAccessLogService.tlsSettings.sni` | `` | `例：tlsomedomain` |
| `global.proxy.envoyAccessLogService.tlsSettings.subjectAltNames` | `[]` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.probes` | `3` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.time` | `10s` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.interval` | `10s` |  |
| `global.proxy.logLevel` | `""` | `代理的日志级别，应用于网关和 sidecars。如果为空，则使用 "warning"。期望值是：trace\|debug\|info\|warning\|error\|critical\|off` |
| `global.proxy.componentLogLevel` | `""` | `每个组件的代理日志级别，应用于网关和 sidecars。如果组件级别没设置，全局的 "logLevel" 将启用。如果为空，"misc:error" 将启用` |
| `global.proxy.dnsRefreshRate` | `300s` | `配置类型为 STRICT_DNS 的 Envoy 集群的 DNS 刷新率，必须以秒为单位。例如：300s 是合法的但 5m 不合法。` |
| `global.proxy.protocolDetectionTimeout` | `10ms` | `自动协议检测使用一组试探法来确定连接是否使用 TLS（服务端），以及正在使用的应用程序协议（例如 http 和 tcp）。 试探法依赖于客户端发送的第一个数据位。对于像 Mysql，MongoDB 这样的服务器的第一协议来说，在指定的时间段之后，Envoy 将对协议检测超时，默认为非 mTLS 的 TCP 流量。设置此字段以调整 Envoy 将等待客户端发送第一个数据位的时间。（必须 >=1ms）` |
| `global.proxy.privileged` | `false` | `如果设置为 true，istio-proxy 容器将享有 securityContext 的权限。` |
| `global.proxy.enableCoreDump` | `false` | `如果设置，新注入的 sidecars 将启用 core dumps。` |
| `global.proxy.enableCoreDumpImage` | `ubuntu:xenial` | `镜像用于开启 core dumps。仅在 "enableCoreDump" 设置为 true 时使用。` |
| `global.proxy.statusPort` | `15020` | `Pilot 代理健康检查的默认端口。值为 0 将关闭健康检查。` |
| `global.proxy.readinessInitialDelaySeconds` | `1` | `readiness 探针的初始延迟秒数。` |
| `global.proxy.readinessPeriodSeconds` | `2` | `readiness 探针的探测间隔。` |
| `global.proxy.readinessFailureThreshold` | `30` | `确定 readiness 失败前探测成功失败的数量。` |
| `global.proxy.includeIPRanges` | `"*"` |  |
| `global.proxy.excludeIPRanges` | `""` |  |
| `global.proxy.excludeOutboundPorts` | `""` |  |
| `global.proxy.kubevirtInterfaces` | `""` | `pod 内部接口` |
| `global.proxy.includeInboundPorts` | `"*"` |  |
| `global.proxy.excludeInboundPorts` | `""` |  |
| `global.proxy.autoInject` | `enabled` | `控制 sidecar 注入器的 'policy'。` |
| `global.proxy.envoyStatsd.enabled` | `false` | `如果设置为 true，主机和端口必须提供。Istio 不再提供一个 statsd 收集器。` |
| `global.proxy.envoyStatsd.host` | `` | `例： statsd-svc.istio-system` |
| `global.proxy.envoyStatsd.port` | `` | `例：9125` |
| `global.proxy.envoyMetricsService.enabled` | `false` |  |
| `global.proxy.envoyMetricsService.host` | `` | `例：metrics-service.istio-system` |
| `global.proxy.envoyMetricsService.port` | `` | `例：15000` |
| `global.proxy.tracer` | `"zipkin"` | `指定使用以下哪一个追踪器：zipkin，lightstep， datadog，stackdriver。 如果使用外部 GCP 的 stackdriver 追踪器，设置环境变量 GOOGLE_APPLICATION_CREDENTIALS 为 GCP 的凭证文件。` |
| `global.proxy_init.image` | `proxy_init` | `proxy_init 容器的基本名称，用于配置 iptables。` |
| `global.imagePullPolicy` | `IfNotPresent` |  |
| `global.controlPlaneSecurityEnabled` | `false` | `启用 controlPlaneSecurityEnabled enabled。当密钥被传输时，将导致启动 pod 的延迟，不建议用于测试。` |
| `global.disablePolicyChecks` | `true` | `disablePolicyChecks 关闭 mixer 策略检查。如果 mixer.policy.enabled==true 那么 disablePolicyChecks 生效。当在 istio config map 中设置此值时 —— pilot 需要重启才能生效。` |
| `global.policyCheckFailOpen` | `false` | `policyCheckFailOpen 允许在无法访问混合策略服务的情况下进行通信。缺省值为 false，这意味着当客户端无法连接到 Mixer 时，流量将被拒绝。` |
| `global.enableTracing` | `true` | `EnableTracing 设置和 istio config map 中同样的值，需要 pilot 重启生效。` |
| `global.tracer.lightstep.address` | `""` | `例：lightstep-satellite:443` |
| `global.tracer.lightstep.accessToken` | `""` | `例：abcdefg1234567` |
| `global.tracer.lightstep.secure` | `true` | `例：true\|false` |
| `global.tracer.lightstep.cacertPath` | `""` | `例：/etc/lightstep/cacert.pem` |
| `global.tracer.zipkin.address` | `""` |  |
| `global.tracer.datadog.address` | `"$(HOST_IP):8126"` |  |
| `global.mtls.enabled` | `false` | `服务到服务 mtls 的默认设置项。可以明确的设置使用目标规则或服务 annotations。` |
| `global.imagePullSecrets` | `[]` | `列出你从私有注册拉取 Istio 镜像所需的密钥。` |
| `global.arch.amd64` | `2` |  |
| `global.arch.s390x` | `2` |  |
| `global.arch.ppc64le` | `2` |  |
| `global.oneNamespace` | `false` | `是否限制控制器管理的应用程序名称空间；如果不设置，控制器将检测所有命名空间。` |
| `global.defaultNodeSelector` | `{}` | `将缺省节点选择器应用于所有 Deployment，以便所有 pod 都能被约束来运行特定的节点。每个组件都可以通过在下面的相关部分中添加其节点选择器块并设置所需的值来覆盖这些默认值。` |
| `global.defaultTolerations` | `[]` | `缺省节点容错应用于所有 Deployment，以便所有 pod 都可以调度到具有匹配 taints 的特定节点。每个组件都可以通过在下面的相关部分中添加自己的 tolerance 块并设置所需的值来覆盖这些默认值。配置此字段，以防所有 Istio 控制平面的 pod 都被调度到指定 taints 的特定节点。` |
| `global.configValidation` | `true` | `是否执行服务端配置验证。` |
| `global.meshExpansion.enabled` | `false` |  |
| `global.meshExpansion.useILB` | `false` | `如果设置为 true，pilot 和 citadel mtls 以及明文 pilot 端口将暴露在内部网关上。` |
| `global.multiCluster.enabled` | `false` | `当两个 kubernetes 集群中的 pod 不能互相直接通信时，设置为 true 将通过各自的 ingressgateway 服务连接两个 kubernetes 集群。所有的集群都应该使用 Istio mTLS，并且必须有一个共享的根 CA 才能让这个模型工作。` |
| `global.defaultResources.requests.cpu` | `10m` |  |
| `global.defaultPodDisruptionBudget.enabled` | `true` |  |
| `global.priorityClassName` | `""` |  |
| `global.useMCP` | `true` | `使用网格控制协议（MCP）来配置 Mixer 和 Pilot。需要 galley (--set galley.enabled=true)。` |
| `global.trustDomain` | `""` |  |
| `global.meshID` | `""` | `Mesh ID 意为 Mesh 标识符。在网格相互作用的范围内，它应该是唯一的，但不要求它是全局/普遍唯一的。例如，如果下面条件任意一个为真，那么两个网格必须有不同的 Mesh ID：—— 网格将遥测聚合在一个地方 —— 网格将连接在一起 —— 如果管理员期望这些条件中的任何一个在将来可能成为现实，那么策略将被从一个网格写入到另一个引用它的网格，他们需要保证这些网格被指定了不同的 Mesh ID。在一个多集群网格下，每一个集群必须（手动或自动）配置相同的 Mesh ID。如果一个存在的集群“加入”多集群网格，它需要被迁移到新的 mesh ID。详细的迁移还在制定中，在安装后更改 Mesh ID 可能会造成混乱。如果这个网格没有指定一个特定值，Istio 将使用该网格信任域的值。最佳实践是选择适当的信任域值。` |
| `global.outboundTrafficPolicy.mode` | `ALLOW_ANY` |  |
| `global.sds.enabled` | `false` | `启用 SDS。如果设置为 true，sidecars 的 mTLS 证书将通过 SecretDiscoveryService 分发，而不是使用 K8S secret 来挂载。` |
| `global.sds.udsPath` | `""` |  |
| `global.meshNetworks` | `{}` |  |
| `global.localityLbSetting.enabled` | `true` |  |
| `global.enableHelmTest` | `false` | `指定是否启用 helm test。此字段默认为 false，所以当生成模板时 'helm template ...' 将忽略 helm test yaml 文件。` |

## `grafana` 选项 {#Grafana-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `grafana.enabled` | `false` |  |
| `grafana.replicaCount` | `1` |  |
| `grafana.image.repository` | `grafana/grafana` |  |
| `grafana.image.tag` | `6.1.6` |  |
| `grafana.ingress.enabled` | `false` |  |
| `grafana.ingress.hosts` | `grafana.local` | `常用于创建一个 Ingress  记录` |
| `grafana.persist` | `false` |  |
| `grafana.storageClassName` | `""` |  |
| `grafana.accessMode` | `ReadWriteMany` |  |
| `grafana.security.enabled` | `false` |  |
| `grafana.security.secretName` | `grafana` |  |
| `grafana.security.usernameKey` | `username` |  |
| `grafana.security.passphraseKey` | `passphrase` |  |
| `grafana.nodeSelector` | `{}` |  |
| `grafana.tolerations` | `[]` |  |
| `grafana.env` | `{}` |  |
| `grafana.envSecrets` | `{}` |  |
| `grafana.podAntiAffinityLabelSelector` | `[]` |  |
| `grafana.podAntiAffinityTermLabelSelector` | `[]` |  |
| `grafana.contextPath` | `/grafana` |  |
| `grafana.service.annotations` | `{}` |  |
| `grafana.service.name` | `http` |  |
| `grafana.service.type` | `ClusterIP` |  |
| `grafana.service.externalPort` | `3000` |  |
| `grafana.datasources.datasources.apiVersion` | `1` |  |
| `grafana.datasources.datasources.datasources.type` | `prometheus` |  |
| `grafana.datasources.datasources.datasources.type.orgId` | `1` |  |
| `grafana.datasources.datasources.datasources.type.url` | `http://prometheus:9090` |  |
| `grafana.datasources.datasources.datasources.type.access` | `proxy` |  |
| `grafana.datasources.datasources.datasources.type.isDefault` | `true` |  |
| `grafana.datasources.datasources.datasources.type.jsonData.timeInterval` | `5s` |  |
| `grafana.datasources.datasources.datasources.type.editable` | `true` |  |
| `grafana.dashboardProviders.dashboardproviders.apiVersion` | `1` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.orgId` | `1` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.orgId.folder` | `'istio'` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.orgId.type` | `file` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.orgId.disableDeletion` | `false` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.orgId.options.path` | `/var/lib/grafana/dashboards/istio` |  |

## `cni` 选项 {#CNI-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `cni.enabled` | `false` |  |

## `istiocoredns` 选项 {#Istio-CoreDNS-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `istiocoredns.enabled` | `false` |  |
| `istiocoredns.replicaCount` | `1` |  |
| `istiocoredns.rollingMaxSurge` | `100%` |  |
| `istiocoredns.rollingMaxUnavailable` | `25%` |  |
| `istiocoredns.coreDNSImage` | `coredns/coredns:1.1.2` |  |
| `istiocoredns.coreDNSPluginImage` | `istio/coredns-plugin:0.2-istio-1.1` |  |
| `istiocoredns.nodeSelector` | `{}` |  |
| `istiocoredns.tolerations` | `[]` |  |
| `istiocoredns.podAntiAffinityLabelSelector` | `[]` |  |
| `istiocoredns.podAntiAffinityTermLabelSelector` | `[]` |  |

## `kiali` 选项 {#Kiali-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `kiali.enabled` | `false` | `注意当通过 Helm 安装，使用 demo yaml 时，默认值为 true。` |
| `kiali.replicaCount` | `1` |  |
| `kiali.hub` | `quay.io/kiali` |  |
| `kiali.image` | `kiali` |  |
| `kiali.tag` | `v1.1.0` |  |
| `kiali.contextPath` | `/kiali` | `访问 Kiali UI 的根上下文路径。` |
| `kiali.nodeSelector` | `{}` |  |
| `kiali.tolerations` | `[]` |  |
| `kiali.podAntiAffinityLabelSelector` | `[]` |  |
| `kiali.podAntiAffinityTermLabelSelector` | `[]` |  |
| `kiali.ingress.enabled` | `false` |  |
| `kiali.ingress.hosts` | `kiali.local` | `用来创建一个 Ingress 记录。` |
| `kiali.dashboard.auth.strategy` | `login` | `可以匿名，登录或 openshift` |
| `kiali.dashboard.secretName` | `kiali` | `必须使用该名称创建密钥——其中一个不是开箱即用的。` |
| `kiali.dashboard.viewOnlyMode` | `false` | `将服务帐户绑定到只读访问权限的角色。` |
| `kiali.dashboard.grafanaURL` | `` | `如果你安装了 Grafana 并可以通过客户端浏览器访问，设置此值作为它的外部 URL。当 Grafana 指标被显示时 Kiali 将重定向用户到此 URL。` |
| `kiali.dashboard.jaegerURL` | `` | `如果你安装了 Jaeger 并可以通过客户端浏览器访问，设置此值作为它的外部 URL。当 Jaeger 追踪被显示时 Kiali 将重定向用户到此 URL。` |
| `kiali.prometheusAddr` | `http://prometheus:9090` |  |
| `kiali.createDemoSecret` | `false` | `为 true 时，将使用默认用户名和密码创建密钥。用于演示。` |
| `kiali.security.enabled` | `true` |  |
| `kiali.security.cert_file` | `/kiali-cert/cert-chain.pem` |  |
| `kiali.security.private_key_file` | `/kiali-cert/key.pem` |  |

## `mixer` 选项 {#mixer-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `mixer.image` | `mixer` |  |
| `mixer.env.GODEBUG` | `gctrace=1` |  |
| `mixer.env.GOMAXPROCS` | `"6"` | `最大进程数为 ceil(cpu limit + 1)` |
| `mixer.policy.enabled` | `false` | `如果策略启用，global.disablePolicyChecks 生效。` |
| `mixer.policy.replicaCount` | `1` |  |
| `mixer.policy.autoscaleEnabled` | `true` |  |
| `mixer.policy.autoscaleMin` | `1` |  |
| `mixer.policy.autoscaleMax` | `5` |  |
| `mixer.policy.cpu.targetAverageUtilization` | `80` |  |
| `mixer.policy.rollingMaxSurge` | `100%` |  |
| `mixer.policy.rollingMaxUnavailable` | `25%` |  |
| `mixer.telemetry.enabled` | `true` |  |
| `mixer.telemetry.replicaCount` | `1` |  |
| `mixer.telemetry.autoscaleEnabled` | `true` |  |
| `mixer.telemetry.autoscaleMin` | `1` |  |
| `mixer.telemetry.autoscaleMax` | `5` |  |
| `mixer.telemetry.cpu.targetAverageUtilization` | `80` |  |
| `mixer.telemetry.rollingMaxSurge` | `100%` |  |
| `mixer.telemetry.rollingMaxUnavailable` | `25%` |  |
| `mixer.telemetry.sessionAffinityEnabled` | `false` |  |
| `mixer.telemetry.loadshedding.mode` | `enforce` | `disabled，logonly 或 enforce` |
| `mixer.telemetry.loadshedding.latencyThreshold` | `100ms` | `根据测量值把 100ms p50 转换成 1s 以下的 p99。这对于本质上是异步的遥测来说是可以接受的。` |
| `mixer.telemetry.resources.requests.cpu` | `1000m` |  |
| `mixer.telemetry.resources.requests.memory` | `1G` |  |
| `mixer.telemetry.resources.limits.cpu` | `4800m` | `最好使用适当的 cpu 分配来实现 Mixer 的水平扩展。我们已经通过实验发现这些数值工作的很好。` |
| `mixer.telemetry.resources.limits.memory` | `4G` |  |
| `mixer.telemetry.reportBatchMaxEntries` | `100` | `设置 reportBatchMaxEntries 为 0 来使用默认的批量行为（例如 每 100 个请求）。正值表示在将遥测数据发送到 Mixer 之前批处理的请求数。` |
| `mixer.telemetry.reportBatchMaxTime` | `1s` | `将 reportBatchMaxTime 设置为 0 以使用默认的批处理行为（例如每秒）。正时间值表示最大的等待时间，因为最后一个请求将在发送到 Mxier 之前批量处理遥测数据。` |
| `mixer.podAnnotations` | `{}` |  |
| `mixer.nodeSelector` | `{}` |  |
| `mixer.tolerations` | `[]` |  |
| `mixer.podAntiAffinityLabelSelector` | `[]` |  |
| `mixer.podAntiAffinityTermLabelSelector` | `[]` |  |
| `mixer.adapters.kubernetesenv.enabled` | `true` |  |
| `mixer.adapters.stdio.enabled` | `false` |  |
| `mixer.adapters.stdio.outputAsJson` | `true` |  |
| `mixer.adapters.prometheus.enabled` | `true` |  |
| `mixer.adapters.prometheus.metricsExpiryDuration` | `10m` |  |
| `mixer.adapters.useAdapterCRDs` | `false` | `设置为 false 则 useAdapterCRDs mixer 启动参数为 false` |

## `nodeagent` 选项 {#node-agent-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `nodeagent.enabled` | `false` |  |
| `nodeagent.image` | `node-agent-k8s` |  |
| `nodeagent.env.CA_PROVIDER` | `""` | `认证提供商名称` |
| `nodeagent.env.CA_ADDR` | `""` | `CA endpoint` |
| `nodeagent.env.Plugins` | `""` | `认证提供商的插件名称` |
| `nodeagent.nodeSelector` | `{}` |  |
| `nodeagent.tolerations` | `[]` |  |
| `nodeagent.podAntiAffinityLabelSelector` | `[]` |  |
| `nodeagent.podAntiAffinityTermLabelSelector` | `[]` |  |

## `pilot` 选项 {#pilot-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `pilot.enabled` | `true` |  |
| `pilot.autoscaleEnabled` | `true` |  |
| `pilot.autoscaleMin` | `1` |  |
| `pilot.autoscaleMax` | `5` |  |
| `pilot.rollingMaxSurge` | `100%` |  |
| `pilot.rollingMaxUnavailable` | `25%` |  |
| `pilot.image` | `pilot` |  |
| `pilot.sidecar` | `true` |  |
| `pilot.traceSampling` | `1.0` |  |
| `pilot.enableProtocolSniffing` | `false` | `是否启用 sniffing 协议。默认是 false。` |
| `pilot.resources.requests.cpu` | `500m` |  |
| `pilot.resources.requests.memory` | `2048Mi` |  |
| `pilot.env.PILOT_PUSH_THROTTLE` | `100` |  |
| `pilot.env.GODEBUG` | `gctrace=1` |  |
| `pilot.cpu.targetAverageUtilization` | `80` |  |
| `pilot.nodeSelector` | `{}` |  |
| `pilot.tolerations` | `[]` |  |
| `pilot.podAntiAffinityLabelSelector` | `[]` |  |
| `pilot.podAntiAffinityTermLabelSelector` | `[]` |  |
| `pilot.keepaliveMaxServerConnectionAge` | `30m` | `用来限制 sidecar 与 pilot 连接的时间。它平衡了 pilot 实例之间的负载，代价是增加了系统的负载。` |

## `prometheus` 选项 {#Prometheus-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `prometheus.enabled` | `true` |  |
| `prometheus.replicaCount` | `1` |  |
| `prometheus.hub` | `docker.io/prom` |  |
| `prometheus.image` | `prometheus` |  |
| `prometheus.tag` | `v2.8.0` |  |
| `prometheus.retention` | `6h` |  |
| `prometheus.nodeSelector` | `{}` |  |
| `prometheus.tolerations` | `[]` |  |
| `prometheus.podAntiAffinityLabelSelector` | `[]` |  |
| `prometheus.podAntiAffinityTermLabelSelector` | `[]` |  |
| `prometheus.scrapeInterval` | `15s` | `控制 prometheus scraping 的频率` |
| `prometheus.contextPath` | `/prometheus` |  |
| `prometheus.ingress.enabled` | `false` |  |
| `prometheus.ingress.hosts` | `prometheus.local` | `常用于创建一个 Ingress 记录` |
| `prometheus.service.annotations` | `{}` |  |
| `prometheus.service.nodePort.enabled` | `false` |  |
| `prometheus.service.nodePort.port` | `32090` |  |
| `prometheus.security.enabled` | `true` |  |

## `security` 选项 {#security-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `security.enabled` | `true` |  |
| `security.replicaCount` | `1` |  |
| `security.rollingMaxSurge` | `100%` |  |
| `security.rollingMaxUnavailable` | `25%` |  |
| `security.enableNamespacesByDefault` | `true` | `确定名称空间没有被密钥创建的 Citadel 标记 ca.istio.io/env 和 ca.istio.io/override 标签。` |
| `security.image` | `citadel` |  |
| `security.selfSigned` | `true` | `表明自签名 CA 是否使用。` |
| `security.createMeshPolicy` | `true` |  |
| `security.nodeSelector` | `{}` |  |
| `security.tolerations` | `[]` |  |
| `security.citadelHealthCheck` | `false` |  |
| `security.workloadCertTtl` | `2160h` | `90*24 小时 = 2160h` |
| `security.enableNamespacesByDefault` | `true` | `指定 Citadel 的默认行为，如果 ca.istio.io/env 或 ca.istio.io/override 标签没有在给定的命名空间发现。例如：考虑一个叫 "target" 的命名空间，既没有 "ca.istio.io/env" 也没有 "ca.istio.io/override" 标签。决定是否为这个 “target” 命名空间的服务账号创建密钥，Citadel 讲参考这一选项。在这个例子中如果值为 "true"，密钥将为 "target" 命名空间生成。如果值是 "false"，Citadel 不会在创建服务账户时产生密钥。` |
| `security.podAntiAffinityLabelSelector` | `[]` |  |
| `security.podAntiAffinityTermLabelSelector` | `[]` |  |

## `sidecarInjectorWebhook` 选项 {#sidecar-injector-webhook-options}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `sidecarInjectorWebhook.enabled` | `true` |  |
| `sidecarInjectorWebhook.replicaCount` | `1` |  |
| `sidecarInjectorWebhook.rollingMaxSurge` | `100%` |  |
| `sidecarInjectorWebhook.rollingMaxUnavailable` | `25%` |  |
| `sidecarInjectorWebhook.image` | `sidecar_injector` |  |
| `sidecarInjectorWebhook.enableNamespacesByDefault` | `false` |  |
| `sidecarInjectorWebhook.nodeSelector` | `{}` |  |
| `sidecarInjectorWebhook.tolerations` | `[]` |  |
| `sidecarInjectorWebhook.podAntiAffinityLabelSelector` | `[]` |  |
| `sidecarInjectorWebhook.podAntiAffinityTermLabelSelector` | `[]` |  |
| `sidecarInjectorWebhook.rewriteAppHTTPProbe` | `false` | `如果是 true，webhook 或 istioctl injector 将为活性健康检查重写 PodSpec 以重定向请求到 sidecar。这使得即使在启用 mTLS 时，活性检查也可以工作。` |
| `sidecarInjectorWebhook.neverInjectSelector` | `[]` | `你可以使用名为 alwaysInjectSelector 和neverInjectSelector 的字段，它们总是注入 sidecar 或者总是略过与标签选择器匹配的 pod 上的注入，而不管全局策略是什么。参看  https://istio.io/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/more-control-adding-exceptions` |
| `sidecarInjectorWebhook.alwaysInjectSelector` | `[]` |  |

## `tracing` 选项 {#tracing-option}

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `tracing.enabled` | `false` |  |
| `tracing.provider` | `jaeger` |  |
| `tracing.nodeSelector` | `{}` |  |
| `tracing.tolerations` | `[]` |  |
| `tracing.podAntiAffinityLabelSelector` | `[]` |  |
| `tracing.podAntiAffinityTermLabelSelector` | `[]` |  |
| `tracing.jaeger.hub` | `docker.io/jaegertracing` |  |
| `tracing.jaeger.image` | `all-in-one` |  |
| `tracing.jaeger.tag` | `1.12` |  |
| `tracing.jaeger.memory.max_traces` | `50000` |  |
| `tracing.jaeger.spanStorageType` | `badger` | `对多合一的镜像 spanStorageType 的值可以是 "memory" 和 "badger"` |
| `tracing.jaeger.persist` | `false` |  |
| `tracing.jaeger.storageClassName` | `""` |  |
| `tracing.jaeger.accessMode` | `ReadWriteMany` |  |
| `tracing.zipkin.hub` | `docker.io/openzipkin` |  |
| `tracing.zipkin.image` | `zipkin` |  |
| `tracing.zipkin.tag` | `2.14.2` |  |
| `tracing.zipkin.probeStartupDelay` | `200` |  |
| `tracing.zipkin.queryPort` | `9411` |  |
| `tracing.zipkin.resources.limits.cpu` | `300m` |  |
| `tracing.zipkin.resources.limits.memory` | `900Mi` |  |
| `tracing.zipkin.resources.requests.cpu` | `150m` |  |
| `tracing.zipkin.resources.requests.memory` | `900Mi` |  |
| `tracing.zipkin.javaOptsHeap` | `700` |  |
| `tracing.zipkin.maxSpans` | `500000` |  |
| `tracing.zipkin.node.cpus` | `2` |  |
| `tracing.service.annotations` | `{}` |  |
| `tracing.service.name` | `http` |  |
| `tracing.service.type` | `ClusterIP` |  |
| `tracing.service.externalPort` | `9411` |  |
| `tracing.ingress.enabled` | `false` |  |
