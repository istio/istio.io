---
title: How can I enable/disable mTLS encryption after I installed Istio?
weight: 10
---
{% include home.html %}

The most straightforward way to enable/disable mTLS is by entirely
uninstalling and re-installing Istio.

If you are an advanced user and understand the risks you can also do the following:

```bash
kubectl edit configmap -n istio-system istio
```

comment out or uncomment `authPolicy: MUTUAL_TLS` to toggle mTLS and then

```bash
kubectl delete pods -n istio-system -l istio=pilot
```

to restart Pilot, after a few seconds (depending on your `*RefreshDelay`) your
Envoy proxies will have picked up the change from Pilot. During that time your
services may be unavailable.

We are working on a smoother solution.
