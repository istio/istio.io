---
title: Wait on Resource Status for Applied Configuration
description: Describes how to wait until a resource reaches a given status of readiness.
weight: 15
owner: istio/wg-user-experience-maintainers
test: yes
---

{{< warning >}}
This feature is in the Alpha stage, see
[Istio Feature Status](/docs/releases/feature-stages/). Your feedback is welcome in the
[Istio User Experience discussion](https://discuss.istio.io/c/UX/23). Currently,
this feature is tested only for single, low volume clusters with a single
control plane revision.
{{< /warning >}}

Istio's mesh configuration is declarative, which means that you define a
configuration and Istio propagates the changes through the mesh over time. As a
result, your command might attempt to use your service mesh before
the relevant resources are ready.

In Istio 1.6 and later, you can use the `kubectl wait` command to have more
control over the way that Istio applies configuration changes to the mesh. To
make this possible, the `kubectl wait` command monitors the
[`status` field](/docs/reference/config/config-status/) of the resource's
status, which Istio updates as it propagates configuration changes.

## Before you begin

This feature is off by default. Enable the `status` field as part of Istio
installation using the following command. You must also enable `config_distribution_tracking`.

{{< text syntax=bash snip_id=install_with_enable_status >}}
$ istioctl install --set values.pilot.env.PILOT_ENABLE_STATUS=true --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set values.global.istiod.enableAnalysis=true
{{< /text >}}

## Wait for resource readiness

You can apply a change and then wait for completion.  For example, to wait for a virtual
service, use
the following commands:

{{< text syntax=bash snip_id=apply_and_wait_for_httpbin_vs >}}
$ kubectl apply -f @samples/httpbin/httpbin.yaml@
$ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@
$ kubectl wait --for=condition=Reconciled virtualservice/httpbin
virtualservice.networking.istio.io/httpbin condition met
{{< /text >}}

This blocking command does not release until the virtual service has been
distributed to all proxies in the mesh, or until the command times out.

When you use the `kubectl wait` command in a script, the return code
will be `0` for success, or a non-zero value for time out.

For more information about usage and syntax, see the
[kubectl wait](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#wait)
command.
