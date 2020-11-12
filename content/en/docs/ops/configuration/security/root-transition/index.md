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

{{< tip >}}
You can skip this guide if your cluster was started with Istio version 1.3 or later,
or if you do not use the Istio self-signed certificates.
{{< /tip >}}

Before version 1.3, Istio self-signed certificates had a 1 year default lifetime.
If your cluster started with Istio version 1.2 or earlier,
and it is using Istio self-signed certificates,
you need to be mindful about the expiration date of the root certificate.
The expiration of a root certificate may lead to an unexpected cluster-wide outage.

The following steps show you how to examine the remaining lifetime for your root certificate,
and how to transition to a new root certificate with a 10 year lifetime.

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

    {{< text bash>}}
    $ ./root-transition.sh root-transition
    Create new ca cert, with trust domain as cluster.local
    Wed Jun  5 19:11:15 PDT 2019 delete old ca secret
    secret "istio-ca-secret" deleted
    Wed Jun  5 19:11:15 PDT 2019 create new ca secret
    secret/istio-ca-secret created
    pod "istiod-86f88b6f6-d8hjt" deleted
    Wed Jun  5 19:11:18 PDT 2019 restarted Citadel, checking status
    NAME                                   READY   STATUS    RESTARTS   AGE
    istiod-5d4798c786-w782z                1/1     Running   0          3s
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

    Envoy proxies will retrieve the new root certificate when they rotate the workload key and certificates.
    Because the rotation is triggered based on the remaining lifetime of the existing certificate,
    with the default 24 hour workload certificate lifetime,
    expect the root transition to happen within the next 12 hours
    (within the 12 hour window, all workloads should rotate their keys and certificates).
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

    Inspect the `valid_from` value of `ca_cert`.
    If it matches the `_Not_ _Before_` value in the new certificate as shown in Step 2,
    your Envoy has loaded the new root certificate.
    If you see your Envoy is not able to load the new certificate, check the health of Istiod.
    You may also manually restart the workloads.