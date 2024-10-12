---
title: 管理网格内证书
linktitle: 管理网格内证书
description: 如何配置您网格内的证书。
weight: 30
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers,istio/wg-environments-maintainers
test: n/a
---

{{< boilerplate experimental >}}

许多用户需要管理其环境中使用的各类证书。
例如，一些用户需要使用椭圆曲线加密（ECC），而其他用户可能需要使用位数更多的 RSA 证书。
对于大多数用户来说，在环境中配置证书可能是一项令人望而却步的任务。

本文内容仅适用于网格内部通信。要管理网关上的证书，
请参阅[安全网关](/zh/docs/tasks/traffic-management/ingress/secure-ingress/)文档。
要管理 istiod 所用的 CA 来生成工作负载证书，
请参阅[插件 CA 证书](/zh/docs/tasks/security/cert-management/plugin-ca-cert/)文档。

## istiod

当在没有根 CA 证书的情况下安装 Istio 时，istiod 将使用 RSA 2048 生成自签名的 CA 证书。

要更改自签名 CA 证书的位长度，您将需要修改提供给 `istioctl` 的 IstioOperator
清单或在 Helm 安装 [istio-discovery]({{< github_tree >}}/manifests/charts/istio-control/istio-discovery) Chart 期间使用的赋值文件。

{{< tip >}}
尽管 [pilot-discovery](/zh/docs/reference/commands/pilot-discovery/) 有许多环境变量可以更改，
但本文仅概述其中一些。
{{< /tip >}}

{{< tabset category-name="证书" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      env:
        CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text yaml >}}
pilot:
  env:
    CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Sidecar

由于 Sidecar 管理其本身用于网格内部通信的证书，因此 Sidecar 负责管理其私钥和生成的证书签发请求（CSR）。
需要修改 Sidecar 注入器以便为此注入环境变量。

{{< tip >}}
尽管 [pilot-agent](/zh/docs/reference/commands/pilot-agent/) 有许多环境变量可以更改，
但本文仅概述其中一些。
{{< /tip >}}

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text yaml >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< tab name="Annotation" category-value="annotation" >}}

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        ...
        proxy.istio.io/config: |
          CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
    spec:
      ...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 签名算法 {#signature-algorithm}

默认情况下，Sidecar 将创建 RSA 证书。
如果您想将其更改为 ECC，您需要将 `ECC_SIGNATURE_ALGORITHM` 设置为 `ECDSA`。

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ECC_SIGNATURE_ALGORITHM: "ECDSA"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text yaml >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      ECC_SIGNATURE_ALGORITHM: "ECDSA"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

只有 P256 和 P384 可通过 `ECC_CURVE` 支持。

如果您希望保留 RSA 签名算法并想要修改 RSA 密钥大小，
您可以更改 `WORKLOAD_RSA_KEY_SIZE` 的值。
