---
title: MySQL Connectivity Troubleshooting
description: Integrate VMs and bare metal hosts into an Istio mesh deployed on Kubernetes.
weight: 95
keywords: [mysql,mtls]
---

You may find MySQL can't be connected after installing Istio. This is because that `PERMISSIVE` mode,
default option `istio-demo.yaml` install, does not work with MySQL.

We have two options to solve the problem.

**Disable Mutual TLS**

Choose this option if you don't want Istio mutual TLS. You achieve this by disable mutual TLS on the MySQL
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

**Enable Mutual TLS in STRICT mode**

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