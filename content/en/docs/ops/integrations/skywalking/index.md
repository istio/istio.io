---
title: Apache SkyWalking
description: How to integrate with Apache SkyWalking.
weight: 32
keywords: [integration,skywalking,tracing]
owner: istio/wg-environments-maintainers
test: no
---

[Apache SkyWalking](http://skywalking.apache.org) is an application performance monitoring (APM) system, especially designed for
microservices, cloud native and container-based architectures. SkyWalking is a one-stop solution for observability that not only
provides distributed tracing ability like Jaeger and Zipkin, metrics ability like Prometheus and Grafana, logging ability like Kiali,
it also extends the observability to many other scenarios, such as associating the logs with traces, collecting system events and
associating the events with metrics, service performance profiling based on eBPF, etc.

## Installation

### Option 1: Quick start

Istio provides a basic sample installation to quickly get SkyWalking up and running:

{{< text bash >}}
$ kubectl apply -f @samples/addons/extras/skywalking.yaml@
{{< /text >}}

This will deploy SkyWalking into your cluster. This is intended for demonstration only, and is not tuned for performance or security.

Istio proxies by default don't send traces to SkyWalking. You will also need to enable the SkyWalking tracing extension provider by adding
the following fields to your configuration:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    extensionProviders:
      - skywalking:
          service: tracing.istio-system.svc.cluster.local
          port: 11800
        name: skywalking
    defaultProviders:
        tracing:
        - "skywalking"
{{< /text >}}

### Option 2: Customizable install

Consult the [SkyWalking documentation](http://skywalking.apache.org) to get started. No special changes are needed for SkyWalking to work with Istio.

Once SkyWalking is installed, remember to modify the option `--set meshConfig.extensionProviders[0].skywalking.service` to point to the `skywalking-oap` deployment.
See [`ProxyConfig.Tracing`](/docs/reference/config/istio.mesh.v1alpha1/#Tracing) for advanced configuration such as TLS settings.

## Usage

For more information on using SkyWalking, please refer to the [SkyWalking task](/docs/tasks/observability/distributed-tracing/skywalking/).
