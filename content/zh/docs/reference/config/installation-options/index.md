---
title: 安装选项（Helm）
description: 描述使用 Helm charts 安装 Istio 时的可选项。
weight: 15
keywords: [kubernetes,helm]
force_inline_toc: true
---

{{< warning >}}
使用 Helm 安装 Istio 正在被弃用，不过你在 [使用 {{< istioctl >}} 安装 Istio](/zh/docs/setup/install/istioctl/)  时仍然可以使用这些 Helm 的配置项，把"`values.`"作为选项名的前缀。例如，替换下面的 `helm` 命令：

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

<!-- Run python scripts/tablegen.py to generate this table -->

<!-- AUTO-GENERATED-START -->
## `certmanager` 选项

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

## `galley` 选项

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

## `gateways` 选项

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
| `gateways.istio-ingressgateway.type` | `LoadBalancer` | `如果需要可以改为 NodePort，ClusterIP 或 LoadBalancer ` |
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
| `gateways.istio-egressgateway.type` | `ClusterIP` | `如果需要可改为 NodePort 或 LoadBalancer ` |
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

## `global` 选项

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
| `global.proxy.envoyAccessLogService.tlsSettings.sni` | `` | `例：als.somedomain` |
| `global.proxy.envoyAccessLogService.tlsSettings.subjectAltNames` | `[]` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.probes` | `3` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.time` | `10s` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.interval` | `10s` |  |
| `global.proxy.logLevel` | `""` | `代理的日志级别，应用于网关和 sidecars。如果为空，则使用 "warning"。期望值是：trace\|debug\|info\|warning\|error\|critical\|off` |
| `global.proxy.componentLogLevel` | `""` | `每个组件的代理日志级别，应用于网关和 sidecars。如果组件级别没设置，全局的“logLevel”将启用。如果为空，“misc:error” 将启用` |
| `global.proxy.dnsRefreshRate` | `300s` | `Configure the DNS refresh rate for Envoy cluster of type STRICT_DNS This must be given it terms of seconds. For example, 300s is valid but 5m is invalid.` |
| `global.proxy.protocolDetectionTimeout` | `10ms` | `Automatic protocol detection uses a set of heuristics to determine whether the connection is using TLS or not (on the server side), as well as the application protocol being used (e.g., http vs tcp). These heuristics rely on the client sending the first bits of data. For server first protocols like MySQL, MongoDB, etc., Envoy will timeout on the protocol detection after the specified period, defaulting to non mTLS plain TCP traffic. Set this field to tweak the period that Envoy will wait for the client to send the first bits of data. (MUST BE >=1ms)` |
| `global.proxy.privileged` | `false` | `If set to true, istio-proxy container will have privileged securityContext` |
| `global.proxy.enableCoreDump` | `false` | `If set, newly injected sidecars will have core dumps enabled.` |
| `global.proxy.enableCoreDumpImage` | `ubuntu:xenial` | `Image used to enable core dumps. This is only used, when "enableCoreDump" is set to true.` |
| `global.proxy.statusPort` | `15020` | `Default port for Pilot agent health checks. A value of 0 will disable health checking.` |
| `global.proxy.readinessInitialDelaySeconds` | `1` | `The initial delay for readiness probes in seconds.` |
| `global.proxy.readinessPeriodSeconds` | `2` | `The period between readiness probes.` |
| `global.proxy.readinessFailureThreshold` | `30` | `The number of successive failed probes before indicating readiness failure.` |
| `global.proxy.includeIPRanges` | `"*"` |  |
| `global.proxy.excludeIPRanges` | `""` |  |
| `global.proxy.excludeOutboundPorts` | `""` |  |
| `global.proxy.kubevirtInterfaces` | `""` | `pod internal interfaces` |
| `global.proxy.includeInboundPorts` | `"*"` |  |
| `global.proxy.excludeInboundPorts` | `""` |  |
| `global.proxy.autoInject` | `enabled` | `This controls the 'policy' in the sidecar injector.` |
| `global.proxy.envoyStatsd.enabled` | `false` | `If enabled is set to true, host and port must also be provided. Istio no longer provides a statsd collector.` |
| `global.proxy.envoyStatsd.host` | `` | `example: statsd-svc.istio-system` |
| `global.proxy.envoyStatsd.port` | `` | `example: 9125` |
| `global.proxy.envoyMetricsService.enabled` | `false` |  |
| `global.proxy.envoyMetricsService.host` | `` | `example: metrics-service.istio-system` |
| `global.proxy.envoyMetricsService.port` | `` | `example: 15000` |
| `global.proxy.tracer` | `"zipkin"` | `Specify which tracer to use. One of: zipkin, lightstep, datadog, stackdriver. If using stackdriver tracer outside GCP, set env GOOGLE_APPLICATION_CREDENTIALS to the GCP credential file.` |
| `global.proxy_init.image` | `proxy_init` | `Base name for the proxy_init container, used to configure iptables.` |
| `global.imagePullPolicy` | `IfNotPresent` |  |
| `global.controlPlaneSecurityEnabled` | `false` | `controlPlaneSecurityEnabled enabled. Will result in delays starting the pods while secrets are propagated, not recommended for tests.` |
| `global.disablePolicyChecks` | `true` | `disablePolicyChecks disables mixer policy checks. if mixer.policy.enabled==true then disablePolicyChecks has affect. Will set the value with same name in istio config map - pilot needs to be restarted to take effect.` |
| `global.policyCheckFailOpen` | `false` | `policyCheckFailOpen allows traffic in cases when the mixer policy service cannot be reached. Default is false which means the traffic is denied when the client is unable to connect to Mixer.` |
| `global.enableTracing` | `true` | `EnableTracing sets the value with same name in istio config map, requires pilot restart to take effect.` |
| `global.tracer.lightstep.address` | `""` | `example: lightstep-satellite:443` |
| `global.tracer.lightstep.accessToken` | `""` | `example: abcdefg1234567` |
| `global.tracer.lightstep.secure` | `true` | `example: true\|false` |
| `global.tracer.lightstep.cacertPath` | `""` | `example: /etc/lightstep/cacert.pem` |
| `global.tracer.zipkin.address` | `""` |  |
| `global.tracer.datadog.address` | `"$(HOST_IP):8126"` |  |
| `global.mtls.enabled` | `false` | `Default setting for service-to-service mtls. Can be set explicitly using destination rules or service annotations.` |
| `global.imagePullSecrets` | `[]` | `Lists the secrets you need to use to pull Istio images from a private registry.` |
| `global.arch.amd64` | `2` |  |
| `global.arch.s390x` | `2` |  |
| `global.arch.ppc64le` | `2` |  |
| `global.oneNamespace` | `false` | `Whether to restrict the applications namespace the controller manages; If not set, controller watches all namespaces` |
| `global.defaultNodeSelector` | `{}` | `Default node selector to be applied to all deployments so that all pods can be constrained to run a particular nodes. Each component can overwrite these default values by adding its node selector block in the relevant section below and setting the desired values.` |
| `global.defaultTolerations` | `[]` | `Default node tolerations to be applied to all deployments so that all pods can be scheduled to a particular nodes with matching taints. Each component can overwrite these default values by adding its tolerations block in the relevant section below and setting the desired values. Configure this field in case that all pods of Istio control plane are expected to be scheduled to particular nodes with specified taints.` |
| `global.configValidation` | `true` | `Whether to perform server-side validation of configuration.` |
| `global.meshExpansion.enabled` | `false` |  |
| `global.meshExpansion.useILB` | `false` | `If set to true, the pilot and citadel mtls and the plaintext pilot ports will be exposed on an internal gateway` |
| `global.multiCluster.enabled` | `false` | `Set to true to connect two kubernetes clusters via their respective ingressgateway services when pods in each cluster cannot directly talk to one another. All clusters should be using Istio mTLS and must have a shared root CA for this model to work.` |
| `global.defaultResources.requests.cpu` | `10m` |  |
| `global.defaultPodDisruptionBudget.enabled` | `true` |  |
| `global.priorityClassName` | `""` |  |
| `global.useMCP` | `true` | `Use the Mesh Control Protocol (MCP) for configuring Mixer and Pilot. Requires galley (--set galley.enabled=true).` |
| `global.trustDomain` | `""` |  |
| `global.meshID` | `""` | `Mesh ID means Mesh Identifier. It should be unique within the scope where meshes will interact with each other, but it is not required to be globally/universally unique. For example, if any of the following are true, then two meshes must have different Mesh IDs: - Meshes will have their telemetry aggregated in one place - Meshes will be federated together - Policy will be written referencing one mesh from the other If an administrator expects that any of these conditions may become true in the future, they should ensure their meshes have different Mesh IDs assigned. Within a multicluster mesh, each cluster must be (manually or auto) configured to have the same Mesh ID value. If an existing cluster 'joins' a multicluster mesh, it will need to be migrated to the new mesh ID. Details of migration TBD, and it may be a disruptive operation to change the Mesh ID post-install. If the mesh admin does not specify a value, Istio will use the value of the mesh's Trust Domain. The best practice is to select a proper Trust Domain value.` |
| `global.outboundTrafficPolicy.mode` | `ALLOW_ANY` |  |
| `global.sds.enabled` | `false` | `SDS enabled. IF set to true, mTLS certificates for the sidecars will be distributed through the SecretDiscoveryService instead of using K8S secrets to mount the certificates.` |
| `global.sds.udsPath` | `""` |  |
| `global.meshNetworks` | `{}` |  |
| `global.localityLbSetting.enabled` | `true` |  |
| `global.enableHelmTest` | `false` | `Specifies whether helm test is enabled or not. This field is set to false by default, so 'helm template ...' will ignore the helm test yaml files when generating the template` |

## `grafana` 选项

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

## `istio_cni` 选项

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `istio_cni.enabled` | `false` |  |

## `istiocoredns` 选项

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

## `kiali` options

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `kiali.enabled` | `false` | `Note that if using the demo yaml when installing via Helm, this default will be true.` |
| `kiali.replicaCount` | `1` |  |
| `kiali.hub` | `quay.io/kiali` |  |
| `kiali.image` | `kiali` |  |
| `kiali.tag` | `v1.1.0` |  |
| `kiali.contextPath` | `/kiali` | `The root context path to access the Kiali UI.` |
| `kiali.nodeSelector` | `{}` |  |
| `kiali.tolerations` | `[]` |  |
| `kiali.podAntiAffinityLabelSelector` | `[]` |  |
| `kiali.podAntiAffinityTermLabelSelector` | `[]` |  |
| `kiali.ingress.enabled` | `false` |  |
| `kiali.ingress.hosts` | `kiali.local` | `Used to create an Ingress record.` |
| `kiali.dashboard.auth.strategy` | `login` | `Can be anonymous, login, or openshift` |
| `kiali.dashboard.secretName` | `kiali` | `You must create a secret with this name - one is not provided out-of-box.` |
| `kiali.dashboard.viewOnlyMode` | `false` | `Bind the service account to a role with only read access` |
| `kiali.dashboard.grafanaURL` | `` | `If you have Grafana installed and it is accessible to client browsers, then set this to its external URL. Kiali will redirect users to this URL when Grafana metrics are to be shown.` |
| `kiali.dashboard.jaegerURL` | `` | `If you have Jaeger installed and it is accessible to client browsers, then set this property to its external URL. Kiali will redirect users to this URL when Jaeger tracing is to be shown.` |
| `kiali.prometheusAddr` | `http://prometheus:9090` |  |
| `kiali.createDemoSecret` | `false` | `When true, a secret will be created with a default username and password. Useful for demos.` |
| `kiali.security.enabled` | `true` |  |
| `kiali.security.cert_file` | `/kiali-cert/cert-chain.pem` |  |
| `kiali.security.private_key_file` | `/kiali-cert/key.pem` |  |

## `mixer` options

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `mixer.image` | `mixer` |  |
| `mixer.env.GODEBUG` | `gctrace=1` |  |
| `mixer.env.GOMAXPROCS` | `"6"` | `max procs should be ceil(cpu limit + 1)` |
| `mixer.policy.enabled` | `false` | `if policy is enabled, global.disablePolicyChecks has affect.` |
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
| `mixer.telemetry.loadshedding.mode` | `enforce` | `disabled, logonly or enforce` |
| `mixer.telemetry.loadshedding.latencyThreshold` | `100ms` | `based on measurements 100ms p50 translates to p99 of under 1s. This is ok for telemetry which is inherently async.` |
| `mixer.telemetry.resources.requests.cpu` | `1000m` |  |
| `mixer.telemetry.resources.requests.memory` | `1G` |  |
| `mixer.telemetry.resources.limits.cpu` | `4800m` | `It is best to do horizontal scaling of mixer using moderate cpu allocation. We have experimentally found that these values work well.` |
| `mixer.telemetry.resources.limits.memory` | `4G` |  |
| `mixer.telemetry.reportBatchMaxEntries` | `100` | `Set reportBatchMaxEntries to 0 to use the default batching behavior (i.e., every 100 requests). A positive value indicates the number of requests that are batched before telemetry data is sent to the mixer server` |
| `mixer.telemetry.reportBatchMaxTime` | `1s` | `Set reportBatchMaxTime to 0 to use the default batching behavior (i.e., every 1 second). A positive time value indicates the maximum wait time since the last request will telemetry data be batched before being sent to the mixer server` |
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
| `mixer.adapters.useAdapterCRDs` | `false` | `Setting this to false sets the useAdapterCRDs mixer startup argument to false` |

## `nodeagent` 选项

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `nodeagent.enabled` | `false` |  |
| `nodeagent.image` | `node-agent-k8s` |  |
| `nodeagent.env.CA_PROVIDER` | `""` | `认证提供商名称` |
| `nodeagent.env.CA_ADDR` | `""` | `CA endpoint.` |
| `nodeagent.env.Plugins` | `""` | `认证提供商的插件名称` |
| `nodeagent.nodeSelector` | `{}` |  |
| `nodeagent.tolerations` | `[]` |  |
| `nodeagent.podAntiAffinityLabelSelector` | `[]` |  |
| `nodeagent.podAntiAffinityTermLabelSelector` | `[]` |  |

## `pilot` 选项

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

## `prometheus` 选项

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

## `security` 选项

| 关键字 | 默认值 | 描述 |
| --- | --- | --- |
| `security.enabled` | `true` |  |
| `security.replicaCount` | `1` |  |
| `security.rollingMaxSurge` | `100%` |  |
| `security.rollingMaxUnavailable` | `25%` |  |
| `security.enableNamespacesByDefault` | `true` | `确定名称空间没有被密钥创建的 Citadel 标记 ca.istio.io/env 和ca.istio.io/override 标签。` |
| `security.image` | `citadel` |  |
| `security.selfSigned` | `true` | `表明自签名 CA 是否使用。` |
| `security.createMeshPolicy` | `true` |  |
| `security.nodeSelector` | `{}` |  |
| `security.tolerations` | `[]` |  |
| `security.citadelHealthCheck` | `false` |  |
| `security.workloadCertTtl` | `2160h` | `90*24 小时 = 2160h` |
| `security.enableNamespacesByDefault` | `true` | `指定 Citadel 的默认行为，如果ca.istio.io/env 或 ca.istio.io/override 标签没有在给定的命名空间发现。例如：考虑一个叫 "target" 的命名空间，既没有 "ca.istio.io/env" 也没有 "ca.istio.io/override" 标签。决定是否为这个 “target” 命名空间的服务账号创建密钥，Citadel 讲参考这一选项。在这个例子中如果值为 "true"，密钥将为 "target" 命名空间生成。如果值是 "false"，Citadel 不会在创建服务账户时产生密钥。` |
| `security.podAntiAffinityLabelSelector` | `[]` |  |
| `security.podAntiAffinityTermLabelSelector` | `[]` |  |

## `sidecarInjectorWebhook` 选项

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
| `sidecarInjectorWebhook.neverInjectSelector` | `[]` | `你可以使用名为 alwaysInjectSelector 和neverInjectSelector 的字段，它们总是注入 sidecar 或者总是略过与标签选择器匹配的 pod 上的注入，而不管全局策略是什么。参看  https://istio.io/docs/setup/kubernetes/additional-setup/sidecar-injection/more-control-adding-exceptions` |
| `sidecarInjectorWebhook.alwaysInjectSelector` | `[]` |  |

## `tracing` 选项

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
| `tracing.jaeger.spanStorageType` | `badger` | `对多合一的镜像 spanStorageType 的值可以是“memory” 和 “badger”` |
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

<!-- AUTO-GENERATED-END -->
