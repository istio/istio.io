---
title: Add a Remote Cluster
description: Describes how to add a remote cluster to your mesh on a flat network.
weight: 30
keywords: [multicluster, remote-cluster, deployment]
owner: istio/wg-environments-maintainers
test: n/a
---

To build a {{< gloss >}}multicluster{{< /gloss >}} deployment, you can add a
{{< gloss >}}remote cluster{{< /gloss >}} to your
{{< gloss >}}service mesh{{< /gloss >}}.

To give you clean instructions, this section starts right after you complete the
initial configuration, and assumes that `Cluster_1` and `Cluster_2` reside on
the same network. The new remote cluster, `Cluster_2` in this section, shares
the {{< gloss >}}control plane{{< /gloss >}} of `CLUSTER_1`, and this guide
assumes that `Cluster_1` and `Cluster_2` reside on the same network.

Production systems use this configuration when all clusters within a region
share a common control plane. Any configuration with one control plane per zone

The following diagram shows a multicluster deployment with a
{{< gloss >}}primary cluster{{< /gloss >}} and a remote cluster:

{{< image width="75%"
    link="remote.svg"
    caption="A multicluster deployment with a primary and a remote cluster"
    >}}

Complete the [initial configuration instructions](/docs/setup/install/multicluster/single-network/initial-configuration)
before you continue.

## Configure Trust

{{< boilerplate trust-config >}}

## Deploy Istio

Next, deploy Istio in `Cluster_2` with the discovery address pointing at the
ingress gateway of `Cluster_1`. Your [initial configuration](/docs/setup/install/multicluster/single-network/initial-configuration)
enabled mesh expansion on `Cluster_1`, and now `Cluster_2` can access the
discovery server in `Cluster_1` via the ingress gateway.

The new remote cluster requires the following configurations:

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
            <td><code>remotePilotAddress</code></td>
            <td>IP address of the Istio ingress gateway of `Cluster_1`. </td>
            <td>${DISCOVERY_ADDRESS}</td>
        </tr>
    </tbody>
</table>

Using the previously [set environment variables,](/docs/setup/install/multicluster/#env-var)
deploy Istio in `Cluster_2` with the following steps:

1. Set the value of the `DISCOVERY_ADDRESS` environment variable to the IP
   address of the Istio ingress gateway of `Cluster_1` with the following
   command:

{{< text bash >}}
$ export DISCOVERY_ADDRESS=$(kubectl \
  --context=${CTX_1} \
  -n istio-system get svc istio-ingressgateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

1. To pass configuration values to the Istio operator for installation, you
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
      # Access the control plane discovery server via the ingress
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
{{< /text >}}

1. Install Istio on `Cluster_2` with the following command:

{{< text bash >}}
$ istioctl --context=${CTX_2} manifest apply -f \
  ${WORK_DIR}/${CLUSTER_2}/install.yaml
{{< /text >}}

1. Verify that the control plane of `Cluster_2` is ready with the following
   command:

{{< text bash >}}
$ kubectl --context=${CTX_2} -n istio-system get pod
NAME                                    READY   STATUS    RESTARTS   AGE
istiod-f756bbfc4-thkmk                  1/1     Running   0          136m
prometheus-b54c6f66b-q8hbt              2/2     Running   0          136m
{{< /text >}}

1. After the status of all pods is `Running`, you can continue configuring
   your deployment.

## Configure endpoint discovery

To enable cross-cluster load balancing in your mesh, configure endpoint
discovery. This feature requires that clusters share secrets between them. If
the shared secrets provide the [needed trust](#configure-trust), each
cluster in the mesh can access the API server in the other clusters directly.

Using the environment variables that you set previously, configure endpoint
discovery with the following steps:

1. Share the secret of `Cluster_2` with `Cluster_1` with the following command:

{{< text bash >}}
$ istioctl x create-remote-secret \
  --context=${CTX_2} \
  --name=${CLUSTER_2} | \
  kubectl apply -f - --context=${CTX_1}
{{< /text >}}

**Congratulations!**

You successfully added a remote cluster to your mesh.

{{< boilerplate mc-next >}}
