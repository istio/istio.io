---
title: Initial Configuration
description: Describes how to complete the initial configuration for a multicluster mesh on a flat network.
weight: 10
keywords: [multicluster,first-cluster]
owner: istio/wg-environments-maintainers
test: n/a
---

To build a {{< gloss >}}multicluster{{< /gloss >}} deployment, configure a
single cluster {{< gloss >}}service mesh{{< /gloss >}} as your starting point.

The single cluster mesh you deploy in this section, serves as a model for the
configuration of the first {{< gloss >}}primary cluster{{< /gloss >}}. You need
at least one primary cluster to complete the [different multicluster deployments.](/docs/ops/deployment/deployment-models/#multiple-clusters)

Each cluster in a multicluster deployment needs a unique identifier. Using
`CLUSTER_1` as a unique identifier for the first cluster, the following
diagram shows a service mesh spanning a single primary cluster.

{{< image width="75%"
    link="init-conf.svg"
    caption="A service mesh with a single primary cluster"
    >}}

Complete the [Before you begin instructions](/docs/setup/install/multicluster/#before-you-begin)
before you continue.

To set up a cluster as the primary cluster of a multicluster service
mesh, complete the following configuration steps:

1. [Configure trust for the cluster](#configure-trust)
1. [Deploy Istio to the cluster](#deploy-istio)

## Configure trust

A multicluster service mesh deployment requires that you establish trust between
the clusters in the mesh. To authenticate workloads across clusters, Istio
requires that only one root Certificate Authority (CA) is active in the mesh. To
establish shared trust, generate a single root CA for the entire mesh, and an
intermediate CA for each cluster. Then, the shared root CA can sign the
intermediate CA of each cluster.

Production environments should use your organization's
root CA whenever possible, or set up a secure PKI like [Vault PKI](https://www.vaultproject.io/docs/secrets/pki)
to generate the common root certificate.

The `Makefile` in [install/certs]({{< github_tree >}}install/certs)
is a simple tool that helps generate the root certificate and intermediate
certificates, but do not use it as a production-ready root CA. The tool
lacks the following critical features:

- Private key protection
- Access control
- Auditing
- Monitoring

Use the `Makefile` to generate the common root and the intermediate certificates
only for tests or demos. All of the files needed for a cluster CA are stored
under the subdirectory `<CLUSTER_NAME>`.

Using [the set environment variables](/docs/setup/install/multicluster/#env-var), configure trust with the following steps:

1. Go to the `WORK_DIR` directory with the following command:

    {{< text bash >}}
    $ cd ${WORK_DIR}
    {{< /text >}}

1. Generate the root CA and the intermediate CA for the cluster with the
   following command:

    {{< text bash >}}
    $ make -f ${ISTIO}/tools/certs/Makefile ${CLUSTER_1}-cacerts-k8s
    {{< /text >}}

1. To ensure that the Istio {{< gloss >}}control plane{{< /gloss >}} and the
   secret share the same namespace, create the `istio-system` namespace with the
   following command:

    {{< text bash >}}
    $ kubectl create namespace istio-system --context=${CTX_1}
    {{< /text >}}

1. Push the secret with the generated CA files to the cluster with the
   following command:

    {{< text bash >}}
    $ kubectl create secret generic cacerts --context=${CTX_1} \
        -n istio-system \
        --from-file=${WORK_DIR}/${CLUSTER_1}/ca-cert.pem \
        --from-file=${WORK_DIR}/${CLUSTER_1}/ca-key.pem \
        --from-file=${WORK_DIR}/${CLUSTER_1}/root-cert.pem \
        --from-file=${WORK_DIR}/${CLUSTER_1}/cert-chain.pem
    {{< /text >}}

Pushing the secret to the cluster overrides Istio's default CA, allowing you to
establish trust between clusters using intermediate CAs that are signed by the
shared root CA.

**Congratulations!**

You configured trust in the cluster to enable a multicluster deployment.

### Deploy Istio

Next, you must deploy Istio to the cluster if you hadn't already, or update your
Istio configuration for multicluster. Istio requires the following configuration
values to enable a multicluster deployment:

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
            <td><code>${CLUSTER_1}</code></td>
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
            <td>Recommended: Exposes the Istio control plane through the ingress gateway
            of the mesh. Enable this option to connect remote clusters to a control
            plane.</td>
            <td><code>enabled: true</code></td>
        </tr>
    </tbody>
</table>

Using the [previously set environment variables,](/docs/setup/install/multicluster/#env-var)
deploy Istio with the following steps:

1. To pass configuration values to the Istio operator for installation,
   define a custom resource (CR). Define and save the `install.yaml` CR with
   the following command:

    {{< text bash >}}
    $ cat <<EOF> ${WORK_DIR}/${CLUSTER_1}/install.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      values:
        global:
          # Expose the control plane through istio-ingressgateway.
          meshExpansion:
            enabled: true
          meshID: ${MESH}
          multiCluster:
            clusterName: ${CLUSTER_1}
          network: ${NETWORK_1}
          meshNetworks:
            ${NETWORK_1}:
            endpoints:
              # fromRegistry should match the clusterName used above.
              # There should be a fromRegistry entry for each cluster on the network.
              - fromRegistry: ${CLUSTER_1}
            gateways:
              - registry_service_name: istio-ingressgateway.istio-system.svc.cluster.local
                port: 443
    EOF
    {{< /text >}}

1. Install Istio on the first cluster with the following command:

    {{< text bash >}}
    $ istioctl --context=${CTX_1} manifest apply -f \
        ${WORK_DIR}/${CLUSTER_1}/install.yaml
    {{< /text >}}

1. Verify that the control plane is ready with the following command:

    {{< text bash >}}
    $ kubectl --context=${CTX_1} -n istio-system get pod
    NAME                                    READY   STATUS    RESTARTS   AGE
    istiod-f756bbfc4-thkmk                  1/1     Running   0          136m
    prometheus-b54c6f66b-q8hbt              2/2     Running   0          136m
    {{< /text >}}

1. After the status of all pods is `Running`, you can continue configuring
   your deployment.

**Congratulations**, you successfully configured the first cluster of your
multicluster mesh!

{{< boilerplate mc-next >}}
