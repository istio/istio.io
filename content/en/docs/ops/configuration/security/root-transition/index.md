---
title: Extending Self-Signed Certificate Lifetime
description: Learn how to extend the lifetime of the Istio self-signed root certificate.
weight: 90
keywords: [security, PKI, certificate, Citadel]
aliases:
  - /help/ops/security/root-transition
  - /docs/ops/security/root-transition
owner: istio/wg-security-maintainers
test: n/a
---

Istio self-signed certificates have historically had a 1 year default lifetime.
If you are using Istio self-signed certificates,
you need to be mindful about the expiration date of the root certificate.
The expiration of a root certificate may lead to an unexpected cluster-wide outage.

To evaluate the lifetime remaining for your root certificate, please refer to the first step in the
[procedure below](#root-transition-procedure).

The steps below show you how to transition to a new root certificate.
After the transition, the new root certificate has a 10 year lifetime.
From Istio V1.5, Envoy can automatically load the new root certificate when it refreshes its
certificate.

## Scenarios

If you are not currently using the mutual TLS feature in Istio and will not use it in the future,
you are not affected and no action is required.

If your cluster started using Istio from V1.3 or later versions,
you are not affected and no action is required.

## Root transition procedure

1. Check when the root certificate expires:

    Download this [script](https://raw.githubusercontent.com/istio/tools/{{< source_branch_name >}}/bin/root-transition.sh)
    on a machine that has `kubectl` access to the cluster.

    {{< text bash>}}
    $ wget https://raw.githubusercontent.com/istio/tools/{{< source_branch_name >}}/bin/root-transition.sh
    $ chmod +x root-transition.sh
    $ ./root-transition.sh check-root
    ...
    =====YOU HAVE 30 DAYS BEFORE THE ROOT CERT EXPIRES!=====
    {{< /text >}}

    Execute the remainder of the steps prior to root certificate expiration to avoid system outages.

1. Execute a root certificate transition:

    From Istio V1.5, Envoy can automatically load the new root certificate when it refreshes its
    certificate.

    {{< text bash>}}
    $ ./root-transition.sh root-transition
    Create new ca cert, with trust domain as cluster.local
    Wed Jun  5 19:11:15 PDT 2019 delete old ca secret
    secret "istio-ca-secret" deleted
    Wed Jun  5 19:11:15 PDT 2019 create new ca secret
    secret/istio-ca-secret created
    pod "istio-citadel-8574b88bcd-j7v2d" deleted
    Wed Jun  5 19:11:18 PDT 2019 restarted Citadel, checking status
    NAME                             READY     STATUS    RESTARTS   AGE
    istio-citadel-8574b88bcd-l2g74   1/1       Running   0          3s
    New root certificate:
    Certificate:
        Data:
            ...
            Validity
                Not Before: Jun  6 03:24:43 2019 GMT
                Not After : Jun  3 03:24:43 2029 GMT
            Subject: O = cluster.local
            ...
    Your old certificate is stored as old-ca-cert.pem, and your private key is stored as ca-key.pem
    Please save them safely and privately.
    {{< /text >}}

1. Verify the new workload certificates are loaded by Envoy:

    Envoy in the mesh will retrieve the new root certificate when they rotate the workload key and
    certificates.
    You can verify whether an Envoy has received the new certificates.
    The following command shows an example to check the Envoy’s certificate for a pod.

    {{< text bash>}}
    $ kubectl exec [YOUR_POD] -c istio-proxy -n [YOUR_NAMESPACE] -- curl http://localhost:15000/certs | head -c 1000
    {
     "certificates": [
      {
       "ca_cert": [
          ...
          "valid_from": "2019-06-06T03:24:43Z",
          "expiration_time": ...
       ],
       "cert_chain": [
        {
          ...
        }
    {{< /text >}}

    Please inspect the `valid\_from` value of the `ca\_cert`.
    If it matches the `_Not_ _Before_` value in the new certificate as shown in Step 3,
    your Envoy has loaded the new root certificate.

