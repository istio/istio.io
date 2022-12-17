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

Create the Istio configuration for `cluster1`:

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

## Install the east-west gateway in `cluster1`

Install a gateway in `cluster1` that is dedicated to east-west traffic. By
default, this gateway will be public on the Internet. Production systems may
require additional access restrictions (e.g. via firewall rules) to prevent
external attacks. Check with your cloud vendor to see what options are
available.

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --mesh mesh1 --cluster cluster1 --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
{{< /text >}}

{{< warning >}}
If the control-plane was installed with a revision, add the `--revision rev` flag to the `gen-eastwest-gateway.sh` command.
{{< /warning >}}

Wait for the east-west gateway to be assigned an external IP address:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## Expose services in `cluster1`

Since the clusters are on separate networks, we also need to expose all user
services (*.local) on the east-west gateway in both clusters. While this
gateway is public on the Internet, services behind it can only be accessed by
services with a trusted mTLS certificate and workload ID, just as if they were
on the same network.

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    @samples/multicluster/expose-services.yaml@
{{< /text >}}

## Configure `cluster2` as a primary

Create the Istio configuration for `cluster2`:

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network1
EOF
{{< /text >}}

Apply the configuration to `cluster2`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

## Install the east-west gateway in `cluster2`

As we did with `cluster1` above, install a gateway in `cluster2` that is dedicated
to east-west traffic.

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --mesh mesh1 --cluster cluster2 --network network2 | \
    istioctl --context="${CTX_CLUSTER2}" install -y -f -
{{< /text >}}

Wait for the east-west gateway to be assigned an external IP address:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
{{< /text >}}

## Expose services in `cluster2`

As we did with `cluster1` above, expose services via the east-west gateway.

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f \
    @samples/multicluster/expose-services.yaml@
{{< /text >}}

## Enable Endpoint Discovery

Install a remote secret in `cluster2` that provides access to `cluster1`’s API server.

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context="${CTX_CLUSTER1}" \
    --name=cluster1 | \
    kubectl apply -f - --context="${CTX_CLUSTER2}"
{{< /text >}}

Install a remote secret in `cluster1` that provides access to `cluster2`’s API server.

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**Congratulations!** You successfully installed an Istio mesh across multiple
primary clusters!

## Next Steps

You can now [verify the installation](/docs/setup/install/multicluster/verify).
