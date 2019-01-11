---
title: Gateway-Connected Clusters
description: Configuring remote services in a gateway-connected multicluster mesh.
weight: 20
keywords: [kubernetes,multicluster]
---

This example shows how to configure and call remote services in a multicluster mesh with a
[multiple control plane topology](/docs/concepts/multicluster-deployments/#multiple-control-plane-topology).
To demonstrate cross cluster access,
the [sleep service]({{<github_tree>}}/samples/sleep)
running in one cluster is configured
to call the [httpbin service]({{<github_tree>}}/samples/httpbin)
running in a second cluster.

## Before you begin

* Set up a multicluster environment with two Istio clusters by following the
    [multiple control planes with gateways](/docs/setup/kubernetes/multicluster-install/gateways/) instructions.

* The `kubectl` command will be used to access both clusters with the `--context` flag.
    Export the following environment variables with the context names of your configuration:

    {{< text bash >}}
    $ export CTX_CLUSTER1=<cluster1 context name>
    $ export CTX_CLUSTER2=<cluster2 context name>
    {{< /text >}}

## Configure the example services

1. Deploy the `sleep` service in `cluster1`.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 namespace foo
    $ kubectl label --context=$CTX_CLUSTER1 namespace foo istio-injection=enabled
    $ kubectl apply --context=$CTX_CLUSTER1 -n foo -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. Deploy the `httpbin` service in `cluster2`.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 namespace bar
    $ kubectl label --context=$CTX_CLUSTER2 namespace bar istio-injection=enabled
    $ kubectl apply --context=$CTX_CLUSTER2 -n bar -f @samples/httpbin/httpbin.yaml@
    $ export GATEWAY_IP_CLUSTER2=$(kubectl get --context=$CTX_CLUSTER2 svc --selector=app=istio-ingressgateway \
        -n istio-system -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
    {{< /text >}}

1. Create a service entry for the `httpbin` service in `cluster1`.

    To allow `sleep` in `cluster1` to access `httpbin` in `cluster2`, we need to create
    a service entry for it. The host name of the service entry should be of the form
    `<name>.<namespace>.global` where name and namespace correspond to the
    remote service's name and namespace respectively.

    For DNS resolution for services under the
    `*.global` domain, you need to assign these services an IP address. We
    suggest assigning an IP address from the 127.255.0.0/16 subnet. These IPs
    are non-routable outside of a pod. Application traffic for these IPs will
    be captured by the sidecar and routed to the appropriate remote service.

    > Each service (in the `.global` DNS domain) must have a unique IP within the cluster.

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin-bar
    spec:
      hosts:
      # must be of form name.namespace.global
      - httpbin.bar.global
      # Treat remote cluster services as part of the service mesh
      # as all clusters in the service mesh share the same root of trust.
      location: MESH_INTERNAL
      ports:
      - name: http1
        number: 8000
        protocol: http
      resolution: DNS
      addresses:
      # the IP address to which httpbin.bar.global will resolve to
      # must be unique for each remote service, within a given cluster.
      # This address need not be routable. Traffic for this IP will be captured
      # by the sidecar and routed appropriately.
      - 127.255.0.2
      endpoints:
      # This is the routable address of the ingress gateway in cluster2 that
      # sits in front of sleep.bar service. Traffic from the sidecar will be
      # routed to this address.
      - address: ${GATEWAY_IP_CLUSTER2}
        ports:
          http1: 15443 # Do not change this port value
    EOF
    {{< /text >}}

    The configurations above will result in all traffic in `cluster1` for
    `httpbin.bar.global` on *any port* to be routed to the endpoint
    `<IPofCluster2IngressGateway>:15443` over an mTLS connection.

    > Do not create a `Gateway` configuration for port 15443.

    The gateway for port 15443 is a special SNI-aware Envoy
    preconfigured and installed as part of the multicluster Istio installation step
    in the [before you begin](#before-you-begin) section. Traffic entering port 15443 will be
    load balanced among pods of the appropriate internal service of the target
    cluster (in this case, `httpbin.bar` in `cluster2`).

1. Verify that `httpbin` is accessible from the `sleep` service.

    {{< text bash >}}
    $ kubectl exec --context=$CTX_CLUSTER1 $(kubectl get --context=$CTX_CLUSTER1 -n foo pod -l app=sleep -o jsonpath={.items..metadata.name}) \
       -n foo -c sleep -- curl httpbin.bar.global:8000/ip
    {{< /text >}}

## Send remote cluster traffic using egress gateway

If you want to route traffic from `cluster1` via a dedicated
egress gateway, instead of directly from the sidecars,
use the following service entry for `httpbin.bar` instead of the one in the previous section.

> The egress gateway used in this configuration cannot also be used for other, non inter-cluster, egress traffic.

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-bar
spec:
  hosts:
  # must be of form name.namespace.global
  - httpbin.bar.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8000
    protocol: http
  resolution: DNS
  addresses:
  - 127.255.0.2
  endpoints:
  - address: ${GATEWAY_IP_CLUSTER2}
    network: external
    ports:
      http1: 15443 # Do not change this port value
  - address: istio-egressgateway.istio-system.svc.cluster.local
    ports:
      http1: 15443
EOF
{{< /text >}}

## Version-aware routing to remote services

If the remote service has multiple versions, you can add one or more
labels to the service entry endpoint.
For example:

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-bar
spec:
  hosts:
  # must be of form name.namespace.global
  - httpbin.bar.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8000
    protocol: http
  resolution: DNS
  addresses:
  # the IP address to which httpbin.bar.global will resolve to
  # must be unique for each service.
  - 127.255.0.2
  endpoints:
  - address: ${GATEWAY_IP_CLUSTER2}
    labels:
      version: beta
      some: thing
      foo: bar
    ports:
      http1: 15443 # Do not change this port value
EOF
{{< /text >}}

You can then follow the steps outlined in the
[request routing](/docs/tasks/traffic-management/request-routing/) task
to create appropriate virtual services and destination rules.
Use destination rules to define subsets of the `httpbin.bar.global` service with
the appropriate label selectors.
The instructions are identical to those used for routing to a local service.

## Cleanup

Execute the following commands to clean up the example services.

* Cleanup `cluster1`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER1 -n foo -f @samples/httpbin/sleep.yaml@
    $ kubectl delete --context=$CTX_CLUSTER1 -n foo serviceentry httpbin-bar
    $ kubectl delete --context=$CTX_CLUSTER1 ns foo
    {{< /text >}}

* Cleanup `cluster2`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 -n bar -f @samples/httpbin/httpbin.yaml@
    $ kubectl delete --context=$CTX_CLUSTER1 ns bar
    {{< /text >}}
