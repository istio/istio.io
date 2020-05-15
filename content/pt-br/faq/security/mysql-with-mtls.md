---
title: MySQL Connectivity Troubleshooting
description: Troubleshooting MySQL connectivity issue due to PERMISSIVE mode.
weight: 95
keywords: [mysql,mtls]
---

You may find MySQL can't connect after installing Istio. This is because of `PERMISSIVE` mode,
which is enabled in the `demo` [configuration profile](/pt-br/docs/setup/additional-setup/config-profiles/),
does not work with MySQL.
You may see error messages such as `ERROR 2013 (HY000): Lost connection to MySQL server at
'reading initial communication packet', system error: 0`.

There have two options to solve the problem.

1. Disable Mutual TLS.

    Choose this option if you don't want Istio mutual TLS. You achieve this by disabling mutual TLS on the MySQL
    service explicitly.

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

1. Enable mutual TLS in STRICT mode.

    If you want mutual TLS protection for MySQL, enable mutual TLS using a destination rule and an authentication policy.

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
