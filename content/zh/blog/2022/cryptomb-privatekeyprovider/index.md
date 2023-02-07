---
title: "使用 Istio 和 CryptoMB 加速 TLS 的握手"
description: "使用 Istio 网关和 Sidecar 中的 CryptoMB Private Key Provider 配置加速 TLS 握手。"
publishdate: 2022-05-13
attribution: "Ravi kumar Veeramally (Intel), Ismo Puustinen (Intel), Sakari Poussa (Intel)"
keywords: [Istio, CryptoMB, gateways, sidecar]
---

就安全连接而言，加密操作是计算密集型和关键操作之一。Istio 使用 Envoy 作为“网关/边车”来处理安全连接和拦截流量。

根据以往的经验，当入口网关必须处理大量传入的 TLS 和通过 sidecar 代理的安全服务到服务连接时，Envoy 上的负载会增加。潜在的性能取决于许多因素，例如运行 Envoy 中的 cpuset 的大小、传入的流量模式和密钥大小等因素。这些因素可能会影响 Envoy 服务许多新传入的 TLS 请求。为了实现性能的提升和加速握手，Envoy 1.20 和 Istio 1.14 中引入了一项新功能。它可以通过第三代英特尔® 至强® 可扩展处理器、英特尔® 集成性能基元（英特尔® IPP）加密库、Envoy 中 CryptoMB 私钥提供程序方法支持以及 Istio 中使用 `ProxyConfig` 的配置来实现。

## CryptoMB{#cryptomb}

英特尔 IPP [加密库](https://github.com/intel/ipp-crypto/tree/develop/sources/ippcp/crypto_mb)支持对多缓冲区进行加密操作。简而言之，多缓冲区加密技术是通过使用 SIMD（单指令多数据）机制的英特尔® 高级矢量扩展 512（英特尔® AVX-512）指令实现的。多达八个 RSA 或 ECDSA 操作被收集到一个缓冲区中并同时处理，从而提供潜在的改进性能。英特尔 AVX-512 指令可用于最近推出的第三代英特尔至强可扩展处理器服务器处理器（Ice Lake 服务器）。

Envoy 的 CryptoMB 私钥提供程序的思路是在使用英特尔 AVX-512 多缓冲区指令，加速传入 TLS 握手的 RSA 操作。

## 使用英特尔 AVX-512 指令加速 Envoy的发展{#accelerate-envoy-with-intel-avx-512-instructions}

Envoy 使用 BoringSSL 作为默认的 TLS 库。BoringSSL 支持设置用于卸载异步私钥的操作方法,并且 Envoy 实现了一个私钥提供程序框架，以允许使用 BoringSSL 挂钩创建处理 TLS 握手私钥操作（签名和解密）的 Envoy 扩展。

CryptoMB 私钥提供程序是一个 Envoy 扩展，它使用英特尔 AVX-512 多缓冲区加速处理了 BoringSSL TLS RSA 操作。当发生新的握手时，BoringSSL 调用私钥提供程序来请求进行加密操作，然后控制权返回给 Envoy。RSA 请求被收集在一个缓冲区中。当缓冲区已满或计时器到期时，私钥提供程序会调用英特尔 AVX-512 处理缓冲区。当处理完成后，会通知 Envoy 加密操作已完成，并且可以继续握手。

{{< image link="./envoy-boringssl-pkp-flow.png" caption="Envoy <-> BoringSSL <-> PrivateKeyProvider" >}}

Envoy 工作线程具有可用于 8 个 RSA 请求的缓冲区大小。当第一个 RSA 请求存储在缓冲区中时，计时器将被启动（计时器持续时间由 CryptoMB 配置中的 `poll_delay` 字段设置）。

{{< image link="./timer-started.png" caption="Buffer timer started" >}}

当缓冲区已满或计时器到期时，会同时对所有 RSA 请求执行加密操作。与非加速情况相比，SIMD（单指令、多数据）处理具有潜在的性能优势。

{{< image link="./timer-expired.png" caption="Buffer timer expired" >}}

## Envoy CryptoMB 私钥提供程序配置{#envoy-cryptomb-private-key-provider-configuration}

常规的 TLS 配置仅使用私钥。当使用私钥提供程序时，私钥字段将被替换为私钥提供程序字段。它包含两个字段，提供程序名称和类型化配置。类型化配置是 CryptoMbPrivateKeyMethodConfig 文件，它指定了私钥和轮询延迟。

仅使用私钥的 TLS 配置。

{{< text yaml >}}
tls_certificates:
  certificate_chain: { "filename": "/path/cert.pem" }
  private_key: { "filename": "/path/key.pem" }
{{< /text >}}

使用 CryptoMB 私钥提供程序的 TLS 配置。

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

## Istio CryptoMB 私钥提供程序配置{#istio-cryptomb-private-key-provider-configuration}

在 Istio 中，CryptoMB 私钥提供程序配置可以使用 pod 注释应用于网格范围、网关特定或 pod 特定配置。用户将在 `ProxyConfig` 中的 `PrivateKeyProvider` 提供 `pollDelay` 值。此配置将应用于网格范围（网关和所有边车）。

{{< image link="./istio-mesh-wide-config.png" caption="Sample mesh wide configuration" >}}

### Istio Mesh 范围配置{#istio-mesh-wide-configuration}

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

### Istio 网关配置{#istio-gateways-configuration}

如果用户只想为入口网关应用私钥提供程序配置，请遵循以下示例配置。

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

### 使用 pod 注解的 Istio Sidecar 配置{#istio-sidecar-configuration-using-pod-annotations}

如果用户想将私钥提供程序配置应用于特定的应用程序中的 pod，请使用 pod 注释对其进行配置，如下例所示。

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

### 性能{#performance}

潜在的性能优势取决于许多因素。例如，正在运行的 cpuset Envoy 的大小、传入的流量模式、加密类型（RSA 或 ECDSA）和密钥大小。

下面，我们根据 k6、网关和 Fortio 服务器之间的总延迟显示性能。这些显示了使用 CryptoMB 提供程序的相对性能改进，并且绝不代表 Istio 的[一般性能或基准测试结果](/zh/docs/ops/deployment/performance-and-scalability/)。我们的测量使用不同的客户端工具（k6 和 fortio）、不同的设置（客户端、网关和在不同节点上运行的服务器），并且我们为每个 HTTP 请求创建一个新的 TLS 握手。

这里有一份[白皮书](https://www.intel.com/content/www/us/en/architecture-and-technology/crypto-acceleration-in-xeon-scalable-processors-wp.html)，其中包含性能数据。

{{< image link="./istio-ingress-gateway-tls-handshake-perf-num.png" caption="Istio ingress gateway TLS handshake performance comparison. Tested using 1.14-dev on May 10th 2022" >}}

上述比较中使用的配置。

* Azure AKS Kubernetes 集群
    * v1.21
    * 三个节点的集群
    * 每个节点 Standard_D4ds_v5：第三代 Intel® Xeon® Platinum 8370C (Ice Lake)，4 个 vCPU，16 GB 内存
* Istio
    * 1.14-dev
    * Istio 入口网关 pod
        * resources.request.cpu: 2
        * resources.request.memory: 4 GB
        * resources.limits.cpu: 2
        * resources.limits.memory: 4 GB
* K6
    * loadimpact/k6:latest
* Fortio
    * fortio/fortio:1.27.0
* K6 客户端、envoy 和 fortio pod 被迫通过 Kubernetes AntiAffinity 和节点选择器强制运行在不同的节点上
* 在上图中
    * Istio 已按上述配置安装
    * Istio 与 CryptoMB (AVX-512) 的上述配置加以下设置

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
