---
title: Gateway-Connected Clusters
description: Configuring remote services in a gateway-connected multicluster mesh.
weight: 20
keywords: [kubernetes,multicluster]
aliases:
  - /docs/examples/multicluster/gateways/
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
    [multiple control planes with gateways](/docs/setup/kubernetes/install/multicluster/gateways/) instructions.

{{< boilerplate kubectl-multicluster-contexts >}}

## Configure the example services

1. Deploy the `sleep` service in `cluster1`.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 namespace foo
    $ kubectl label --context=$CTX_CLUSTER1 namespace foo istio-injection=enabled
    $ kubectl apply --context=$CTX_CLUSTER1 -n foo -f @samples/sleep/sleep.yaml@
    $ export SLEEP_POD=$(kubectl get --context=$CTX_CLUSTER1 -n foo pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

1. Deploy the `httpbin` service in `cluster2`.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 namespace bar
    $ kubectl label --context=$CTX_CLUSTER2 namespace bar istio-injection=enabled
    $ kubectl apply --context=$CTX_CLUSTER2 -n bar -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. Export the `cluster2` gateway address:

    {{< text bash >}}
    $ export CLUSTER2_GW_ADDR=$(kubectl get --context=$CTX_CLUSTER2 svc --selector=app=istio-ingressgateway \
        -n istio-system -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
    {{< /text >}}

    This command sets the value to the gateway's public IP, but note that you can set it to
    a DNS name instead, if you have one.

    {{< tip >}}
    If `cluster2` is running in an environment that does not
    support external load balancers, you will need to use a nodePort to access the gateway.
    Instructions for obtaining the IP to use can be found in the
    [Control Ingress Traffic](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
    guide. You will also need to change the service entry endpoint port in the following step from 15443
    to its corresponding nodePort
    (i.e., `kubectl --context=$CTX_CLUSTER2 get svc -n istio-system istio-ingressgateway -o=jsonpath='{.spec.ports[?(@.port==15443)].nodePort}'`).
    {{< /tip >}}

1. Create a service entry for the `httpbin` service in `cluster2`.

    To allow `sleep` in `cluster1` to access `httpbin` in `cluster2`, we need to create
    a service entry for it. The host name of the service entry should be of the form
    `<name>.<namespace>.global` where name and namespace correspond to the
    remote service's name and namespace respectively.

    For DNS resolution for services under the `*.global` domain, you need to assign these
    services an IP address.

    {{< tip >}}
    Each service (in the `.global` DNS domain) must have a unique IP within the cluster.
    {{< /tip >}}

    If the global services have actual VIPs, you can use those, but otherwise we suggest
    using IPs from the loopback range `127.0.0.0/8` that are not already allocated.
    These IPs are non-routable outside of a pod.
    In this example we'll use IPs in `127.255.0.0/16` which avoids conflicting with
    well known IPs such as `127.0.0.1` (`localhost`).
    Application traffic for these IPs will be captured by the sidecar and routed to the
    appropriate remote service.

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
      # sits in front of sleep.foo service. Traffic from the sidecar will be
      # routed to this address.
      - address: ${CLUSTER2_GW_ADDR}
        ports:
          http1: 15443 # Do not change this port value
    EOF
    {{< /text >}}

    The configurations above will result in all traffic in `cluster1` for
    `httpbin.bar.global` on *any port* to be routed to the endpoint
    `<IPofCluster2IngressGateway>:15443` over a mutual TLS connection.

    The gateway for port 15443 is a special SNI-aware Envoy
    preconfigured and installed as part of the multicluster Istio installation step
    in the [before you begin](#before-you-begin) section. Traffic entering port 15443 will be
    load balanced among pods of the appropriate internal service of the target
    cluster (in this case, `httpbin.bar` in `cluster2`).

    {{< warning >}}
    Do not create a `Gateway` configuration for port 15443.
    {{< /warning >}}

1. Verify that `httpbin` is accessible from the `sleep` service.

    {{< text bash >}}
    $ kubectl exec --context=$CTX_CLUSTER1 $SLEEP_POD -n foo -c sleep -- curl -I httpbin.bar.global:8000/headers
    {{< /text >}}

## Send remote cluster traffic using egress gateway

If you want to route traffic from `cluster1` via a dedicated egress gateway, instead of directly from the sidecars,
use the following service entry for `httpbin.bar` instead of the one in the previous section.

{{< tip >}}
The egress gateway used in this configuration cannot also be used for other, non inter-cluster, egress traffic.
If $CLUSTER2_GW_ADDR is an IP address, use option 1.  If $CLUSTER2_GW_ADDR is a host name, use option 2.
{{< /tip >}}

{{< tabset cookie-name="profile" >}}

{{< tab name="Option 1" cookie-value="option1" >}}
1. Export the `cluster1` egress gateway address:
{{< text bash >}}
export CLUSTER1_EGW_ADDR=$(kubectl get --context=$CTX_CLUSTER1 svc --selector=app=istio-egressgateway \
    -n istio-system -o yaml -o jsonpath='{.items[0].spec.clusterIP}')
{{< /text >}}

1. Apply the httpbin-bar service entry:
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
  resolution: STATIC
  addresses:
  - 127.255.0.2
  endpoints:
  - address: ${CLUSTER2_GW_ADDR}
    network: external
    ports:
      http1: 15443 # Do not change this port value
  - address: ${CLUSTER1_EGW_ADDR}
    ports:
      http1: 15443
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Option 2" cookie-value="option2" >}}

If the `${CLUSTER2_GW_ADDR}` is a hostname, you can use `resolution: DNS` for the endpoint resolution: 
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
  - address: ${CLUSTER2_GW_ADDR}
    network: external
    ports:
      http1: 15443 # Do not change this port value
  - address: istio-egressgateway.istio-system.svc.cluster.local
    ports:
      http1: 15443
EOF
{{< /text >}}    
    
{{< /tab >}}

{{< /tabset >}}

## Version-aware routing to remote services

If the remote service has multiple versions, you can add
labels to the service entry endpoints.
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
  - address: ${CLUSTER2_GW_ADDR}
    labels:
      cluster: cluster2
    ports:
      http1: 15443 # Do not change this port value
EOF
{{< /text >}}

You can then create virtual services and destination rules
to define subsets of the `httpbin.bar.global` service using the appropriate gateway label selectors.
The instructions are the same as those used for routing to a local service.
See [multicluster version routing](/blog/2019/multicluster-version-routing/)
for a complete example.

## Cleanup

Execute the following commands to clean up the example services.

* Cleanup `cluster1`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER1 -n foo -f @samples/sleep/sleep.yaml@
    $ kubectl delete --context=$CTX_CLUSTER1 -n foo serviceentry httpbin-bar
    $ kubectl delete --context=$CTX_CLUSTER1 ns foo
    {{< /text >}}

* Cleanup `cluster2`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 -n bar -f @samples/httpbin/httpbin.yaml@
    $ kubectl delete --context=$CTX_CLUSTER2 ns bar
    {{< /text >}}
