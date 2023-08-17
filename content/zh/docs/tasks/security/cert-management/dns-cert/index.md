---
title: Istio 的 DNS 证书管理
description: 如何在 Istiod 中配置和管理 DNS 证书。
weight: 90
keywords: [security,certificate]
aliases:
    - /zh/docs/tasks/security/dns-cert/
owner: istio/wg-security-maintainers
test: yes
---

此文档主要说明如何使用 [Chiron](/zh/blog/2019/dns-cert/) 配置和管理 DNS 证书。
Chiron 是一个与 Istiod 相连的轻量型组件，使用 Kubernetes 的 CA API 签发证书，
无需管理私钥。优势如下：

* 与 {{< gloss >}}Istiod{{< /gloss >}} 不同, 这种方式无需维护签发的私钥，增强了安全性。

* 简化了将根证书分发到 TLS 客户端。客户端不再需要等待 Istiod 生成和分发其 CA 证书。

## 开始之前{#before-you-begin}

* 通过 `istioctl` 安装 Istio，并配置 DNS 证书。当 Istio 启动后会读取该配置。

{{< text bash >}}
$ cat <<EOF > ./istio.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    certificates:
      - secretName: dns.example1-service-account
        dnsNames: [example1.istio-system.svc, example1.istio-system]
      - secretName: dns.example2-service-account
        dnsNames: [example2.istio-system.svc, example2.istio-system]
EOF
$ istioctl install -f ./istio.yaml
{{< /text >}}

## DNS 证书的提供和管理{#DNS-certificate-provisioning-and-management}

Istio 根据用户的配置，为 DNS 证书提供 DNS 名称和 Secret 名称。
DNS 证书 通过 Kubernetes CA 签发，并根据配置保存到 Secret 中。
Istio 也管理 DNS 证书的生命周期，包括证书的滚动和重新生成。

## 配置 DNS 证书{#configure-DNS-certificates}

在 `istioctl install` 命令中使用 `IstioOperator` 自定义资源用于配置 Istio。
`IstioOperator` 自定义资源包括 DNS 证书配置的例子。其中，`dnsNames`
字段定义证书中 DNS 名称，`secretName` 字段定义用于存储证书和私钥的
Kubernetes Secret 名称。

## 检查 DNS 证书的提供{#check-the-provisioning-of-DNS-certificates}

在配置 Istio 生成 DNS 证书和保存证书到 Secret 后，您可以校验证书是够已经生成并正常运行。

为了校验例子中 Istio 的配置 `dns.example1-service-account` 生成的 DNS
证书，和校验证书是否包含 配置的 DNS 名称，需要获取 Kubernetes 的 Secret
进行解析解码，通过以下命令查看具体内容：

{{< text bash >}}
$ kubectl get secret dns.example1-service-account -n istio-system -o jsonpath="{.data['cert-chain\.pem']}" | base64 --decode | openssl x509 -in /dev/stdin -text -noout
{{< /text >}}

输出内容包括：

{{< text plain >}}
            X509v3 Subject Alternative Name:
                DNS:example1.istio-system.svc, DNS:example1.istio-system
{{< /text >}}

## 重新生成 DNS 证书{#regenerating-a-DNS-certificate}

Istio 还可以在重新生成被误删的 DNS 证书。接下来，将会演示如何删除最近配置的证书，
并校验 Istio 自动重新生成证书。

1. 删除前面保存的配置 DNS 证书的 Secret：

    {{< text bash >}}
    $ kubectl delete secret dns.example1-service-account -n istio-system
    {{< /text >}}

1. 校验 Istio 重新生成已删除 DNS 证书，且证书包含配置的 DNS 名称，
   您需要获取 Kubernetes 的 Secret进行解析解码，通过以下命令查看详细内容：

    {{< text bash >}}
    $ sleep 10; kubectl get secret dns.example1-service-account -n istio-system -o jsonpath="{.data['cert-chain\.pem']}" | base64 --decode | openssl x509 -in /dev/stdin -text -noout
    {{< /text >}}

输出内容包括：

{{< text plain >}}
            X509v3 Subject Alternative Name:
                DNS:example1.istio-system.svc, DNS:example1.istio-system
{{< /text >}}

## 清理{#cleanup}

*   移除 `istio-system` Namespace：

    {{< text bash >}}
    $ kubectl delete ns istio-system
    {{< /text >}}
