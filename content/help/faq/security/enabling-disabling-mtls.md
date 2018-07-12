---
title: How can I enable/disable mutual TLS encryption after I installed Istio?
weight: 10
---

Starting with Istio 0.8, [authentication policy](/docs/concepts/security/#authentication-policy) can be used to change mutual TLS setting at run time, without needing to reinstall Istio.

Before 0.8, the most straightforward way to enable/disable mutual TLS is by entirely
uninstalling and re-installing Istio.

If you are an advanced user and understand the risks you can also do the following:

{{< text bash >}}
$ kubectl edit configmap -n istio-system istio
{{< /text >}}

comment out or uncomment `authPolicy: MUTUAL_TLS` to toggle mutual TLS and then

{{< text bash >}}
$ kubectl delete pods -n istio-system -l istio=pilot
{{< /text >}}

to restart Pilot, after a few seconds (depending on your `*RefreshDelay`) your
Envoy proxies will have picked up the change from Pilot. During that time your
services may be unavailable.
