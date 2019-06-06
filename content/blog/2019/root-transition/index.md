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

Istio self-signed certificates have the default lifetime of 1 year.
If you are using the Istio self-signed certificates with default lifetime configuration,
please schedule a root transition before it expires. An expiration of root certificate may lead to an unexpected cluster-wide outage.
After the transition, the root certificate will be renewed to have 10 year lifetime.
As a best practice for security, we strongly recommend you to do annual root key/cert rotation.
We will send out instructions for root key/cert rotation as a follow-up.

To evaluate the lifetime remaining for your root certificate, please refer to Step 0 in the following procedure.

To resolve this problem, we have a procedure that does the root transition automatically.
Note that the Envoy instances will be hot restarted to reload the new root certificates, which may impact the long-lived connections.
For details about the impacts and how Envoy hot restart works, please refer to
[here](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/hot_restart#arch-overview-hot-restart) and
[here](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5).

## Scenarios

If you are not currently using the mTLS feature in Istio and will not use it in the future, you are not affected and can skip the below content.

If you are not currently using the mTLS feature in Istio and may use it in the future, you are recommended to follow the procedure listed below to upgrade. 

If you are currently using the mTLS feature in Istio, please follow the procedure and check whether you will be affected.

## Procedure

### Step 0. Check when your root certificate will expire

Download this [script](TODO) on a machine that has kubectl access to the cluster.

{{< text bash>}}
$ ./root-transition.sh check
...
===YOU HAVE 364 DAYS BEFORE THE ROOT CERT EXPIRED!=====
{{< /text >}}

If there is less than 30 days remaining, we suggest to run following steps immediately to avoid system outage. Otherwise we will have a smoother solution released in 30 days.

### Step 1. Do the root certificate transition

Run the following command to do the root certificate transition.

{{< text bash>}}
$ ./root_transition.sh transition
{{< /text >}}

After the transition, the Envoy sidecars may be hot-restarted. This does not have an impact on short-lived connections. Long-lived connections will be gracefully drained, and normally applications can reconnect automatically.

### Step 2. Verify the new workload certificates are generated

Run the following command to verify that all the new certificates are generated. If not, wait a minute and run it again.

{{< text bash>}}
$ ./root_transition.sh verify
{{< /text >}}

### Step 3. Install Istio 1.1.8

Note that this step is necessary, to make sure the control plane components and sidecar Envoys all reload the new certificates and keys.

Upgrade your control plane and Envoy sidecars to 1.1.8. You can refer to this
[doc](https://istio.io/docs/setup/kubernetes/upgrade/steps/)
to do the upgrades.

### Step 4. Verify the new workload certificates are loaded by Envoy

You can verify your Envoy sidecars have picked on the new certificates.
The following command can be used to check the certificates loaded for a pod _foo_ running in namespace _bar_.

{{< text bash>}}
$ kubectl exec -it foo -c istio-proxy -n bar -- curl http://localhost:15000/certs | head -c 1000
{
 "certificates": [
  {
   "ca_cert": [
      ...
      "valid_from": "2019-06-01T16:47:10Z",
      "expiration_time": ...
   ],
   "cert_chain": [
    {
      ...
    }
{{< /text >}}

Please inspect the "valid\_from" value of the "cert\_chain".
It should be after the time Citadel is restarted. If so, the Envoy is loading the new certificate.

## Troubleshooting

Why my workloads do not pick up the new certificates (in Step 4)?

Please make sure you have updated the sidecar images in Step 2.
If you are using Istio releases 1.1.3 - 1.1.7, pilot agent may not restart Envoy automatically.
