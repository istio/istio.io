---
title: Extending Self-Signed Certificate Lifetime
description: Learn how to extend the lifetime of the Istio self-signed root certificate.
weight: 90
keywords: [security, PKI, certificate, Citadel]
aliases:
  - /help/ops/security/root-transition
  - /docs/ops/security/root-transition
---

Istio self-signed certificates have historically had a 1 year default lifetime.
If you are using Istio self-signed certificates,
you need to be mindful about the expiration date of the root certificate.
The expiration of a root certificate may lead to an unexpected cluster-wide outage.

To evaluate the lifetime remaining for your root certificate, please refer to the first step in the
[procedure below](#root-transition-procedure).

The steps below show you how to transition to a new root certificate.
After the transition, the new root certificate has a 10 year lifetime.
Note that the Envoy instances will be hot restarted to reload the new root certificates, which may impact long-lived connections.
For details about the impact and how Envoy hot restart works, please refer to
[here](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/hot_restart) and
[here](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5).

## Scenarios

If you are not currently using the mutual TLS feature in Istio and will not use it in the future,
you are not affected and no action is required.

If you may use the mutual TLS feature in the future, you should
follow the procedure below to perform a root certificate transition.

If you are currently using the mutual TLS feature in Istio with self-signed certificates,
please follow the procedure and check whether you will be affected.

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

1. Check the version of your sidecars and upgrade if needed:

    Some early versions of Istio sidecar could not automatically reload the new root certificate.
    Please run the following command to check the version of your Istio sidecars.

    {{< text bash>}}
    $ ./root-transition.sh check-version
    Checking namespace: default
    Istio proxy version: 1.3.5
    Checking namespace: istio-system
    Istio proxy version: 1.3.5
    Istio proxy version: 1.3.5
    ...
    {{< /text >}}

    If your sidecars are using versions lower than 1.0.8 and 1.1.8,
    please upgrade the Istio control plane and sidecars to versions no lower than 1.0.8 and 1.1.8.
    To upgrade, follow the Istio [upgrade procedure](/pt-br/docs/setup/upgrade/)
    or the procedure provided by your cloud service provider.

1. Execute a root certificate transition:

    During the transition, the Envoy sidecars may be hot-restarted to reload the new certificates.
    This may have some impact on your traffic. Please refer to
    [Envoy hot restart](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/hot_restart)
    and read [this](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5)
    blog post for more details.

    {{< warning >}}
    If your Pilot does not have an Envoy sidecar, consider installing one.
    Pilot has issues using the old root certificate to verify the new workload certificates, which
    may cause disconnection between Pilot and Envoy.
    Please see [here](#how-can-i-check-if-pilot-has-a-sidecar) for how to check for this
    condition.
    The [Istio upgrade guide](/pt-br/docs/setup/upgrade/)
    by default installs Pilot with a sidecar.
    {{< /warning >}}

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

1. Verify the new workload certificates are generated:

    {{< text bash>}}
    $ ./root-transition.sh verify-certs
    ...
    Checking the current root CA certificate is propagated to all the Istio-managed workload secrets in the cluster.
    Root cert MD5 is 8fa8229ab89122edba73706e49a55e4c
    Checking namespace: default
      Secret default.istio.default matches current root.
      Secret default.istio.sleep matches current root.
    Checking namespace: istio-system
      Secret istio-system.istio.default matches current root.
      ...

    =====All Istio mutual TLS keys and certificates match the current root!=====

    {{< /text >}}

    If this command fails, wait a minute and run the command again.
    It takes some time for Citadel to propagate the certificates.

1. Verify the new workload certificates are loaded by Envoy:

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

## Troubleshooting

### Why aren't workloads picking up the new certificates (in Step 5)?

Please make sure you have updated to 1.0.8, 1.1.8 or later for the `istio-proxy` sidecars in Step 2.

{{< warning >}}
If you are using Istio releases 1.1.3 - 1.1.7, the Envoy may not be hot-restarted
after the new certificates are generated.
{{< /warning >}}

### Why does Pilot not work and log "handshake error"?

This may because Pilot is
[not using an Envoy sidecar](#how-can-i-check-if-pilot-has-a-sidecar),
while the `controlPlaneSecurity` is enabled.
In this case, restart both Galley and Pilot to ensure they load the new certificates.
As an example, the following commands redeploy a pod for Galley / Pilot by removing a pod.

{{< text bash>}}
$ kubectl delete po <galley-pod> -n istio-system
$ kubectl delete po <pilot-pod> -n istio-system
{{< /text >}}

### How can I check if Pilot has a sidecar?

If the following command shows `1/1`, that means your Pilot does not have an Envoy sidecar,
otherwise, if it is showing `2/2`, your Pilot is using an Envoy sidecar.

{{< text bash>}}
$ kubectl get po -l istio=pilot -n istio-system
istio-pilot-569bc6d9c-tfwjr   1/1     Running   0          11m
{{< /text >}}

### Why can't I deploy new workloads with the sidecar-injector?

This may happen if you did not upgrade to 1.0.8, 1.1.8 or later.
Try to restart the sidecar injector.
The sidecar injector will reload the certificate after the restart:

{{< text bash>}}
$ kubectl delete po -l istio=sidecar-injector -n istio-system
pod "istio-sidecar-injector-788bd8fc48-x9gdc" deleted
{{< /text >}}
