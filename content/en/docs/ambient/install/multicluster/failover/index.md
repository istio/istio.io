---
title: Configure failover behavior in multicluster ambient installation
description: Configure outlier detection and failover behavior in ambient multicluster ambient mesh using waypoints.
weight: 70
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /docs/ambient/install/multicluster/verify
---
Follow this guide to customize failover behavior in your ambient multicluster Istio installation using waypoint proxies.

Before proceeding, be sure to complete ambient multicluster Istio installation following one of the
[multicluster installation guides](/docs/ambient/install/multicluster) and verify that the installation is working properly.

In this guide, we will build on top of the `HelloWorld` application used to verify the multicluster installation. We will
configure locality failover for the `HelloWorld` service to prefer endpoints in the cluster local to the client using a
`DestinationRule` and will deploy a waypoint proxy to enforce the configuration.

## Deploy waypoint proxy

In order to configure outlier detection and customize failover behavior for the service we need a waypoint proxy. To begin,
deploy waypoint proxy to each cluster in the mesh:

{{< text bash >}}
$ istioctl --context "${CTX_CLUSTER1}" waypoint apply --name waypoint --for service -n sample --wait
$ istioctl --context "${CTX_CLUSTER2}" waypoint apply --name waypoint --for service -n sample --wait
{{< /text >}}

Confirm the status of the waypoint proxy deployment on `cluster1`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" get deployment waypoint --namespace sample
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
waypoint   1/1     1            1           137m
{{< /text >}}

Confirm the status of the waypoint proxy deployment on `cluster2`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER2}" get deployment waypoint --namespace sample
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
waypoint   1/1     1            1           138m
{{< /text >}}

Wait until all waypoint proxies are ready.

Configure `HelloWorld` service in each cluster to use the waypoint proxy:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" label svc helloworld -n sample istio.io/use-waypoint=waypoint
$ kubectl --context "${CTX_CLUSTER2}" label svc helloworld -n sample istio.io/use-waypoint=waypoint
{{< /text >}}

Finally, and this step is specific to multicluster deployment of waypoint proxies, mark the waypoint proxy service in each
cluster as global, just like you did earlier with the `HelloWorld` service:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" label svc waypoint -n sample istio.io/global=true
$ kubectl --context "${CTX_CLUSTER2}" label svc waypoint -n sample istio.io/global=true
{{< /text >}}

The `HelloWorld` service in both clusters is now configured to use waypoint proxies, but waypoint proxies don't do anything
useful yet.

## Configure locality failover

To configure locality failover create and apply a `DestinationRule` in `cluster1`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
          - topology.istio.io/cluster
EOF
{{< /text >}}

Apply the same `DestinationRule` in `cluster2` as well:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER2}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
          - topology.istio.io/cluster
EOF
{{< /text >}}

This `DestinationRule` configures the following:

- [Outlier detection](/docs/reference/config/networking/destination-rule/#OutlierDetection) for the `HelloWorld` service.
  This instructs waypoint proxies how to identify when endpoints for a service are unhealthy. It's required for failover
  to function properly.

- [Failover priority](/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting) that instructs
  waypoint proxy how to prioritize endpoints when routing requests. In this example, waypoint proxy will prefer endpoints
  in the same cluster over endpoints in other clusters.

With these policies in place, waypoint proxies will prefer endpoints in the same cluster as the waypoint proxy when they
are available and considered healthy based on the outlier detection configuration.

## Verify traffic stays in local cluster

Send request from the `curl` pods on `cluster1` to the `HelloWorld` service:

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Now, if you repeat this request several times and verify that the `HelloWorld` version should always be `v1` because the
traffic stays in `cluster1`:

{{< text plain >}}
Hello version: v1, instance: helloworld-v1-954745fd-z6qcn
Hello version: v1, instance: helloworld-v1-954745fd-z6qcn
...
{{< /text >}}

Similarly, send request from `curl` pods on `cluster2` several times:

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER2}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER2}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

You should see that all requests are processed in `cluster2` by looking at the version in the response:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
...
{{< /text >}}

## Verify failover to another cluster

To verify that failover to remote cluster works simulate `HelloWorld` service outage in `cluster1` by scaling down
deployment:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" scale --replicas=0 deployment/helloworld-v1 -n sample
{{< /text >}}

Send request from the `curl` pods on `cluster1` to the `HelloWorld` service again:

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

This time you should see that the request is processed by `HelloWorld` service in `cluster2` because there are no
available endpoints in `cluster1`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
...
{{< /text >}}

**Congratulations!** You successfully configuration locality failover in Istio ambient multicluster deployment!
