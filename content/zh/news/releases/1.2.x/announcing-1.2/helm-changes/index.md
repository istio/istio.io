---
title: Helm Changes
description: Details the Helm chart installation options differences between Istio 1.1 and Istio 1.2.
weight: 30
keywords: [kubernetes, helm, install, options]
---

下面的表格展示了 Istio 1.2 相比于 Istio 1.1 在使用 Helm 安装时关于自定义安装选项的一些变化。表格分为三类：

- 安装选项在之前发行版本中就已经有了，但是在新发行版本中对其值作了修改。
- 在新发行版本中增加的安装选项。
- 在新发行版本中被移除的安装选项。

<!-- Run python scripts/tablegen.py to generate this table -->

<!-- AUTO-GENERATED-START -->

## 作了修改的配置选项{#modified-configuration-options}

### 修改 `kiali` 键值对{#modified-Kiali-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `kiali.hub` | `docker.io/kiali` | `quay.io/kiali` |  |  |
| `kiali.tag` | `v0.14` | `v0.20` |  |  |

### 修改 `prometheus` 键值对{#modified-Prometheus-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `prometheus.tag` | `v2.3.1` | `v2.8.0` |  |  |

### 修改 `global` 键值对{#modified-global-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `global.tag` | `release-1.1-latest-daily` | `1.2.0-rc.3` | `Istio 镜像的默认标签。` | `Istio 镜像的默认标签。` |
| `global.proxy.resources.limits.memory` | `128Mi` | `1024Mi` |  |  |
| `global.proxy.dnsRefreshRate` | `5s` | `300s` | `配置 STRICT_DNS 类型的 Envoy 集群的 DNS 刷新速率，默认值为 5 秒` | `配置 STRICT_DNS 类型的 Envoy 集群的 DNS 刷新速率，单位必须为秒。例如，可以 设为 300s，不能设为 5m` |

### 修改 `mixer` 键值对{#modified-mixer-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `mixer.adapters.useAdapterCRDs` | `true` | `false` | `如果设这个值为 false，则 useAdapterCRDs mixer 的起始参数为 false` | `如果设这个值为 false，则 useAdapterCRDs mixer 的起始参数为 false` |

### 修改 `grafana` 键值对{#modified-Grafana-key-value-pairs}

| 键 | 旧默认值 | 新默认值 | 旧描述 | 新描述 |
| --- | --- | --- | --- | --- |
| `grafana.image.tag` | `5.4.0` | `6.1.6` |  |  |

## 新增的配置选项{#new-configuration-options}

### 新增 `tracing` 键值对{#new-tracing-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `tracing.podAntiAffinityLabelSelector` | `[]` |  |
| `tracing.podAntiAffinityTermLabelSelector` | `[]` |  |

### 新增 `sidecarInjectorWebhook` 键值对{#new-sidecar-injector-webhook-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `sidecarInjectorWebhook.podAntiAffinityLabelSelector` | `[]` |  |
| `sidecarInjectorWebhook.podAntiAffinityTermLabelSelector` | `[]` |  |
| `sidecarInjectorWebhook.neverInjectSelector` | `[]` | `你可以用alwaysInjectSelector 和 neverInjectSelector 两个值，分别表示强制注入 sidecar 和无视全局策略，跳过符合标签过滤条件的 pod。请查看 https://istio.io/docs/setup/kubernetes/additional-setup/sidecar-injection/more-control-adding-exceptions` |
| `sidecarInjectorWebhook.alwaysInjectSelector` | `[]` |  |

### 新增 `global` 键值对{#new-global-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `global.logging.level` | `"default:info"` |  |
| `global.proxy.logLevel` | `""` | `代理的 log 等级，用于 gateway 和 sidecar。如果值为空，则使用 "warning"。可选的值为：trace\|debug\|info\|warning\|error\|critical\|off` |
| `global.proxy.componentLogLevel` | `""` | `代理的每一个组件的 log 等级，用于 gateway 和 sidecar。如果组件等级未设置，则使用全局的 "logLevel"。如果设置值为空，则使用 "misc:error"。` |
| `global.proxy.excludeOutboundPorts` | `""` |  |
| `global.tracer.datadog.address` | `"$(HOST_IP):8126"` |  |
| `global.imagePullSecrets` | `[]` | `列出你从一个安全的镜像仓库拉取 Istio 镜像时需要用的 secret` |
| `global.localityLbSetting` | `{}` |  |

### 新增 `galley` 键值对{#new-galley-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `galley.nodeSelector` | `{}` |  |
| `galley.tolerations` | `[]` |  |
| `galley.podAntiAffinityLabelSelector` | `[]` |  |
| `galley.podAntiAffinityTermLabelSelector` | `[]` |  |

### 新增 `mixer` 键值对

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `mixer.tolerations` | `[]` |  |
| `mixer.podAntiAffinityLabelSelector` | `[]` |  |
| `mixer.podAntiAffinityTermLabelSelector` | `[]` |  |
| `mixer.templates.useTemplateCRDs` | `false` |  |

### 新增 `grafana` 键值对{#new-Grafana-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `grafana.tolerations` | `[]` |  |
| `grafana.podAntiAffinityLabelSelector` | `[]` |  |
| `grafana.podAntiAffinityTermLabelSelector` | `[]` |  |

### 新增 `prometheus` 键值对{#new-Prometheus-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `prometheus.tolerations` | `[]` |  |
| `prometheus.podAntiAffinityLabelSelector` | `[]` |  |
| `prometheus.podAntiAffinityTermLabelSelector` | `[]` |  |

### 新增 `gateways` 键值对{#new-gateways-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `gateways.istio-ingressgateway.sds.resources.requests.cpu` | `100m` |  |
| `gateways.istio-ingressgateway.sds.resources.requests.memory` | `128Mi` |  |
| `gateways.istio-ingressgateway.sds.resources.limits.cpu` | `2000m` |  |
| `gateways.istio-ingressgateway.sds.resources.limits.memory` | `1024Mi` |  |
| `gateways.istio-ingressgateway.resources.requests.cpu` | `100m` |  |
| `gateways.istio-ingressgateway.resources.requests.memory` | `128Mi` |  |
| `gateways.istio-ingressgateway.resources.limits.cpu` | `2000m` |  |
| `gateways.istio-ingressgateway.resources.limits.memory` | `1024Mi` |  |
| `gateways.istio-ingressgateway.applicationPorts` | `""` |  |
| `gateways.istio-ingressgateway.tolerations` | `[]` |  |
| `gateways.istio-ingressgateway.podAntiAffinityLabelSelector` | `[]` |  |
| `gateways.istio-ingressgateway.podAntiAffinityTermLabelSelector` | `[]` |  |
| `gateways.istio-egressgateway.resources.requests.cpu` | `100m` |  |
| `gateways.istio-egressgateway.resources.requests.memory` | `128Mi` |  |
| `gateways.istio-egressgateway.resources.limits.cpu` | `2000m` |  |
| `gateways.istio-egressgateway.resources.limits.memory` | `256Mi` |  |
| `gateways.istio-egressgateway.tolerations` | `[]` |  |
| `gateways.istio-egressgateway.podAntiAffinityLabelSelector` | `[]` |  |
| `gateways.istio-egressgateway.podAntiAffinityTermLabelSelector` | `[]` |  |
| `gateways.istio-ilbgateway.tolerations` | `[]` |  |

### 新增 `certmanager` 键值对{#new-cert-manager-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `certmanager.replicaCount` | `1` |  |
| `certmanager.nodeSelector` | `{}` |  |
| `certmanager.tolerations` | `[]` |  |
| `certmanager.podAntiAffinityLabelSelector` | `[]` |  |
| `certmanager.podAntiAffinityTermLabelSelector` | `[]` |  |

### 新增 `kiali` 键值对{#new-Kiali-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `kiali.podAntiAffinityLabelSelector` | `[]` |  |
| `kiali.podAntiAffinityTermLabelSelector` | `[]` |  |
| `kiali.dashboard.viewOnlyMode` | `false` | `将一个服务账户与一个只读的角色绑定` |

### 新增 `istiocoredns` 键值对{#new-Istio-CoreDNS-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `istiocoredns.tolerations` | `[]` |  |
| `istiocoredns.podAntiAffinityLabelSelector` | `[]` |  |
| `istiocoredns.podAntiAffinityTermLabelSelector` | `[]` |  |

### 新增 `security` 键值对{#new-security-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `security.tolerations` | `[]` |  |
| `security.citadelHealthCheck` | `false` |  |
| `security.podAntiAffinityLabelSelector` | `[]` |  |
| `security.podAntiAffinityTermLabelSelector` | `[]` |  |

### 新增 `nodeagent` 键值对{#new-node-agent-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `nodeagent.tolerations` | `[]` |  |
| `nodeagent.podAntiAffinityLabelSelector` | `[]` |  |
| `nodeagent.podAntiAffinityTermLabelSelector` | `[]` |  |

### 新增 `pilot` 键值对{#new-pilot-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `pilot.tolerations` | `[]` |  |
| `pilot.podAntiAffinityLabelSelector` | `[]` |  |
| `pilot.podAntiAffinityTermLabelSelector` | `[]` |  |

## 被移除的配置选项{#removed-configuration-options}

### 移除 `kiali` 键值对{#removed-Kiali-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `kiali.dashboard.usernameKey` | `username` | `secret 中用户名的键名。` |
| `kiali.dashboard.passphraseKey` | `passphrase` | `secret 中密码的键名。` |

### 移除 `security` 键值对{#removed-security-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `security.replicaCount` | `1` |  |

### 移除 `gateways` 键值对{#removed-gateways-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `gateways.istio-ingressgateway.resources` | `{}` |  |

### 移除 `mixer` 键值对{#removed-mixer-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `mixer.enabled` | `true` |  |

### 移除 `servicegraph` 键值对{#removed-service-graph-key-value-pairs}

| 键 | 默认值 | 描述 |
| --- | --- | --- |
| `servicegraph.ingress.enabled` | `false` |  |
| `servicegraph.service.name` | `http` |  |
| `servicegraph.replicaCount` | `1` |  |
| `servicegraph.service.type` | `ClusterIP` |  |
| `servicegraph.service.annotations` | `{}` |  |
| `servicegraph.enabled` | `false` |  |
| `servicegraph.image` | `servicegraph` |  |
| `servicegraph.service.externalPort` | `8088` |  |
| `servicegraph.ingress.hosts` | `servicegraph.local` | `用来创建一条进入记录` |
| `servicegraph.nodeSelector` | `{}` |  |
| `servicegraph.prometheusAddr` | `http://prometheus:9090` |  |

<!-- AUTO-GENERATED-END -->
