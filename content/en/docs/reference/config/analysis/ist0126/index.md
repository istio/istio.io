---
title: UnknownMeshNetworksServiceRegistry
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a network in the mesh networks configuration has an endpoint with a
`fromRegistry` value that Istio does not recognize.

The known service registries are `Kubernetes`, `External`, and the cluster IDs of the remote
clusters that have a remote secret (a `Secret` with the label `istio/multiCluster: "true"`).

## An example

Consider a mesh networks configuration that references a registry named `cluster2`, but there
is no remote secret for `cluster2`:

{{< text yaml >}}
networks:
  network1:
    endpoints:
    - fromRegistry: cluster2
    gateways:
    - address: 192.0.2.10
      port: 15443
{{< /text >}}

You will receive this message:

{{< text plain >}}
Error [IST0126] (MeshNetworks istio-system/meshnetworks) Unknown service registry cluster2 in network network1
{{< /text >}}

## How to resolve

- Make sure that the `fromRegistry` value is the same as the cluster ID of the remote cluster.
- Make sure that a remote secret exists for that cluster. You can create one with
  [`istioctl create-remote-secret`](/docs/reference/commands/istioctl/#istioctl-create-remote-secret).

For more information, refer to [Install Multicluster](/docs/setup/install/multicluster/).
