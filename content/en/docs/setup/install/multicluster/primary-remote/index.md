---
title: Install Primary-Remote
description: Install an Istio mesh across primary and remote clusters.
weight: 20
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---
Follow this guide to install the Istio control plane on `cluster1` (the
{{< gloss >}}primary cluster{{< /gloss >}}) and configure `cluster2` (the
{{< gloss >}}remote cluster{{< /gloss >}}) to use the control plane in `cluster1`.
Both clusters reside on the `network1` network, meaning there is direct
connectivity between the pods in both clusters.

Before proceeding, be sure to complete the steps under
[before you begin](/docs/setup/install/multicluster/before-you-begin).

{{< boilerplate multi-cluster-with-metallb >}}

In this configuration, cluster `cluster1` will observe the API Servers in
both clusters for endpoints. In this way, the control plane will be able to
provide service discovery for workloads in both clusters.

Service workloads communicate directly (pod-to-pod) across cluster boundaries.

Services in `cluster2` will reach the control plane in `cluster1` via a
dedicated gateway for [east-west](https://en.wikipedia.org/wiki/East-west_traffic)
traffic.

{{< image width="75%"
    link="arch.svg"
    caption="Primary and remote clusters on the same network"
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
$ istioctl install --set values.pilot.env.EXTERNAL_ISTIOD=true --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

Notice that `values.pilot.env.EXTERNAL_ISTIOD` is set to `true`. This enables the control plane
installed on `cluster1` to also serve as an external control plane for other remote clusters.
When this feature is enabled, `istiod` will attempt to acquire the leadership lock, and consequently manage,
[appropriately annotated](#set-the-control-plane-cluster-for-cluster2) remote clusters that will be
attached to it (`cluster2` in this case).

## Install the east-west gateway in `cluster1`

Install a gateway in `cluster1` that is dedicated to
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) traffic. By
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

## Expose the control plane in `cluster1`

Before we can install on `cluster2`, we need to first expose the control plane in
`cluster1` so that services in `cluster2` will be able to access service discovery:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -n istio-system -f \
    @samples/multicluster/expose-istiod.yaml@
{{< /text >}}

## Set the control plane cluster for `cluster2`

We need identify the external control plane cluster that should manage `cluster2` by annotating the
istio-system namespace:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" create namespace istio-system
$ kubectl --context="${CTX_CLUSTER2}" annotate namespace istio-system topology.istio.io/controlPlaneClusters=cluster1
{{< /text >}}

Setting the `topology.istio.io/controlPlaneClusters` namespace annotation to `cluster1` instructs the `istiod`
running in the same namespace (istio-system in this case) on `cluster1` to manage `cluster2` when it
is [attached as a remote cluster](#attach-cluster2-as-a-remote-cluster-of-cluster1).

## Configure `cluster2` as a remote

Save the address of `cluster1`’s east-west gateway.

{{< text bash >}}
$ export DISCOVERY_ADDRESS=$(kubectl \
    --context="${CTX_CLUSTER1}" \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

Now create a remote configuration for `cluster2`.

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: remote
  values:
    istiodRemote:
      injectionPath: /inject/cluster/cluster2/net/network1
    global:
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
{{< /text >}}

{{< tip >}}
Here we're configuring the location of the control plane using the `injectionPath` and
`remotePilotAddress` parameters. Although convenient for demonstration, in a production
environment it is recommended to instead configure the `injectionURL` parameter using
properly signed DNS certs similar to the configuration shown in the
[external control plane instructions](/docs/setup/install/external-controlplane/#register-the-new-cluster).
{{< /tip >}}

Apply the configuration to `cluster2`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

## Attach `cluster2` as a remote cluster of `cluster1`

To attach the remote cluster to its control plane, we give the control
plane in `cluster1` access to the API Server in `cluster2`. This will do the
following:

- Enables the control plane to authenticate connection requests from
  workloads running in `cluster2`. Without API Server access, the control
  plane will reject the requests.

- Enables discovery of service endpoints running in `cluster2`.

Because it has been included in the `topology.istio.io/controlPlaneClusters` namespace
annotation, the control plane on `cluster1` will also:

- Patch certs in the webhooks in `cluster2`.

- Start the namespace controller which writes configmaps in namespaces in `cluster2`.

To provide API Server access to `cluster2`, we generate a remote secret and
apply it to `cluster1`:

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**Congratulations!** You successfully installed an Istio mesh across primary
and remote clusters!

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
