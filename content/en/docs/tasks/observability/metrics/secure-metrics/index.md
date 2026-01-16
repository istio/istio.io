---
title: Securing Prometheus Scraping for Istio Sidecar and Gateway
description: This task shows how to securely scrape Istio workload and gateway metrics in sidecar mode using Prometheus and Istio mutual TLS (mTLS).
weight: 50
keywords: [telemetry,metrics,prometheus,istio,mtls]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

This task demonstrates how to **securely scrape Istio sidecar and gateway metrics** using Prometheus over **Istio mTLS**. By default, Prometheus scrapes metrics from Istio workloads and gateways over HTTP. In this task, you configure Istio and Prometheus so that metrics are scraped securely over encrypted connections. This document focuses specifically on Envoy and Istio-generated telemetry exposed by sidecars and gateways. It does not cover application-level metrics emitted by workloads themselves. For general Prometheus integration with Istio, including application metrics, see the [Prometheus integration](/docs/ops/integrations/prometheus/) documentation.

## Understand default metrics scraping

By default, Istio exposes metrics on the `/stats/prometheus` endpoint:

* Workload metrics are served from the sidecar telemetry port (`15020`) or Envoy-only port (`15090`).
* Gateway metrics are served from the gateway pod telemetry port.
* These endpoints are **not protected by mutual TLS**, and scraping directly over HTTPS is discouraged.

This task replaces the default scraping with a **secure mTLS-enabled configuration**. Prometheus will use a secure fronting port (`15091`) instead of hitting telemetry ports directly.

## Before you begin

* [Install Istio](/docs/setup) in your cluster using the **default profile**.

## Install Prometheus with secure scraping

To enable secure metrics scraping, Prometheus requires an Istio sidecar to authenticate to workloads and gateways over mTLS.

1. Enable sidecar injection for Prometheus namespace

    {{< text bash >}}
    $ kubectl create namespace prometheus
    $ kubectl label namespace monitoring istio-injection=enabled --overwrite
    {{< /text >}}

    This ensures that any Prometheus pods created or restarted will automatically have an `istio-proxy` sidecar.

    {{< tip >}}
    The Istio sidecar injected into the Prometheus pod is used only to provision an Istio workload certificate for mTLS authentication. Traffic interception is explicitly disabled and Prometheus continues to operate as a standard Kubernetes workload. As an alternative, Istio can be integrated with [cert-manager](docs/ops/integrations/certmanager/) to provision certificates for Prometheus. In that model, an Istio sidecar is not required.
    {{< /tip >}}

1. Update the Prometheus Deployment pod template

    Istio provides a sample Prometheus installation at `samples/addons/prometheus.yaml`. Modify `samples/addons/prometheus.yaml` to annotate the Prometheus deployment to enable sidecar injection, mount Istio certificates, and configure the proxy:

    {{< text yaml >}}
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: prometheus
      namespace: monitoring
    spec:
      template:
        metadata:
          annotations:
            sidecar.istio.io/inject: "true"
            sidecar.istio.io/userVolumeMount: |
              [{"name": "istio-certs", "mountPath": "/etc/istio-certs", "readOnly": true}]
            proxy.istio.io/config: |
              proxyMetadata:
                OUTPUT_CERTS: /etc/istio-certs
              proxyMetadata.INBOUND_CAPTURE_PORTS: ""
        spec:
          containers:
          - name: prometheus
            image: prom/prometheus:latest
          volumes:
          - name: istio-certs
            secret:
              secretName: istio.default
    {{< /text >}}

    **Notes:**

    * `OUTPUT_CERTS` points to where the Istio sidecar writes certificates for Prometheus to use.
    * `INBOUND_CAPTURE_PORTS: ""` prevents the sidecar from intercepting Prometheus traffic.
    * `userVolumeMount` mounts the certificates inside Prometheus.

1. Modify the Prometheus Scrape Job Configuration in `samples/addons/prometheus.yaml` to add an additional job for scraping secure metrics:

    {{< text yaml >}}
    - job_name: 'istio-secure-merged-metrics'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_istio_io_secure_port]
        action: keep
        regex: .+
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels:
        - __meta_kubernetes_pod_ip
        - __meta_kubernetes_pod_annotation_prometheus_istio_io_secure_port
        action: replace
        target_label: __address__
        regex: (.+);(.+)
        replacement: $1:$2
      scheme: https
      tls_config:
        ca_file: /etc/istio-certs/root-cert.pem
        cert_file: /etc/istio-certs/cert-chain.pem
        key_file: /etc/istio-certs/key.pem
        insecure_skip_verify: true
    {{< /text >}}

1. Verify the Prometheus pod has an Istio sidecar

    {{< text bash >}}
    $ kubectl get pod <prometheus-pod> -n monitoring -o jsonpath='{.spec.containers[*].name}'
    {{< /text >}}

    You should see an `istio-proxy` container.

## Secure Metrics for Sidecars

This task uses `httpbin` as the example workload to generate traffic and metrics.

1. Enable sidecar injection in the default namespace and deploy httpbin

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    $ kubectl apply -f @samples/httpbin/httpbin.yaml
    {{< /text >}}

1. Annotate the httpbin pod for secure Prometheus scraping

    Ensure Prometheus scrapes metrics securely via the mTLS port (`15091`):

    {{< text bash >}}
    $ kubectl annotate pod -n default \
      -l app=httpbin \
      prometheus.io/scrape="true" \
      prometheus.io/path="/stats/prometheus" \
      prometheus.istio.io/secure-port="15091" \
      --overwrite
    {{< /text >}}

    These annotations allow Prometheus to discover the httpbin pod and scrape metrics over the secure listener.

1. Create a secure listener on port 15091

    Workload metrics can be exposed securely using a sidecar listener on port `15091`. This forwards requests from the secure listener to the sidecar telemetry port `15020`. For Envoy-only metrics, use port `15090`.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: Sidecar
    metadata:
      name: secure-metrics
      namespace: default
    spec:
      ingress:
      - port:
          number: 15091
          name: https-metrics
          protocol: HTTP
        defaultEndpoint: 127.0.0.1:15020 # Change to 15090 for Envoy-only metrics
    EOF
    {{< /text >}}

## Secure Metrics for Gateways

Istio Gateways expose metrics that Prometheus can scrape. By default, these metrics are on ports `15020` for merged telemetry and `15090` for Envoy-only telemetry, and they are not mTLS-protected. The following steps configure secure scraping over port 15091 using Istio mTLS.

1. Create a `Gateway` with secure listener on port `15091`.

    We create a `Gateway` to expose both standard HTTP traffic and a dedicated secure HTTPS port for metrics. The HTTPS server uses `ISTIO_MUTUAL` TLS mode so that only clients with Istio-issued certificates (like the Prometheus sidecar) can scrape metrics.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: Gateway
    metadata:
      name: httpbin-gateway
      namespace: default
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts: ["*"]
      - port:
          number: 15091
          name: https-metrics
          protocol: HTTPS
        tls:
          mode: ISTIO_MUTUAL
        hosts: ["*"]
    EOF
    {{< /text >}}

1. Create a `ServiceEntry` for the `Gateway` telemetry port (15020 or 15090)

    Prometheus cannot directly access the gateway’s internal ports unless they are exposed in the mesh. A `ServiceEntry` allows Prometheus to route requests inside the mesh to these ports. You can choose 15020 for merged telemetry or 15090 for Envoy-only telemetry.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: gateway-admin
      namespace: istio-system
    spec:
      hosts: [gateway-admin.local]
      location: MESH_INTERNAL
      ports:
      - number: 15020  # Change to 15090 for Envoy-only metrics
        name: http-metrics
        protocol: HTTP
      resolution: STATIC
      endpoints:
      - address: 127.0.0.1
    EOF
    {{< /text >}}

1. Create a `VirtualService` to route metrics

    The `VirtualService` maps requests from the secure listener (15091) to the `ServiceEntry` pointing to the telemetry port (15020 or 15090). This ensures that metrics requests sent to `https://<gateway-ip>:15091/stats/prometheus` are properly routed inside the mesh.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: gateway-metrics
      namespace: default
    spec:
      hosts: ["*"]
      gateways: [httpbin-gateway]
      http:
      - match:
        - uri:
            prefix: /stats/prometheus
        route:
        - destination:
            host: gateway-admin.local
            port:
              number: 15020  # Change to 15090 for Envoy-only metrics
    EOF
    {{< /text >}}

1. Annotate the `Gateway` pod

    {{< text bash >}}
    $ kubectl annotate pod -n istio-system <ingress-pod> prometheus.istio.io/secure-port=15091 --overwrite
    {{< /text >}}

## Verification

### Verify secure metrics scraping with Prometheus

After completing the configuration, verify that Prometheus is successfully scraping metrics from Istio workloads and gateways over **mutual TLS**.

1. Open the Prometheus dashboard

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    This command opens the Prometheus dashboard in your default browser.

1. Verify scrape targets

    1. In the Prometheus UI, navigate to **Status → Targets**.
    1. Locate the job named `istio-secure-merged-metrics` which is what we used while configuring the new Prometheus scrape job.

    Verify that the targets for the httpbin workload and the Istio Ingress Gateway are listed with endpoints similar to: `https://<pod-ip>:15091/stats/prometheus   UP`. Each target should report a status of **UP**.

This confirms that Prometheus is scraping metrics using **HTTPS over Istio mTLS** via the secure fronting port (`15091`), rather than directly accessing the telemetry ports (`15020` or `15090`).
