---
title: MySQL 连接故障排除
description: 解决由于 PERMISSIVE 模式导致的 MySQL 连接问题。
weight: 95
keywords: [mysql,mtls]
---

安装 Istio 后您可能会发现 MySQL 无法连接。这是因为 `istio-demo.yaml` 中默认使用的 `PERMISSIVE` 模式不适用于 MySQL。您可能会看到类似于 "ERROR 2013 (HY000): Lost connection to MySQL server at 'reading initial communication packet', system error: 0" 的错误。

有两种方法可以解决此问题。

1. 禁用双向 TLS。

    如果不需要 Istio 双向 TLS，您可以选择这种方法。您可以通过显式的禁用 MySQL 上的双向 TLS 来实现。

    {{< text syntax="bash" >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: mysql-nomtls-authn
    spec:
      targets:
      - name: YOUR-MYSQL-SERVICE     # The name of *your* K8s Service
    EOF
    {{< /text >}}

1. 在 STRICT 模式下启用双向 TLS。

    如果您需要为 MySQL 提供双向 TLS 保护，请使用目标规则和认证策略来启用双向 TLS。

    {{< text syntax="bash" >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: mysql-mtls-authn
    spec:
      targets:
      - name: YOUR-MYSQL-SERVICE     # The name of *your* K8s Service
      peers:
      - mtls:
          mode: STRICT
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: mysql-mtls-dr
    spec:
      host: YOUR-MYSQL-SERVICE     # The name of *your* K8s Service
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}
