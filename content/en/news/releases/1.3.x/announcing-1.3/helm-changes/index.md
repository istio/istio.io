---
title: Helm Changes
description: Details the Helm chart installation options differences between Istio 1.2 and Istio 1.3.
weight: 30
keywords: [kubernetes, helm, install, options]
aliases:
    - /docs/reference/config/installation-options-changes
---

The tables below show changes made to the installation options used to customize Istio install using Helm between Istio 1.2 and Istio 1.3. The tables are grouped in to three different categories:

- The installation options already in the previous release but whose values have been modified in the new release.
- The new installation options added in the new release.
- The installation options removed from the new release.

<!-- Run python scripts/tablegen.py to generate this table -->

<!-- AUTO-GENERATED-START -->

## Modified configuration options

### Modified `kiali` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `kiali.tag` | `v0.20` | `v1.1.0` |  |  |

### Modified `global` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `global.tag` | `1.2.0-rc.3` | `release-1.3-latest-daily` | `Default tag for Istio images.`  | `Default tag for Istio images.` |

### Modified `gateways` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `gateways.istio-egressgateway.resources.limits.memory` | `256Mi` | `1024Mi` |  |  |

### Modified `tracing` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `tracing.jaeger.tag` | `1.9` | `1.12` |  |  |
| `tracing.zipkin.tag` | `2` | `2.14.2` |  |  |

## New configuration options

### New `tracing` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `tracing.tolerations` | `[]` |  |
| `tracing.jaeger.image` | `all-in-one` |  |
| `tracing.jaeger.spanStorageType` | `badger` | `spanStorageType value can be "memory" and "badger" for all-in-one image` |
| `tracing.jaeger.persist` | `false` |  |
| `tracing.jaeger.storageClassName` | `""` |  |
| `tracing.jaeger.accessMode` | `ReadWriteMany` |  |
| `tracing.zipkin.image` | `zipkin` |  |

### New `sidecarInjectorWebhook` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `sidecarInjectorWebhook.rollingMaxSurge` | `100%` |  |
| `sidecarInjectorWebhook.rollingMaxUnavailable` | `25%` |  |
| `sidecarInjectorWebhook.tolerations` | `[]` |  |

### New `global` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `global.proxy.init.resources.limits.cpu` | `100m` |  |
| `global.proxy.init.resources.limits.memory` | `50Mi` |  |
| `global.proxy.init.resources.requests.cpu` | `10m` |  |
| `global.proxy.init.resources.requests.memory` | `10Mi` |  |
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
| `global.proxy.protocolDetectionTimeout` | `10ms` | `Automatic protocol detection uses a set of heuristics to determine whether the connection is using TLS or not (on the server side), as well as the application protocol being used (e.g., http vs tcp). These heuristics rely on the client sending the first bits of data. For server first protocols like MySQL, MongoDB, etc., Envoy will timeout on the protocol detection after the specified period, defaulting to non mTLS plain TCP traffic. Set this field to tweak the period that Envoy will wait for the client to send the first bits of data. (MUST BE >=1ms)` |
| `global.proxy.enableCoreDumpImage` | `ubuntu:xenial` | `Image used to enable core dumps. This is only used, when "enableCoreDump" is set to true.` |
| `global.defaultTolerations` | `[]` | `Default node tolerations to be applied to all deployments so that all pods can be scheduled to a particular nodes with matching taints. Each component can overwrite these default values by adding its tolerations block in the relevant section below and setting the desired values. Configure this field in case that all pods of Istio control plane are expected to be scheduled to particular nodes with specified taints.` |
| `global.meshID` | `""` | `Mesh ID means Mesh Identifier. It should be unique within the scope where meshes will interact with each other, but it is not required to be globally/universally unique. For example, if any of the following are true, then two meshes must have different Mesh IDs: - Meshes will have their telemetry aggregated in one place - Meshes will be federated together - Policy will be written referencing one mesh from the other If an administrator expects that any of these conditions may become true in the future, they should ensure their meshes have different Mesh IDs assigned. Within a multicluster mesh, each cluster must be (manually or auto) configured to have the same Mesh ID value. If an existing cluster 'joins' a multicluster mesh, it will need to be migrated to the new mesh ID. Details of migration TBD, and it may be a disruptive operation to change the Mesh ID post-install. If the mesh admin does not specify a value, Istio will use the value of the mesh's Trust Domain. The best practice is to select a proper Trust Domain value.` |
| `global.localityLbSetting.enabled` | `true` |  |

### New `galley` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `galley.rollingMaxSurge` | `100%` |  |
| `galley.rollingMaxUnavailable` | `25%` |  |

### New `mixer` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `mixer.policy.rollingMaxSurge` | `100%` |  |
| `mixer.policy.rollingMaxUnavailable` | `25%` |  |
| `mixer.telemetry.rollingMaxSurge` | `100%` |  |
| `mixer.telemetry.rollingMaxUnavailable` | `25%` |  |
| `mixer.telemetry.reportBatchMaxEntries` | `100` | `Set reportBatchMaxEntries to 0 to use the default batching behavior (i.e., every 100 requests). A positive value indicates the number of requests that are batched before telemetry data is sent to the mixer server` |
| `mixer.telemetry.reportBatchMaxTime` | `1s` | `Set reportBatchMaxTime to 0 to use the default batching behavior (i.e., every 1 second). A positive time value indicates the maximum wait time since the last request will telemetry data be batched before being sent to the mixer server` |

### New `grafana` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `grafana.env` | `{}` |  |
| `grafana.envSecrets` | `{}` |  |
| `grafana.datasources.datasources.datasources.type.orgId` | `1` |  |
| `grafana.datasources.datasources.datasources.type.url` | `http://prometheus:9090` |  |
| `grafana.datasources.datasources.datasources.type.access` | `proxy` |  |
| `grafana.datasources.datasources.datasources.type.isDefault` | `true` |  |
| `grafana.datasources.datasources.datasources.type.jsonData.timeInterval` | `5s` |  |
| `grafana.datasources.datasources.datasources.type.editable` | `true` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.orgId.folder` | `'istio'` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.orgId.type` | `file` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.orgId.disableDeletion` | `false` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.orgId.options.path` | `/var/lib/grafana/dashboards/istio` |  |

### New `prometheus` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `prometheus.image` | `prometheus` |  |

### New `gateways` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `gateways.istio-ingressgateway.rollingMaxSurge` | `100%` |  |
| `gateways.istio-ingressgateway.rollingMaxUnavailable` | `25%` |  |
| `gateways.istio-egressgateway.rollingMaxSurge` | `100%` |  |
| `gateways.istio-egressgateway.rollingMaxUnavailable` | `25%` |  |
| `gateways.istio-ilbgateway.rollingMaxSurge` | `100%` |  |
| `gateways.istio-ilbgateway.rollingMaxUnavailable` | `25%` |  |

### New `certmanager` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `certmanager.image` | `cert-manager-controller` |  |

### New `kiali` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `kiali.image` | `kiali` |  |
| `kiali.tolerations` | `[]` |  |
| `kiali.dashboard.auth.strategy` | `login` | `Can be anonymous, login, or openshift` |
| `kiali.security.enabled` | `true` |  |
| `kiali.security.cert_file` | `/kiali-cert/cert-chain.pem` |  |
| `kiali.security.private_key_file` | `/kiali-cert/key.pem` |  |

### New `istiocoredns` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `istiocoredns.rollingMaxSurge` | `100%` |  |
| `istiocoredns.rollingMaxUnavailable` | `25%` |  |

### New `security` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `security.replicaCount` | `1` |  |
| `security.rollingMaxSurge` | `100%` |  |
| `security.rollingMaxUnavailable` | `25%` |  |
| `security.workloadCertTtl` | `2160h` | `90*24hour = 2160h` |
| `security.enableNamespacesByDefault` | `true` | `Determines Citadel default behavior if the ca.istio.io/env or ca.istio.io/override labels are not found on a given namespace. For example: consider a namespace called "target", which has neither the "ca.istio.io/env" nor the "ca.istio.io/override" namespace labels. To decide whether or not to generate secrets for service accounts created in this "target" namespace, Citadel will defer to this option. If the value of this option is "true" in this case, secrets will be generated for the "target" namespace. If the value of this option is "false" Citadel will not generate secrets upon service account creation.` |

### New `pilot` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `pilot.rollingMaxSurge` | `100%` |  |
| `pilot.rollingMaxUnavailable` | `25%` |  |
| `pilot.enableProtocolSniffing` | `false` | `if protocol sniffing is enabled. Default to false.` |

## Removed configuration options

### Removed `global` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `global.sds.useTrustworthyJwt` | `false` |  |
| `global.sds.useNormalJwt` | `false` |  |
| `global.localityLbSetting` | `{}` |  |

### Removed `mixer` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `mixer.templates.useTemplateCRDs` | `false` |  |

### Removed `grafana` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `grafana.dashboardProviders.dashboardproviders.providers.disableDeletion` | `false` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.type` | `file` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.folder` | `'istio'` |  |
| `grafana.datasources.datasources.datasources.isDefault` | `true` |  |
| `grafana.datasources.datasources.datasources.url` | `http://prometheus:9090` |  |
| `grafana.datasources.datasources.datasources.access` | `proxy` |  |
| `grafana.datasources.datasources.datasources.jsonData.timeInterval` | `5s` |  |
| `grafana.dashboardProviders.dashboardproviders.providers.options.path` | `/var/lib/grafana/dashboards/istio` |  |
| `grafana.datasources.datasources.datasources.editable` | `true` |  |
| `grafana.datasources.datasources.datasources.orgId` | `1` |  |

<!-- AUTO-GENERATED-END -->
