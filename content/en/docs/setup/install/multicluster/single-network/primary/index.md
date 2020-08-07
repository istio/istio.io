---
title: Add a Primary Cluster
description: Describes how to add a primary cluster to your mesh on a flat network.
weight: 20
keywords: [multicluster, primary-cluster, deployment]
owner: istio/wg-environments-maintainers
test: n/a
---

To build a {{< gloss >}}multicluster{{< /gloss >}} deployment, you can add
{{< gloss "primary cluster" >}}primary clusters{{< /gloss >}} to your
{{< gloss >}}service mesh{{< /gloss >}}.

To give you clean instructions, this section starts right after you complete the
[initial configuration](/docs/setup/install/multicluster/single-network/initial-configuration),
and assumes that `Cluster_1` and `Cluster_2` reside on the same network.
However, you can add primary clusters to your existing mesh regardless of your
current [deployment model](/docs/ops/deployment/deployment-models/).

Add primary clusters to your deployment to improve the availability of your
mesh. To keep multiple {{< gloss "control plane" >}}control planes{{< /gloss >}}
in sync, apply your configuration to each cluster. Production systems employ
continuous integration and continuous deployment (CI/CD) pipelines to apply
configurations since they typically have at least one control plane per region.
Administrators use these pipelines to manage configuration rollouts. Apply new
configurations to one primary cluster at a time to help minimize
troubleshooting.

The following diagram shows a multicluster deployment with two primary
clusters:

{{< image width="75%"
    link="primary.svg"
    caption="A multicluster deployment with two primary clusters"
    >}}

Complete the [initial configuration instructions](/docs/setup/install/multicluster/single-network/initial-configuration)
before you continue.

## Configure Trust

{{< boilerplate trust-config >}}

## Deploy Istio

Next, deploy a full Istio control plane on `Cluster_2`. The new control plane
requires the following configurations to enable a multicluster deployment:

<table>
    <thead>
        <tr>
            <th>Configuration field</th>
            <th>Description</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>clusterName</code>
            </td>
            <td>Specifies a human-readable cluster name.</td>
            <td><code>${CLUSTER_2}</code></td>
        </tr>
        <tr>
            <td><code>network</code></td>
            <td>Specifies a network ID as an arbitrary string. All clusters in your mesh
            must be on the same network, and have the same network ID.</td>
            <td><code>${NETWORK_1}</code></td>
        </tr>
        <tr>
            <td><code>meshID</code></td>
            <td>Specifies a mesh ID as an arbitrary string. All clusters in your mesh share
            the same mesh ID.</td>
            <td><code>${MESH}</code></td>
        </tr>
        <tr>
            <td><code>meshExpansion</code></td>
            <td>[Recommended] Exposes the Istio control plane through the ingress gateway
            of the mesh. Enable this option to connect remote clusters to a control
            plane.</td>
            <td><code>enabled: true</code></td>
        </tr>
    </tbody>
</table>

Using the [previously set environment variables,](/docs/setup/install/multicluster/#env-var)
deploy an Istio control plane with the following steps:

1. To pass configuration values to the Istio operator for installation,
   define a custom resource (CR). Define and save the `install.yaml` CR with
   the following command:

{{< text bash >}}
$ cat <<EOF> ${WORK_DIR}/${CLUSTER_2}/install.yaml

apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: ${MESH}
      multiCluster:
        clusterName: ${CLUSTER_2}
      network: ${NETWORK_1}

      meshNetworks:
        ${NETWORK_1}:
          endpoints:
          # fromRegistry should match the clusterName used above.
          # There should be a fromRegistry entry for each cluster on the network.
          - fromRegistry: ${CLUSTER_1}
          - fromRegistry: ${CLUSTER_2}
          gateways:
          - registry_service_name: istio-ingressgateway.istio-system.svc.cluster.local
            port: 443
      # Expose the control plane through istio-ingressgateway.
      meshExpansion:
        enabled: true
EOF
{{< /text >}}

1. Install Istio on Cluster-2 with the following command:

    {{< text bash >}}
    $ istioctl --context=${CTX_2} manifest apply -f \
    ${WORK_DIR}/${CLUSTER_2}/install.yaml
    {{< /text >}}

1. Verify that the control plane is ready with the following command:

    {{< text bash >}}
    $ kubectl --context=${CTX_2} -n istio-system get pod
    NAME                                    READY   STATUS    RESTARTS   AGE
    istiod-f756bbfc4-thkmk                  1/1     Running   0          136m
    prometheus-b54c6f66b-q8hbt              2/2     Running   0          136m
    {{< /text >}}

1. After the status of all pods is `Running`, you can continue configuring
   your deployment.

**Congratulations!**

You successfully added a control plane to your primary
cluster.

Next, configure endpoint discovery to support cross-cluster load balancing.

## Configure endpoint discovery

To enable cross-cluster load balancing in your mesh, configure endpoint
discovery. This feature requires that clusters share secrets between them. If
the shared secrets provide the [needed trust](#configure-trust), each
cluster in the mesh can access the API server in the other clusters directly.
Using the previously set environment variables, configure endpoint discovery
with the following steps:

1. Share the secret of `Cluster_1` with `Cluster_2`:

    {{< text bash >}}
    $ istioctl x create-remote-secret \
      --context=${CTX_1} \
      --name=${CLUSTER_1} | \
      kubectl apply -f - --context=${CTX_2}
    {{< /text >}}

1. Share the secret of `Cluster_2` with `Cluster_1`:

    {{< text bash >}}
    $ istioctl x create-remote-secret \
      --context=${CTX_2} \
      --name=${CLUSTER_2} | \
      kubectl apply -f - --context=${CTX_1}
    {{< /text >}}

    {{< tip >}}
    If you have added other clusters to your deployment, you must share the
    secret of `Cluster_2` with those clusters too.
    {{< /tip >}}

**Congratulations!**

You successfully added a primary cluster to your mesh!

{{< boilerplate mc-next >}}
