---
title: 구성을 적용할 때까지 리소스 상태 대기
description: 리소스가 지정된 상태 또는 준비 상태에 도달할 때까지 메시 구성 적용을 기다리는 방법에 대해 설명한다.
weight: 15
owner: istio/wg-user-experience-maintainers
test: no
---

{{< warning >}}
This feature is in the Alpha stage, see
[Istio Feature Status](/about/feature-stages/). Your feedback is welcome in the
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
[`status` field](/ko/docs/reference/config/config-status/) of the resource's
status, which Istio updates as it propagates configuration changes.

## Before you begin

This feature is off by default. Enable the `status` field as part of Istio
installation using the following command. If you enable it after installation,
you must re-deploy the control plane.

{{< text bash >}}
$ istioctl install --set values.pilot.env.PILOT_ENABLE_STATUS=true --set values.global.istiod.enableAnalysis=true
{{< /text >}}

## Wait for resource readiness

You can apply a change to a virtual service and then wait for completion, using
the following commands:

{{< text bash >}}
$ kubectl apply -f virtual_service_name.yaml
$ kubectl wait --for=condition=Reconciled virtual_service/name
{{< /text >}}

This blocking command does not release until the virtual service has been
distributed to all proxies in the mesh, or until the command times out.

When you use the `kubectl wait` command in a script, the return code
will be `0` for success, or a non-zero value for time out.

For more information about usage and syntax, see the
[kubectl wait](https://kubernetes.io/ko/docs/reference/generated/kubectl/kubectl-commands#wait)
command.
