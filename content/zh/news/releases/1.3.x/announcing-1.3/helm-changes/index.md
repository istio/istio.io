---
title: Helm 安装参数变动表
description: 本文详细介绍了 Istio 1.2 系列到 Istio 1.3 系列之间的安装参数变化详情。
weight: 30
keywords: [kubernetes, helm, install, options]
aliases:
    - /zh/docs/reference/config/installation-options-changes
---

下表显示了在 Istio 1.2 版本到 Istio 1.3 版本之间使用 Helm 自定义安装 Istio 时参数变更，主要包含了三种类型的变更：

- 安装参数在 1.2 版本之前已经存在，但是值在新发布的 1.3 版本中进行了修改。
- 1.3 版本新加的参数。
- 1.3 版本删除的参数。

<!-- 下表是运行 python 脚本 scripts/tablegen.py 自动生成 -->

<!-- 自动生成开始 -->

## 修改的配置选项{#modified-configuration-options}

### 修改 `kiali` 键/值对{#modified-Kiali-key-value-pairs}

|  键   |  老的默认值    |   新的默认值     |   老的说明     |     新的说明    |
| --- | --- | --- | --- | --- |
| `kiali.tag` | `v0.20` | `v1.1.0` |  |  |

### 修改 `global` 键/值对{#modified-global-key-value-pairs}

|  键   |  老的默认值    |   新的默认值     |   老的说明     |     新的说明    |
| --- | --- | --- | --- | --- |
| `global.tag` | `1.2.0-rc.3` | `release-1.3-latest-daily` | `Istio 镜像默认 tag。` | `Istio 镜像默认 tag。` |

### 修改 `gateways` 键/值对{#modified-gateways-key-value-pairs}

|  键   |  老的默认值    |   新的默认值     |   老的说明     |     新的说明    |
| --- | --- | --- | --- | --- |
| `gateways.istio-egressgateway.resources.limits.memory` | `256Mi` | `1024Mi` |  |  |

### 修改 `tracing` 键/值对{#modified-tracing-key-value-pairs}

|  键   |  老的默认值    |   新的默认值     |   老的说明     |     新的说明    |
| --- | --- | --- | --- | --- |
| `tracing.jaeger.tag` | `1.9` | `1.12` |  |  |
| `tracing.zipkin.tag` | `2` | `2.14.2` |  |  |

## 新加的配置选项{#new-configuration-options}

### 添加 `tracing` 键/值对{#new-tracing-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `tracing.tolerations` | `[]` |  |
| `tracing.jaeger.image` | `all-in-one` |  |
| `tracing.jaeger.spanStorageType` | `badger` | `对于 all-in-one 模式镜像 spanStorageType 值可以是“memory”和“badger”` |
| `tracing.jaeger.persist` | `false` |  |
| `tracing.jaeger.storageClassName` | `""` |  |
| `tracing.jaeger.accessMode` | `ReadWriteMany` |  |
| `tracing.zipkin.image` | `zipkin` |  |

### 添加 `sidecarInjectorWebhook` 键/值对{#new-sidecar-injector-webhook-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `sidecarInjectorWebhook.rollingMaxSurge` | `100%` |  |
| `sidecarInjectorWebhook.rollingMaxUnavailable` | `25%` |  |
| `sidecarInjectorWebhook.tolerations` | `[]` |  |

### 添加 `global` 键/值对{#new-global-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `global.proxy.init.resources.limits.cpu` | `100m` |  |
| `global.proxy.init.resources.limits.memory` | `50Mi` |  |
| `global.proxy.init.resources.requests.cpu` | `10m` |  |
| `global.proxy.init.resources.requests.memory` | `10Mi` |  |
| `global.proxy.envoyAccessLogService.enabled` | `false` |  |
| `global.proxy.envoyAccessLogService.host` | `` | `例如：accesslog-service.istio-system` |
| `global.proxy.envoyAccessLogService.port` | `` | `例如：15000` |
| `global.proxy.envoyAccessLogService.tlsSettings.mode` | `DISABLE` | `DISABLE, SIMPLE, MUTUAL, ISTIO_MUTUAL` |
| `global.proxy.envoyAccessLogService.tlsSettings.clientCertificate` | `` | `例如: /etc/istio/als/cert-chain.pem` |
| `global.proxy.envoyAccessLogService.tlsSettings.privateKey` | `` | `例如：/etc/istio/als/key.pem` |
| `global.proxy.envoyAccessLogService.tlsSettings.caCertificates` | `` | `例如：/etc/istio/als/root-cert.pem` |
| `global.proxy.envoyAccessLogService.tlsSettings.sni` | `` | `例如： als.somedomain` |
| `global.proxy.envoyAccessLogService.tlsSettings.subjectAltNames` | `[]` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.probes` | `3` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.time` | `10s` |  |
| `global.proxy.envoyAccessLogService.tcpKeepalive.interval` | `10s` |  |
| `global.proxy.protocolDetectionTimeout` | `10ms` | `在服务端，自动协议检测使用一组启发式方法来确定连接是否正在使用 TLS，以及所使用的应用协议（例如，http vs tcp）。 这些试探法依赖于客户端发送第一次请求数。对于一些优先发现的协议，如 MySQL 协议，MongoDB 协议等等，Envoy 在完成协议检测超时情况下，默认为非 mTLS 的普通 TCP 流量。 设置此字段可调整 Envoy 等待客户端发送第一次请求数据时间。（必须 >= 1ms）` |
| `global.proxy.enableCoreDumpImage` | `ubuntu:xenial` | `当 "enableCoreDump" 设置为 true 的时候，启动核心存储的镜像` |
| `global.defaultTolerations` | `[]` | `节点的默认 tolerations 将应用于所有部署，以便可以将所有 Pod 调度到具有匹配 taints 的特定节点。每个组件都可以通过在下面的相关部分中添加其 tolerations block 并设置所需的值来覆盖这些默认值。如果希望将 Istio 控制平面的所有 Pod 都调度到具有指定 taints 的特定节点，请配置此字段。` |
| `global.meshID` | `""` | `MeshID 表示 Mesh 标识符。在可能会彼此交互的 mesh 之间，它应该是唯一的，但是并不需要是全局唯一的。例如，如果满足以下任一条件，则两个 mesh 必须具有不同的 MeshID：- Mesh 将遥测聚集在同一个地方。- Mesh 将联合在一起。- 策略将被另一个 Mesh 引用。管理员希望这些条件中的任何一种将来可能成为现实，因此应确保为其 Mesh 分配了不同的 MeshID。在多集群 Mesh 中，每个集群必须（手动或自动）配置为具有相同的 MeshID 值。如果现有集群“加入”到多集群 Mesh 则需要将其迁移到新的 MeshID。迁移的详细信息待定，并且在安装后更改 MeshID 可能是一项破坏性操作。如果 Mesh 管理者未指定值，则 Istio 将使用 Mesh “信任域”的值。最佳实践是选择适当的“信任域”值。` |
| `global.localityLbSetting.enabled` | `true` |  |

### 添加 `galley` 键/值对{#new-galley-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `galley.rollingMaxSurge` | `100%` |  |
| `galley.rollingMaxUnavailable` | `25%` |  |

### 添加 `mixer` 键/值对{#new-mixer-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `mixer.policy.rollingMaxSurge` | `100%` |  |
| `mixer.policy.rollingMaxUnavailable` | `25%` |  |
| `mixer.telemetry.rollingMaxSurge` | `100%` |  |
| `mixer.telemetry.rollingMaxUnavailable` | `25%` |  |
| `mixer.telemetry.reportBatchMaxEntries` | `100` | `将 reportBatchMaxEntries 设置为 0 表示使用默认的批处理行为（即每 100 个批处理一次）。 正值表示遥测数据发送到 mixer 服务器之前已批处理的请求数` |
| `mixer.telemetry.reportBatchMaxTime` | `1s` | `将 reportBatchMaxTime 设置为 0 以使用默认的批处理行为（即每 1 秒批处理一次）。 正值表示处理完上次请求并将遥测数据发送到 mixer 服务器后，进行下次批处理前的最大等待时间` |

### 添加 `grafana` 键/值对{#new-Grafana-key-value-pairs}

|  键   |         默认值     |        说明       |
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

### 添加 `prometheus` 键/值对{#new-Prometheus-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `prometheus.image` | `prometheus` |  |

### 添加 `gateways` 键/值对{#new-gateways-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `gateways.istio-ingressgateway.rollingMaxSurge` | `100%` |  |
| `gateways.istio-ingressgateway.rollingMaxUnavailable` | `25%` |  |
| `gateways.istio-egressgateway.rollingMaxSurge` | `100%` |  |
| `gateways.istio-egressgateway.rollingMaxUnavailable` | `25%` |  |
| `gateways.istio-ilbgateway.rollingMaxSurge` | `100%` |  |
| `gateways.istio-ilbgateway.rollingMaxUnavailable` | `25%` |  |

### 添加 `certmanager` 键/值对{#new-cert-manager-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `certmanager.image` | `cert-manager-controller` |  |

### 添加 `kiali` 键/值对{#new-Kiali-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `kiali.image` | `kiali` |  |
| `kiali.tolerations` | `[]` |  |
| `kiali.dashboard.auth.strategy` | `login` | `可以通过匿名，登录，或者是 openshift 方式` |
| `kiali.security.enabled` | `true` |  |
| `kiali.security.cert_file` | `/kiali-cert/cert-chain.pem` |  |
| `kiali.security.private_key_file` | `/kiali-cert/key.pem` |  |

### 添加 `istiocoredns` 键/值对{#new-Istio-core-DNS-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `istiocoredns.rollingMaxSurge` | `100%` |  |
| `istiocoredns.rollingMaxUnavailable` | `25%` |  |

### 添加 `security` 键/值对{#new-security-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `security.replicaCount` | `1` |  |
| `security.rollingMaxSurge` | `100%` |  |
| `security.rollingMaxUnavailable` | `25%` |  |
| `security.workloadCertTtl` | `2160h` | `90*24hour = 2160h` |
| `security.enableNamespacesByDefault` | `true` | `如果在给定命名空间上找不到 ca.istio.io/env 或 ca.istio.io/override 标签，则确定 Citadel 默认行为。 例如：考虑一个名为 “target” 的命名空间，该命名空间既没有 ca.istio.io/env 也没有 ca.istio.io/override 命名空间标签，为了确定是否为在 “target” 命名空间中创建的服务帐户生成 secret，Citadel 将采用此选项。如果在这种情况下此选项的值为 “true”，则将为 “target” 命名空间生成 secret。 如果此选项的值为“false”，则 Citadel 在创建服务帐户时不会生成机密信息。` |

### 添加 `pilot` 键/值对{#new-pilot-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `pilot.rollingMaxSurge` | `100%` |  |
| `pilot.rollingMaxUnavailable` | `25%` |  |
| `pilot.enableProtocolSniffing` | `false` | `如果启用了协议嗅探。默认为 false。` |

## 删除的配置选项{#removed-configuration-options}

### 删除 `global` 键/值对{#removed-global-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `global.sds.useTrustworthyJwt` | `false` |  |
| `global.sds.useNormalJwt` | `false` |  |
| `global.localityLbSetting` | `{}` |  |

### 删除 `mixer` 键/值对{#removed-mixer-key-value-pairs}

|  键   |         默认值     |        说明       |
| --- | --- | --- |
| `mixer.templates.seTemplateCRDs` | `false` |  |

### 删除 `grafana` 键/值对{#removed-Grafana-key-value-pairs}

|  键   |         默认值     |        说明       |
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

<!-- 自动生成结束-->
