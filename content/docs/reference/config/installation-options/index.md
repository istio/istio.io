---
title: Installation Options
description: Describes the options available when installing Istio using the included Helm chart.
weight: 30
keywords: [kubernetes,helm]
force_inline_toc: true
---

To customize Istio install using Helm, use the `--set <key>=<value>` option in Helm command to override one or more values. The set of supported keys is shown in the table below.

<!-- Run python scripts/tablegen.py to generate this table -->

<!-- AUTO-GENERATED-START -->
## `certmanager` options

| Key | Default Value | Description |
| --- | --- | --- |
| `certmanager.enabled` | `false` |  |
| `certmanager.hub` | `quay.io/jetstack` |  |
| `certmanager.tag` | `v0.5.0` |  |
| `certmanager.resources` | `{}` |  |
| `certmanager.nodeSelector` | `{}` |  |

## `galley` options

| Key | Default Value | Description |
| --- | --- | --- |
| `galley.enabled` | `true` |  |
| `galley.replicaCount` | `1` |  |
| `galley.image` | `galley` |  |
| `galley.nodeSelector` | `{}` |  |

## `gateways` options

| Key | Default Value | Description |
| --- | --- | --- |
| `gateways.enabled` | `true` |  |
| `gateways.istio-ingressgateway.enabled` | `true` |  |
| `gateways.istio-ingressgateway.sds.enabled` | `false` |  |
| `gateways.istio-ingressgateway.sds.image` | `node-agent-k8s` |  |
| `gateways.istio-ingressgateway.labels.app` | `istio-ingressgateway` |  |
| `gateways.istio-ingressgateway.labels.istio` | `ingressgateway` |  |
| `gateways.istio-ingressgateway.replicaCount` | `1` |  |
| `gateways.istio-ingressgateway.autoscaleMin` | `1` |  |
| `gateways.istio-ingressgateway.autoscaleMax` | `5` |  |
| `gateways.istio-ingressgateway.resources` | `{}` |  |
| `gateways.istio-ingressgateway.cpu.targetAverageUtilization` | `80` |  |
| `gateways.istio-ingressgateway.podDisruptionBudget` | `{}` |  |
| `gateways.istio-ingressgateway.loadBalancerIP` | `""` |  |
| `gateways.istio-ingressgateway.loadBalancerSourceRanges` | `[]` |  |
| `gateways.istio-ingressgateway.externalIPs` | `[]` |  |
| `gateways.istio-ingressgateway.serviceAnnotations` | `{}` |  |
| `gateways.istio-ingressgateway.podAnnotations` | `{}` |  |
| `gateways.istio-ingressgateway.type` | `LoadBalancer #change to NodePort, ClusterIP or LoadBalancer if need be` |  |
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
| `gateways.istio-ingressgateway.meshExpansionPorts.targetPort` | `8060` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.name` | `tcp-citadel-grpc-tls` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.targetPort` | `853` |  |
| `gateways.istio-ingressgateway.meshExpansionPorts.name` | `tcp-dns-tls` |  |
| `gateways.istio-ingressgateway.secretVolumes.secretName` | `istio-ingressgateway-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.mountPath` | `/etc/istio/ingressgateway-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.secretName` | `istio-ingressgateway-ca-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.mountPath` | `/etc/istio/ingressgateway-ca-certs` |  |
| `gateways.istio-ingressgateway.env.ISTIO_META_ROUTER_MODE` | `"sni-dnat"` |  |
| `gateways.istio-ingressgateway.nodeSelector` | `{}` |  |
| `gateways.istio-egressgateway.enabled` | `false` |  |
| `gateways.istio-egressgateway.labels.app` | `istio-egressgateway` |  |
| `gateways.istio-egressgateway.labels.istio` | `egressgateway` |  |
| `gateways.istio-egressgateway.replicaCount` | `1` |  |
| `gateways.istio-egressgateway.autoscaleMin` | `1` |  |
| `gateways.istio-egressgateway.autoscaleMax` | `5` |  |
| `gateways.istio-egressgateway.cpu.targetAverageUtilization` | `80` |  |
| `gateways.istio-egressgateway.podDisruptionBudget` | `{}` |  |
| `gateways.istio-egressgateway.serviceAnnotations` | `{}` |  |
| `gateways.istio-egressgateway.podAnnotations` | `{}` |  |
| `gateways.istio-egressgateway.type` | `ClusterIP #change to NodePort or LoadBalancer if need be` |  |
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
| `gateways.istio-ilbgateway.enabled` | `false` |  |
| `gateways.istio-ilbgateway.labels.app` | `istio-ilbgateway` |  |
| `gateways.istio-ilbgateway.labels.istio` | `ilbgateway` |  |
| `gateways.istio-ilbgateway.replicaCount` | `1` |  |
| `gateways.istio-ilbgateway.autoscaleMin` | `1` |  |
| `gateways.istio-ilbgateway.autoscaleMax` | `5` |  |
| `gateways.istio-ilbgateway.cpu.targetAverageUtilization` | `80` |  |
| `gateways.istio-ilbgateway.podDisruptionBudget` | `{}` |  |
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

## `global` options

| Key | Default Value | Description |
| --- | --- | --- |
| `global.hub` | `gcr.io/istio-release` |  |
| `global.tag` | `master-latest-daily` |  |
| `global.monitoringPort` | `9093` |  |
| `global.k8sIngress.enabled` | `false` |  |
| `global.k8sIngress.gatewayName` | `ingress` |  |
| `global.k8sIngress.enableHttps` | `false` |  |
| `global.proxy.image` | `proxyv2` |  |
| `global.proxy.clusterDomain` | `"cluster.local"` |  |
| `global.proxy.resources.requests.cpu` | `10m` |  |
| `global.proxy.resources.requests.memory` | `30Mi` |  |
| `global.proxy.concurrency` | `0` |  |
| `global.proxy.accessLogFile` | `"/dev/stdout"` |  |
| `global.proxy.accessLogFormat` | `""` |  |
| `global.proxy.accessLogEncoding` | `TEXT` |  |
| `global.proxy.privileged` | `false` |  |
| `global.proxy.enableCoreDump` | `false` |  |
| `global.proxy.statusPort` | `15020` |  |
| `global.proxy.readinessInitialDelaySeconds` | `1` |  |
| `global.proxy.readinessPeriodSeconds` | `2` |  |
| `global.proxy.readinessFailureThreshold` | `30` |  |
| `global.proxy.includeIPRanges` | `"*"` |  |
| `global.proxy.excludeIPRanges` | `""` |  |
| `global.proxy.includeInboundPorts` | `"*"` |  |
| `global.proxy.excludeInboundPorts` | `""` |  |
| `global.proxy.autoInject` | `enabled` |  |
| `global.proxy.tracer` | `"zipkin"` |  |
| `global.proxy_init.image` | `proxy_init` |  |
| `global.imagePullPolicy` | `IfNotPresent` |  |
| `global.controlPlaneSecurityEnabled` | `false` |  |
| `global.disablePolicyChecks` | `false` |  |
| `global.policyCheckFailOpen` | `false` |  |
| `global.enableTracing` | `true` |  |
| `global.tracer.lightstep.address` | `""                # example: lightstep-satellite:443` |  |
| `global.tracer.lightstep.accessToken` | `""            # example: abcdefg1234567` |  |
| `global.tracer.lightstep.secure` | `true               # example: true|false` |  |
| `global.tracer.lightstep.cacertPath` | `""             # example: /etc/lightstep/cacert.pem` |  |
| `global.tracer.zipkin.address` | `""` |  |
| `global.mtls.enabled` | `false` |  |
| `global.arch.amd64` | `2` |  |
| `global.arch.s390x` | `2` |  |
| `global.arch.ppc64le` | `2` |  |
| `global.oneNamespace` | `false` |  |
| `global.defaultNodeSelector` | `{}` |  |
| `global.configValidation` | `true` |  |
| `global.meshExpansion.enabled` | `false` |  |
| `global.meshExpansion.useILB` | `false` |  |
| `global.multiCluster.enabled` | `false` |  |
| `global.defaultResources.requests.cpu` | `10m` |  |
| `global.defaultResources.requests.memory` | `30Mi` |  |
| `global.defaultPodDisruptionBudget.minAvailable` | `1` |  |
| `global.priorityClassName` | `""` |  |
| `global.useMCP` | `true` |  |
| `global.trustDomain` | `""` |  |
| `global.outboundTrafficPolicy.mode` | `REGISTRY_ONLY` |  |
| `global.sds.enabled` | `false` |  |
| `global.sds.udsPath` | `""` |  |
| `global.sds.useTrustworthyJwt` | `false` |  |
| `global.sds.useNormalJwt` | `false` |  |
| `global.enableHelmTest` | `false` |  |

## `grafana` options

| Key | Default Value | Description |
| --- | --- | --- |
| `grafana.enabled` | `false` |  |
| `grafana.replicaCount` | `1` |  |
| `grafana.image.repository` | `grafana/grafana` |  |
| `grafana.image.tag` | `5.4.0` |  |
| `grafana.ingress.enabled` | `false` |  |
| `grafana.ingress.hosts` | `grafana.local` |  |
| `grafana.persist` | `false` |  |
| `grafana.storageClassName` | `""` |  |
| `grafana.accessMode` | `ReadWriteMany` |  |
| `grafana.security.enabled` | `false` |  |
| `grafana.security.secretName` | `grafana` |  |
| `grafana.security.usernameKey` | `username` |  |
| `grafana.security.passphraseKey` | `passphrase` |  |
| `grafana.nodeSelector` | `{}` |  |
| `grafana.contextPath` | `/grafana` |  |
| `grafana.service.annotations` | `{}` |  |
| `grafana.service.name` | `http` |  |
| `grafana.service.type` | `ClusterIP` |  |
| `grafana.service.externalPort` | `3000` |  |
| `grafana.gateway.enabled` | `false` |  |
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

## `istio_cni` options

| Key | Default Value | Description |
| --- | --- | --- |
| `istio_cni.enabled` | `false` |  |

## `istiocoredns` options

| Key | Default Value | Description |
| --- | --- | --- |
| `istiocoredns.enabled` | `false` |  |
| `istiocoredns.replicaCount` | `1` |  |
| `istiocoredns.coreDNSImage` | `coredns/coredns:1.1.2` |  |
| `istiocoredns.coreDNSPluginImage` | `istio/coredns-plugin:0.1-istio-1.1` |  |
| `istiocoredns.nodeSelector` | `{}` |  |

## `kiali` options

| Key | Default Value | Description |
| --- | --- | --- |
| `kiali.enabled` | `false` |  |
| `kiali.replicaCount` | `1` |  |
| `kiali.hub` | `docker.io/kiali` |  |
| `kiali.tag` | `v0.12` |  |
| `kiali.contextPath` | `/kiali` |  |
| `kiali.nodeSelector` | `{}` |  |
| `kiali.ingress.enabled` | `false` |  |
| `kiali.ingress.hosts` | `kiali.local` |  |
| `kiali.gateway.enabled` | `false` |  |
| `kiali.dashboard.secretName` | `kiali` |  |
| `kiali.dashboard.usernameKey` | `username` |  |
| `kiali.dashboard.passphraseKey` | `passphrase` |  |
| `kiali.prometheusAddr` | `http://prometheus:9090` |  |
| `kiali.createDemoSecret` | `false` |  |

## `mixer` options

| Key | Default Value | Description |
| --- | --- | --- |
| `mixer.image` | `mixer` |  |
| `mixer.env.GODEBUG` | `gctrace=2` |  |
| `mixer.policy.enabled` | `true` |  |
| `mixer.policy.replicaCount` | `1` |  |
| `mixer.policy.autoscaleEnabled` | `true` |  |
| `mixer.policy.autoscaleMin` | `1` |  |
| `mixer.policy.autoscaleMax` | `5` |  |
| `mixer.policy.cpu.targetAverageUtilization` | `80` |  |
| `mixer.policy.podDisruptionBudget` | `{}` |  |
| `mixer.telemetry.enabled` | `true` |  |
| `mixer.telemetry.replicaCount` | `1` |  |
| `mixer.telemetry.autoscaleEnabled` | `true` |  |
| `mixer.telemetry.autoscaleMin` | `1` |  |
| `mixer.telemetry.autoscaleMax` | `5` |  |
| `mixer.telemetry.cpu.targetAverageUtilization` | `80` |  |
| `mixer.telemetry.podDisruptionBudget` | `{}` |  |
| `mixer.telemetry.sessionAffinityEnabled` | `false` |  |
| `mixer.podAnnotations` | `{}` |  |
| `mixer.nodeSelector` | `{}` |  |
| `mixer.adapters.kubernetesenv.enabled` | `true` |  |
| `mixer.adapters.stdio.enabled` | `true` |  |
| `mixer.adapters.stdio.outputAsJson` | `true` |  |
| `mixer.adapters.prometheus.enabled` | `true` |  |
| `mixer.adapters.prometheus.metricsExpiryDuration` | `10m` |  |
| `mixer.adapters.useAdapterCRDs` | `true` |  |

## `nodeagent` options

| Key | Default Value | Description |
| --- | --- | --- |
| `nodeagent.enabled` | `false` |  |
| `nodeagent.image` | `node-agent-k8s` |  |
| `nodeagent.env.CA_PROVIDER` | `""` |  |
| `nodeagent.env.CA_ADDR` | `""` |  |
| `nodeagent.env.Plugins` | `""` |  |
| `nodeagent.nodeSelector` | `{}` |  |

## `pilot` options

| Key | Default Value | Description |
| --- | --- | --- |
| `pilot.enabled` | `true` |  |
| `pilot.replicaCount` | `1` |  |
| `pilot.autoscaleMin` | `1` |  |
| `pilot.autoscaleMax` | `5` |  |
| `pilot.image` | `pilot` |  |
| `pilot.sidecar` | `true` |  |
| `pilot.traceSampling` | `100.0` |  |
| `pilot.resources.requests.cpu` | `500m` |  |
| `pilot.resources.requests.memory` | `2048Mi` |  |
| `pilot.podDisruptionBudget` | `{}` |  |
| `pilot.env.PILOT_PUSH_THROTTLE_COUNT` | `100` |  |
| `pilot.env.GODEBUG` | `gctrace=2` |  |
| `pilot.cpu.targetAverageUtilization` | `80` |  |
| `pilot.nodeSelector` | `{}` |  |

## `prometheus` options

| Key | Default Value | Description |
| --- | --- | --- |
| `prometheus.enabled` | `true` |  |
| `prometheus.replicaCount` | `1` |  |
| `prometheus.hub` | `docker.io/prom` |  |
| `prometheus.tag` | `v2.3.1` |  |
| `prometheus.retention` | `6h` |  |
| `prometheus.nodeSelector` | `{}` |  |
| `prometheus.scrapeInterval` | `15s` |  |
| `prometheus.contextPath` | `/prometheus` |  |
| `prometheus.ingress.enabled` | `false` |  |
| `prometheus.ingress.hosts` | `prometheus.local` |  |
| `prometheus.service.annotations` | `{}` |  |
| `prometheus.service.nodePort.enabled` | `false` |  |
| `prometheus.service.nodePort.port` | `32090` |  |
| `prometheus.gateway.enabled` | `false` |  |
| `prometheus.security.enabled` | `true` |  |

## `security` options

| Key | Default Value | Description |
| --- | --- | --- |
| `security.enabled` | `true` |  |
| `security.replicaCount` | `1` |  |
| `security.image` | `citadel` |  |
| `security.selfSigned` | `true # indicate if self-signed CA is used.` |  |
| `security.trustDomain` | `cluster.local # indicate the domain used in SPIFFE identity URL` |  |
| `security.nodeSelector` | `{}` |  |

## `servicegraph` options

| Key | Default Value | Description |
| --- | --- | --- |
| `servicegraph.enabled` | `false` |  |
| `servicegraph.replicaCount` | `1` |  |
| `servicegraph.image` | `servicegraph` |  |
| `servicegraph.nodeSelector` | `{}` |  |
| `servicegraph.service.annotations` | `{}` |  |
| `servicegraph.service.name` | `http` |  |
| `servicegraph.service.type` | `ClusterIP` |  |
| `servicegraph.service.externalPort` | `8088` |  |
| `servicegraph.ingress.enabled` | `false` |  |
| `servicegraph.ingress.hosts` | `servicegraph.local` |  |
| `servicegraph.prometheusAddr` | `http://prometheus:9090` |  |

## `sidecarInjectorWebhook` options

| Key | Default Value | Description |
| --- | --- | --- |
| `sidecarInjectorWebhook.enabled` | `true` |  |
| `sidecarInjectorWebhook.replicaCount` | `1` |  |
| `sidecarInjectorWebhook.image` | `sidecar_injector` |  |
| `sidecarInjectorWebhook.enableNamespacesByDefault` | `false` |  |
| `sidecarInjectorWebhook.nodeSelector` | `{}` |  |

## `tracing` options

| Key | Default Value | Description |
| --- | --- | --- |
| `tracing.enabled` | `false` |  |
| `tracing.provider` | `jaeger` |  |
| `tracing.nodeSelector` | `{}` |  |
| `tracing.jaeger.hub` | `docker.io/jaegertracing` |  |
| `tracing.jaeger.tag` | `1.9` |  |
| `tracing.jaeger.memory.max_traces` | `50000` |  |
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
| `tracing.service.annotations` | `{}` |  |
| `tracing.service.name` | `http` |  |
| `tracing.service.type` | `ClusterIP` |  |
| `tracing.service.externalPort` | `9411` |  |
| `tracing.ingress.enabled` | `false` |  |
| `tracing.gateway.enabled` | `false` |  |
| `tracing.gateway.name` | `ingressgateway` |  |

<!-- AUTO-GENERATED-END -->








