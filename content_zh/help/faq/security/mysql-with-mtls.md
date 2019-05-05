---
title: MySQL 连接错误的排查
description: 解决由于 PERMISSIVE 模式导致的 MySQL 连接问题。
weight: 95
keywords: [mysql,mtls]
---

在安装 Istio 之后，你可能会遇到 MySQL 无法连接的问题。这是因为 `istio-demo.yaml` 中缺省启用了 `PERMISSIVE`，这一模式会影响 MySQL 的连接。

有两种方法可以解决这一问题。

1. 禁用双向 TLS

    如果不需要 Istio 的双向 TLS 支持的话，就可以选择这一方法。可以在 MySQL 服务上显式的禁用双向 TLS。

    {{< text syntax="bash" outputis="yaml" >}}
    $ kubectl apply -f <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: mysql-nomtls-authn
    spec:
      targets:
      - name: mysql-service
    EOF
    {{< /text >}}

1. 用 STRICT 模式启用双向 TLS

    如果希望使用双向 TLS 保护 MySQL，可以用 `DestinationRule` 结合认证策略来启用双向 TLS。

    {{< text syntax="bash" outputis="yaml" >}}
    $ kubectl apply -f <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: mysql-mtls-authn
    spec:
      targets:
      - name: mysql-service
      peers:
      - mtls:
          mode: STRICT
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: mysql-mtls-dr
    spec:
      host: "mysql-service"
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}
