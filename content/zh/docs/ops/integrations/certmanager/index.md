---
title: cert-manager
description: 关于如何与 cert-manager 集成的相关说明。
weight: 26
keywords: [integration,cert-manager]
aliases:
  - /zh/docs/tasks/traffic-management/ingress/ingress-certmgr/
  - /zh/docs/examples/advanced-gateways/ingress-certmgr/
owner: istio/wg-environments-maintainers
test: no
---

[cert-manager](https://cert-manager.io/) 是一种自动执行证书管理的工具，
它可以与 Istio Gateway 集成以管理 TLS 证书。

## 配置 {#configuration}

查阅 [cert-manager 安装文档](https://cert-manager.io/docs/installation/kubernetes/)来快速开始，
它无需特殊配置即可与 Istio 一起使用。

## 使用 {#usage}

### Istio Gateway {#istio-gateway}

cert-manager 可用于向 Kubernetes 写入 Secret 秘钥，Gateway 可以引用该秘钥。

1. 首先，按照 [cert-manager 颁发者文档](https://cert-manager.io/docs/configuration/)配置 `Issuer` 资源。
   `Issuer` 是代表证书颁发机构（CA）的 Kubernetes 资源，
   证书颁发机构能够通过尊重证书签名请求来生成签名证书。例如：`Issuer` 可能如下所示：

    {{< text yaml >}}
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: ca-issuer
      namespace: istio-system
    spec:
      ca:
        secretName: ca-key-pair
    {{< /text >}}

    {{< tip >}}
    对于常见的发行者类型 ACME，创建一个 Pod 和服务来响应质询请求，以验证客户端是否拥有该域。
    为了应对这些挑战，需要可以访问位于 `http://<YOUR_DOMAIN>/.well-known/acme-challenge/<TOKEN>` 的端点。
    该配置可能是特定于实现的。
    {{< /tip >}}

1. 接下来，按照 [cert-manager 文档](https://cert-manager.io/docs/usage/certificate/) 配置 `Certificate` 资源。
   应在与 `istio-ingressgateway` 部署相同的命名空间中创建 `Certificate`。例如，`Certificate` 可能如下所示：

    {{< text yaml >}}
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: ingress-cert
      namespace: istio-system
    spec:
      secretName: ingress-cert
      commonName: my.example.com
      dnsNames:
      - my.example.com
      ...
    {{< /text >}}

1. 一旦创建了 `Certificate` 资源，我们就能在 `istio-system`
   命名空间中看到创建的秘钥，接着就可以在 Gateway 的 `tls`
   配置下的 `cresentialName` 字段中引用它：

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1
    kind: Gateway
    metadata:
      name: gateway
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: ingress-cert # This should match the Certificate secretName
        hosts:
        - my.example.com # This should match a DNS name in the Certificate
    {{< /text >}}

### Kubernetes Ingress {#kubernetes-ingress}

cert-manager 通过 [在 Ingress 对象上配置注解](https://cert-manager.io/docs/usage/ingress/)，
做到与 Kubernetes Ingress 的直接集成。如果使用此方法，则 Ingress 必须与
`istio-ingressgateway` Deployment 位于同一命名空间中，因为 Secret
只能在同一命名空间中被读取。

或者，也可以按照 [Istio Gateway](#istio-gateway) 部分的描述创建
`Certificate`，然后在 `Ingress` 对象中引用它：

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress
  annotations:
    kubernetes.io/ingress.class: istio
spec:
  rules:
  - host: my.example.com
    http: ...
  tls:
  - hosts:
    - my.example.com # 这应该与证书中的 DNS 名称相匹配
    secretName: ingress-cert # 这应该与证书的 Secret 名称相匹配
{{< /text >}}
