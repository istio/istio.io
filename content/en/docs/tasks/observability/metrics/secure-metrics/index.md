---
title: Securing Prometheus Scraping for Istio Sidecar and Gateway
description: This task shows how to securely scrape Istio workload and gateway metrics in sidecar mode using Prometheus and Istio mutual TLS (mTLS).
weight: 50
keywords: [telemetry,metrics,prometheus,istio,mtls,secure-metrics]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

This task demonstrates how to **securely scrape Istio sidecar and gateway metrics** using Prometheus over **Istio mTLS**. By default, Prometheus scrapes metrics from Istio workloads and gateways over plain HTTP. In this task, you configure Istio and Prometheus so that metrics are scraped securely over mutually-authenticated TLS connections. This document focuses on Envoy and Istio-generated telemetry exposed by sidecars and gateways. For general Prometheus integration with Istio, including application metrics, see the [Prometheus integration](/docs/ops/integrations/prometheus/) documentation.

{{< tip >}}
Starting with Istio 1.31, secure mTLS metrics ports can be enabled natively. For older versions of Istio, see the [legacy workaround](#legacy-workaround-istio--131) section.
{{< /tip >}}

## Understand default metrics scraping

By default, Istio exposes metrics on the `/stats/prometheus` endpoint:

* Workload metrics are served from the sidecar telemetry port (`15020`) or the Envoy-only port (`15090`).
* Gateway metrics are served from the gateway pod telemetry port.
* These endpoints are **not protected by mutual TLS**, and scraping directly over HTTPS is discouraged.

The approach in this task adds dedicated mTLS-protected listeners so that Prometheus scrapes over an encrypted, mutually-authenticated connection.

## Before you begin

* [Install Istio](/docs/setup) in your cluster using the **default profile**.

## Configure Prometheus for mTLS scraping

Prometheus must present a valid certificate trusted by the mesh CA when scraping the secure ports. The simplest way to provision those credentials is to inject an Istio sidecar into the Prometheus pod and use `OUTPUT_CERTS` to write the workload certificate to a shared volume.

The `prometheus-secure-metrics` sample (`samples/addons/extras/prometheus-secure-metrics.yaml`) is a standalone Prometheus deployment with sidecar injection, certificate export, and the mTLS scrape jobs pre-configured. Use it **instead of** `samples/addons/prometheus.yaml` - do not apply both files, as they define the same resource names.

1. Deploy Prometheus with mTLS scraping pre-configured:

    {{< text bash >}}
    $ kubectl apply -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
    $ kubectl rollout status deployment/prometheus -n istio-system
    {{< /text >}}

    The sample configures the following key settings compared to the standard Prometheus addon:

    * `sidecar.istio.io/inject: "true"` **label** - overrides the `"false"` default on the Prometheus pod, enabling sidecar injection.
    * `OUTPUT_CERTS: /etc/istio-certs` - instructs the sidecar to write the workload certificate, key, and root CA to a shared volume so Prometheus can read them for mTLS scraping.
    * `INBOUND_CAPTURE_PORTS: ""` - prevents the sidecar from intercepting inbound Prometheus traffic; the sidecar is used solely for certificate provisioning.
    * `sidecar.istio.io/userVolumeMount` - mounts the certificate volume into the `istio-proxy` container so it can write certificates. The same volume is also mounted into `prometheus-server` so it can read them. Both mounts are required.
    * **Scrape jobs** - the ConfigMap contains two pre-configured mTLS scrape jobs (`istio-secure-merged-metrics` on port `15092`, `istio-secure-envoy-metrics` on port `15091`) that discover pods via the `prometheus.istio.io/secure-port` and `prometheus.istio.io/secure-envoy-port` annotations.

    {{< tip >}}
    As an alternative to sidecar-based certificate provisioning, Istio can be integrated with [cert-manager](/docs/ops/integrations/certmanager/) to provision certificates for Prometheus. In that model, an Istio sidecar is not required.
    {{< /tip >}}

1. Verify the Prometheus pod has an Istio sidecar injected and is running:

    {{< text bash >}}
    $ kubectl get pod -n istio-system -l app.kubernetes.io/name=prometheus
    NAME                          READY   STATUS    RESTARTS   AGE
    prometheus-6c647c84c8-gpxt4   3/3     Running   0          75s
    {{< /text >}}

## Enable native mTLS metrics ports (Istio 1.31+)

Istio 1.31 introduced two environment variables that inject mTLS-protected static bootstrap listeners directly into every Envoy proxy - both sidecar and gateway proxies:

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `ENVOY_SECURE_METRICS_PORT` | `0` (disabled) | Adds an mTLS listener that proxies to the Envoy-only stats port (`15090`) |
| `ENVOY_SECURE_MERGED_METRICS_PORT` | `0` (disabled) | Adds an mTLS listener that proxies to the merged metrics port (`15020`, includes app and agent stats) |

When set, Envoy adds the configured listeners at bootstrap time. Scrapers must present a certificate trusted by the mesh CA; this can be an Istio workload certificate (as provisioned above) or any certificate issued by a trusted CA such as cert-manager.

### Enable on a sidecar workload

This example uses `httpbin` as the workload.

1. Deploy `httpbin` with secure metrics ports enabled

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. Patch the `httpbin` deployment to enable the secure listeners

    {{< text bash >}}
    $ cat <<EOF > /tmp/httpbin-secure-metrics-patch.yaml
    spec:
      template:
        metadata:
          annotations:
            proxy.istio.io/config: |
              proxyMetadata:
                ENVOY_SECURE_METRICS_PORT: "15091"
                ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
            prometheus.io/path: "/stats/prometheus"
    EOF
    $ kubectl patch deployment httpbin -n default --type=merge --patch-file=/tmp/httpbin-secure-metrics-patch.yaml
    {{< /text >}}

    * The value of `ENVOY_SECURE_METRICS_PORT` (`15091`) is the mTLS listener port for **Envoy-only** stats.
    * The value of `ENVOY_SECURE_MERGED_METRICS_PORT` (`15092`) is the mTLS listener port for **merged** metrics (Envoy + application + agent).

1. Verify the secure listeners are configured on the `httpbin` sidecar:

    {{< text bash >}}
    $ export HTTPBIN_POD=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].metadata.name}')
    $ istioctl proxy-config listeners $HTTPBIN_POD -n default | grep -E "15090|15091|15092"
    0.0.0.0       15090 ALL                                                                                     Inline Route: /stats/prometheus*
    0.0.0.0       15091 Trans: tls                                                                              Inline Route: /stats/prometheus*
    0.0.0.0       15092 Trans: tls                                                                              Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    The `Trans: tls` on ports `15091` and `15092` confirms the mTLS listeners are active.

### Enable on a gateway

The same variables work identically on gateway proxies since they use the same `pilot-agent` bootstrap path.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

1. Patch the ingress gateway Deployment:

    {{< text bash >}}
    $ cat <<EOF > /tmp/gateway-secure-metrics-patch.yaml
    spec:
      template:
        metadata:
          annotations:
            prometheus.istio.io/secure-port: "15092"
            prometheus.io/path: "/stats/prometheus"
        spec:
          containers:
          - name: istio-proxy
            env:
            - name: ENVOY_SECURE_METRICS_PORT
              value: "15091"
            - name: ENVOY_SECURE_MERGED_METRICS_PORT
              value: "15092"
    EOF
    $ kubectl patch deployment istio-ingressgateway -n istio-system --type=strategic --patch-file=/tmp/gateway-secure-metrics-patch.yaml
    $ kubectl rollout status deployment/istio-ingressgateway -n istio-system
    {{< /text >}}

1. Verify the secure listeners are configured on the ingress gateway:

    {{< text bash >}}
    $ export GW_POD=$(kubectl get pod -n istio-system -l app=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}')
    $ istioctl proxy-config listeners $GW_POD -n istio-system | grep -E "15090|15091|15092"
    0.0.0.0   15090 ALL        Inline Route: /stats/prometheus*
    0.0.0.0   15091 Trans: tls Inline Route: /stats/prometheus*
    0.0.0.0   15092 Trans: tls Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    The `Trans: tls` on ports `15091` and `15092` confirms the mTLS listeners are active on the gateway.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

1. Patch the `Gateway` resource to enable the secure listeners:

    {{< text bash >}}
    $ cat <<EOF > /tmp/gateway-api-secure-metrics-patch.yaml
    spec:
      infrastructure:
        annotations:
          proxy.istio.io/config: |
            proxyMetadata:
              ENVOY_SECURE_METRICS_PORT: "15091"
              ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
          prometheus.istio.io/secure-port: "15092"
          prometheus.io/path: "/stats/prometheus"
    EOF
    $ kubectl patch gateway istio-ingressgateway -n istio-system --type=merge --patch-file=/tmp/gateway-api-secure-metrics-patch.yaml
    {{< /text >}}

1. Verify the secure listeners are configured on the gateway pod:

    {{< text bash >}}
    $ export GW_POD=$(kubectl get pod -n istio-system -l gateway.networking.k8s.io/gateway-name=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}')
    $ istioctl proxy-config listeners $GW_POD -n istio-system | grep -E "15090|15091|15092"
    0.0.0.0   15090 ALL        Inline Route: /stats/prometheus*
    0.0.0.0   15091 Trans: tls Inline Route: /stats/prometheus*
    0.0.0.0   15092 Trans: tls Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    The `Trans: tls` on ports `15091` and `15092` confirms the mTLS listeners are active on the gateway.

{{< /tab >}}

{{< /tabset >}}

### Fully hardened setup

For a fully hardened deployment, combine the secure ports with `METRICS_LOCALHOST_ACCESS_ONLY`. This restricts the underlying plaintext ports (`15090` and `15020`) to localhost, making the mTLS listeners the **only** externally reachable scrape surface:

{{< text bash >}}
$ cat <<EOF > /tmp/httpbin-hardened-patch.yaml
spec:
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |
          proxyMetadata:
            ENVOY_SECURE_METRICS_PORT: "15091"
            ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
            METRICS_LOCALHOST_ACCESS_ONLY: "true"
        prometheus.io/path: "/stats/prometheus"
EOF
$ kubectl patch deployment httpbin -n default --type=merge --patch-file=/tmp/httpbin-hardened-patch.yaml
{{< /text >}}

{{< warning >}}
Once `METRICS_LOCALHOST_ACCESS_ONLY` is set, direct HTTP access to ports `15090` and `15020` from outside the pod is blocked. Ensure Prometheus is configured to scrape via the mTLS ports before applying this setting.
{{< /warning >}}

{{< tip >}}
To apply these settings mesh-wide without patching individual deployments, use an `IstioOperator` during installation:

{{< text bash >}}
$ cat <<EOF > ./istio-secure-metrics.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ENVOY_SECURE_METRICS_PORT: "15091"
        ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
        METRICS_LOCALHOST_ACCESS_ONLY: "true"
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        podAnnotations:
          prometheus.istio.io/secure-port: "15092"
          prometheus.io/path: "/stats/prometheus"
EOF
$ istioctl install -f ./istio-secure-metrics.yaml
{{< /text >}}

When installed this way, `istioctl` renders the gateway Deployment with the `proxyMetadata` values as container env vars directly, activating the secure listeners on both sidecars and gateways. The `components.ingressGateways.k8s.podAnnotations` block adds the Prometheus discovery annotations to gateway pods. For sidecar workloads, `prometheus.istio.io/secure-port` is automatically set by the sidecar injector to the value of `ENVOY_SECURE_MERGED_METRICS_PORT` - no per-Deployment annotation is needed.
{{< /tip >}}

## Verification

### Verify secure metrics scraping with Prometheus

After completing the configuration, verify that Prometheus is successfully scraping metrics over **mutual TLS**.

1. Verify mTLS scraping succeeds by curling the secure port from the Prometheus pod using its workload certificate:

    {{< text bash >}}
    $ export PROM_POD=$(kubectl get pod -n istio-system -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')
    $ export HTTPBIN_IP=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].status.podIP}')
    $ kubectl exec -n istio-system $PROM_POD -c istio-proxy -- \
        curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
        --cacert /etc/istio-certs/root-cert.pem \
        --cert /etc/istio-certs/cert-chain.pem \
        --key /etc/istio-certs/key.pem \
        --insecure \
        https://$HTTPBIN_IP:15092/stats/prometheus
    200
    {{< /text >}}

    An HTTP `200` response confirms that the Prometheus pod successfully completed an mTLS handshake with httpbin's port `15092` and retrieved metrics. The `--insecure` flag skips hostname verification only - Istio workload certificates use SPIFFE URI SANs (e.g. `spiffe://cluster.local/ns/default/sa/httpbin`) rather than IP addresses, so curl cannot match the pod IP against the cert. The mutual TLS handshake and certificate exchange still occur, which is why `--cacert`, `--cert`, and `--key` are still required. This is also why the Prometheus scrape job uses `insecure_skip_verify: true`.

1. Verify scrape targets in the Prometheus UI

    Open the Prometheus dashboard with `istioctl dashboard prometheus -n istio-system`, then navigate to **Status → Targets**. Verify that the `istio-secure-merged-metrics` and `istio-secure-envoy-metrics` jobs list the `httpbin` pod with a status of **UP** and endpoints in the form `https://<pod-ip>:15092/stats/prometheus`.

1. Verify mTLS is enforced by confirming that a plain HTTP request to the secure port is rejected:

    {{< text bash >}}
    $ export HTTPBIN_POD=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].metadata.name}')
    $ export HTTPBIN_IP=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].status.podIP}')
    $ kubectl exec -n default $HTTPBIN_POD -c istio-proxy -- curl -s --max-time 3 http://$HTTPBIN_IP:15091/stats/prometheus
    upstream connect error or disconnect/reset before headers. reset reason: connection termination
    {{< /text >}}

    The connection termination error confirms the port only accepts TLS connections - a plain HTTP request is rejected immediately.

This confirms that Prometheus is scraping metrics using **HTTPS over Istio mTLS** via the native secure ports, rather than directly accessing the plaintext telemetry ports (`15020` or `15090`).

## Cleanup

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl label namespace default istio-injection-
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl delete gateway istio-ingressgateway -n istio-system
$ kubectl label namespace default istio-injection-
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Legacy workaround (Istio < 1.31)

If you are running Istio older than 1.31, the native env-var approach is not available. The steps below demonstrate one way to achieve secure metrics scraping using Istio CRDs: a secure TLS frontend is created on port `15091` (exposed to Prometheus) that routes internally to either port `15020` (merged metrics - Envoy + application + agent) or `15090` (Envoy-only metrics). Scrapers connect to `15091` over `ISTIO_MUTUAL` TLS; the `ServiceEntry` and `VirtualService` handle the internal routing to the plaintext backend.

### Legacy: Secure metrics for sidecars

1. Deploy `httpbin` and create a `Sidecar` resource with a secure ingress listener on port `15091`:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

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

1. Annotate the workload pod for Prometheus discovery:

    {{< text bash >}}
    $ kubectl annotate pod -n default \
      -l app=httpbin \
      prometheus.io/scrape="true" \
      prometheus.io/path="/stats/prometheus" \
      prometheus.istio.io/secure-port="15091" \
      --overwrite
    {{< /text >}}

### Legacy: Secure metrics for gateways

1. Create a `Gateway` with a secure HTTPS listener on port `15091`:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: Gateway
    metadata:
      name: metrics-gateway
      namespace: istio-system
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 15091
          name: https-metrics
          protocol: HTTPS
        tls:
          mode: ISTIO_MUTUAL
        hosts: ["*"]
    EOF
    {{< /text >}}

1. Create a `ServiceEntry` to expose the gateway telemetry port inside the mesh:

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

1. Create a `VirtualService` to route requests from the secure listener to the telemetry port:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: gateway-metrics
      namespace: istio-system
    spec:
      hosts: ["*"]
      gateways: [metrics-gateway]
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

1. Annotate the gateway pod for Prometheus discovery:

    {{< text bash >}}
    $ kubectl annotate pod -n istio-system \
      -l app=istio-ingressgateway \
      prometheus.istio.io/secure-port=15091 \
      --overwrite
    {{< /text >}}

### Cleanup

{{< text bash >}}
$ kubectl delete sidecar secure-metrics -n default
$ kubectl delete gateway metrics-gateway -n istio-system
$ kubectl delete serviceentry gateway-admin -n istio-system
$ kubectl delete virtualservice gateway-metrics -n istio-system
$ kubectl delete -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl label namespace default istio-injection-
{{< /text >}}
