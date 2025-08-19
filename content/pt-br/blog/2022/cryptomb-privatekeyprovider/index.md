---
title: "CryptoMB - TLS handshake acceleration for Istio"
description: "Accelerate TLS handshake using CryptoMB Private Key Provider configuration in Istio gateways and sidecars."
publishdate: 2022-06-15
attribution: "Ravi kumar Veeramally (Intel), Ismo Puustinen (Intel), Sakari Poussa (Intel)"
keywords: [Istio, CryptoMB, gateways, sidecar]
---

Cryptographic operations are among the most compute-intensive and critical operations when it comes to secured connections. Istio uses Envoy as the "gateways/sidecar" to handle secure connections and intercept the traffic.

Depending upon use cases, when an ingress gateway must handle a large number of incoming TLS and secured service-to-service connections through sidecar proxies, the load on Envoy increases. The potential performance depends on many factors, such as size of the cpuset on which Envoy is running, incoming traffic patterns, and key size. These factors can impact Envoy serving many new incoming TLS requests. To achieve performance improvements and accelerated handshakes, a new feature was introduced in Envoy 1.20 and Istio 1.14. It can be achieved with 3rd Gen Intel® Xeon® Scalable processors, the Intel® Integrated Performance Primitives (Intel® IPP) crypto library, CryptoMB Private Key Provider Method support in Envoy, and Private Key Provider configuration in Istio using `ProxyConfig`.

## CryptoMB

The Intel IPP [crypto library](https://github.com/intel/ipp-crypto/tree/develop/sources/ippcp/crypto_mb) supports multi-buffer crypto operations. Briefly, multi-buffer cryptography is implemented with Intel® Advanced Vector Extensions 512 (Intel® AVX-512) instructions using a SIMD (single instruction, multiple data) mechanism. Up to eight RSA or ECDSA operations are gathered into a buffer and processed at the same time, providing potentially improved performance. Intel AVX-512 instructions are available on recently launched 3rd generation Intel Xeon Scalable processor server processors (Ice Lake server).

The idea of Envoy’s CryptoMB private key provider is that incoming TLS handshakes’ RSA operations are accelerated using Intel AVX-512 multi-buffer instructions.

## Accelerate Envoy with Intel AVX-512 instructions

Envoy uses BoringSSL as the default TLS library. BoringSSL supports setting private key methods for offloading asynchronous private key operations, and Envoy implements a private key provider framework to allow creation of Envoy extensions which handle TLS handshakes private key operations (signing and decryption) using the BoringSSL hooks.

CryptoMB private key provider is an Envoy extension which handles BoringSSL TLS RSA operations using Intel AVX-512 multi-buffer acceleration. When a new handshake happens, BoringSSL invokes the private key provider to request the cryptographic operation, and then the control returns to Envoy. The RSA requests are gathered in a buffer. When the buffer is full or the timer expires, the private key provider invokes Intel AVX-512 processing of the buffer. When processing is done, Envoy is notified that the cryptographic operation is done and that it may continue with the handshakes.

{{< image link="./envoy-boringssl-pkp-flow.png" caption="Envoy <-> BoringSSL <-> PrivateKeyProvider" >}}

The Envoy worker thread has a buffer size for eight RSA requests. When the first RSA request is stored in the buffer, a timer will be initiated (timer duration is set by the `poll_delay` field in the CryptoMB configuration).

{{< image link="./timer-started.png" caption="Buffer timer started" >}}

When the buffer is full or when the timer expires, the crypto operations are performed for all RSA requests simultaneously. The SIMD (single instruction, multiple data) processing gives the potential performance benefit compared to the non-accelerated case.

{{< image link="./timer-expired.png" caption="Buffer timer expired" >}}

## Envoy CryptoMB Private Key Provider configuration

A regular TLS configuration only uses a private key. When a private key provider is used, the private key field is replaced with a private key provider field. It contains two fields, provider name and typed config. Typed config is CryptoMbPrivateKeyMethodConfig, and it specifies the private key and the poll delay.

TLS configuration with just a private key.

{{< text yaml >}}
tls_certificates:
  certificate_chain: { "filename": "/path/cert.pem" }
  private_key: { "filename": "/path/key.pem" }
{{< /text >}}

TLS configuration with CryptoMB private key provider.

{{< text yaml >}}
tls_certificates:
  certificate_chain: { "filename": "/path/cert.pem" }
  private_key_provider:
    provider_name: cryptomb
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.private_key_providers.cryptomb.v3alpha.CryptoMbPrivateKeyMethodConfig
      private_key: { "filename": "/path/key.pem" }
      poll_delay: 10ms
{{< /text >}}

## Istio CryptoMB Private Key Provider configuration

In Istio, CryptoMB private key provider configuration can be applied mesh wide, gateways specific or pod specific configurations using pod annotations. The User will provide the `PrivateKeyProvider` in the `ProxyConfig` with the `pollDelay` value. This configuration will be applied to mesh wide (gateways and all sidecars).

{{< image link="./istio-mesh-wide-config.png" caption="Sample mesh wide configuration" >}}

### Istio Mesh wide Configuration

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: true
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
  meshConfig:
    defaultConfig:
      privateKeyProvider:
        cryptomb:
          pollDelay: 10ms
{{< /text >}}

### Istio Gateways Configuration

If a user wants to apply a private key provider configuration for ingress gateway only, follow the below sample configuration.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: true
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        podAnnotations:
          proxy.istio.io/config: |
            privateKeyProvider:
              cryptomb:
                pollDelay: 10ms
{{< /text >}}

### Istio Sidecar Configuration using pod annotations

If a user wants to apply private key provider configuration to application specific pods, configure them using pod annotations like the below sample.

{{< text yaml >}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
      annotations:
        proxy.istio.io/config: |
          privateKeyProvider:
            cryptomb:
              pollDelay: 10ms
    spec:
      serviceAccountName: httpbin
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
{{< /text >}}

### Performance

The potential performance benefit depends on many factors. For example, the size of the cpuset Envoy is running on, incoming traffic pattern, encryption type (RSA or ECDSA), and key size.

Below, we show performance based on the total latency between k6, gateway and Fortio server. These show relative performance improvement using the CryptoMB provider, and are in no way representative of Istio's [general performance or benchmark results](https://archive.istio.io/v1.16/docs/ops/deployment/performance-and-scalability/).  Our measurements use different client tools (k6 and fortio), different setup (client, gateway and server running on separate nodes) and we create a new TLS handshake with every HTTP request.

We have [published a white paper](https://www.intel.com/content/www/us/en/architecture-and-technology/crypto-acceleration-in-xeon-scalable-processors-wp.html) with general cryptographic performance numbers.

{{< image link="./istio-ingress-gateway-tls-handshake-perf-num.png" caption="Istio ingress gateway TLS handshake performance comparison. Tested using 1.14-dev on May 10th 2022" >}}

Configuration used in above comparison.

* Azure AKS Kubernetes cluster
    * v1.21
    * Three-node cluster
    * Each node Standard_D4ds_v5: 3rd Generation Intel® Xeon® Platinum 8370C (Ice Lake), 4 vCPU, 16 GB memory
* Istio
    * 1.14-dev
    * Istio ingress gateway pod
        * resources.request.cpu: 2
        * resources.request.memory: 4 GB
        * resources.limits.cpu: 2
        * resources.limits.memory: 4 GB
* K6
    * loadimpact/k6:latest
* Fortio
    * fortio/fortio:1.27.0
* K6 client, envoy and fortio pods are forced to run on separate nodes via Kubernetes AntiAffinity and node selectors
* In above picture
    * Istio is installed with above configuration
    * Istio with CryptoMB (AVX-512) with above configuration + below settings

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    ingressGateways:
    - enabled: true
      name: istio-ingressgateway
      k8s:
        # this controls the SDS service which configures ingress gateway
        podAnnotations:
          proxy.istio.io/config: |
            privateKeyProvider:
              cryptomb:
                pollDelay: 1ms
  values:
    # Annotate pods with
    #     inject.istio.io/templates: sidecar, cryptomb
    sidecarInjectorWebhook:
      templates:
        cryptomb: |
          spec:
            containers:
            - name: istio-proxy
{{< /text >}}
