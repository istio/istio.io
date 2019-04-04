---
title: MySQL Connectivity Troubleshooting
description: Trouble shooting MySQL connectivity issue due to PERMISSIVE mode.
weight: 95
keywords: [mysql,mtls]
---

You may find MySQL can't be connected after installing Istio. This is because of `PERMISSIVE` mode which is enabled in `istio-demo.yaml` by default, does not work with MySQL.

There have two options to solve the problem.

1. Disable Mutual TLS

    Choose this option if you don't want Istio mutual TLS. You achieve this by disabling mutual TLS on the MySQL
    service explicitly.

    {{< text syntax="bash" >}}
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

1. Enable mutual TLS in STRICT mode.

    If you want mutual TLS protection for MySQL, enable mutual TLS using a destination rule and an authentication policy.

    {{< text syntax="bash" >}}
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
