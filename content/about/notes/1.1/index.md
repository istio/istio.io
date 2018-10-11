---
title: Istio 1.1
weight: 89
icon: notes
---

TODO announcement

{{< relnote_links >}}

## Policies and Telemetry

- **Kiali**. The Service Graph addon has been [deprecated](https://github.com/istio/istio/issues/9066) in favor of [Kiali](https://www.kiali.io). See the [Kiali Task](/docs/tasks/telemetry/kiali/) for more details about Kiali.

## Security

- Deprecated `RbacConfig` by `ClusterRbacConfig` with correct cluster scope implementation.
  Refer to [Migrating the `RbacConfig` to `ClusterRbacConfig`](/docs/setup/kubernetes/upgrading-istio#migrating-the-rbacconfig-to-clusterrbacconfig)
  for the migration instruction.
