---
title: Install Multi-Primary
description: Install an Istio mesh across multiple primary clusters.
weight: 10
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---
Follow this guide to install the Istio control plane on both `cluster1` and
`cluster2`, making each a {{< gloss >}}primary cluster{{< /gloss >}}. Both
clusters reside on the `network1` network, meaning there is direct
connectivity between the pods in both clusters.

Before proceeding, be sure to complete the steps under
[before you begin](/docs/setup/install/multicluster/before-you-begin).

In this configuration, each control plane observes the API Servers in both
clusters for endpoints.

Service workloads communicate directly (pod-to-pod) across cluster boundaries.

{{< image width="75%"
    link="arch.svg"
    caption="Multiple primary clusters on the same network"
    >}}

## Configure `cluster1` as a primary

{{< tabset category-name="multicluster-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Create the Istio configuration for cluster1:

{{< text bash >}}
$ cat <<EOF > cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF
{{< /text >}}

Apply the configuration to `cluster1`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

Then install using standard `istioctl` commands:

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Install Istio as primary in `cluster1` using standard `helm` commands.

First, install the `base` chart in `cluster1`:

{{< text bash >}}
$ kubectl create namespace istio-system
$ helm install istio-base istio/base -n istio-system --kube-context $CTX_CLUSTER1 
{{< /text >}}

Then, install the `istiod` chart in `cluster1` with the following multi-cluster settings:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context $CTX_CLUSTER1 --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster1 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Configure `cluster2` as a primary

Create the Istio configuration for `cluster2`:

{{< tabset category-name="multicluster-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Create the Istio configuration for cluster1:

{{< text bash >}}
$ cat <<EOF > cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF
{{< /text >}}

Apply the configuration to `cluster1`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

Then install using standard `istioctl` commands:

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Install Istio as primary in `cluster2` using standard `helm` commands.

First, install the `base` chart in `cluster2`:

{{< text bash >}}
$ kubectl create namespace istio-system
$ helm install istio-base istio/base -n istio-system --kube-context $CTX_CLUSTER2
{{< /text >}}

Then, install the `istiod` chart in `cluster2` with the following multi-cluster settings:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context $CTX_CLUSTER1 --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster2 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Enable Endpoint Discovery

Install a remote secret in `cluster2` that provides access to `cluster1`’s API server.

{{< text bash >}}
$ istioctl create-remote-secret \
    --context="${CTX_CLUSTER1}" \
    --name=cluster1 | \
    kubectl apply -f - --context="${CTX_CLUSTER2}"
{{< /text >}}

Install a remote secret in `cluster1` that provides access to `cluster2`’s API server.

{{< text bash >}}
$ istioctl create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**Congratulations!** You successfully installed an Istio mesh across multiple
primary clusters!

## Next Steps

You can now [verify the installation](/docs/setup/install/multicluster/verify).

## Cleanup

1. Uninstall Istio in `cluster1`:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --context="${CTX_CLUSTER1}" -y --purge
    $ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
    {{< /text >}}

1. Uninstall Istio in `cluster2`:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --context="${CTX_CLUSTER2}" -y --purge
    $ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
    {{< /text >}}
