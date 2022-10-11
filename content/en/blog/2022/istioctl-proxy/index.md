---
title: Configuring istioctl for a remote cluster
description: Using a proxy server to support istioctl commands in a mesh with an external control plane.
publishdate: 2022-03-25
attribution: Frank Budinsky (IBM)
keywords: [istioctl, cli, external, remote, multicluster]
---

When using the `istioctl` CLI on a {{< gloss >}}remote cluster{{< /gloss >}} of an
[external control plane](/docs/setup/install/external-controlplane/) or a [multicluster](/docs/setup/install/multicluster/)
Istio deployment, some of the commands will not work by default. For example, `istioctl proxy-status` requires access to
the `istiod` service to retrieve the status and configuration of the proxies it's managing. If you try running it on a
remote cluster, you'll get an error message like this:

{{< text bash >}}
$ istioctl proxy-status
Error: unable to find any Istiod instances
{{< /text >}}

Notice that the error message doesn't just say that it's unable to access the `istiod` service, it specifically mentions
its inability to find `istiod` instances. This is because the `istioctl proxy-status` implementation needs to retrieve
the sync status of not just any single `istiod` instance, but rather all of them. When there is more than one `istiod`
instance (replica) running, each instance is only connected to a subset of the service proxies running in the mesh.
The `istioctl` command needs to return the status for the entire mesh, not just the subset managed by one of the instances.

In an ordinary Istio installation where the `istiod` service is running locally on the cluster
(i.e., a {{< gloss >}}primary cluster{{< /gloss >}}), the command is implemented by simply finding all of the running
`istiod` pods, calling each one in turn, and then aggregating the result before returning it to the user.

{{< image width="75%"
    link="istioctl-primary-cluster.svg"
    caption="CLI with local access to istiod pods"
    >}}

When using a remote cluster, on the other hand, this is not possible since the `istiod` instances are running outside
of the mesh cluster and not accessible to the mesh user. The instances may not even be deployed using pods on a Kubernetes
cluster.

Fortunately, `istioctl` provides a configuration option to address this issue.
You can configure `istioctl` with the address of an external proxy service that will have access to the
`istiod` instances. Unlike an ordinary load-balancer service, which would delegate incoming requests to one of the
instances, this proxy service must instead delegate to all of the `istiod` instances, aggregate the responses,
and then return the combined result.

If the external proxy service is, in fact, running on another Kubernetes cluster, the proxy implementation code
can be very similar to the implementation code that `istioctl` runs in the primary cluster case, i.e., find all of the
running `istiod` pods, call each one in turn, and then aggregate the result.

{{< image width="75%"
    link="istioctl-remote-cluster.svg"
    caption="CLI without local access to istiod pods"
    >}}

An Istio Ecosystem project that includes an implementation of such an `istioctl` proxy server can be found
[here](https://github.com/istio-ecosystem/istioctl-proxy-sample). To try it out, you'll need two clusters, one of which is
configured as a remote cluster using a control plane installed in the other cluster.

## Install Istio with a remote cluster topology

To demonstrate `istioctl` working on a remote cluster, we'll start by using the
[external control plane install instructions](/docs/setup/install/external-controlplane/)
to set up a single remote cluster mesh with an external control plane running in a separate external cluster.

After completing the installation, we should have two environment variables, `CTX_REMOTE_CLUSTER` and `CTX_EXTERNAL_CLUSTER`,
containing the context names of the remote (mesh) and external (control plane) clusters, respectively.

We should also have the `helloworld` and `sleep` samples running in the mesh, i.e., on the remote cluster:

{{< text bash >}}
$ kubectl get pod -n sample --context="${CTX_REMOTE_CLUSTER}"
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-776f57d5f6-tmpkd   2/2     Running   0          10s
sleep-557747455f-v627d           2/2     Running   0          9s
{{< /text >}}

Notice that if you try to run `istioctl proxy-status` in the remote cluster, you will see the error message
described earlier:

{{< text bash >}}
$ istioctl proxy-status --context="${CTX_REMOTE_CLUSTER}"
Error: unable to find any Istiod instances
{{< /text >}}

## Configure istioctl to use the sample proxy service

To configure `istioctl`, we first need to deploy  the proxy service next to the running `istiod` pods.
In our installation, we've deployed the control plane in the `external-istiod` namespace, so we start the proxy
service on the external cluster using the following command:

{{< text bash >}}
$ kubectl apply -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}" \
    -f https://raw.githubusercontent.com/istio-ecosystem/istioctl-proxy-sample/main/istioctl-proxy.yaml
service/istioctl-proxy created
serviceaccount/istioctl-proxy created
secret/jwt-cert-key-secret created
deployment.apps/istioctl-proxy created
role.rbac.authorization.k8s.io/istioctl-proxy-role created
rolebinding.rbac.authorization.k8s.io/istioctl-proxy-role created
{{< /text >}}

You can run the following command to confirm that the `istioctl-proxy` service is running next to `istiod`:

{{< text bash >}}
$ kubectl get po -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
NAME                              READY   STATUS    RESTARTS   AGE
istioctl-proxy-664bcc596f-9q8px   1/1     Running   0          15s
istiod-666fb6694d-jklkt           1/1     Running   0          5m31s
{{< /text >}}

The proxy service is a gRPC server that is serving on port 9090:

{{< text bash >}}
$ kubectl get svc istioctl-proxy -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
istioctl-proxy   ClusterIP   172.21.127.192   <none>        9090/TCP   11m
{{< /text >}}

Before we can use it, however, we need to expose it outside of the external cluster.
There are many ways to do that, depending on the deployment environment. In our setup, we have an ingress gateway
running on the external cluster, so we could update it to also expose port 9090, update the associated virtual service
to direct port 9090 requests to the proxy service, and then configure `istioctl` to use the gateway address for the proxy
service. This would be a "proper" approach.

However, since this is just a simple demonstration where we have access to both clusters, we will simply `port-forward`
the proxy service to `localhost`:

{{< text bash >}}
$ kubectl port-forward -n external-istiod service/istioctl-proxy 9090:9090 --context="${CTX_EXTERNAL_CLUSTER}"
{{< /text >}}

We now configure `istioctl` to use `localhost:9090` to access the proxy by setting the `ISTIOCTL_XDS_ADDRESS` environment
variable:

{{< text bash >}}
$ export ISTIOCTL_XDS_ADDRESS=localhost:9090
$ export ISTIOCTL_ISTIONAMESPACE=external-istiod
$ export ISTIOCTL_PREFER_EXPERIMENTAL=true
{{< /text >}}

Because our control plane is running in the `external-istiod` namespace, instead of the default `istio-system`, we also
need to set the `ISTIOCTL_ISTIONAMESPACE` environment variable.

Setting `ISTIOCTL_PREFER_EXPERIMENTAL` is optional. It instructs `istioctl` to redirect `istioctl command` calls to
an experimental equivalent, `istioctl x command`, for any `command` that has both a stable and experimental implementation.
In our case we need to use `istioctl x proxy-status`, the version that implements the proxy delegation feature.

## Run the istioctl proxy-status command

Now that we're finished configuring `istioctl` we can try it out by running the `proxy-status` command again:

{{< text bash >}}
$ istioctl proxy-status --context="${CTX_REMOTE_CLUSTER}"
NAME                                                      CDS        LDS        EDS        RDS        ISTIOD         VERSION
helloworld-v1-776f57d5f6-tmpkd.sample                     SYNCED     SYNCED     SYNCED     SYNCED     <external>     1.12.1
istio-ingressgateway-75bfd5668f-lggn4.external-istiod     SYNCED     SYNCED     SYNCED     SYNCED     <external>     1.12.1
sleep-557747455f-v627d.sample                             SYNCED     SYNCED     SYNCED     SYNCED     <external>     1.12.1
{{< /text >}}

As you can see, this time it correctly displays the sync status of all the services running in the mesh. Notice that the
`ISTIOD` column returns the generic value `<external>`, instead of the instance name (e.g., `istiod-666fb6694d-jklkt`)
that would be displayed if the pod was running locally. In this case, this detail is not available, or needed, by the
mesh user. It's only available on the external cluster for the mesh operator to see.

## Summary

In this article, we used a [sample proxy server](https://github.com/istio-ecosystem/istioctl-proxy-sample) to configure `istioctl` to
work with an [external control plane installation](/docs/setup/install/external-controlplane/).
We've seen how some of the `istioctl` CLI commands don't work out of the box on a remote cluster managed
by an external control plane. Commands such as `istioctl proxy-status`, among others, need access to the `istiod` service
instances managing the mesh, which are unavailable when the control plane is running outside of the mesh cluster.
To address this issue, `istioctl` was configured to delegate to a proxy server, running along side the external control
plane, which accesses the `istiod` instances on its behalf.
