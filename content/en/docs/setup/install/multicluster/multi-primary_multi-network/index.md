---
title: Install Multi-Primary on different networks
description: Install an Istio mesh across multiple primary clusters on different networks.
weight: 30
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---
Follow this guide to install the Istio control plane on both `cluster1` and
`cluster2`, making each a {{< gloss >}}primary cluster{{< /gloss >}}. Cluster
`cluster1` is on the `network1` network, while `cluster2` is on the
`network2` network. This means there is no direct connectivity between pods
across cluster boundaries.

Before proceeding, be sure to complete the steps under
[before you begin](/docs/setup/install/multicluster/before-you-begin).

{{< boilerplate multi-cluster-with-metallb >}}

In this configuration, both `cluster1` and `cluster2` observe the API Servers
in each cluster for endpoints.

Service workloads across cluster boundaries communicate indirectly, via
dedicated gateways for [east-west](https://en.wikipedia.org/wiki/East-west_traffic)
traffic. The gateway in each cluster must be reachable from the other cluster.

{{< image width="75%"
    link="arch.svg"
    caption="Multiple primary clusters on separate networks"
    >}}

## Set the default network for `cluster1`

If the istio-system namespace is already created, we need to set the cluster's network there:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

## Configure `cluster1` as a primary

Create the `istioctl` configuration for `cluster1`:

{{< tabset category-name="multicluster-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Install Istio as primary in `cluster1` using istioctl and the `IstioOperator` API.

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

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Install Istio as primary in `cluster1` using the following Helm commands:

Install the `base` chart in `cluster1`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

Then, install the `istiod` chart in `cluster1` with the following multi-cluster settings:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster1 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Install the east-west gateway in `cluster1`

Install a gateway in `cluster1` that is dedicated to
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) traffic. By
default, this gateway will be public on the Internet. Production systems may
require additional access restrictions (e.g. via firewall rules) to prevent
external attacks. Check with your cloud vendor to see what options are
available.

{{< warning >}}
Layer 7 load balancers terminate TLS and are incompatible with `AUTO_PASSTHROUGH`, which can result in mTLS handshake failures and 503 errors. Do not expose an east-west gateway with a Layer 7 load balancer.
{{< /warning >}}

{{< tabset category-name="east-west-gateway-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
{{< /text >}}

{{< warning >}}
If the control-plane was installed with a revision, add the `--revision rev` flag to the `gen-eastwest-gateway.sh` command.
{{< /warning >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Install the east-west gateway in `cluster1` using the following Helm command:

{{< text bash >}}
$ helm install istio-eastwestgateway istio/gateway -n istio-system --kube-context "${CTX_CLUSTER1}" --set name=istio-eastwestgateway --set networkGateway=network1
{{< /text >}}

{{< warning >}}
If the control-plane was installed with a revision, you must add a `--set revision=<my-revision>` flag to the Helm install command.
{{< /warning >}}

{{< /tab >}}

{{< /tabset >}}

Wait for the east-west gateway to be assigned an external IP address:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## Expose services in `cluster1`

Since the clusters are on separate networks, we need to expose all services
(*.local) on the east-west gateway in both clusters. While this gateway is
public on the Internet, services behind it can only be accessed by services
with a trusted mTLS certificate and workload ID, just as if they were on the
same network.

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    @samples/multicluster/expose-services.yaml@
{{< /text >}}

## Set the default network for `cluster2`

If the istio-system namespace is already created, we need to set the cluster's network there:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
{{< /text >}}

## Configure cluster2 as a primary

Create the `istioctl` configuration for `cluster2`:

{{< tabset category-name="multicluster-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Install Istio as primary in `cluster2` using istioctl and the `IstioOperator` API.

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
      network: network2
EOF
{{< /text >}}

Apply the configuration to `cluster2`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Install Istio as primary in `cluster2` using the following Helm commands:

Install the `base` chart in `cluster2`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

Then, install the `istiod` chart in `cluster2` with the following multi-cluster settings:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER2}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster2 --set global.network=network2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Install the east-west gateway in `cluster2`

As we did with `cluster1` above, install a gateway in `cluster2` that is dedicated
to east-west traffic.

{{< tabset category-name="east-west-gateway-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network2 | \
    istioctl --context="${CTX_CLUSTER2}" install -y -f -
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Install the east-west gateway in `cluster2` using the following Helm command:

{{< text bash >}}
$ helm install istio-eastwestgateway istio/gateway -n istio-system --kube-context "${CTX_CLUSTER2}" --set name=istio-eastwestgateway --set networkGateway=network2
{{< /text >}}

{{< warning >}}
If the control-plane was installed with a revision, you must add a `--set revision=<my-revision>` flag to the Helm install command.
{{< /warning >}}

{{< /tab >}}

{{< /tabset >}}

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
primary clusters on different networks!

## Next Steps

You can now [verify the installation](/docs/setup/install/multicluster/verify).

## Cleanup

Uninstall Istio from both `cluster1` and `cluster2` using the same mechanism you installed Istio with (istioctl or Helm).

{{< tabset category-name="multicluster-uninstall-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Uninstall Istio in `cluster1`:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER1}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

Uninstall Istio in `cluster2`:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER2}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

Delete Istio Helm installation from `cluster1`:

{{< text syntax=bash >}}
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-eastwestgateway -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

Delete the `istio-system` namespace from `cluster1`:

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

Delete Istio Helm installation from `cluster2`:

{{< text syntax=bash >}}
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-eastwestgateway -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

Delete the `istio-system` namespace from `cluster2`:

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

(Optional) Delete CRDs installed by Istio:

Deleting CRDs permanently removes any Istio resources you have created in your clusters.
To delete Istio CRDs installed in your clusters:

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
