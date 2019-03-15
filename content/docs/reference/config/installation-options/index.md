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
| `certmanager.tag` | `v0.6.2` |  |
| `certmanager.resources` | `{}` |  |

## `galley` options

| Key | Default Value | Description |
| --- | --- | --- |
| `galley.enabled` | `true` |  |
| `galley.replicaCount` | `1` |  |
| `galley.image` | `galley` |  |

## `gateways` options

| Key | Default Value | Description |
| --- | --- | --- |
| `gateways.enabled` | `true` |  |
| `gateways.istio-ingressgateway.enabled` | `true` |  |
| `gateways.istio-ingressgateway.sds.enabled` | `false` | `If true, ingress gateway fetches credentials from SDS server to handle TLS connections.` |
| `gateways.istio-ingressgateway.sds.image` | `node-agent-k8s` | `SDS server that watches kubernetes secrets and provisions credentials to ingress gateway.This server runs in the same pod as ingress gateway.` |
| `gateways.istio-ingressgateway.labels.app` | `istio-ingressgateway` |  |
| `gateways.istio-ingressgateway.labels.istio` | `ingressgateway` |  |
| `gateways.istio-ingressgateway.autoscaleEnabled` | `true` |  |
| `gateways.istio-ingressgateway.autoscaleMin` | `1` |  |
| `gateways.istio-ingressgateway.autoscaleMax` | `5` |  |
| `gateways.istio-ingressgateway.resources` | `{}` |  |
| `gateways.istio-ingressgateway.cpu.targetAverageUtilization` | `80` |  |
| `gateways.istio-ingressgateway.loadBalancerIP` | `""` |  |
| `gateways.istio-ingressgateway.loadBalancerSourceRanges` | `[]` |  |
| `gateways.istio-ingressgateway.externalIPs` | `[]` |  |
| `gateways.istio-ingressgateway.serviceAnnotations` | `{}` |  |
| `gateways.istio-ingressgateway.podAnnotations` | `{}` |  |
| `gateways.istio-ingressgateway.type` | `LoadBalancer` | `change to NodePort, ClusterIP or LoadBalancer if need be` |
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
| `gateways.istio-ingressgateway.secretVolumes.secretName` | `istio-ingressgateway-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.mountPath` | `/etc/istio/ingressgateway-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.secretName` | `istio-ingressgateway-ca-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.mountPath` | `/etc/istio/ingressgateway-ca-certs` |  |
| `gateways.istio-ingressgateway.env.ISTIO_META_ROUTER_MODE` | `"sni-dnat"` | `A gateway with this mode ensures that pilot generates an additionalset of clusters for internal services but without Istio mTLS, toenable cross cluster routing.` |
| `gateways.istio-ingressgateway.nodeSelector` | `{}` |  |
| `gateways.istio-egressgateway.enabled` | `false` |  |
| `gateways.istio-egressgateway.labels.app` | `istio-egressgateway` |  |
| `gateways.istio-egressgateway.labels.istio` | `egressgateway` |  |
| `gateways.istio-egressgateway.autoscaleEnabled` | `true` |  |
| `gateways.istio-egressgateway.autoscaleMin` | `1` |  |
| `gateways.istio-egressgateway.autoscaleMax` | `5` |  |
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
| `gateways.istio-ilbgateway.enabled` | `false` |  |
| `gateways.istio-ilbgateway.labels.app` | `istio-ilbgateway` |  |
| `gateways.istio-ilbgateway.labels.istio` | `ilbgateway` |  |
| `gateways.istio-ilbgateway.autoscaleEnabled` | `true` |  |
| `gateways.istio-ilbgateway.autoscaleMin` | `1` |  |
| `gateways.istio-ilbgateway.autoscaleMax` | `5` |  |
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

## `global` options

| Key | Default Value | Description |
| --- | --- | --- |
| `global.hub` | `gcr.io/istio-release` | `Default hub for Istio images.Releases are published to docker hub under 'istio' project.Daily builds from prow are on gcr.io, and nightly builds from circle on docker.io/istionightly` |
| `global.tag` | `release-1.1-latest-daily` | `Default tag for Istio images.` |
| `global.monitoringPort` | `15014` | `monitoring port used by mixer, pilot, galley` |
| `global.k8sIngress.enabled` | `false` |  |
| `global.k8sIngress.gatewayName` | `ingressgateway` | `Gateway used for k8s Ingress resources. By default it isusing 'istio:ingressgateway' that will be installed by setting'gateways.enabled' and 'gateways.istio-ingressgateway.enabled'flags to true.` |
| `global.k8sIngress.enableHttps` | `false` | `enableHttps will add port 443 on the ingress.It REQUIRES that the certificates are installed  in theexpected secrets - enabling this option without certificateswill result in LDS rejection and the ingress will not work.` |
| `global.proxy.image` | `proxyv2` |  |
| `global.proxy.clusterDomain` | `"cluster.local"` | `cluster domain. Default value is "cluster.local".` |
| `global.proxy.resources.requests.cpu` | `100m` |  |
| `global.proxy.resources.requests.memory` | `128Mi` |  |
| `global.proxy.resources.limits.cpu` | `2000m` |  |
| `global.proxy.resources.limits.memory` | `128Mi` |  |
| `global.proxy.concurrency` | `2` | `Controls number of Proxy worker threads.If set to 0 (default), then start worker thread for each CPU thread/core.` |
| `global.proxy.accessLogFile` | `""` |  |
| `global.proxy.accessLogFormat` | `""` | `Configure how and what fields are displayed in sidecar access log. Setting toempty string will result in default log format` |
| `global.proxy.accessLogEncoding` | `TEXT` | `Configure the access log for sidecar to JSON or TEXT.` |
| `global.proxy.dnsRefreshRate` | `5s` | `Configure the DNS refresh rate for Envoy cluster of type STRICT_DNS5 seconds is the default refresh rate used by Envoy` |
| `global.proxy.privileged` | `false` | `If set to true, istio-proxy container will have privileged securityContext` |
| `global.proxy.enableCoreDump` | `false` | `If set, newly injected sidecars will have core dumps enabled.` |
| `global.proxy.statusPort` | `15020` | `Default port for Pilot agent health checks. A value of 0 will disable health checking.` |
| `global.proxy.readinessInitialDelaySeconds` | `1` | `The initial delay for readiness probes in seconds.` |
| `global.proxy.readinessPeriodSeconds` | `2` | `The period between readiness probes.` |
| `global.proxy.readinessFailureThreshold` | `30` | `The number of successive failed probes before indicating readiness failure.` |
| `global.proxy.includeIPRanges` | `"*"` |  |
| `global.proxy.excludeIPRanges` | `""` |  |
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
| `global.proxy.tracer` | `"zipkin"` | `Specify which tracer to use. One of: lightstep, zipkin` |
| `global.proxy_init.image` | `proxy_init` | `Base name for the proxy_init container, used to configure iptables.` |
| `global.imagePullPolicy` | `IfNotPresent` |  |
| `global.controlPlaneSecurityEnabled` | `false` | `controlPlaneMtls enabled. Will result in delays starting the pods while secrets arepropagated, not recommended for tests.` |
| `global.disablePolicyChecks` | `true` | `disablePolicyChecks disables mixer policy checks.if mixer.policy.enabled==true then disablePolicyChecks has affect.Will set the value with same name in istio config map - pilot needs to be restarted to take effect.` |
| `global.policyCheckFailOpen` | `false` | `policyCheckFailOpen allows traffic in cases when the mixer policy service cannot be reached.Default is false which means the traffic is denied when the client is unable to connect to Mixer.` |
| `global.enableTracing` | `true` | `EnableTracing sets the value with same name in istio config map, requires pilot restart to take effect.` |
| `global.tracer.lightstep.address` | `""` | `example: lightstep-satellite:443` |
| `global.tracer.lightstep.accessToken` | `""` | `example: abcdefg1234567` |
| `global.tracer.lightstep.secure` | `true` | `example: true\|false` |
| `global.tracer.lightstep.cacertPath` | `""` | `example: /etc/lightstep/cacert.pem` |
| `global.tracer.zipkin.address` | `""` |  |
| `global.mtls.enabled` | `false` | `Default setting for service-to-service mtls. Can be set explicitly usingdestination rules or service annotations.` |
| `global.arch.amd64` | `2` |  |
| `global.arch.s390x` | `2` |  |
| `global.arch.ppc64le` | `2` |  |
| `global.oneNamespace` | `false` | `Whether to restrict the applications namespace the controller manages;If not set, controller watches all namespaces` |
| `global.defaultNodeSelector` | `{}` | `Default node selector to be applied to all deployments so that all pods can beconstrained to run a particular nodes. Each component can overwrite these defaultvalues by adding its node selector block in the relevant section below and settingthe desired values.` |
| `global.configValidation` | `true` | `Whether to perform server-side validation of configuration.` |
| `global.meshExpansion.enabled` | `false` |  |
| `global.meshExpansion.useILB` | `false` | `If set to true, the pilot and citadel mtls and the plain text pilot portswill be exposed on an internal gateway` |
| `global.multiCluster.enabled` | `false` | `Set to true to connect two kubernetes clusters via their respectiveingressgateway services when pods in each cluster cannot directlytalk to one another. All clusters should be using Istio mTLS and musthave a shared root CA for this model to work.` |
| `global.defaultResources.requests.cpu` | `10m` |  |
| `global.defaultPodDisruptionBudget.enabled` | `true` |  |
| `global.priorityClassName` | `""` |  |
| `global.useMCP` | `true` | `Use the Mesh Control Protocol (MCP) for configuring Mixer andPilot. Requires galley (--set galley.enabled=true).` |
| `global.trustDomain` | `""` |  |
| `global.outboundTrafficPolicy.mode` | `ALLOW_ANY` |  |
| `global.sds.enabled` | `false` | `SDS enabled. IF set to true, mTLS certificates for the sidecars will bedistributed through the SecretDiscoveryService instead of using K8S secrets to mount the certificates.` |
| `global.sds.udsPath` | `""` |  |
| `global.sds.useTrustworthyJwt` | `false` |  |
| `global.sds.useNormalJwt` | `false` |  |
| `global.meshNetworks` | `{}` |  |
| `global.enableHelmTest` | `false` | `Specifies whether helm test is enabled or not.This field is set to false by default, so 'helm template ...'will ignore the helm test yaml files when generating the template` |

## `grafana` options

| Key | Default Value | Description |
| --- | --- | --- |
| `grafana.enabled` | `false` |  |
| `grafana.replicaCount` | `1` |  |
| `grafana.image.repository` | `grafana/grafana` |  |
| `grafana.image.tag` | `5.4.0` |  |
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
| `grafana.contextPath` | `/grafana` |  |
| `grafana.service.annotations` | `{}` |  |
| `grafana.service.name` | `http` |  |
| `grafana.service.type` | `ClusterIP` |  |
| `grafana.service.externalPort` | `3000` |  |
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
| `istiocoredns.coreDNSPluginImage` | `istio/coredns-plugin:0.2-istio-1.1` |  |
| `istiocoredns.nodeSelector` | `{}` |  |

## `kiali` options

| Key | Default Value | Description |
| --- | --- | --- |
| `kiali.enabled` | `false` | `Note that if using the demo or demo-auth yaml when installing via Helm, this default will be true.` |
| `kiali.replicaCount` | `1` |  |
| `kiali.hub` | `docker.io/kiali` |  |
| `kiali.tag` | `v0.14` |  |
| `kiali.contextPath` | `/kiali` | `The root context path to access the Kiali UI.` |
| `kiali.nodeSelector` | `{}` |  |
| `kiali.ingress.enabled` | `false` |  |
| `kiali.ingress.hosts` | `kiali.local` | `Used to create an Ingress record.` |
| `kiali.dashboard.secretName` | `kiali` | `You must create a secret with this name - one is not provided out-of-box.` |
| `kiali.dashboard.usernameKey` | `username` | `This is the key name within the secret whose value is the actual username.` |
| `kiali.dashboard.passphraseKey` | `passphrase` | `This is the key name within the secret whose value is the actual passphrase.` |
| `kiali.dashboard.grafanaURL` | `` | `If you have Grafana installed and it is accessible to client browsers, then set this to its external URL. Kiali will redirect users to this URL when Grafana metrics are to be shown.` |
| `kiali.dashboard.jaegerURL` | `` | `If you have Jaeger installed and it is accessible to client browsers, then set this property to its external URL. Kiali will redirect users to this URL when Jaeger tracing is to be shown.` |
| `kiali.prometheusAddr` | `http://prometheus:9090` |  |
| `kiali.createDemoSecret` | `false` | `When true, a secret will be created with a default username and password. Useful for demos.` |

## `mixer` options

| Key | Default Value | Description |
| --- | --- | --- |
| `mixer.enabled` | `true` |  |
| `mixer.image` | `mixer` |  |
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

## `nodeagent` options

| Key | Default Value | Description |
| --- | --- | --- |
| `nodeagent.enabled` | `false` |  |
| `nodeagent.image` | `node-agent-k8s` |  |
| `nodeagent.env.CA_PROVIDER` | `""` | `name of authentication provider.` |
| `nodeagent.env.CA_ADDR` | `""` | `CA endpoint.` |
| `nodeagent.env.Plugins` | `""` | `names of authentication provider's plugins.` |
| `nodeagent.nodeSelector` | `{}` |  |

## `pilot` options

| Key | Default Value | Description |
| --- | --- | --- |
| `pilot.enabled` | `true` |  |
| `pilot.autoscaleEnabled` | `true` |  |
| `pilot.autoscaleMin` | `1` |  |
| `pilot.autoscaleMax` | `5` |  |
| `pilot.image` | `pilot` |  |
| `pilot.sidecar` | `true` |  |
| `pilot.traceSampling` | `1.0` |  |
| `pilot.resources.requests.cpu` | `500m` |  |
| `pilot.resources.requests.memory` | `2048Mi` |  |
| `pilot.env.PILOT_PUSH_THROTTLE` | `100` |  |
| `pilot.env.GODEBUG` | `gctrace=1` |  |
| `pilot.cpu.targetAverageUtilization` | `80` |  |
| `pilot.nodeSelector` | `{}` |  |
| `pilot.keepaliveMaxServerConnectionAge` | `30m` | `The following is used to limit how long a sidecar can be connectedto a pilot. It balances out load across pilot instances at the cost ofincreasing system churn.` |

## `prometheus` options

| Key | Default Value | Description |
| --- | --- | --- |
| `prometheus.enabled` | `true` |  |
| `prometheus.replicaCount` | `1` |  |
| `prometheus.hub` | `docker.io/prom` |  |
| `prometheus.tag` | `v2.3.1` |  |
| `prometheus.retention` | `6h` |  |
| `prometheus.nodeSelector` | `{}` |  |
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
| `security.image` | `citadel` |  |
| `security.selfSigned` | `true` | `indicate if self-signed CA is used.` |
| `security.createMeshPolicy` | `true` |  |
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
| `servicegraph.ingress.hosts` | `servicegraph.local` | `Used to create an Ingress record.` |
| `servicegraph.prometheusAddr` | `http://prometheus:9090` |  |

## `sidecarInjectorWebhook` options

| Key | Default Value | Description |
| --- | --- | --- |
| `sidecarInjectorWebhook.enabled` | `true` |  |
| `sidecarInjectorWebhook.replicaCount` | `1` |  |
| `sidecarInjectorWebhook.image` | `sidecar_injector` |  |
| `sidecarInjectorWebhook.enableNamespacesByDefault` | `false` |  |
| `sidecarInjectorWebhook.nodeSelector` | `{}` |  |
| `sidecarInjectorWebhook.rewriteAppHTTPProbe` | `false` | `If true, webhook or istioctl injector will rewrite PodSpec for livenesshealth check to redirect request to sidecar. This makes liveness check workeven when mTLS is enabled.` |

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

<!-- AUTO-GENERATED-END -->
