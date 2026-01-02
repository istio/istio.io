---
title: "CryptoMB: aceleración del handshake TLS para Istio"
description: "Acelera el handshake TLS usando la configuración de CryptoMB Private Key Provider en gateways y sidecars de Istio."
publishdate: 2022-06-15
attribution: "Ravi kumar Veeramally (Intel), Ismo Puustinen (Intel), Sakari Poussa (Intel)"
keywords: [Istio, CryptoMB, gateways, sidecar]
---

Las operaciones criptográficas están entre las más intensivas en cómputo y críticas cuando hablamos de conexiones seguras. Istio usa Envoy como “gateway/sidecar” para gestionar conexiones seguras e interceptar el tráfico.

Según los casos de uso, cuando un ingress gateway debe gestionar un gran número de conexiones TLS entrantes y conexiones seguras servicio‑a‑servicio a través de proxies sidecar, aumenta la carga sobre Envoy. El rendimiento potencial depende de muchos factores, como el tamaño del cpuset en el que se ejecuta Envoy, los patrones de tráfico entrante y el tamaño de clave. Estos factores pueden afectar a Envoy a la hora de servir muchas nuevas peticiones TLS entrantes. Para lograr mejoras de rendimiento y handshakes acelerados, se introdujo una nueva funcionalidad en Envoy 1.20 e Istio 1.14. Puede lograrse con procesadores Intel® Xeon® Scalable de 3.ª generación, la librería criptográfica Intel® Integrated Performance Primitives (Intel® IPP), el soporte en Envoy del método CryptoMB Private Key Provider, y la configuración de Private Key Provider en Istio usando `ProxyConfig`.

## CryptoMB

La [librería crypto de Intel IPP](https://github.com/intel/ipp-crypto/tree/develop/sources/ippcp/crypto_mb) soporta operaciones criptográficas multi‑buffer. En resumen, la criptografía multi‑buffer se implementa con instrucciones Intel® Advanced Vector Extensions 512 (Intel® AVX‑512) usando un mecanismo SIMD (single instruction, multiple data). Se pueden agrupar hasta ocho operaciones RSA o ECDSA en un buffer y procesarlas al mismo tiempo, lo que puede mejorar el rendimiento. Las instrucciones Intel AVX‑512 están disponibles en los procesadores servidor Intel Xeon Scalable de 3.ª generación lanzados recientemente (Ice Lake server).

La idea del private key provider CryptoMB de Envoy es que las operaciones RSA de los handshakes TLS entrantes se aceleren usando instrucciones multi‑buffer Intel AVX‑512.

## Acelerar Envoy con instrucciones Intel AVX‑512

Envoy usa BoringSSL como librería TLS por defecto. BoringSSL soporta configurar métodos de clave privada para descargar operaciones asíncronas de clave privada, y Envoy implementa un framework de private key provider para permitir crear extensiones de Envoy que gestionen operaciones de clave privada en el handshake TLS (firma y descifrado) usando los hooks de BoringSSL.

CryptoMB private key provider es una extensión de Envoy que gestiona operaciones RSA TLS de BoringSSL usando aceleración multi‑buffer Intel AVX‑512. Cuando se produce un nuevo handshake, BoringSSL invoca el private key provider para solicitar la operación criptográfica y el control vuelve a Envoy. Las peticiones RSA se agrupan en un buffer. Cuando el buffer está lleno o expira el temporizador, el private key provider invoca el procesamiento Intel AVX‑512 del buffer. Cuando el procesamiento termina, se notifica a Envoy que la operación criptográfica ha finalizado y puede continuar con los handshakes.

{{< image link="./envoy-boringssl-pkp-flow.png" caption="Envoy <-> BoringSSL <-> PrivateKeyProvider" >}}

El worker thread de Envoy tiene un buffer con capacidad para ocho peticiones RSA. Cuando se almacena la primera petición RSA en el buffer, se inicia un temporizador (su duración se establece con el campo `poll_delay` en la configuración de CryptoMB).

{{< image link="./timer-started.png" caption="Buffer timer started" >}}

Cuando el buffer está lleno o expira el temporizador, se realizan las operaciones criptográficas para todas las peticiones RSA de forma simultánea. El procesamiento SIMD (single instruction, multiple data) aporta el potencial beneficio de rendimiento frente al caso no acelerado.

{{< image link="./timer-expired.png" caption="Buffer timer expired" >}}

## Configuración de Envoy para CryptoMB Private Key Provider

Una configuración TLS habitual solo usa una clave privada. Cuando se usa un private key provider, el campo de clave privada se reemplaza por un campo de private key provider. Contiene dos campos: nombre del provider y typed config. El typed config es `CryptoMbPrivateKeyMethodConfig` y especifica la clave privada y el poll delay.

Configuración TLS con solo una clave privada.

{{< text yaml >}}
tls_certificates:
  certificate_chain: { "filename": "/path/cert.pem" }
  private_key: { "filename": "/path/key.pem" }
{{< /text >}}

Configuración TLS con CryptoMB private key provider.

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

## Configuración de Istio para CryptoMB Private Key Provider

En Istio, la configuración de CryptoMB private key provider puede aplicarse a nivel de mesh (mesh‑wide), específica de gateways o específica de pods usando anotaciones de pod. El usuario proporcionará el `PrivateKeyProvider` en el `ProxyConfig` con el valor `pollDelay`. Esta configuración se aplicará a todo el mesh (gateways y todos los sidecars).

{{< image link="./istio-mesh-wide-config.png" caption="Ejemplo de configuración a nivel de mesh" >}}

### Configuración a nivel de mesh (mesh‑wide) en Istio

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

### Configuración de gateways en Istio

Si un usuario quiere aplicar la configuración de private key provider solo al ingress gateway, puede seguir el siguiente ejemplo.

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

### Configuración de sidecar en Istio usando anotaciones de pod

Si un usuario quiere aplicar la configuración de private key provider a pods concretos de una aplicación, puede configurarlos usando anotaciones de pod como en el siguiente ejemplo.

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

El beneficio potencial de rendimiento depende de muchos factores. Por ejemplo: el tamaño del cpuset en el que se ejecuta Envoy, el patrón de tráfico entrante, el tipo de cifrado (RSA o ECDSA) y el tamaño de clave.

A continuación mostramos rendimiento basándonos en la latencia total entre k6, el gateway y el servidor Fortio. Estas cifras muestran una mejora relativa usando el provider CryptoMB y no son representativas del [rendimiento general o benchmarks de Istio](https://archive.istio.io/v1.16/docs/ops/deployment/performance-and-scalability/). Nuestras mediciones usan herramientas cliente distintas (k6 y fortio), un setup distinto (cliente, gateway y servidor ejecutándose en nodos separados) y creamos un nuevo handshake TLS en cada petición HTTP.

Hemos [publicado un white paper](https://www.intel.com/content/www/us/en/architecture-and-technology/crypto-acceleration-in-xeon-scalable-processors-wp.html) con cifras generales de rendimiento criptográfico.

{{< image link="./istio-ingress-gateway-tls-handshake-perf-num.png" caption="Comparación de rendimiento de handshake TLS en el ingress gateway de Istio. Probado usando 1.14-dev el 10 de mayo de 2022" >}}

Configuración usada en la comparación anterior.

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
