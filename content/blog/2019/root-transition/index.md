---
title: User guide for extenting Istio root certificate lifetime
description: The user guide to extend Istio root certificate lifetime.
publishdate: 2019-06-06
subtitle:
attribution: Oliver Liu
twitter:
keywords: [security, PKI, certificate, Citadel]

---

## Background

The Istio self-signed certificates have the default lifetime of 1 year.
If you are using the Istio self-signed certificates,
please schedule a root transition before it expires.
An expiration of root certificate may lead to an unexpected cluster-wide outage.
After the transition, the root certificate will be renewed to have 10 year lifetime.

{{< tip >}}
We strongly recommend you rotate root keys and root certificates anually as a security best practice.
We will send out instructions for root key/cert rotation as a follow-up.
{{< /tip >}}

To evaluate the lifetime remaining for your root certificate, please refer to Step 0 in the following procedure.

We provide the following procedure for you to do the root transition.
Note that the Envoy instances will be hot restarted to reload the new root certificates, which may impact the long-lived connections.
For details about the impacts and how Envoy hot restart works, please refer to
[here](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/hot_restart#arch-overview-hot-restart) and
[here](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5).

## Scenarios

If you are not currently using the mutual TLS feature in Istio and will not use it in the future,
you are not affected and no action is required.
You may choose to upgrade to 1.1.8 or later versions to avoid this problem in the future.

If you are not currently using the mutual TLS feature in Istio and may use it in the future,
you are recommended to follow the procedure listed below to upgrade.

If you are currently using the mutual TLS feature in Istio with self-signed certificates,
please follow the procedure and check whether you will be affected.

## Procedure

### Step 0. Check when the root certificate expires

Download this [script](TODO) on a machine that has `kubectl` access to the cluster.

{{< text bash>}}
$ ./root-transition.sh check
...
===YOU HAVE 30 DAYS BEFORE THE ROOT CERT EXPIRES!=====
{{< /text >}}

Execute the remainder of the steps prior to root certificate expiration to avoid system outages.

### Step 1. Execute a root certificate transition

During the transition, the Envoy sidecars may be hot-restarted. This may have some impact on your traffic.
Please refer to
[Envoy hot restart](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/hot_restart#arch-overview-hot-restart)
and read [this](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5)
blog post for more details.

{{< text bash>}}
$ ./root_transition.sh transition
create new ca cert, with trust domain as  cluster.abc
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
        Subject: O = " cluster.abc"
        ...
{{< /text >}}

### Step 2. Verify the new workload certificates are generated

{{< text bash>}}
$ ./root_transition.sh verify
This script checks the current root CA certificate is propagated to all the Istio-managed workload secrets in the cluster.                    
Root cert MD5 is 8fa8229ab89122edba73706e49a55e4c
Checking namespace: default
  Secret default.istio.default is updated.
  Secret default.istio.sleep is updated.
Checking namespace: istio-system
  Secret istio-system.istio.default is updated.
  ...
------All Istio keys and certificates are updated in secret!
{{< /text >}}

If this command fails, wait a minute and run the command again.
It takes time for Citadel to propogate the certificates.

### Step 3. Update to Istio 1.1.8

{{< warning >}}
To ensure the control plane components and Envoy sidecars all reload the new certificates and keys, this step is mandatory.
{{< /warning >}}

Upgrade your control plane and `istio-proxy` sidecars to 1.1.8.
To upgrade to 1.1.8, please follow the Istio [upgrade procedure](https://istio.io/docs/setup/kubernetes/upgrade/steps/).

### Step 4. Verify the new workload certificates are loaded by Envoy

You can verify whether an Envoy has received the new certificates.
The following command shows an example to check the Envoy’s certificate for pod _foo_ running in namespace _bar_.

{{< text bash>}}
$ kubectl exec -it foo -c istio-proxy -n bar -- curl http://localhost:15000/certs | head -c 1000
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
If it matches the `_Not_ _Before_` value in the new certificate as shown in Step 1,
your Envoy has loaded the new root certificate.

## Troubleshooting

### Why my workloads do not pick up the new certificates (in Step 4)?

Please make sure you have updated to Istio 1.1.8 for the `istio-proxy` sidecars in Step 3.

{{< warning >}}
If you are using Istio releases 1.1.3 - 1.1.7, the Envoy may not be hot-restarted
after the new certificates are generated.
{{< /warning >}}
