---
title: Required Pod Capabilities
description: Describes how to check which capabilities are allowed for your pods.
weight: 40
---

If [pod security policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) are [enforced](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#enabling-pod-security-policies) in your
cluster and unless you use Istio CNI Plugin, your pods must have the `NET_ADMIN` capability allowed.
The initialization containers of the Envoy proxies require this capability. To check which capabilities are allowed for
your pods, check if their
[service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) can use a
pod security policy that allows the `NET_ADMIN` capability.

If you don't specify a service account in your pods' deployment, the pods run as the `default` service account in
their deployment's namespace.

To check which capabilities are allowed for the service account of your pods, run the
following command:

{{< text bash >}}
$ for psp in $(kubectl get psp -o jsonpath="{range .items[*]}{@.metadata.name}{'\n'}{end}"); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:<your namespace>:<your service account>) = yes ]; then kubectl get psp/$psp --no-headers -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
{{< /text >}}

For example, to check which capabilities are allowed for the `default` service account in the `default` namespace,
run the following command:

{{< text bash >}}
$ for psp in $(kubectl get psp -o jsonpath="{range .items[*]}{@.metadata.name}{'\n'}{end}"); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:default:default) = yes ]; then kubectl get psp/$psp --no-headers -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
{{< /text >}}

If you see `NET_ADMIN` or `*` in the list of capabilities of one of the allowed policies for your service account,
your pods have permission to run the Istio init containers. Otherwise, you must
[provide such permission](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#authorizing-policies).
