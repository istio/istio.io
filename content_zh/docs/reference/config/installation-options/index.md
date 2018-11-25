---
title: 安装选项 
description: 描述了使用 Helm chart 安装 Istio 时可以使用的选项。
weight: 30
keywords: [kubernetes,helm]
---

可以通过在使用 Helm 命令时，增加 `--set <key>=<value>` 参数来覆写默认值的方式，来定制化安装 Istio。

下面列出所有可用键名。

<!-- Run python scripts/tablegen.py to generate this table -->
<!-- AUTO-GENERATED-START -->
## `certmanager` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `certmanager.enabled` | `true` |  |
| `certmanager.hub` | `quay.io/jetstack` |  |
| `certmanager.tag` | `v0.3.1` |  |
| `certmanager.resources` | `{}` |  |

## `galley` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `galley.enabled` | `true` |  |
| `galley.replicaCount` | `1` |  |
| `galley.image` | `galley` |  |

## `gateways` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `gateways.enabled` | `true` |  |
| `gateways.istio-ingressgateway.enabled` | `true` |  |
| `gateways.istio-ingressgateway.labels.app` | `istio-ingressgateway` |  |
| `gateways.istio-ingressgateway.labels.istio` | `ingressgateway` |  |
| `gateways.istio-ingressgateway.replicaCount` | `1` |  |
| `gateways.istio-ingressgateway.autoscaleMin` | `1` |  |
| `gateways.istio-ingressgateway.autoscaleMax` | `5` |  |
| `gateways.istio-ingressgateway.resources` | `{}` |  |
| `gateways.istio-ingressgateway.loadBalancerIP` | `""` |  |
| `gateways.istio-ingressgateway.serviceAnnotations` | `{}` |  |
| `gateways.istio-ingressgateway.type` | `LoadBalancer` | `如果需要，请更改为 NodePort，ClusterIP 或 LoadBalancer` |
| `gateways.istio-ingressgateway.ports.targetPort` | `80` |  |
| `gateways.istio-ingressgateway.ports.name` | `http2` |  |
| `gateways.istio-ingressgateway.ports.nodePort` | `31380` |  |
| `gateways.istio-ingressgateway.ports.name` | `https` |  |
| `gateways.istio-ingressgateway.ports.nodePort` | `31390` |  |
| `gateways.istio-ingressgateway.ports.name` | `tcp` |  |
| `gateways.istio-ingressgateway.ports.nodePort` | `31400` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15011` |  |
| `gateways.istio-ingressgateway.ports.name` | `tcp-pilot-grpc-tls` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `8060` |  |
| `gateways.istio-ingressgateway.ports.name` | `tcp-citadel-grpc-tls` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15030` |  |
| `gateways.istio-ingressgateway.ports.name` | `http2-prometheus` |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `15031` |  |
| `gateways.istio-ingressgateway.ports.name` | `http2-grafana` |  |
| `gateways.istio-ingressgateway.secretVolumes.secretName` | `istio-ingressgateway-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.mountPath` | `/etc/istio/ingressgateway-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.secretName` | `istio-ingressgateway-ca-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.mountPath` | `/etc/istio/ingressgateway-ca-certs` |  |
| `gateways.istio-egressgateway.enabled` | `true` |  |
| `gateways.istio-egressgateway.labels.app` | `istio-egressgateway` |  |
| `gateways.istio-egressgateway.labels.istio` | `egressgateway` |  |
| `gateways.istio-egressgateway.replicaCount` | `1` |  |
| `gateways.istio-egressgateway.autoscaleMin` | `1` |  |
| `gateways.istio-egressgateway.autoscaleMax` | `5` |  |
| `gateways.istio-egressgateway.serviceAnnotations` | `{}` |  |
| `gateways.istio-egressgateway.type` | `ClusterIP` |  `如果需要，请更改为 NodePort 或 LoadBalancer` |
| `gateways.istio-egressgateway.ports.name` | `http2` |  |
| `gateways.istio-egressgateway.ports.name.name` | `https` |  |
| `gateways.istio-egressgateway.secretVolumes.secretName` | `istio-egressgateway-certs` |  |
| `gateways.istio-egressgateway.secretVolumes.secretName.mountPath` | `/etc/istio/egressgateway-certs` |  |
| `gateways.istio-egressgateway.secretVolumes.secretName.secretName` | `istio-egressgateway-ca-certs` |  |
| `gateways.istio-egressgateway.secretVolumes.secretName.mountPath` | `/etc/istio/egressgateway-ca-certs` |  |
| `gateways.istio-ilbgateway.enabled` | `false` |  |
| `gateways.istio-ilbgateway.enabled.labels.app` | `istio-ilbgateway` |  |
| `gateways.istio-ilbgateway.enabled.labels.istio` | `ilbgateway` |  |
| `gateways.istio-ilbgateway.enabled.replicaCount` | `1` |  |
| `gateways.istio-ilbgateway.enabled.autoscaleMin` | `1` |  |
| `gateways.istio-ilbgateway.enabled.autoscaleMax` | `5` |  |
| `gateways.istio-ilbgateway.enabled.resources.requests.cpu` | `800m` |  |
| `gateways.istio-ilbgateway.enabled.resources.requests.memory` | `512Mi` |  |
| `gateways.istio-ilbgateway.enabled.loadBalancerIP` | `""` |  |
| `gateways.istio-ilbgateway.enabled.serviceAnnotations.cloud.google.com/load-balancer-type` | `"internal"` |  |
| `gateways.istio-ilbgateway.enabled.type` | `LoadBalancer` |  |
| `gateways.istio-ilbgateway.enabled.ports.name` | `grpc-pilot-mtls` |  |
| `gateways.istio-ilbgateway.enabled.ports.name` | `grpc-pilot` |  |
| `gateways.istio-ilbgateway.enabled.ports.targetPort` | `8060` |  |
| `gateways.istio-ilbgateway.enabled.ports.name` | `tcp-citadel-grpc-tls` |  |
| `gateways.istio-ilbgateway.enabled.ports.name` | `tcp-dns` |  |
| `gateways.istio-ilbgateway.enabled.secretVolumes.secretName` | `istio-ilbgateway-certs` |  |
| `gateways.istio-ilbgateway.enabled.secretVolumes.mountPath` | `/etc/istio/ilbgateway-certs` |  |
| `gateways.istio-ilbgateway.enabled.secretVolumes.secretName` | `istio-ilbgateway-ca-certs` |  |
| `gateways.istio-ilbgateway.enabled.secretVolumes.mountPath` | `/etc/istio/ilbgateway-ca-certs` |  |

## `global` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `global.hub` | `docker.io/istio` |  |
| `global.tag` | `1.0.0` |  |
| `global.k8sIngressSelector` | `ingress` |  |
| `global.k8sIngressHttps` | `false` |  |
| `global.proxy.image` | `proxyv2` |  |
| `global.proxy.resources.requests.cpu` | `10m` |  |
| `global.proxy.accessLogFile` | `"/dev/stdout"` |  |
| `global.proxy.enableCoreDump` | `false` |  |
| `global.proxy.includeIPRanges` | `"*"` |  |
| `global.proxy.excludeIPRanges` | `""` |  |
| `global.proxy.includeInboundPorts` | `"*"` |  |
| `global.proxy.excludeInboundPorts` | `""` |  |
| `global.proxy.autoInject` | `enabled` |  |
| `global.proxy.envoyStatsd.enabled` | `true` |  |
| `global.proxy.envoyStatsd.host` | `istio-statsd-prom-bridge` |  |
| `global.proxy.envoyStatsd.port` | `9125` |  |
| `global.proxy_init.image` | `proxy_init` |  |
| `global.imagePullPolicy` | `IfNotPresent` |  |
| `global.controlPlaneSecurityEnabled` | `true` |  |
| `global.disablePolicyChecks` | `false` |  |
| `global.enableTracing` | `true` |  |
| `global.mtls.enabled` | `true` |  |
| `global.arch.amd64` | `2` |  |
| `global.arch.s390x` | `2` |  |
| `global.arch.ppc64le` | `2` |  |
| `global.oneNamespace` | `false` |  |
| `global.configValidation` | `true` |  |
| `global.meshExpansion` | `false` |  |
| `global.meshExpansionILB` | `false` |  |
| `global.defaultResources.requests.cpu` | `10m` |  |
| `global.hyperkube.hub` | `quay.io/coreos` |  |
| `global.hyperkube.tag` | `v1.7.6_coreos.0` |  |
| `global.priorityClassName` | `""` |  |
| `global.crds` | `true` |  |

## `grafana` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `grafana.enabled` | `true` |  |
| `grafana.replicaCount` | `1` |  |
| `grafana.image` | `grafana` |  |
| `grafana.security.enabled` | `true` |  |
| `grafana.security.adminUser` | `admin` |  |
| `grafana.security.adminPassword` | `admin` |  |
| `grafana.service.annotations` | `{}` |  |
| `grafana.service.name` | `http` |  |
| `grafana.service.type` | `ClusterIP` |  |
| `grafana.service.externalPort` | `3000` |  |
| `grafana.service.internalPort` | `3000` |  |

## `ingress` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `ingress.enabled` | `true` |  |
| `ingress.replicaCount` | `1` |  |
| `ingress.autoscaleMin` | `1` |  |
| `ingress.autoscaleMax` | `5` |  |
| `ingress.service.annotations` | `{}` |  |
| `ingress.service.loadBalancerIP` | `""` |  |
| `ingress.service.type` | `LoadBalancer` | `如果需要，请更改为 NodePort，ClusterIP 或 LoadBalancer` |
| `ingress.service.ports.name` | `http` |  |
| `ingress.service.ports.nodePort` | `32000` |  |
| `ingress.service.ports.name` | `https` |  |
| `ingress.service.selector.istio` | `ingress` |  |

## `kiali` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `kiali.enabled` | `true` |  |
| `kiali.replicaCount` | `1` |  |
| `kiali.hub` | `docker.io/kiali` |  |
| `kiali.tag` | `istio-release-1.0` |  |
| `kiali.ingress.enabled` | `true` |  |
| `kiali.dashboard.username` | `admin` |  |
| `kiali.dashboard.passphrase` | `admin` |  |

## `mixer` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `mixer.enabled` | `true` |  |
| `mixer.replicaCount` | `1` |  |
| `mixer.autoscaleMin` | `1` |  |
| `mixer.autoscaleMax` | `5` |  |
| `mixer.image` | `mixer` |  |
| `mixer.istio-policy.autoscaleEnabled` | `true` |  |
| `mixer.istio-policy.autoscaleMin` | `1` |  |
| `mixer.istio-policy.autoscaleMax` | `5` |  |
| `mixer.istio-policy.cpu.targetAverageUtilization` | `80` |  |
| `mixer.istio-telemetry.autoscaleEnabled` | `true` |  |
| `mixer.istio-telemetry.autoscaleMin` | `1` |  |
| `mixer.istio-telemetry.autoscaleMax` | `5` |  |
| `mixer.istio-telemetry.cpu.targetAverageUtilization` | `80` |  |
| `mixer.prometheusStatsdExporter.hub` | `docker.io/prom` |  |
| `mixer.prometheusStatsdExporter.tag` | `v0.6.0` |  |

## `pilot` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `pilot.enabled` | `true` |  |
| `pilot.replicaCount` | `1` |  |
| `pilot.autoscaleMin` | `1` |  |
| `pilot.autoscaleMax` | `1` |  |
| `pilot.image` | `pilot` |  |
| `pilot.sidecar` | `true` |  |
| `pilot.traceSampling` | `100.0` |  |
| `pilot.resources.requests.cpu` | `500m` |  |
| `pilot.resources.requests.memory` | `2048Mi` |  |

## `prometheus` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `prometheus.enabled` | `true` |  |
| `prometheus.replicaCount` | `1` |  |
| `prometheus.hub` | `docker.io/prom` |  |
| `prometheus.tag` | `v2.3.1` |  |
| `prometheus.service.annotations` | `{}` |  |
| `prometheus.service.nodePort.enabled` | `false` |  |
| `prometheus.service.nodePort.port` | `32090` |  |

## `security` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `security.replicaCount` | `1` |  |
| `security.image` | `citadel` |  |
| `security.selfSigned` | `true` | `指示是否使用自签名 CA.` |

## `sidecarInjectorWebhook` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `sidecarInjectorWebhook.enabled` | `true` |  |
| `sidecarInjectorWebhook.replicaCount` | `1` |  |
| `sidecarInjectorWebhook.image` | `sidecar_injector` |  |
| `sidecarInjectorWebhook.enableNamespacesByDefault` | `false` |  |

## `telemetry-gateway` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `telemetry-gateway.gatewayName` | `ingressgateway` |  |
| `telemetry-gateway.grafanaEnabled` | `true` |  |
| `telemetry-gateway.prometheusEnabled` | `true` |  |

## `tracing` 选项

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `tracing.enabled` | `true` |  |
| `tracing.provider` | `jaeger` |  |
| `tracing.jaeger.hub` | `docker.io/jaegertracing` |  |
| `tracing.jaeger.tag` | `1.5` |  |
| `tracing.jaeger.memory.max_traces` | `50000` |  |
| `tracing.jaeger.ui.port` | `16686` |  |
| `tracing.replicaCount` | `1` |  |
| `tracing.service.annotations` | `{}` |  |
| `tracing.service.name` | `http` |  |
| `tracing.service.type` | `ClusterIP` |  |
| `tracing.service.externalPort` | `9411` |  |
| `tracing.service.internalPort` | `9411` |  |
| `tracing.ingress.enabled` | `false` |  |

<!-- AUTO-GENERATED-END -->








