---
title: Istio DNS 证书管理
description: 展示如何准备和管理 Istio DNS 证书。
weight: 90
keywords: [security,certificate]
---

{{< boilerplate experimental-feature-warning >}}

默认情况下，Citadel 负责准备和管理 Galley webhooks 及 sidecar 注入器所使用的 DNS 证书。Citadel 是一个功能丰富的组件，不仅维护自身的签名密钥，还充当着 Istio 的 CA。

在特定部署场景中，您或许希望使用自己的证书授权机构取代 Citadel。此时，Citadel 不再发挥其准备 DNS 证书的功能。在这种情况下，无须部署 Citadel，您可以使用一个轻量级组件 Chiron 取而代之。Chiron 与 Pilot 关联在一起，通过 Kubernetes CA APIs 签名证书，不用维护自己的私有密钥。

本任务展示如何通过 Chiron 为 Istio 的控制平面组件准备和管理 DNS 证书。该特性具备以下优点：

* 比 Citadel 更加轻量级。

* 不像 Citadel，该特性无需维护一个私有的签名密钥，增强了安全性。

* 简化了向 TLS 客户端分发根证书的过程。客户端无需等待 Citadel 生成并分发 CA 证书。

## 开始之前{#before-you-begin}

* 配置好 DNS 证书，使用 `istioctl` 安装 Istio。
Pilot 启动时，读取配置文件。

{{< text bash >}}
$ cat <<EOF > ./istio.yaml
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
spec:
  values:
    global:
      certificates:
        - secretName: dns.istio-galley-service-account
          dnsNames: [istio-galley.istio-system.svc, istio-galley.istio-system]
        - secretName: dns.istio-sidecar-injector-service-account
          dnsNames: [istio-sidecar-injector.istio-system.svc, istio-sidecar-injector.istio-system]
EOF
$ istioctl manifest apply -f ./istio.yaml
{{< /text >}}

* 安装 [`jq`](https://stedolan.github.io/jq/) ，验证运行结果。

## 准备和管理 DNS 证书{#DNS-certificate-provisioning-and-management}

Istio 根据您提供的配置文件设置 DNS 证书的 DNS 域名和 secret 名。
准备好的 DNS 证书经 Kubernetes CA 签名后，存储在配置文件指明的 secrets 中。
Istio 还需要管理 DNS 证书的生命周期，包括证书的轮换和重新生成。

## 配置 DNS 证书{#configure-DNS-certificates}

`IstioControlPlane` 自定义资源提供了一个 DNS 证书配置模版，用来通过 `istioctl manifest apply` 命令配置 Istio （见上文）。其中，`dnsName` 域指定证书的 DNS 域名，`secretName` 域指定用于存储证书和密钥的 Kubernetes secret 名。

## 检查 DNS 证书的准备工作{#check-the-provisioning-of-DNS-certificates}

配置好 Istio 生成 DNS 证书并根据您的要求指定好存放它的 secretes 之后，您可以验证证书按预期被准备出来且如常工作。

为了检查 Istio 按照示例配置生成了 `dns.istio-galley-service-account` DNS 证书，并且证书中包含配置好的 DNS 域名，您需要从 Kubernetes 中获取 secret，进行解析解码并检查它的输出文本，命令如下：

{{< text bash >}}
$ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
{{< /text >}}

输出文本应该包括：

{{< text plain >}}
X509v3 Subject Alternative Name:
  DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
{{< /text >}}

## 重新生成一个 DNS 证书{#regenerating-a-DNS-certificate}

Istio 也可以重新生成被误删的 DNS 证书。接下来，我们展示如何删除一个近期配置好的证书并验证 Istio 自动重新生成了该证书。

1. 删除存储之前配置好的 DNS 证书的 secret：

    {{< text bash >}}
    $ kubectl delete secret dns.istio-galley-service-account -n istio-system
    {{< /text >}}

1. 为了检查 Istio 重新生成了已删除的 DNS 证书，并且该证书包含配置好的 DNS 域名，您需要从 Kubernetes 中获取 secret，进行解析解码并检查它的输出文本，命令如下：

    {{< text bash >}}
    $ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
    {{< /text >}}

输出应该包括：

{{< text plain >}}
X509v3 Subject Alternative Name:
  DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
{{< /text >}}
