---
title: Istio 1.19 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.19.
weight: 20
publishdate: 2023-09-05
---

When you upgrade from Istio 1.18.x to Istio 1.19.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio `1.18.x.`
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio `1.18.x.`

## Use the canonical filter names for EnvoyFilter

If you are using EnvoyFilter API, please use canonical filter names. The use of deprecated filter name is not supported. See the [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.14.0#deprecated) for further details.

## `base` Helm Chart removals

A number of configurations previously present in the the `base` Helm chart were *copied* to the `istiod` chart in a previous releases.

In this release, the duplicated configurations are fully removed from the `base` chart.

Below shows a mapping of old configuration to new configuration:

| Old                                     | New                                     |
| --------------------------------------- | --------------------------------------- |
| `ClusterRole istiod`                    | `ClusterRole istiod-clusterrole`        |
| `ClusterRole istiod-reader`             | `ClusterRole istio-reader-clusterrole`  |
| `ClusterRoleBinding istiod`             | `ClusterRoleBinding istiod-clusterrole` |
| `Role istiod`                           | `Role istiod`                           |
| `RoleBinding istiod`                    | `RoleBinding istiod`                    |
| `ServiceAccount istiod-service-account` | `ServiceAccount istiod`                 |

Note: most resources have a suffix automatically added in addition.
In the old chart, this was `-{{ .Values.global.istioNamespace }}`.
In the new chart it is `{{- if not (eq .Values.revision "") }}-{{ .Values.revision }}{{- end }}` for namespace scoped resources, and `{{- if not (eq .Values.revision "")}}-{{ .Values.revision }}{{- end }}-{{ .Release.Namespace }}` for cluster scoped resources.

## EnvoyFilter must specify the type URL for an Envoy extension injection

Previously, Istio permitted a lookup of the extension in `EnvoyFilter` by its internal Envoy name alone. To see if you are affected,
run `istioctl analyze` and check for a deprecation warning `using deprecated types by name without typed_config`. Additionally, make
sure any nested extension lists inside `EnvoyFilter` include both `name:` and `typed_config:` fields.

## Gateway API: Service-attached `parentRefs` must specify empty group

As a result of updates to the Gateway API conformance tests, Istio will no longer accept the default group of `gateway.networking.k8s.io` for a Service `parentRef` in a Gateway API route (e.g. `HTTPRoute`, `TCPRoute`, etc). Instead, you must explicitly set  `group: ""` like so:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: productpage
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: productpage
    port: 9080
{{< /text >}}
