---
title: Authorization on Ingress Gateway
description: Shows how to set up access control on ingress gateway.
weight: 50
keywords: [security,access-control,rbac,authorization,ingress,ip,whitelist,blacklist]
---

This task shows you how to enforce access control on an Istio ingress gateway
using an authorization policy.

The authorization policy supports IP-based allow list or deny list and
attribute-based allow list or deny list previously provided by the Mixer policy.
The Mixer policy is deprecated in 1.5 and not recommended for production use.

## Before you begin

Before you begin this task, perform the following actions:

* Read the [Authorization conceptual documentation](/docs/concepts/security/#authorization).

* Install Istio using the [Istio installation guide](/docs/setup/install/istioctl/).

* Deploy a workload, `httpbin` in a namespace named, for example, `foo` and expose it
through the Istio ingress gateway with this command.

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin-gateway.yaml) -n foo
    {{< /text >}}

* Update the ingress gateway to set `externalTrafficPolicy: local` to preserve the
original client source IP on the ingress gateway using the following command.
See [Source IP for Services with `Type=NodePort`](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-nodeport)
for more information.

    {{< text bash >}}
    $ kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"externalTrafficPolicy":"Local"}}'
    {{< /text >}}

* Verify that the `httpbin` workload and ingress gateway are working as expected using this command.

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

* Verify the ingress gateway receives the original client source IP address, which
will be used in the authorization policy in this task.

    {{< text bash >}}
    $ CLIENT_IP=$(curl $INGRESS_HOST/ip -s | grep "origin" | cut -d'"' -f 4) && echo $CLIENT_IP
    105.133.10.12
    {{< /text >}}

{{< warning >}}
If you don’t see the expected output as you follow the task, retry after a few seconds.
Caching and propagation overhead can cause some delay.
{{< /warning >}}

## IP-based allow list and deny list

1. The following command creates the authorization policy, `ingress-policy`, for
the Istio ingress gateway. The following policy sets the `action` field to `ALLOW` to
allow the IP addresses specified in the `ipBlocks` to access the ingress gateway,
IP addresses not in the list will be denied, also known as whitelist-style access control.
The `ipBlocks` supports both single IP address and CIDR notation.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: ingress-policy
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: ALLOW
      rules:
      - from:
        - source:
           ipBlocks: ["1.2.3.4", "5.6.7.0/24"]
    EOF
    {{< /text >}}

1. Verify that a request to the ingress gateway is denied.

    {{< text bash >}}
    $ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. Update the `ingress-policy` to include your client IP address.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: ingress-policy
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: ALLOW
      rules:
      - from:
        - source:
           ipBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
    EOF
    {{< /text >}}

1. Verify that a request to the ingress gateway is allowed.

    {{< text bash >}}
    $ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. The following command updates the `ingress-policy` authorization policy to set
the `action` key to `DENY` so that the IP addresses specified in the `ipBlocks` are
not allowed to access the ingress gateway, also known as blacklist-style access control:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: ingress-policy
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: DENY
      rules:
      - from:
        - source:
           ipBlocks: ["$CLIENT_IP"]
    EOF
    {{< /text >}}

1. Verify that a request to the ingress gateway is denied.

    {{< text bash >}}
    $ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. You could use an online proxy service to access the ingress gateway that uses a
different client IP to verify the request is allowed.

## Clean up

1. Remove the namespace `foo` from your configuration:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

1. Remove the authorization policy:

    {{< text bash >}}
    $ kubectl delete authorizationpolicy ingress-policy -n istio-system
    {{< /text >}}
