---
title: IneffectivePolicy
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a policy applied in your Istio service mesh has no impact. This might be due to the
policy's configuration incorrectly targeting any workloads or namespaces in your service mesh.

## Example

You will receive a message like this:

{{< text plain >}}
Warning [IST0167] (Sidecar ns-ambient/namespace-scoped testdata/sidecar-default-selector.yaml:84) The policy has no
impact: namespace is in ambient mode, the policy has no impact.
{{< /text >}}

or this:

{{< text plain >}}
Warning [IST0167] (Sidecar ns-ambient/pod-scoped testdata/sidecar-default-selector.yaml:90) The policy has no impact:
selected workload is in ambient mode, the policy has no impact.
{{< /text >}}

These messages indicate that the `Sidecar` resource is targeting a workload or namespace which is in
ambient mode, meaning that the policy specified in the `Sidecar` resource does not have any effect.

## How to resolve

To resolve this issue, you first need to check the reason. Currently, the policy is ineffective for the following
reasons:

1. The `Sidecar` resource is targeting a workload or namespace which is in ambient mode.

To resolve this, ensure that the policy is defined correctly or determine if it is necessary. If the namespace/pod was
recently added to the ambient mesh, you might have forgotten to remove the policy that is no longer needed, or you may
need to update the policy to target the correct workload or namespace.
