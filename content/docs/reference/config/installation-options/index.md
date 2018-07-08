---
title: Installation Options
description: Describes the options available when installing Istio using the included Helm chart.
weight: 30
keywords: [kubernetes,helm]
---

You can [install Istio using Helm](/docs/setup/kubernetes/helm-install/), and although the included Helm chart uses reasonable defaults, there are circumstances that require customization. You can use Helm's `--set key=value` option to override one or more values. The set of supported keys is shown in the table below.

<!-- AUTO-GENERATED-START -->
| Key | Default Value | Description |
| --- | --- | --- |
| `global` |  |  |
| `global.hub` | `docker.io/istionightly` |  |
| `global.tag` | `nightly-master` |  |
| `global.proxy` |  |  |
| `global.proxy.image` | `proxyv2` |  |
| `global.proxy.accessLogFile` | `"/dev/stdout"` |  |
| `global.proxy.enableCoreDump` | `false` |  |
| `global.proxy.includeIPRanges` | `"*"` |  |
| `global.proxy.excludeIPRanges` | `""` |  |
| `global.proxy.includeInboundPorts` | `"*"` |  |
| `global.proxy.excludeInboundPorts` | `""` |  |
| `global.proxy.autoInject` | `enabled` |  |
| `global.proxy.envoyStatsd` |  |  |
| `global.proxy.envoyStatsd.enabled` | `true` |  |
| `global.proxy.envoyStatsd.host` | `istio-statsd-prom-bridge` |  |
| `global.proxy.envoyStatsd.port` | `9125` |  |
| `global.proxy_init` |  |  |
| `global.proxy_init.image` | `proxy_init` |  |
| `global.imagePullPolicy` | `IfNotPresent` |  |
| `global.hyperkube` |  |  |
| `global.hyperkube.repository` | `quay.io/coreos/hyperkube` |  |
| `global.hyperkube.tag` | `v1.7.6_coreos.0` |  |
| `global.controlPlaneSecurityEnabled` | `false` |  |
| `global.disablePolicyChecks` | `false` |  |
| `global.enableTracing` | `true` |  |
| `global.mtls` |  |  |
| `global.mtls.enabled` | `false` |  |
| `global.nodePort` | `true` |  |
| `global.imagePullSecrets` |  |  |
| `global.refreshInterval` | `10s` |  |
| `global.arch` |  |  |
| `global.arch.amd64` | `2` |  |
| `global.arch.s390x` | `2` |  |
| `global.arch.ppc64le` | `2` |  |
| `global.oneNamespace` | `false` |  |
| `global.configValidation` | `true` |  |
| `global.defaultResources` |  |  |
| `global.defaultResources.requests` |  |  |
| `global.defaultResources.requests.cpu` | `10m` |  |
| `istiotesting` |  |  |
| `istiotesting.oneNameSpace` | `false` |  |
| `ingress` |  |  |
| `ingress.enabled` | `true` |  |
| `ingress.replicaCount` | `1` |  |
| `ingress.autoscaleMin` | `1` |  |
| `ingress.autoscaleMax` | `1` |  |
| `ingress.service` |  |  |
| `ingress.service.annotations` | `{}` |  |
| `ingress.service.loadBalancerIP` | `""` |  |
| `ingress.service.type` | `LoadBalancer #change to NodePort, ClusterIP or LoadBalancer if need be` |  |
| `ingress.service.ports` |  |  |
| `ingress.service.ports.name` | `http` |  |
| `ingress.service.ports.nodePort` | `32000` |  |
| `ingress.service.ports.name` | `https` |  |
| `ingress.service.selector` |  |  |
| `ingress.service.selector.istio` | `ingress` |  |
| `gateways` |  |  |
| `gateways.enabled` | `true` |  |
| `gateways.istio-ingressgateway` |  |  |
| `gateways.istio-ingressgateway.enabled` | `true` |  |
| `gateways.istio-ingressgateway.labels` |  |  |
| `gateways.istio-ingressgateway.labels.istio` | `ingressgateway` |  |
| `gateways.istio-ingressgateway.replicaCount` | `1` |  |
| `gateways.istio-ingressgateway.autoscaleMin` | `1` |  |
| `gateways.istio-ingressgateway.autoscaleMax` | `5` |  |
| `gateways.istio-ingressgateway.resources` | `{}` |  |
| `gateways.istio-ingressgateway.loadBalancerIP` | `""` |  |
| `gateways.istio-ingressgateway.serviceAnnotations` | `{}` |  |
| `gateways.istio-ingressgateway.type` | `LoadBalancer #change to NodePort, ClusterIP or LoadBalancer if need be` |  |
| `gateways.istio-ingressgateway.ports` |  |  |
| `gateways.istio-ingressgateway.ports.targetPort` | `80` |  |
| `gateways.istio-ingressgateway.ports.name` | `http2` |  |
| `gateways.istio-ingressgateway.ports.nodePort` | `31380` |  |
| `gateways.istio-ingressgateway.ports.name` | `https` |  |
| `gateways.istio-ingressgateway.ports.nodePort` | `31390` |  |
| `gateways.istio-ingressgateway.ports.name` | `tcp` |  |
| `gateways.istio-ingressgateway.ports.nodePort` | `31400` |  |
| `gateways.istio-ingressgateway.secretVolumes` |  |  |
| `gateways.istio-ingressgateway.secretVolumes.secretName` | `istio-ingressgateway-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.mountPath` | `/etc/istio/ingressgateway-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.secretName` | `istio-ingressgateway-ca-certs` |  |
| `gateways.istio-ingressgateway.secretVolumes.mountPath` | `/etc/istio/ingressgateway-ca-certs` |  |
| `gateways.istio-egressgateway` |  |  |
| `gateways.istio-egressgateway.enabled` | `true` |  |
| `gateways.istio-egressgateway.labels` |  |  |
| `gateways.istio-egressgateway.labels.istio` | `egressgateway` |  |
| `gateways.istio-egressgateway.replicaCount` | `1` |  |
| `gateways.istio-egressgateway.autoscaleMin` | `1` |  |
| `gateways.istio-egressgateway.autoscaleMax` | `1` |  |
| `gateways.istio-egressgateway.serviceAnnotations` | `{}` |  |
| `gateways.istio-egressgateway.type` | `ClusterIP #change to NodePort or LoadBalancer if need be` |  |
| `gateways.istio-egressgateway.ports` |  |  |
| `gateways.istio-egressgateway.ports.name` | `http2` |  |
| `gateways.istio-egressgateway.ports.name.name` | `https` |  |
| `gateways.istio-egressgateway.secretVolumes` |  |  |
| `gateways.istio-egressgateway.secretVolumes.secretName` | `istio-egressgateway-certs` |  |
| `gateways.istio-egressgateway.secretVolumes.secretName.mountPath` | `/etc/istio/egressgateway-certs` |  |
| `gateways.istio-egressgateway.secretVolumes.secretName.secretName` | `istio-egressgateway-ca-certs` |  |
| `gateways.istio-egressgateway.secretVolumes.secretName.mountPath` | `/etc/istio/egressgateway-ca-certs` |  |
| `sidecarInjectorWebhook` |  |  |
| `sidecarInjectorWebhook.enabled` | `true` |  |
| `sidecarInjectorWebhook.replicaCount` | `1` |  |
| `sidecarInjectorWebhook.image` | `sidecar_injector` |  |
| `sidecarInjectorWebhook.enableNamespacesByDefault` | `false` |  |
| `galley` |  |  |
| `galley.enabled` | `true` |  |
| `galley.replicaCount` | `1` |  |
| `galley.image` | `galley` |  |
| `mixer` |  |  |
| `mixer.enabled` | `true` |  |
| `mixer.replicaCount` | `1` |  |
| `mixer.image` | `mixer` |  |
| `mixer.prometheusStatsdExporter` |  |  |
| `mixer.prometheusStatsdExporter.repository` | `prom/statsd-exporter` |  |
| `mixer.prometheusStatsdExporter.tag` | `latest` |  |
| `pilot` |  |  |
| `pilot.enabled` | `true` |  |
| `pilot.replicaCount` | `1` |  |
| `pilot.image` | `pilot` |  |
| `security` |  |  |
| `security.replicaCount` | `1` |  |
| `security.image` | `citadel` |  |
| `security.selfSigned` | `true # indicate if self-signed CA is used.` |  |
| `security.cleanUpOldCA` | `true` |  |
| `grafana` | `grafana.local` |  |
| `grafana.enabled` | `false` |  |
| `grafana.replicaCount` | `1` |  |
| `grafana.image` | `grafana` |  |
| `grafana.service` |  |  |
| `grafana.service.annotations` | `{}` |  |
| `grafana.service.name` | `http` |  |
| `grafana.service.type` | `ClusterIP` |  |
| `grafana.service.externalPort` | `3000` |  |
| `grafana.service.internalPort` | `3000` |  |
| `grafana.ingress` | `grafana.local` |  |
| `grafana.ingress.enabled` | `false` |  |
| `grafana.ingress.hosts` | `grafana.local` |  |
| `grafana.ingress.annotations` |  |  |
| `grafana.ingress.tls` |  |  |
| `prometheus` |  |  |
| `prometheus.enabled` | `true` |  |
| `prometheus.replicaCount` | `1` |  |
| `prometheus.image` |  |  |
| `prometheus.image.repository` | `docker.io/prom/prometheus` |  |
| `prometheus.image.tag` | `latest` |  |
| `prometheus.ingress` |  |  |
| `prometheus.ingress.enabled` | `false` |  |
| `prometheus.ingress.annotations` |  |  |
| `prometheus.ingress.tls` |  |  |
| `prometheus.service` |  |  |
| `prometheus.service.annotations` | `{}` |  |
| `prometheus.service.nodePort` |  |  |
| `prometheus.service.nodePort.enabled` | `false` |  |
| `prometheus.service.nodePort.port` | `32090` |  |
| `servicegraph` | `servicegraph.local` |  |
| `servicegraph.enabled` | `false` |  |
| `servicegraph.replicaCount` | `1` |  |
| `servicegraph.image` | `servicegraph` |  |
| `servicegraph.service` |  |  |
| `servicegraph.service.annotations` | `{}` |  |
| `servicegraph.service.name` | `http` |  |
| `servicegraph.service.type` | `ClusterIP` |  |
| `servicegraph.service.externalPort` | `8088` |  |
| `servicegraph.service.internalPort` | `8088` |  |
| `servicegraph.ingress` | `servicegraph.local` |  |
| `servicegraph.ingress.enabled` | `false` |  |
| `servicegraph.ingress.hosts` | `servicegraph.local` |  |
| `servicegraph.ingress.annotations` |  |  |
| `servicegraph.ingress.tls` |  |  |
| `servicegraph.prometheusAddr` | `http://prometheus:9090` |  |
| `zipkin` |  |  |
| `zipkin.enabled` | `true` |  |
| `tracing` | `zipkin.local` |  |
| `tracing.enabled` | `false` |  |
| `tracing.jaeger` |  |  |
| `tracing.jaeger.enabled` | `false` |  |
| `tracing.jaeger.memory` |  |  |
| `tracing.jaeger.memory.max_traces` | `50000` |  |
| `tracing.replicaCount` | `1` |  |
| `tracing.image` |  |  |
| `tracing.image.repository` | `jaegertracing/all-in-one` |  |
| `tracing.image.tag` | `1.5` |  |
| `tracing.service` |  |  |
| `tracing.service.annotations` | `{}` |  |
| `tracing.service.name` | `http` |  |
| `tracing.service.type` | `ClusterIP` |  |
| `tracing.service.externalPort` | `9411` |  |
| `tracing.service.internalPort` | `9411` |  |
| `tracing.service.uiPort` | `16686` |  |
| `tracing.ingress` | `zipkin.local` |  |
| `tracing.ingress.enabled` | `false` |  |
| `tracing.ingress.hosts` | `zipkin.local` |  |
| `tracing.ingress.annotations` |  |  |
| `tracing.ingress.tls` |  |  |
| `kiali` |  |  |
| `kiali.enabled` | `false` |  |
| `kiali.replicaCount` | `1` |  |
| `kiali.image` |  |  |
| `kiali.image.repository` | `kiali/kiali` |  |
| `kiali.image.tag` | `v0.4.0` |  |
| `kiali.ingress` |  |  |
| `kiali.ingress.enabled` | `false` |  |
| `kiali.ingress.annotations` |  |  |
| `kiali.ingress.tls` |  |  |
| `kiali.dashboard` |  |  |
| `kiali.dashboard.username` | `admin` |  |
| `kiali.dashboard.password` | `admin` |  |
<!-- AUTO-GENERATED-END -->

The Helm chart also offers significant customization options per individual
service. Customize these per-service options at your own risk. The per-service options are exposed via
the [`values.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/values.yaml) file.

## Example: traffic management minimal set

Istio has a rich feature set, but you may only want to use a subset of these. For instance, you might be only interested in installing the minimum necessary to support traffic management functionality.

This example shows how to install the minimal set of components necessary to use [traffic management](/docs/tasks/traffic-management/) features.

Execute the following command to install the Pilot and Citadel:

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set ingress.enabled=false,gateways.istio-egressgateway.enabled=false,galley.enabled=false \
  --set gateways.istio-ingressgateway.enabled=false,sidecarInjectorWebhook.enabled=false \
  --set mixer.enabled=false,prometheus.enabled=false,global.proxy.envoyStatsd.enabled=false
{{< /text >}}

Ensure the `istio-pilot-*` and `istio-citadel-*` Kubernetes pods are deployed and their containers are up and running:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                     READY     STATUS    RESTARTS   AGE
istio-citadel-b48446f79-wd4tk            1/1       Running   0          1m
istio-pilot-58c65f74bc-2f5xn             2/2       Running   0          1m
{{< /text >}}

With this minimal set you can proceed to installing the sample [Bookinfo](/docs/examples/bookinfo/) application or install your own application and [configure request routing](/docs/tasks/traffic-management/request-routing/) for instance. You will need to [manually inject the sidecar](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection).
