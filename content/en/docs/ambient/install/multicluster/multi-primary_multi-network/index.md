---
title: Install ambient multi-primary on different networks
description: Install an Istio ambient mesh across multiple primary clusters on different networks.
weight: 30
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
next: /docs/ambient/install/multicluster/verify
prev: /docs/ambient/install/multicluster/before-you-begin
---

{{< boilerplate alpha >}}

{{< tip >}}
This guide requires installation of the Gateway API CRDs.
{{< boilerplate gateway-api-install-crds >}}
{{< /tip >}}

Follow this guide to install the Istio control plane on both `cluster1` and
`cluster2`, making each a {{< gloss >}}primary cluster{{< /gloss >}} (this is currently the only supported configuration in ambient mode). Cluster
`cluster1` is on the `network1` network, while `cluster2` is on the
`network2` network. This means there is no direct connectivity between pods
across cluster boundaries.

Before proceeding, be sure to complete the steps under
[before you begin](/docs/ambient/install/multicluster/before-you-begin).

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
$ kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

## Configure `cluster1` as a primary

Create the `istioctl` configuration for `cluster1`:

{{< tabset category-name="multicluster-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Install Istio as primary in `cluster1` using istioctl and the `IstioOperator` API.

{{< text bash >}}
$ cat <<EOF > cluster1.yaml
apiVersion: insall.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
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
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster1 --set global.network=network1 --set profile=ambient --set env.AMBIENT_ENABLE_MULTI_NETWORK="true"
{{< /text >}}

Next, install the CNI node agent in ambient mode:

{{< text syntax=bash snip_id=install_cni_cluster1 >}}
$ helm install istio-cni istio/cni -n istio-system --kube-context "${CTX_CLUSTER1}" --set profile=ambient
{{< /text >}}

Finally, install the ztunnel data plane:

{{< text syntax=bash snip_id=install_ztunnel_cluster1 >}}
$ helm install ztunnel istio/ztunnel -n istio-system --kube-context "${CTX_CLUSTER1}" --set multiCluster.clusterName=cluster1 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Install an ambient east-west gateway in `cluster1`

Install a gateway in `cluster1` that is dedicated to ambient
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) traffic. Be
aware that, depending on your Kubernetes environment, this gateway may be
deployed on the public Internet by default. Production systems may
require additional access restrictions (e.g. via firewall rules) to prevent
external attacks. Check with your cloud vendor to see what options are
available.

{{< tabset category-name="east-west-gateway-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network1 \
    --ambient | \
    kubectl --context="${CTX_CLUSTER1}" apply -f -
{{< /text >}}

{{< warning >}}
If the control-plane was installed with a revision, add the `--revision rev` flag to the `gen-eastwest-gateway.sh` command.
{{< /warning >}}

{{< /tab >}}
{{< tab name="Kubectl apply" category-value="helm" >}}

Install the east-west gateway in `cluster1` using the following Gateway definition:

{{< text bash >}}
$ cat <<EOF > cluster1-ewgateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "network1"
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # represents double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< warning >}}
If you are running a revisioned instance of istiod and you don't have a default revision or tag set, you may need to add the `istio.io/rev` label to this `Gateway` manifest.
{{< /warning >}}

Apply the configuration to `cluster1`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -f cluster1-ewgateway.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Wait for the east-west gateway to be assigned an external IP address:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
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
apiVersion: insall.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
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
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER2}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster2 --set global.network=network2 --set profile=ambient --set env.AMBIENT_ENABLE_MULTI_NETWORK="true"
{{< /text >}}

Next, install the CNI node agent in ambient mode:

{{< text syntax=bash snip_id=install_cni_cluster2 >}}
$ helm install istio-cni istio/cni -n istio-system --kube-context "${CTX_CLUSTER2}" --set profile=ambient
{{< /text >}}

Finally, install the ztunnel data plane:

{{< text syntax=bash snip_id=install_ztunnel_cluster2 >}}
$ helm install ztunnel istio/ztunnel -n istio-system --kube-context "${CTX_CLUSTER2}"  --set multiCluster.clusterName=cluster2 --set global.network=network2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Install an ambient east-west gateway in `cluster2`

As we did with `cluster1` above, install a gateway in `cluster2` that is dedicated
to east-west traffic.

{{< tabset category-name="east-west-gateway-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network2 \
    --ambient | \
    kubectl apply --context="${CTX_CLUSTER2}" -f -
{{< /text >}}

{{< /tab >}}
{{< tab name="Kubectl apply" category-value="helm" >}}

Install the east-west gateway in `cluster2` using the following Gateway definition:

{{< text bash >}}
$ cat <<EOF > cluster2-ewgateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "network2"
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # represents double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< warning >}}
If you are running a revisioned instance of istiod and you don't have a default revision or tag set, you may need to add the `istio.io/rev` label to this `Gateway` manifest.
{{< /warning >}}

Apply the configuration to `cluster2`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER2}" -f cluster2-ewgateway.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Wait for the east-west gateway to be assigned an external IP address:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
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

You can now [verify the installation](/docs/ambient/install/multicluster/verify).

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
$ helm delete ztunnel -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-cni -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

Delete the `istio-system` namespace from `cluster1`:

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

Delete Istio Helm installation from `cluster2`:

{{< text syntax=bash >}}
$ helm delete ztunnel -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-cni -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER2}"
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

And finally, clean up the Gateway API CRDs:

{{< text syntax=bash snip_id=delete_gateway_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'gateway.networking.k8s.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'gateway.networking.k8s.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
