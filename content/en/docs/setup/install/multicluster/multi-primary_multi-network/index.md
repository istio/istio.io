---
title: Install Multi-Primary on Different Networks
description: Install an Istio mesh across multiple primary clusters on different networks.
weight: 30
icon: setup
aliases:
    - /docs/setup/kubernetes/multicluster-install/
    - /docs/setup/kubernetes/multicluster/
    - /docs/setup/kubernetes/install/multicluster/
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
[Before you begin](/docs/setup/install/multicluster#before-you-begin).

In this configuration, both `cluster1` and `cluster2` observe the API Servers
in each cluster for endpoints.

Service workloads across cluster boundaries communicate indirectly, via
dedicated gateways for [east-west](https://en.wikipedia.org/wiki/East-west_traffic)
traffic. The gateway in each cluster must be reachable from the other cluster.

{{< image width="75%"
    link="arch.svg"
    caption="Multiple primary clusters on separate networks"
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

Install a gateway in `cluster1` that is dedicated to
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) traffic. By
default, this gateway will be public on the Internet. Production systems may
require additional access restrictions (e.g. via firewall rules) to prevent
external attacks. Check with your cloud vendor to see what options are
available.

{{< text bash >}}
$ MESH=mesh1 CLUSTER=cluster1 NETWORK=network1 \
    @samples/multicluster/gen-eastwest-gateway.sh@ | \
    istioctl manifest generate -f - | \
    kubectl apply --context="${CTX_CLUSTER1}" -f -
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

## Configure cluster2 as a primary

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
      network: network2
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
$ MESH=mesh1 CLUSTER=cluster2 NETWORK=network2 \
    @samples/multicluster/gen-eastwest-gateway.sh@ | \
    istioctl manifest generate -f - | \
    kubectl apply --context="${CTX_CLUSTER2}" -f -
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

## Verify the Installation

To verify that your Istio installation is working as intended, we will deploy
the `HelloWorld` application `V1` to `cluster1` and `V2` to `cluster2`. Upon receiving a
request, `HelloWorld` will include its version in its response.

We will also deploy the `Sleep` container to both clusters. We will use these
pods as the source of requests to the `HelloWorld` service,
simulating in-mesh traffic. Finally, after generating traffic, we will observe
which cluster received the requests.

### Deploy the `HelloWorld` Service

In order to make the `HelloWorld` service callable from any cluster, the DNS
lookup must succeed in each cluster (see
[deployment models](/docs/ops/deployment/deployment-models#dns-with-multiple-clusters)
for details). We will address this by deploying the `HelloWorld` Service to
each cluster in the mesh.

To begin, create the `sample` namespace in each cluster:

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace sample
{{< /text >}}

Enable automatic sidecar injection for the `sample` namespace:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio-injection=enabled
$ kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio-injection=enabled
{{< /text >}}

Create the `HelloWorld` service in both clusters:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l service=helloworld -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l service=helloworld -n sample
{{< /text >}}

### Deploy `HelloWorld` `V1`

Deploy the `helloworld-v1` application to `cluster1`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v1 -n sample
{{< /text >}}

Confirm the `helloworld-v1` pod status:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v1-86f77cd7bd-cpxhv  2/2       Running   0          40s
{{< /text >}}

Wait until the status of `helloworld-v1` is `Running`.

### Deploy `HelloWorld` `V2`

Deploy the `helloworld-v2` application to `cluster2`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v2 -n sample
{{< /text >}}

Confirm the status the `helloworld-v2` pod status:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v2-758dd55874-6x4t8  2/2       Running   0          40s
{{< /text >}}

Wait until the status of `helloworld-v2` is `Running`.

### Deploy `Sleep`

Deploy the `Sleep` application to both clusters:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/sleep/sleep.yaml@ -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/sleep/sleep.yaml@ -n sample
{{< /text >}}

Confirm the status `Sleep` pod on `cluster1`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=sleep
NAME                             READY   STATUS    RESTARTS   AGE
sleep-754684654f-n6bzf           2/2     Running   0          5s
{{< /text >}}

Wait until the status of the `Sleep` pod is `Running`.

Confirm the status of the `Sleep` pod on `cluster2`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=sleep
NAME                             READY   STATUS    RESTARTS   AGE
sleep-754684654f-dzl9j           2/2     Running   0          5s
{{< /text >}}

Wait until the status of the `Sleep` pod is `Running`.

### Verifying Cross-Cluster Traffic

To verify that cross-cluster load balancing works as expected, call the
`HelloWorld` service several times using the `Sleep` pod. To ensure load
balancing is working properly, call the `HelloWorld` service from all
clusters in your deployment.

Send one request from the `Sleep` pod on `cluster1` to the `HelloWorld` service:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
{{< /text >}}

Repeat this request several times and verify that the `HelloWorld` version
should toggle between `v1` and `v2`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

Now repeat this process from the `Sleep` pod on `cluster2`:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER2}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
{{< /text >}}

Repeat this request several times and verify that the `HelloWorld` version
should toggle between `v1` and `v2`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

**Congratulations!** You successfully installed and verified Istio in a
multi-primary, multi-network configuration!
