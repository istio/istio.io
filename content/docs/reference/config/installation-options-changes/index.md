---
title: Installation Options Changes
description: Details the Helm chart installation options differences between release-1.0 and release-1.1.
weight: 30
keywords: [kubernetes, helm, install, options]
---

The tables below show changes made to the installation options used to customize Istio install using Helm between release 1.0 and release 1.1. The tables are grouped in to three different categories:

- The installation options already in the previous release but whose values or descriptions have been modified in the new release.
- The new installation options added in the new release.
- The installation options removed from the new release.

<!-- Run python scripts/tablegen.py to generate this table -->

<!-- AUTO-GENERATED-START -->

## Modified configuration options

### Modified `servicegraph` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `servicegraph.ingress.hosts` | `servicegraph.local` | `servicegraph.local` |  | `Used to create an Ingress record.` |

### Modified `tracing` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `tracing.jaeger.tag` | `1.5` | `1.9` |  |  |

### Modified `global` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `global.hub` | `gcr.io/istio-release` | `gcr.io/istio-release` |  | `Default hub for Istio images.Releases are published to docker hub under 'istio' project.Daily builds from prow are on gcr.io, and nightly builds from circle on docker.io/istionightly` |
| `global.tag` | `release-1.0-latest-daily` | `release-1.1-latest-daily` |  | `Default tag for Istio images.` |
| `global.proxy.resources.requests.cpu` | `10m` | `100m` |  |  |
| `global.proxy.accessLogFile` | `"/dev/stdout"` | `""` |  |  |
| `global.proxy.enableCoreDump` | `false` | `false` |  | `If set, newly injected sidecars will have core dumps enabled.` |
| `global.proxy.autoInject` | `enabled` | `enabled` |  | `This controls the 'policy' in the sidecar injector.` |
| `global.proxy.envoyStatsd.enabled` | `true` | `false` |  | `If enabled is set to true, host and port must also be provided. Istio no longer provides a statsd collector.` |
| `global.proxy.envoyStatsd.host` | `istio-statsd-prom-bridge` | `` |  | `example: statsd-svc.istio-system` |
| `global.proxy.envoyStatsd.port` | `9125` | `` |  | `example: 9125` |
| `global.proxy_init.image` | `proxy_init` | `proxy_init` |  | `Base name for the proxy_init container, used to configure iptables.` |
| `global.controlPlaneSecurityEnabled` | `false` | `false` |  | `controlPlaneMtls enabled. Will result in delays starting the pods while secrets arepropagated, not recommended for tests.` |
| `global.disablePolicyChecks` | `false` | `true` |  | `disablePolicyChecks disables mixer policy checks.if mixer.policy.enabled==true then disablePolicyChecks has affect.Will set the value with same name in istio config map - pilot needs to be restarted to take effect.` |
| `global.enableTracing` | `true` | `true` |  | `EnableTracing sets the value with same name in istio config map, requires pilot restart to take effect.` |
| `global.mtls.enabled` | `false` | `false` |  | `Default setting for service-to-service mtls. Can be set explicitly usingdestination rules or service annotations.` |
| `global.oneNamespace` | `false` | `false` |  | `Whether to restrict the applications namespace the controller manages;If not set, controller watches all namespaces` |
| `global.configValidation` | `true` | `true` |  | `Whether to perform server-side validation of configuration.` |

### Modified `gateways` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `gateways.istio-ingressgateway.type` | `LoadBalancer #change to NodePort, ClusterIP or LoadBalancer if need be` | `LoadBalancer` |  | `change to NodePort, ClusterIP or LoadBalancer if need be` |
| `gateways.istio-egressgateway.enabled` | `true` | `false` |  |  |
| `gateways.istio-egressgateway.type` | `ClusterIP #change to NodePort or LoadBalancer if need be` | `ClusterIP` |  | `change to NodePort or LoadBalancer if need be` |

### Modified `certmanager` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `certmanager.tag` | `v0.3.1` | `v0.6.2` |  |  |

### Modified `kiali` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `kiali.tag` | `istio-release-1.0` | `v0.14` |  |  |

### Modified `security` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `security.selfSigned` | `true # indicate if self-signed CA is used.` | `true` |  | `indicate if self-signed CA is used.` |

### Modified `pilot` key/value pairs

| Key | Old Default Value | New Default Value | Old Description | New Description |
| --- | --- | --- | --- | --- |
| `pilot.autoscaleMax` | `1` | `5` |  |  |
| `pilot.traceSampling` | `100.0` | `1.0` |  |  |

## New configuration options

### New `istio_cni` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `istio_cni.enabled` | `false` |  |

### New `servicegraph` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `servicegraph.nodeSelector` | `{}` |  |

### New `tracing` key/value pairs

| Key | Default Value | Description |
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

### New `sidecarInjectorWebhook` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `sidecarInjectorWebhook.nodeSelector` | `{}` |  |
| `sidecarInjectorWebhook.rewriteAppHTTPProbe` | `false` | `If true, webhook or istioctl injector will rewrite PodSpec for livenesshealth check to redirect request to sidecar. This makes liveness check workeven when mTLS is enabled.` |

### New `global` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `global.monitoringPort` | `15014` | `monitoring port used by mixer, pilot, galley` |
| `global.k8sIngress.enabled` | `false` |  |
| `global.k8sIngress.gatewayName` | `ingressgateway` | `Gateway used for k8s Ingress resources. By default it isusing 'istio:ingressgateway' that will be installed by setting'gateways.enabled' and 'gateways.istio-ingressgateway.enabled'flags to true.` |
| `global.k8sIngress.enableHttps` | `false` | `enableHttps will add port 443 on the ingress.It REQUIRES that the certificates are installed  in theexpected secrets - enabling this option without certificateswill result in LDS rejection and the ingress will not work.` |
| `global.proxy.clusterDomain` | `"cluster.local"` | `cluster domain. Default value is "cluster.local".` |
| `global.proxy.resources.requests.memory` | `128Mi` |  |
| `global.proxy.resources.limits.cpu` | `2000m` |  |
| `global.proxy.resources.limits.memory` | `128Mi` |  |
| `global.proxy.concurrency` | `2` | `Controls number of Proxy worker threads.If set to 0 (default), then start worker thread for each CPU thread/core.` |
| `global.proxy.accessLogFormat` | `""` | `Configure how and what fields are displayed in sidecar access log. Setting toempty string will result in default log format` |
| `global.proxy.accessLogEncoding` | `TEXT` | `Configure the access log for sidecar to JSON or TEXT.` |
| `global.proxy.dnsRefreshRate` | `5s` | `Configure the DNS refresh rate for Envoy cluster of type STRICT_DNS5 seconds is the default refresh rate used by Envoy` |
| `global.proxy.privileged` | `false` | `If set to true, istio-proxy container will have privileged securityContext` |
| `global.proxy.statusPort` | `15020` | `Default port for Pilot agent health checks. A value of 0 will disable health checking.` |
| `global.proxy.readinessInitialDelaySeconds` | `1` | `The initial delay for readiness probes in seconds.` |
| `global.proxy.readinessPeriodSeconds` | `2` | `The period between readiness probes.` |
| `global.proxy.readinessFailureThreshold` | `30` | `The number of successive failed probes before indicating readiness failure.` |
| `global.proxy.kubevirtInterfaces` | `""` | `pod internal interfaces` |
| `global.proxy.envoyMetricsService.enabled` | `false` |  |
| `global.proxy.envoyMetricsService.host` | `` | `example: metrics-service.istio-system` |
| `global.proxy.envoyMetricsService.port` | `` | `example: 15000` |
| `global.proxy.tracer` | `"zipkin"` | `Specify which tracer to use. One of: lightstep, zipkin` |
| `global.policyCheckFailOpen` | `false` | `policyCheckFailOpen allows traffic in cases when the mixer policy service cannot be reached.Default is false which means the traffic is denied when the client is unable to connect to Mixer.` |
| `global.tracer.lightstep.address` | `""` | `example: lightstep-satellite:443` |
| `global.tracer.lightstep.accessToken` | `""` | `example: abcdefg1234567` |
| `global.tracer.lightstep.secure` | `true` | `example: true\|false` |
| `global.tracer.lightstep.cacertPath` | `""` | `example: /etc/lightstep/cacert.pem` |
| `global.tracer.zipkin.address` | `""` |  |
| `global.defaultNodeSelector` | `{}` | `Default node selector to be applied to all deployments so that all pods can beconstrained to run a particular nodes. Each component can overwrite these defaultvalues by adding its node selector block in the relevant section below and settingthe desired values.` |
| `global.meshExpansion.enabled` | `false` |  |
| `global.meshExpansion.useILB` | `false` | `If set to true, the pilot and citadel mutual TLS and the plaintext Pilot ports will be exposed on an internal gateway` |
| `global.multiCluster.enabled` | `false` | `Set to true to connect two kubernetes clusters via their respectiveingressgateway services when pods in each cluster cannot directlytalk to one another. All clusters should be using Istio mTLS and musthave a shared root CA for this model to work.` |
| `global.defaultPodDisruptionBudget.enabled` | `true` |  |
| `global.useMCP` | `true` | `Use the Mesh Control Protocol (MCP) for configuring Mixer andPilot. Requires galley (--set galley.enabled=true).` |
| `global.trustDomain` | `""` |  |
| `global.outboundTrafficPolicy.mode` | `ALLOW_ANY` |  |
| `global.sds.enabled` | `false` | `SDS enabled. IF set to true, mTLS certificates for the sidecars will bedistributed through the SecretDiscoveryService instead of using K8S secrets to mount the certificates.` |
| `global.sds.udsPath` | `""` |  |
| `global.sds.useTrustworthyJwt` | `false` |  |
| `global.sds.useNormalJwt` | `false` |  |
| `global.meshNetworks` | `{}` |  |
| `global.enableHelmTest` | `false` | `Specifies whether helm test is enabled or not.This field is set to false by default, so 'helm template ...'will ignore the helm test yaml files when generating the template` |

### New `mixer` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `mixer.env.GODEBUG` | `gctrace=1` |  |
| `mixer.env.GOMAXPROCS` | `"6"` | `max procs should be ceil(cpu limit + 1)` |
| `mixer.policy.enabled` | `false` | `if policy is enabled, global.disablePolicyChecks has affect.` |
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
| `mixer.telemetry.loadshedding.mode` | `enforce` | `disabled, logonly or enforce` |
| `mixer.telemetry.loadshedding.latencyThreshold` | `100ms` | `based on measurements 100ms p50 translates to p99 of under 1s. This is ok for telemetry which is inherently async.` |
| `mixer.telemetry.resources.requests.cpu` | `1000m` |  |
| `mixer.telemetry.resources.requests.memory` | `1G` |  |
| `mixer.telemetry.resources.limits.cpu` | `4800m` | `It is best to do horizontal scaling of mixer using moderate cpu allocation.We have experimentally found that these values work well.` |
| `mixer.telemetry.resources.limits.memory` | `4G` |  |
| `mixer.podAnnotations` | `{}` |  |
| `mixer.nodeSelector` | `{}` |  |
| `mixer.adapters.kubernetesenv.enabled` | `true` |  |
| `mixer.adapters.stdio.enabled` | `false` |  |
| `mixer.adapters.stdio.outputAsJson` | `true` |  |
| `mixer.adapters.prometheus.enabled` | `true` |  |
| `mixer.adapters.prometheus.metricsExpiryDuration` | `10m` |  |
| `mixer.adapters.useAdapterCRDs` | `true` | `Setting this to false sets the useAdapterCRDs mixer startup argument to false` |

### New `grafana` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `grafana.image.repository` | `grafana/grafana` |  |
| `grafana.image.tag` | `5.4.0` |  |
| `grafana.ingress.enabled` | `false` |  |
| `grafana.ingress.hosts` | `grafana.local` | `Used to create an Ingress record.` |
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

### New `prometheus` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `prometheus.retention` | `6h` |  |
| `prometheus.nodeSelector` | `{}` |  |
| `prometheus.scrapeInterval` | `15s` | `Controls the frequency of prometheus scraping` |
| `prometheus.contextPath` | `/prometheus` |  |
| `prometheus.ingress.enabled` | `false` |  |
| `prometheus.ingress.hosts` | `prometheus.local` | `Used to create an Ingress record.` |
| `prometheus.security.enabled` | `true` |  |

### New `gateways` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `gateways.istio-ingressgateway.sds.enabled` | `false` | `If true, ingress gateway fetches credentials from SDS server to handle TLS connections.` |
| `gateways.istio-ingressgateway.sds.image` | `node-agent-k8s` | `SDS server that watches kubernetes secrets and provisions credentials to ingress gateway.This server runs in the same pod as ingress gateway.` |
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
| `gateways.istio-ingressgateway.env.ISTIO_META_ROUTER_MODE` | `"sni-dnat"` | `A gateway with this mode ensures that pilot generates an additionalset of clusters for internal services but without Istio mTLS, toenable cross cluster routing.` |
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

### New `kiali` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `kiali.contextPath` | `/kiali` |  |
| `kiali.nodeSelector` | `{}` |  |
| `kiali.ingress.hosts` | `kiali.local` | `Used to create an Ingress record.` |
| `kiali.dashboard.secretName` | `kiali` |  |
| `kiali.dashboard.usernameKey` | `username` |  |
| `kiali.dashboard.passphraseKey` | `passphrase` |  |
| `kiali.prometheusAddr` | `http://prometheus:9090` |  |
| `kiali.createDemoSecret` | `false` | `When true, a secret will be created with a default username and password. Useful for demos.` |

### New `istiocoredns` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `istiocoredns.enabled` | `false` |  |
| `istiocoredns.replicaCount` | `1` |  |
| `istiocoredns.coreDNSImage` | `coredns/coredns:1.1.2` |  |
| `istiocoredns.coreDNSPluginImage` | `istio/coredns-plugin:0.2-istio-1.1` |  |
| `istiocoredns.nodeSelector` | `{}` |  |

### New `security` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `security.enabled` | `true` |  |
| `security.createMeshPolicy` | `true` |  |
| `security.nodeSelector` | `{}` |  |

### New `nodeagent` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `nodeagent.enabled` | `false` |  |
| `nodeagent.image` | `node-agent-k8s` |  |
| `nodeagent.env.CA_PROVIDER` | `""` | `name of authentication provider.` |
| `nodeagent.env.CA_ADDR` | `""` | `CA endpoint.` |
| `nodeagent.env.Plugins` | `""` | `names of authentication provider's plugins.` |
| `nodeagent.nodeSelector` | `{}` |  |

### New `pilot` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `pilot.autoscaleEnabled` | `true` |  |
| `pilot.env.PILOT_PUSH_THROTTLE` | `100` |  |
| `pilot.env.GODEBUG` | `gctrace=1` |  |
| `pilot.cpu.targetAverageUtilization` | `80` |  |
| `pilot.nodeSelector` | `{}` |  |
| `pilot.keepaliveMaxServerConnectionAge` | `30m` | `The following is used to limit how long a sidecar can be connectedto a pilot. It balances out load across pilot instances at the cost ofincreasing system churn.` |

## Removed configuration options

### Removed `ingress` key/value pairs

| Key | Default Value | Description |
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

### Removed `servicegraph` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `servicegraph` | `servicegraph.local` |  |
| `servicegraph.ingress` | `servicegraph.local` |  |
| `servicegraph.service.internalPort` | `8088` |  |

### Removed `telemetry-gateway` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `telemetry-gateway.prometheusEnabled` | `false` |  |
| `telemetry-gateway.gatewayName` | `ingressgateway` |  |
| `telemetry-gateway.grafanaEnabled` | `false` |  |

### Removed `global` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `global.hyperkube.tag` | `v1.7.6_coreos.0` |  |
| `global.k8sIngressHttps` | `false` |  |
| `global.crds` | `true` |  |
| `global.hyperkube.hub` | `quay.io/coreos` |  |
| `global.meshExpansion` | `false` |  |
| `global.k8sIngressSelector` | `ingress` |  |
| `global.meshExpansionILB` | `false` |  |

### Removed `mixer` key/value pairs

| Key | Default Value | Description |
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

### Removed `grafana` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `grafana.image` | `grafana` |  |
| `grafana.service.internalPort` | `3000` |  |
| `grafana.security.adminPassword` | `admin` |  |
| `grafana.security.adminUser` | `admin` |  |

### Removed `gateways` key/value pairs

| Key | Default Value | Description |
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

### Removed `tracing` key/value pairs

| Key | Default Value | Description |
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

### Removed `kiali` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `kiali.dashboard.username` | `admin` |  |
| `kiali.dashboard.passphrase` | `admin` |  |

### Removed `pilot` key/value pairs

| Key | Default Value | Description |
| --- | --- | --- |
| `pilot.replicaCount` | `1` |  |

<!-- AUTO-GENERATED-END -->
