---
title: Installation Options (Helm)
description: Describes the options available when installing Istio using Helm charts.
weight: 15
keywords: [kubernetes,helm]
force_inline_toc: true
---

{{< warning >}}
Installing Istio with Helm is in the process of deprecation, however, you can use these Helm
configuration options when [installing Istio with {{< istioctl >}}](/docs/setup/install/istioctl/)
by prepending the string "`values.`" to the option name. For example, instead of this `helm` command:

{{< text bash >}}
$ helm template ... --set global.mtls.enabled=true
{{< /text >}}

You can use this `istioctl` command:

{{< text bash >}}
$ istioctl manifest generate ... --set values.global.mtls.enabled=true
{{< /text >}}

Refer to [customizing the configuration](/docs/setup/install/istioctl/#customizing-the-configuration) for details.
{{< /warning >}}

{{< warning >}}
This document is unfortunately out of date with the latest changes in the set of supported options.
To get the exact set of supported options, please see the [Helm charts]({{< github_tree >}}/install/kubernetes/helm/istio).
{{< /warning >}}

<!-- Run python scripts/tablegen.py to generate this table -->

<!-- AUTO-GENERATED-START -->
## `certmanager` options

| Key | Default Value | Description |
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

## `galley` options

| Key | Default Value | Description |
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

## `gateways` options

| Key | Default Value | Description |
| --- | --- | --- |
| `gateways.enabled` | `true` |  |
| `gateways.istio-ingressgateway.enabled` | `true` |  |
| `gateways.istio-ingressgateway.sds.enabled` | `false` | `If true, ingress gateway fetches credentials from SDS server to handle TLS connections.` |
| `gateways.istio-ingressgateway.sds.image` | `node-agent-k8s` | `SDS server that watches kubernetes secrets and provisions credentials to ingress gateway. This server runs in the same pod as ingress gateway.` |
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
| `gateways.istio-ingressgateway.type` | `LoadBalancer` | `change to NodePort, ClusterIP or LoadBalancer if need be` |
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
| `gateways.istio-ingressgateway.env.ISTIO_META_ROUTER_MODE` | `"sni-dnat"` | `A gateway with this mode ensures that pilot generates an additional set of clusters for internal services but without Istio mTLS, to enable cross cluster routing.` |
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
| `gateways.istio-egressgateway.type` | `ClusterIP` | `change to NodePort or LoadBalancer if need be` |
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

## `global` options

| Key | Default Value | Description |
| --- | --- | --- |
| `global.hub` | `` | `Default hub for Istio images. Releases are published to docker hub under 'istio' project. Daily builds from prow are on gcr.io` |
| `global.tag` | `` | `Default tag for Istio images.` |
| `global.logging.level` | `"default:info"` |  |
| `global.monitoringPort` | `15014` | `monitoring port used by mixer, pilot, galley and sidecar injector` |
| `global.k8sIngress.enabled` | `false` |  |
| `global.k8sIngress.gatewayName` | `ingressgateway` | `Gateway used for k8s Ingress resources. By default it is using 'istio:ingressgateway' that will be installed by setting 'gateways.enabled' and 'gateways.istio-ingressgateway.enabled' flags to true.` |
| `global.k8sIngress.enableHttps` | `false` | `enableHttps will add port 443 on the ingress. It REQUIRES that the certificates are installed  in the expected secrets - enabling this option without certificates will result in LDS rejection and the ingress will not work.` |
| `global.proxy.init.resources.limits.cpu` | `100m` |  |
| `global.proxy.init.resources.limits.memory` | `50Mi` |  |
| `global.proxy.init.resources.requests.cpu` | `10m` |  |
| `global.proxy.init.resources.requests.memory` | `10Mi` |  |
| `global.proxy.image` | `proxyv2` |  |
| `global.proxy.clusterDomain` | `"cluster.local"` | `cluster domain. Default value is "cluster.local".` |
| `global.proxy.resources.requests.cpu` | `100m` |  |
| `global.proxy.resources.requests.memory` | `128Mi` |  |
| `global.proxy.resources.limits.cpu` | `2000m` |  |
| `global.proxy.resources.limits.memory` | `1024Mi` |  |
| `global.proxy.concurrency` | `2` | `Controls number of Proxy worker threads. If set to 0, then start worker thread for each CPU thread/core.` |
| `global.proxy.accessLogFile` | `""` |  |
| `global.proxy.accessLogFormat` | `""` | `Configure how and what fields are displayed in sidecar access log. Setting to empty string will result in default log format` |
| `global.proxy.accessLogEncoding` | `TEXT` | `Configure the access log for sidecar to JSON or TEXT.` |
| `global.proxy.envoyAccessLogService.enabled` | `false` |  |
| `global.proxy.envoyAccessLogService.host` | `` | `example: accesslog-service.istio-system` |
| `global.proxy.envoyAccessLogService.port` | `` | `example: 15000` |
| `global.proxy.envoyAccessLogService.tlsSettings.mode` | `DISABLE` | `DISABLE, SIMPLE, MUTUAL, ISTIO_MUTUAL` |
| `global.proxy.envoyAccessLogService.tlsSettings.clientCertificate` | `` | `example: /etc/istio/als/cert-chain.pem` |
| `global.proxy.envoyAccessLogService.tlsSettings.privateKey` | `` | `example: /etc/istio/als/key.pem` |
| `global.proxy.envoyAccessLogService.tlsSettings.caCertificates` | `` | `example: /etc/istio/als/root-cert.pem` |
| `global.proxy.envoyAccessLogService.tlsSettings.sni` | `` | `example: als.somedomain` |
| `global.proxy.envoyAccessLogService.tlsSettings.subjectAltNames` | `[]` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.probes` | `3` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.time` | `10s` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.interval` | `10s` |  |
| `global.proxy.logLevel` | `""` | `Log level for proxy, applies to gateways and sidecars.  If left empty, "warning" is used. Expected values are: trace\|debug\|info\|warning\|error\|critical\|off` |
| `global.proxy.componentLogLevel` | `""` | `Per Component log level for proxy, applies to gateways and sidecars. If a component level is not set, then the global "logLevel" will be used. If left empty, "misc:error" is used.` |
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

## `grafana` options

| Key | Default Value | Description |
| --- | --- | --- |
| `grafana.enabled` | `false` |  |
| `grafana.replicaCount` | `1` |  |
| `grafana.image.repository` | `grafana/grafana` |  |
| `grafana.image.tag` | `6.1.6` |  |
| `grafana.ingress.enabled` | `false` |  |
| `grafana.ingress.hosts` | `grafana.local` | `Used to create an Ingress record.` |
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

## `istio_cni` options

| Key | Default Value | Description |
| --- | --- | --- |
| `istio_cni.enabled` | `false` |  |

## `istiocoredns` options

| Key | Default Value | Description |
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

| Key | Default Value | Description |
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

| Key | Default Value | Description |
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

## `nodeagent` options

| Key | Default Value | Description |
| --- | --- | --- |
| `nodeagent.enabled` | `false` |  |
| `nodeagent.image` | `node-agent-k8s` |  |
| `nodeagent.env.CA_PROVIDER` | `""` | `name of authentication provider.` |
| `nodeagent.env.CA_ADDR` | `""` | `CA endpoint.` |
| `nodeagent.env.Plugins` | `""` | `names of authentication provider's plugins.` |
| `nodeagent.nodeSelector` | `{}` |  |
| `nodeagent.tolerations` | `[]` |  |
| `nodeagent.podAntiAffinityLabelSelector` | `[]` |  |
| `nodeagent.podAntiAffinityTermLabelSelector` | `[]` |  |

## `pilot` options

| Key | Default Value | Description |
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
| `pilot.enableProtocolSniffing` | `false` | `if protocol sniffing is enabled. Default to false.` |
| `pilot.resources.requests.cpu` | `500m` |  |
| `pilot.resources.requests.memory` | `2048Mi` |  |
| `pilot.env.PILOT_PUSH_THROTTLE` | `100` |  |
| `pilot.env.GODEBUG` | `gctrace=1` |  |
| `pilot.cpu.targetAverageUtilization` | `80` |  |
| `pilot.nodeSelector` | `{}` |  |
| `pilot.tolerations` | `[]` |  |
| `pilot.podAntiAffinityLabelSelector` | `[]` |  |
| `pilot.podAntiAffinityTermLabelSelector` | `[]` |  |
| `pilot.keepaliveMaxServerConnectionAge` | `30m` | `The following is used to limit how long a sidecar can be connected to a pilot. It balances out load across pilot instances at the cost of increasing system churn.` |

## `prometheus` options

| Key | Default Value | Description |
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
| `prometheus.scrapeInterval` | `15s` | `Controls the frequency of prometheus scraping` |
| `prometheus.contextPath` | `/prometheus` |  |
| `prometheus.ingress.enabled` | `false` |  |
| `prometheus.ingress.hosts` | `prometheus.local` | `Used to create an Ingress record.` |
| `prometheus.service.annotations` | `{}` |  |
| `prometheus.service.nodePort.enabled` | `false` |  |
| `prometheus.service.nodePort.port` | `32090` |  |
| `prometheus.security.enabled` | `true` |  |

## `security` options

| Key | Default Value | Description |
| --- | --- | --- |
| `security.enabled` | `true` |  |
| `security.replicaCount` | `1` |  |
| `security.rollingMaxSurge` | `100%` |  |
| `security.rollingMaxUnavailable` | `25%` |  |
| `security.enableNamespacesByDefault` | `true` | `determines whether namespaces without the ca.istio.io/env and ca.istio.io/override labels should be targeted by the Citadel instance for secret creation` |
| `security.image` | `citadel` |  |
| `security.selfSigned` | `true` | `indicate if self-signed CA is used.` |
| `security.createMeshPolicy` | `true` |  |
| `security.nodeSelector` | `{}` |  |
| `security.tolerations` | `[]` |  |
| `security.citadelHealthCheck` | `false` |  |
| `security.workloadCertTtl` | `2160h` | `90*24hour = 2160h` |
| `security.enableNamespacesByDefault` | `true` | `Determines Citadel default behavior if the ca.istio.io/env or ca.istio.io/override labels are not found on a given namespace. For example: consider a namespace called "target", which has neither the "ca.istio.io/env" nor the "ca.istio.io/override" namespace labels. To decide whether or not to generate secrets for service accounts created in this "target" namespace, Citadel will defer to this option. If the value of this option is "true" in this case, secrets will be generated for the "target" namespace. If the value of this option is "false" Citadel will not generate secrets upon service account creation.` |
| `security.podAntiAffinityLabelSelector` | `[]` |  |
| `security.podAntiAffinityTermLabelSelector` | `[]` |  |

## `sidecarInjectorWebhook` options

| Key | Default Value | Description |
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
| `sidecarInjectorWebhook.rewriteAppHTTPProbe` | `false` | `If true, webhook or istioctl injector will rewrite PodSpec for liveness health check to redirect request to sidecar. This makes liveness check work even when mTLS is enabled.` |
| `sidecarInjectorWebhook.neverInjectSelector` | `[]` | `You can use the field called alwaysInjectSelector and neverInjectSelector which will always inject the sidecar or always skip the injection on pods that match that label selector, regardless of the global policy. See https://istio.io/docs/setup/kubernetes/additional-setup/sidecar-injection/more-control-adding-exceptions` |
| `sidecarInjectorWebhook.alwaysInjectSelector` | `[]` |  |

## `tracing` options

| Key | Default Value | Description |
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
| `tracing.jaeger.spanStorageType` | `badger` | `spanStorageType value can be "memory" and "badger" for all-in-one image` |
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
