---
title: Troubleshooting Multicluster
description: Describes tools and techniques to diagnose issues with multicluster and multi-network installations.
weight: 90
keywords: [debug,multicluster,multi-network,envoy]
owner: istio/wg-environments-maintainers
test: no
---

This page describes how to troubleshoot issues with Istio deployed to multiple clusters and/or networks.
Before reading this, you should take the steps in [Multicluster Installation](/docs/setup/install/multicluster/)
and read the [Deployment Models](/docs/ops/deployment/deployment-models/) guide.

## Cross-Cluster Load Balancing

The most common, but also broad problem with multi-network installations is that cross-cluster load balancing doesn’t work. Usually this manifests itself as only seeing responses from the cluster-local instance of a Service:

{{< text bash >}}
$ for i in $(seq 10); do kubectl --context=$CTX_CLUSTER1 -n sample exec sleep-dd98b5f48-djwdw -c sleep -- curl -s helloworld:5000/hello; done
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
...
{{< /text >}}

When following the guide to [verify multicluster installation](/docs/setup/install/multicluster/verify/)
we would expect both `v1` and `v2` responses, indicating traffic is going to both clusters.

There are many possible causes to the problem:

### Connectivity and firewall issues

In some environments it may not be apparent that a firewall is blocking traffic between your clusters. It's possible
that `ICMP` (ping) traffic may succeed, but HTTP and other types of traffic do not. This can appear as a timeout, or
in some cases a more confusing error such as:

{{< text plain >}}
upstream connect error or disconnect/reset before headers. reset reason: local reset, transport failure reason: TLS error: 268435612:SSL routines:OPENSSL_internal:HTTP_REQUEST
{{< /text >}}

While Istio provides service discovery capabilities to make it easier, cross-cluster traffic should still succeed
if pods in each cluster are on a single network without Istio. To rule out issues with TLS/mTLS, you can do a manual
traffic test using pods without Istio sidecars.

In each cluster, create a new namespace for this test. Do _not_ enable sidecar injection:

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace uninjected-sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace uninjected-sample
{{< /text >}}

Then deploy the same apps used in [verify multicluster installation](/docs/setup/install/multicluster/verify/):

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v1 -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v2 -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/sleep/sleep.yaml -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/sleep/sleep.yaml -n uninjected-sample
{{< /text >}}

Verify that there is a helloworld pod running in `cluster2`, using the `-o wide` flag, so we can get the Pod IP:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" -n uninjected-sample get pod -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
helloworld-v2-54df5f84b-z28p5    1/1     Running   0          43s   10.100.0.1   node-1   <none>           <none>
sleep-557747455f-jdsd8           1/1     Running   0          41s   10.100.0.2   node-2   <none>           <none>
{{< /text >}}

Take note of the `IP` column for `helloworld`. In this case, it is `10.100.0.1`:

{{< text bash >}}
$ REMOTE_POD_IP=10.100.0.1
{{< /text >}}

Next, attempt to send traffic from the `sleep` pod in `cluster1` directly to this Pod IP:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n uninjected-sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n uninjected-sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS $REMOTE_POD_IP:5000/hello
Hello version: v2, instance: helloworld-v2-54df5f84b-z28p5
{{< /text >}}

If successful, there should be responses only from `helloworld-v2`. Repeat the steps, but send traffic from `cluster2`
to `cluster1`.

If this succeeds, you can rule out connectivity issues. If it does not, the cause of the problem may lie outside your
Istio configuration.

### Locality Load Balancing

[Locality load balancing](/docs/tasks/traffic-management/locality-load-balancing/failover/#configure-locality-failover)
can be used to make clients prefer that traffic go to the nearest destination. If the clusters
are in different localities (region/zone), locality load balancing will prefer the local-cluster and is working as
intended. If locality load balancing is disabled, or the clusters are in the same locality, there may be another issue.

### Trust Configuration

Cross-cluster traffic, as with intra-cluster traffic, relies on a common root of trust between the proxies. The default
Istio installation will use their own individually generated root certificate-authorities. For multi-cluster, we
must manually configure a shared root of trust. Follow Plug-in Certs below or read [Identity and Trust Models](/docs/ops/deployment/deployment-models/#identity-and-trust-models)
to learn more.

**Plug-in Certs:**

To verify certs are configured correctly, you can compare the root-cert in each cluster:

{{< text bash >}}
$ diff \
   <(kubectl --context="${CTX_CLUSTER1}" -n istio-system get secret cacerts -ojsonpath='{.data.root-cert\.pem}') \
   <(kubectl --context="${CTX_CLUSTER2}" -n istio-system get secret cacerts -ojsonpath='{.data.root-cert\.pem}')
{{< /text >}}

If the root-certs do not match or the secret does not exist at all, you can follow the [Plugin CA Certs](/docs/tasks/security/cert-management/plugin-ca-cert/)
guide, ensuring to run the steps for every cluster.

### Step-by-step Diagnosis

If you've gone through the sections above and are still having issues, then it's time to dig a little deeper.

The following steps assume you're following the [HelloWorld verification](/docs/setup/install/multicluster/verify/).
Before continuing, make sure both `helloworld` and `sleep` are deployed in each cluster.

From each cluster, find the endpoints the `sleep` service has for `helloworld`:

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
{{< /text >}}

Troubleshooting information differs based on the cluster that is the source of traffic:

{{< tabset category-name="source-cluster" >}}

{{< tab name="Primary cluster" category-value="primary" >}}

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
10.0.0.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

Only one endpoint is shown, indicating the control plane cannot read endpoints from the remote cluster.
Verify that remote secrets are configured properly.

{{< text bash >}}
$ kubectl get secrets --context=$CTX_CLUSTER1 -n istio-system -l "istio/multiCluster=true"
{{< /text >}}

* If the secret is missing, create it.
* If the secret is present:
    * Look at the config in the secret. Make sure the cluster name is used as the data key for the remote `kubeconfig`.
    * If the secret looks correct, check the logs of `istiod` for connectivity or permissions issues reaching the
     remote Kubernetes API server. Log messages may include `Failed to add remote cluster from secret` along with an
     error reason.

{{< /tab >}}

{{< tab name="Remote cluster" category-value="remote" >}}

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER2 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
10.0.1.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

Only one endpoint is shown, indicating the control plane cannot read endpoints from the remote cluster.
Verify that remote secrets are configured properly.

{{< text bash >}}
$ kubectl get secrets --context=$CTX_CLUSTER1 -n istio-system -l "istio/multiCluster=true"
{{< /text >}}

* If the secret is missing, create it.
* If the secret is present and the endpoint is a Pod in the **primary** cluster:
    * Look at the config in the secret. Make sure the cluster name is used as the data key for the remote `kubeconfig`.
    * If the secret looks correct, check the logs of `istiod` for connectivity or permissions issues reaching the
     remote Kubernetes API server. Log messages may include `Failed to add remote cluster from secret` along with an
     error reason.
* If the secret is present and the endpoint is a Pod in the **remote** cluster:
    * The proxy is reading configuration from an istiod inside the remote cluster. When a remote cluster has an in
     -cluster istiod,  it is only meant for sidecar injection and CA. You can verify this is the problem by looking
     for a Service named `istiod-remote` in the `istio-system` namespace. If it's missing, reinstall making sure
     `values.global.remotePilotAddress` is set.

{{< /tab >}}

{{< tab name="Multi-Network" category-value="multi-primary" >}}

The steps for Primary and Remote clusters still apply for multi-network, although multi-network has an additional case:

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
10.0.5.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
10.0.6.13:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

In multi-network, we expect one of the endpoint IPs to match the remote cluster's east-west gateway public IP. Seeing
multiple Pod IPs indicates one of two things:

* The address of the gateway for the remote network cannot be determined.
* The network of either the client or server pod cannot be determined.

**The address of the gateway for the remote network cannot be determined:**

In the remote cluster that cannot be reached, check that the Service has an External IP:

{{< text bash >}}
$ kubectl -n istio-system get service -l "istio=eastwestgateway"
NAME                      TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                                                           AGE
istio-eastwestgateway    LoadBalancer   10.8.17.119   <PENDING>        15021:31781/TCP,15443:30498/TCP,15012:30879/TCP,15017:30336/TCP   76m
{{< /text >}}

If the `EXTERNAL-IP` is stuck in `<PENDING>`, the environment may not support `LoadBalancer` services. In this case, it
may be necessary to customize the `spec.externalIPs` section of the Service to manually give the Gateway an IP reachable
from outside the cluster.

If the external IP is present, check that the Service includes a `topology.istio.io/network` label with the correct
value. If that is incorrect, reinstall the gateway and make sure to set the --network flag on the generation script.

**The network of either the client or server cannot be determined.**

On the source pod, check the proxy metadata.

{{< text bash >}}
$ kubectl get pod $SLEEP_POD_NAME \
  -o jsonpath="{.spec.containers[*].env[?(@.name=='ISTIO_META_NETWORK')].value}"
{{< /text >}}

{{< text bash >}}
$ kubectl get pod $HELLOWORLD_POD_NAME \
  -o jsonpath="{.metadata.labels.topology\.istio\.io/network}"
{{< /text >}}

If either of these values aren't set, or have the wrong value, istiod may treat the source and client proxies as being on the same network and send network-local endpoints.
When these aren't set, check that `values.global.network` was set properly during install, or that the injection webhook is configured correctly.

Istio determines the network of a Pod using the `topology.istio.io/network` label which is set during injection. For
non-injected Pods, Istio relies on the `topology.istio.io/network` label set on the system namespace in the cluster.

In each cluster, check the network:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get ns istio-system -ojsonpath='{.metadata.labels.topology\.istio\.io/network}'
{{< /text >}}

If the above command doesn't output the expected network name, set the label:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
