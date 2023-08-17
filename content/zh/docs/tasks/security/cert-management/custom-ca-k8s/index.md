---
title: 使用 Kubernetes CSR 自定义 CA 集成
description: 演示如何使用自定义证书颁发机构（与 Kubernetes CSR API 集成）来提供 Istio 工作负载证书。
weight: 100
keywords: [security,certificate]
aliases:
    - /zh/docs/tasks/security/custom-ca-k8s/
owner: istio/wg-security-maintainers
test: no
status: Experimental
---

{{< boilerplate experimental >}}

这个特性需要 Kubernetes 版本 >= 1.18。

此任务演示如何使用集成了
[Kubernetes CSR API](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/certificate-signing-requests/)
的自定义证书颁发机构来制备工作负载证书。不同的工作负载可以获取不同的证书签名者签名的证书。
每个证书签名者本质上是一个不同的 CA。可以预期的是，如果工作负载的证书是同一个证书签名者颁发的，
则这些工作负载可以与 MTLS 通信，而不同签名者签名的工作负载则不能这样。这个特性利用了
[Chiron](/zh/blog/2019/dns-cert/)，这是一个与 Istiod 关联的轻量级组件，使用 Kubernetes CSR API 签署证书。

在本例中，我们使用[开源 cert-manager](https://cert-manager.io)。Cert-manager 从 1.4
版本开始已增加了[对 Kubernetes `CertificateSigningRequests` 实验性支持](https://cert-manager.io/docs/usage/kube-csr/)。

## 在 Kubernetes 集群中部署自定义 CA 控制器{#deploy-custom-ca-controller-in-the-k8s-cluster}

1. 按照[安装文档](https://cert-manager.io/docs/installation/)部署 cert-manager。

    {{< warning >}}
    确保启用特性门控 `--feature-gates=ExperimentalCertificateSigningRequestControllers=true`。
    {{< /warning >}}

1. 为 cert-manager 创建三个自签名的集群签发器：`istio-system`、`foo` 和 `bar`。
   注：也可以使用命名空间签发器和其他类型的签发器。

    {{< text bash >}}
    $ cat <<EOF > ./selfsigned-issuer.yaml
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-bar-issuer
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: bar-ca
      namespace: cert-manager
    spec:
      isCA: true
      commonName: bar
      secretName: bar-ca-selfsigned
      issuerRef:
        name: selfsigned-bar-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: bar
    spec:
      ca:
        secretName: bar-ca-selfsigned
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-foo-issuer
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: foo-ca
      namespace: cert-manager
    spec:
      isCA: true
      commonName: foo
      secretName: foo-ca-selfsigned
      issuerRef:
        name: selfsigned-foo-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: foo
    spec:
      ca:
        secretName: foo-ca-selfsigned
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-istio-issuer
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: istio-ca
      namespace: cert-manager
    spec:
      isCA: true
      commonName: istio-system
      secretName: istio-ca-selfsigned
      issuerRef:
        name: selfsigned-istio-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: istio-system
    spec:
      ca:
        secretName: istio-ca-selfsigned
    EOF
    $ kubectl apply -f ./selfsigned-issuer.yaml
    {{< /text >}}

## 导出每个集群签发器的根证书{#export-root-certificates-for-each-cluster-issuer}

{{< text bash >}}
$ export istioca=$(kubectl get clusterissuers istio-system -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d)
$ export fooca=$(kubectl get clusterissuers foo -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d)
$ export barca=$(kubectl get clusterissuers bar -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d)
{{< /text >}}

## 使用默认的证书签名者信息部署 Istio{#deploy-istio-with-default-cert-signer-info}

1. 使用具有以下配置的 `istioctl` 在集群上部署 Istio。`ISTIO_META_CERT_SIGNER` 是工作负载所用的默认证书签名者。

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      values:
        pilot:
          env:
            EXTERNAL_CA: ISTIOD_RA_KUBERNETES_API
      meshConfig:
        defaultConfig:
          proxyMetadata:
            ISTIO_META_CERT_SIGNER: istio-system
        caCertificates:
        - pem: |
          $istioca
          certSigners:
          - clusterissuers.cert-manager.io/istio-system
        - pem: |
          $fooca
          certSigners:
          - clusterissuers.cert-manager.io/foo
        - pem: |
          $barca
          certSigners:
          - clusterissuers.cert-manager.io/bar
      components:
        pilot:
          k8s:
            env:
            - name: CERT_SIGNER_DOMAIN
              value: clusterissuers.cert-manager.io
            - name: PILOT_CERT_PROVIDER
              value: k8s.io/clusterissuers.cert-manager.io/istio-system
            overlays:
              - kind: ClusterRole
                name: istiod-clusterrole-istio-system
                patches:
                  - path: rules[-1]
                    value: |
                      apiGroups:
                      - certificates.k8s.io
                      resourceNames:
                      - clusterissuers.cert-manager.io/foo
                      - clusterissuers.cert-manager.io/bar
                      - clusterissuers.cert-manager.io/istio-system
                      resources:
                      - signers
                      verbs:
                      - approve
    EOF
    $ istioctl install -f ./istio.yaml
    {{< /text >}}

1. 创建 `bar` 和 `foo` 命名空间。

    {{< text bash >}}
    $ kubectl create ns bar
    $ kubectl create ns foo
    {{< /text >}}

1. 在 `bar` 命名空间中部署 `proxyconfig-bar.yaml`，以便在 `bar` 命名空间中为工作负载定义证书签名者。

    {{< text bash >}}
    $ cat <<EOF > ./proxyconfig-bar.yaml
    apiVersion: networking.istio.io/v1beta1
    kind: ProxyConfig
    metadata:
      name: barpc
      namespace: bar
    spec:
      environmentVariables:
        ISTIO_META_CERT_SIGNER: bar
    EOF
    $ kubectl apply  -f ./proxyconfig-bar.yaml
    {{< /text >}}

1. 在 `foo` 命名空间中部署 `proxyconfig-foo.yaml`，以便在 `foo` 命名空间中为工作负载定义证书签名者。

    {{< text bash >}}
    $ cat <<EOF > ./proxyconfig-foo.yaml
    apiVersion: networking.istio.io/v1beta1
    kind: ProxyConfig
    metadata:
      name: foopc
      namespace: foo
    spec:
      environmentVariables:
        ISTIO_META_CERT_SIGNER: foo
    EOF
    $ kubectl apply  -f ./proxyconfig-foo.yaml
    {{< /text >}}

1. 在 `foo` 和 `bar` 命名空间中部署 `httpbin` 和 `sleep` 样例应用程序。

    {{< text bash >}}
    $ kubectl label ns foo istio-injection=enabled
    $ kubectl label ns bar istio-injection=enabled
    $ kubectl apply -f samples/httpbin/httpbin.yaml -n foo
    $ kubectl apply -f samples/sleep/sleep.yaml -n foo
    $ kubectl apply -f samples/httpbin/httpbin.yaml -n bar
    {{< /text >}}

## 验证相同命名空间内 `httpbin` 和 `sleep` 之间的网络连通性{#verify-network-connectivity-between-httpbin-and-sleep-within-a-namespace}

在部署工作负载时，它们会发送具有相关签名者信息的 CSR 请求。Istiod 将这些 CSR 请求转发到自定义 CA 进行签名。
自定义 CA 将使用正确的集群签发器在证书上签名。`foo` 命名空间下的工作负载将使用 `foo` 集群签发器，
而 `bar` 命名空间下的工作负载将使用 `bar` 集群签发器。要验证它们已经被正确的集群签发器进行了真正的签名，
我们可以验证相同命名空间下的工作负载可以通信，而不同命名空间下的工作负载不能通信。

1. 将 `SLEEP_POD_FOO` 环境变量设置为 `sleep` Pod 的名称。

    {{< text bash >}}
    $ export SLEEP_POD_FOO=$(kubectl get pod -n foo -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

1. 检查 `foo` 命名空间中 `sleep` 和 `httpbin` 服务之间的网络连通性。

    {{< text bash >}}
    $ kubectl exec -it $SLEEP_POD_FOO -n foo -c sleep curl http://httpbin.foo:8000/html
    <!DOCTYPE html>
    <html>
      <head>
      </head>
      <body>
          <h1>Herman Melville - Moby-Dick</h1>

          <div>
            <p>
              Availing himself of the mild...
            </p>
          </div>
      </body>
     {{< /text >}}

1. 检查 `foo` 命名空间中的 `sleep` 服务与 `bar` 命名空间中的 `httpbin` 服务之间的网络连通性。

    {{< text bash >}}
    $ kubectl exec -it $SLEEP_POD_FOO -n foo -c sleep curl http://httpbin.bar:8000/html
    upstream connect error or disconnect/reset before headers. reset reason: connection failure, transport failure reason: TLS error: 268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED
    {{< /text >}}

## 清理{#cleanup}

* 移除 `istio-system`、`foo` 和 `bar` 命名空间：

    {{< text bash >}}
    $ kubectl delete ns istio-system
    $ kubectl delete ns foo
    $ kubectl delete ns bar
    {{< /text >}}

## 使用此特性的原因{#reasons-to-use-this-feature}

* 自定义 CA 集成 - 通过在 Kubernetes CSR 请求中指定签名者名称，此特性允许 Istio 使用 Kubernetes CSR API
  接口与自定义证书颁发机构集成。这确实需要自定义 CA 来实现一个 Kubernetes 控制器来观察
  `CertificateSigningRequest` 和 `Certificate` 资源并对其采取行动。

* 更好的多租户 - 通过为不同工作负载指定不同的证书签名者，不同租户的工作负载所用的证书可以由不同的 CA 进行签名。
