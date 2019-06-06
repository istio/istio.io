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

For Istio releases prior to 1.0.8 and prior to 1.1.8, the Istio self-signed certificates have the default lifetime of 1 year.
If you are using the Istio self-signed certificates with default lifetime configuration,
please schedule a root transition before it expires. An expiration of root certificate may lead to an unexpected cluster-wide outage.
After the transition, the root certificate will be renewed to have 10 year lifetime.
As a best practice for security, we strongly recommend you to do annual root key/cert rotation.
We will send out instructions for root key/cert rotation as a follow-up.

To evaluate the lifetime remaining for your root certificate, please refer to Step 0 in the following procedure.

We provide the following procedure for you to do the root transition.
Note that the Envoy instances will be hot restarted to reload the new root certificates, which may impact the long-lived connections.
For details about the impacts and how Envoy hot restart works, please refer to
[here](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/hot_restart#arch-overview-hot-restart) and
[here](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5).

## Scenarios

If you are not currently using the mTLS feature in Istio and will not use it in the future,
you are not affected and should only upgrade to 1.1.8 or later versions.

If you are not currently using the mTLS feature in Istio and may use it in the future,
you are recommended to follow the procedure listed below to upgrade.

If you are currently using the mTLS feature in Istio with self-signed certificates,
please follow the procedure and check whether you will be affected.

## Procedure

### Step 0. Check when your root certificate will expire

Download this [script](TODO) on a machine that has kubectl access to the cluster.

{{< text bash>}}
$ ./root-transition.sh check
...
===YOU HAVE 30 DAYS BEFORE THE ROOT CERT EXPIRED!=====
{{< /text >}}

Please run the following steps to upgrade immediately to avoid system outages, before your root certificate expires.

### Step 1. Do the root certificate transition

Run the following command to do the root certificate transition.

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

After the transition, the Envoy sidecars may be hot-restarted. This may have some impact on your traffic.
Please refer to 
[here](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/hot_restart#arch-overview-hot-restart) and
[here](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5) for more details.

### Step 2. Verify the new workload certificates are generated

Run the following command to verify that all the new certificates are generated. If not, wait a minute and run it again.

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

### Step 3. Install Istio 1.1.8

Note that this step is necessary, to make sure the control plane components and sidecar Envoys all reload the new certificates and keys.

Upgrade your control plane and Envoy sidecars to 1.1.8. You can refer to this
[doc](https://istio.io/docs/setup/kubernetes/upgrade/steps/)
to do the upgrades.

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

Please inspect the "valid\_from" value of the "ca\_cert".
If it matches the "_Not_ _Before_" value in the new certificate as shown in Step 1,
your Envoy has loaded the new root certificate.

## Troubleshooting

### Why my workloads do not pick up the new certificates (in Step 4)?

Please make sure you have updated to Istio 1.1.8 for the sidecars in Step 3.
If you are using Istio releases 1.1.3 - 1.1.7, pilot agent may not hot-restart Envoy
after the new certificates are generated.

