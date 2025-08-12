---
title: Verify the ambient installation
description: Verify that Istio ambient mesh has been installed properly on multiple clusters.
weight: 50
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /docs/ambient/install/multicluster/multi-primary_multi-network
---
Follow this guide to verify that your ambient multicluster Istio installation is working
properly.

Before proceeding, be sure to complete the steps under
[before you begin](/docs/ambient/install/multicluster/before-you-begin) as well as
choosing and following one of the [multicluster installation guides](/docs/ambient/install/multicluster).

In this guide, we will verify multicluster is functional, deploy the `HelloWorld`
application `v1` to `cluster1` and `v2` to `cluster2`. Upon receiving a request,
`HelloWorld` will include its version in its response when we call the `/hello` path.

We will also deploy the `curl` container to both clusters. We will use these
pods as the source of requests to the `HelloWorld` service,
simulating in-mesh traffic. Finally, after generating traffic, we will observe
which cluster received the requests.

## Verify Multicluster

To confirm that Istiod is now able to communicate with the Kubernetes control plane
of the remote cluster.

{{< text bash >}}
$ istioctl remote-clusters --context="${CTX_CLUSTER1}"
NAME         SECRET                                        STATUS      ISTIOD
cluster1                                                   synced      istiod-7b74b769db-kb4kj
cluster2     istio-system/istio-remote-secret-cluster2     synced      istiod-7b74b769db-kb4kj
{{< /text >}}

All clusters should indicate their status as `synced`. If a cluster is listed with
a `STATUS` of `timeout` that means that Istiod in the primary cluster is unable to
communicate with the remote cluster. See the Istiod logs for detailed error
messages.

Note: if you do see `timeout` issues and there is an intermediary host (such as the [Rancher auth proxy](https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/manage-clusters/access-clusters/authorized-cluster-endpoint#two-authentication-methods-for-rke-clusters))
sitting between Istiod in the primary cluster and the Kubernetes control plane in
the remote cluster, you may need to update the `certificate-authority-data` field
of the kubeconfig that `istioctl create-remote-secret` generates in order to
match the certificate being used by the intermediate host.

## Deploy the `HelloWorld` Service

In order to make the `HelloWorld` service callable from any cluster, the DNS
lookup must succeed in each cluster (see
[deployment models](/docs/ops/deployment/deployment-models#dns-with-multiple-clusters)
for details). We will address this by deploying the `HelloWorld` Service to
each cluster in the mesh.

{{< tip >}}
Before proceeding, ensure that the istio-system namespaces in both clusters have the `istio.io/topology-network` set to the appropriate value (e.g., `network1` for `cluster1` and `network2` for `cluster2`).
{{< /tip >}}

To begin, create the `sample` namespace in each cluster:

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace sample
{{< /text >}}

Enroll the `sample` namespace in the mesh:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio.io/dataplane-mode=ambient
$ kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio.io/dataplane-mode=ambient
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

## Deploy `HelloWorld` `V1`

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
helloworld-v1-86f77cd7bd-cpxhv  1/1       Running   0          40s
{{< /text >}}

Wait until the status of `helloworld-v1` is `Running`.

Now, mark the helloworld service in `cluster1` as global so that it can be accessed from other clusters in the mesh:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" svc helloworld -n sample \
    istio.io/global="true"
{{< /text >}}

## Deploy `HelloWorld` `V2`

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
helloworld-v2-758dd55874-6x4t8  1/1       Running   0          40s
{{< /text >}}

Wait until the status of `helloworld-v2` is `Running`.

Now, mark the helloworld service in `cluster2` as global so that it can be accessed from other clusters in the mesh:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER2}" svc helloworld -n sample \
    istio.io/global="true"
{{< /text >}}

## Deploy `curl`

Deploy the `curl` application to both clusters:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/curl/curl.yaml@ -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/curl/curl.yaml@ -n sample
{{< /text >}}

Confirm the status `curl` pod on `cluster1`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=curl
NAME                             READY   STATUS    RESTARTS   AGE
curl-754684654f-n6bzf            1/1     Running   0          5s
{{< /text >}}

Wait until the status of the `curl` pod is `Running`.

Confirm the status of the `curl` pod on `cluster2`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=curl
NAME                             READY   STATUS    RESTARTS   AGE
curl-754684654f-dzl9j            1/1     Running   0          5s
{{< /text >}}

Wait until the status of the `curl` pod is `Running`.

## Verifying Cross-Cluster Traffic

To verify that cross-cluster load balancing works as expected, call the
`HelloWorld` service several times using the `curl` pod. To ensure load
balancing is working properly, call the `HelloWorld` service from all
clusters in your deployment.

Send one request from the `curl` pod on `cluster1` to the `HelloWorld` service:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Repeat this request several times and verify that the `HelloWorld` version
should change between `v1` and `v2`, signifying that endpoints in both
clusters are being used:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

Now repeat this process from the `curl` pod on `cluster2`:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER2}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Repeat this request several times and verify that the `HelloWorld` version
should toggle between `v1` and `v2`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

**Congratulations!** You successfully installed and verified Istio on multiple
clusters!

<!-- TODO: Link to guide for locality load balancing once we add waypoint instructions -->
