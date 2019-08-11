---
title: Installation Options Changes
description: Details the Helm chart installation options differences between release-1.1 and release-1.2.
weight: 30
keywords: [kubernetes, helm, install, options]
---

The tables below show changes made to the installation options used to customize Istio install using Helm between release 1.1 and release 1.2. The tables are grouped in to three different categories:

- The installation options already in the previous release but whose values have been modified in the new release.
- The new installation options added in the new release.
- The installation options removed from the new release.

<!-- Run python scripts/tablegen.py to generate this table -->

<!-- AUTO-GENERATED-START -->

## Modified configuration options

### Modified `kiali` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `kiali.hub` | `docker.io/kiali` | `quay.io/kiali` |  |  |
| `kiali.tag` | `v0.14` | `v0.20` |  |  |

### Modified `prometheus` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `prometheus.tag` | `v2.3.1` | `v2.8.0` |  |  |

### Modified `global` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `global.tag` | `release-1.1-latest-daily` | `1.2.0-rc.3` | `Default tag for Istio images.`  | `Default tag for Istio images.` |
| `global.proxy.resources.limits.memory` | `128Mi` | `1024Mi` |  |  |
| `global.proxy.dnsRefreshRate` | `5s` | `300s` | `Configure the DNS refresh rate for Envoy cluster of type STRICT_DNS 5 seconds is the default refresh rate used by Envoy`  | `Configure the DNS refresh rate for Envoy cluster of type STRICT_DNS This must be given it terms of seconds. For example, 300s is valid but 5m is invalid.` |

### Modified `mixer` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `mixer.adapters.useAdapterCRDs` | `true` | `false` | `Setting this to false sets the useAdapterCRDs mixer startup argument to false`  | `Setting this to false sets the useAdapterCRDs mixer startup argument to false` |

### Modified `grafana` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `grafana.image.tag` | `5.4.0` | `6.1.6` |  |  |

## New configuration options

### New `tracing` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `tracing.podAntiAffinityLabelSelector` | `[]` |  |
| `tracing.podAntiAffinityTermLabelSelector` | `[]` |  |

### New `sidecarInjectorWebhook` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `sidecarInjectorWebhook.podAntiAffinityLabelSelector` | `[]` |  |
| `sidecarInjectorWebhook.podAntiAffinityTermLabelSelector` | `[]` |  |
| `sidecarInjectorWebhook.neverInjectSelector` | `[]` | `You can use the field called alwaysInjectSelector and neverInjectSelector which will always inject the sidecar or always skip the injection on pods that match that label selector, regardless of the global policy. See https://istio.io/docs/setup/kubernetes/additional-setup/sidecar-injection/more-control-adding-exceptions` |
| `sidecarInjectorWebhook.alwaysInjectSelector` | `[]` |  |

### New `global` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `global.logging.level` | `"default:info"` |  |
| `global.proxy.logLevel` | `""` | `Log level for proxy, applies to gateways and sidecars.  If left empty, "warning" is used. Expected values are: trace\|debug\|info\|warning\|error\|critical\|off` |
| `global.proxy.componentLogLevel` | `""` | `Per Component log level for proxy, applies to gateways and sidecars. If a component level is not set, then the global "logLevel" will be used. If left empty, "misc:error" is used.` |
| `global.proxy.excludeOutboundPorts` | `""` |  |
| `global.tracer.datadog.address` | `"$(HOST_IP):8126"` |  |
| `global.imagePullSecrets` | `[]` | `Lists the secrets you need to use to pull Istio images from a secure registry.` |
| `global.localityLbSetting` | `{}` |  |

### New `galley` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `galley.nodeSelector` | `{}` |  |
| `galley.tolerations` | `[]` |  |
| `galley.podAntiAffinityLabelSelector` | `[]` |  |
| `galley.podAntiAffinityTermLabelSelector` | `[]` |  |

### New `mixer` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `mixer.tolerations` | `[]` |  |
| `mixer.podAntiAffinityLabelSelector` | `[]` |  |
| `mixer.podAntiAffinityTermLabelSelector` | `[]` |  |
| `mixer.templates.useTemplateCRDs` | `false` |  |

### New `grafana` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `grafana.tolerations` | `[]` |  |
| `grafana.podAntiAffinityLabelSelector` | `[]` |  |
| `grafana.podAntiAffinityTermLabelSelector` | `[]` |  |

### New `prometheus` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `prometheus.tolerations` | `[]` |  |
| `prometheus.podAntiAffinityLabelSelector` | `[]` |  |
| `prometheus.podAntiAffinityTermLabelSelector` | `[]` |  |

### New `gateways` key/value pairs

| Key | Default Value | Description |
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

### New `certmanager` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `certmanager.replicaCount` | `1` |  |
| `certmanager.nodeSelector` | `{}` |  |
| `certmanager.tolerations` | `[]` |  |
| `certmanager.podAntiAffinityLabelSelector` | `[]` |  |
| `certmanager.podAntiAffinityTermLabelSelector` | `[]` |  |

### New `kiali` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `kiali.podAntiAffinityLabelSelector` | `[]` |  |
| `kiali.podAntiAffinityTermLabelSelector` | `[]` |  |
| `kiali.dashboard.viewOnlyMode` | `false` | `Bind the service account to a role with only read access` |

### New `istiocoredns` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `istiocoredns.tolerations` | `[]` |  |
| `istiocoredns.podAntiAffinityLabelSelector` | `[]` |  |
| `istiocoredns.podAntiAffinityTermLabelSelector` | `[]` |  |

### New `security` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `security.tolerations` | `[]` |  |
| `security.citadelHealthCheck` | `false` |  |
| `security.podAntiAffinityLabelSelector` | `[]` |  |
| `security.podAntiAffinityTermLabelSelector` | `[]` |  |

### New `nodeagent` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `nodeagent.tolerations` | `[]` |  |
| `nodeagent.podAntiAffinityLabelSelector` | `[]` |  |
| `nodeagent.podAntiAffinityTermLabelSelector` | `[]` |  |

### New `pilot` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `pilot.tolerations` | `[]` |  |
| `pilot.podAntiAffinityLabelSelector` | `[]` |  |
| `pilot.podAntiAffinityTermLabelSelector` | `[]` |  |

## Removed configuration options

### Removed `kiali` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `kiali.dashboard.usernameKey` | `username` | `This is the key name within the secret whose value is the actual username.`  |
| `kiali.dashboard.passphraseKey` | `passphrase` | `This is the key name within the secret whose value is the actual passphrase.`  |

### Removed `security` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `security.replicaCount` | `1` |  |

### Removed `gateways` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `gateways.istio-ingressgateway.resources` | `{}` |  |

### Removed `mixer` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `mixer.enabled` | `true` |  |

### Removed `servicegraph` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `servicegraph.ingress.enabled` | `false` |  |
| `servicegraph.service.name` | `http` |  |
| `servicegraph.replicaCount` | `1` |  |
| `servicegraph.service.type` | `ClusterIP` |  |
| `servicegraph.service.annotations` | `{}` |  |
| `servicegraph.enabled` | `false` |  |
| `servicegraph.image` | `servicegraph` |  |
| `servicegraph.service.externalPort` | `8088` |  |
| `servicegraph.ingress.hosts` | `servicegraph.local` | `Used to create an Ingress record.`  |
| `servicegraph.nodeSelector` | `{}` |  |
| `servicegraph.prometheusAddr` | `http://prometheus:9090` |  |

<!-- AUTO-GENERATED-END -->
