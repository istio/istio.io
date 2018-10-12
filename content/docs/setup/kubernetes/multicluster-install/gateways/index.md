---
title: Gateway connectivity
description: Install an Istio mesh across multiple Kubernetes clusters using Istio Gateway to reach remote pods.
weight: 2
keywords: [kubernetes,multicluster,federation,gateway]
---

Instructions for installing an Istio mesh across multiple clusters when pods
in each cluster can only connect to remote gateway IPs.

Instead of using a central Istio control plane to manage the mesh,
in this configuration each cluster has an **identical** Istio control plane
installation, each managing its own endpoints.
All of the clusters are under a shared administrative control for the purposes of
policy enforcement and security.

A single Istio service mesh across the clusters is achieved by replicating
shared services and namespaces and using a common root CA in all of the clusters.
Cross-cluster communication occurs over Istio Gateways of the respective clusters.

{{< image width="80%" ratio="36.01%"
    link="./multicluster-with-gateways.svg"
    caption="Istio mesh spanning multiple Kubernetes clusters using Istio Gateway to reach remote pods"
    >}}

## Prerequisites

* Two or more Kubernetes clusters with **1.9 or newer**.

* Authority to deploy the [Istio control plane using Helm](/docs/setup/kubernetes/helm-install/)
on **each** Kubernetes cluster.

* The IP address of the Istio gateway in each cluster must be accessible
  from every other cluster.

* A **Root CA**. To enable mTLS communication across clusters, each cluster's
  Citadel will be configured with intermediate CA credentials generated
  by a shared root CA.

## Deploy Istio control plane in each cluster

1. Generate intermediate CA certs for each cluster's Citadel from your
organization's root CA. The shared root CA enables mTLS communication
across different clusters.

1. Create a Kubernetes secret for your generated CA certs using a command similar
   to the following:

    {{< text bash >}}
    $ kubectl create secret generic cacerts -n istio-system \
        --from-file=path/to/intermediate/ca-cert.pem \
        --from-file=path/to/intermediate/ca-key.pem \
        --from-file=path/to/intermediate/root-cert.pem \
        --from-file=path/to/intermediate/cert-chain.pem
    {{< /text >}}

1. Install the Istio control plane using Helm:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
        --set multiCluster.connectUsingGateway=true \
        --set global.controlPlaneSecurityEnabled=true \
        --set security.selfSigned=false > $HOME/istio.yaml
    $ kubectl create namespace istio-system
    $ kubectl apply -f $HOME/istio.yaml
    {{< /text >}}

For further details and customization options, refer to the [Installation
with Helm](/docs/setup/kubernetes/helm-install/) instructions.

## Enable mTLS globally

Cross-cluster communication via the Istio gateway requires mTLS.
Therefore you must enable mTLS for all services in each cluster by
setting the global authentication policy to permissive or stricter
and setting a default destination rule to originate an mTLS connection
from every pod.

For example, apply the following global configuration in each cluster:

{{< text yaml >}}
apiVersion: authentication.istio.io/v1alpha1
kind: MeshPolicy
metadata:
  name: default
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: default
spec:
  host: "*.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
{{< /text >}}

## Replicate services and namespaces across clusters

In order for pods in a cluster to be able to resolve DNS names of services
in remote clusters, you need to replicate every namespace and service
declaration from one cluster to every other cluster in the mesh.

For example, the diagram above depicts two services `foo.ns1` in
`cluster1` and `bar.ns2` in `cluster2`. Lets say their respective
declarations are as follows:

In `cluster1` (file: `cluster1-svc.yaml`)

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: ns1
  labels:
    istio-injection: enabled
---
apiVersion: v1
kind: Service
metadata:
  name: foo
  labels:
    app: foo
  namespace: ns1
spec:
  ports:
  - port: 80
    targetPort: 80
    name: http
  selector:
    app: foo
{{< /text >}}

In `cluster2` (file: `cluster2-svc.yaml`)

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: ns2
  labels:
    istio-injection: enabled
---
apiVersion: v1
kind: Service
metadata:
  name: bar
  labels:
    app: bar
  namespace: ns2
spec:
  ports:
  - port: 80
    targetPort: 80
    name: http
  - port: 9090
    targetPort: 9090
    name: tcp
  selector:
    app: bar
{{< /text >}}

The namespaces and services need to be replicated in each cluster
to enable DNS resolution and connectivity. This can be done by simply applying
the configuration in `cluster1-svc.yaml` to `cluster2` and the configuration in
`cluster2-svc.yaml` to `cluster1`.

In `cluster1`:

{{< text bash >}}
$ kubectl apply -f cluster2-svc.yaml
{{< /text >}}

In `cluster2`:

{{< text bash >}}
$ kubectl apply -f cluster1-svc.yaml
{{< /text >}}

## Route traffic for remote services to remote cluster gateway

By replicating the remote services, you enabled DNS resolution for
them inside the application code running on a local cluster. However, network traffic
from the application will be sent to the cluster IP associated with the
Kubernetes service, instead of to the remote pods.

To allow Envoy to route traffic to the remote services, you need to provide endpoints
for the remote service where traffic should be routed. In this case, that's
the remote cluster gateway.

Continuing with the example from the previous section,
apply the following service entry in `cluster1`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: remote-endpoint-for-bar-in-cluster1
spec:
  hosts:
  - bar.ns2.svc.cluster.local
  ports:
  # Add all ports from bar service
  - number: 80
    name: http
    protocol: HTTP
  - number: 9090
    name: tcp
    protocol: TCP
  resolution: STATIC
  location: MESH_INTERNAL
  endpoints:
  - address: <IPofCluster2IngressGateway>
    ports:
      http: 15443 # Map everything to 15443 of ingress gateway
      tcp: 15443
{{< /text >}}

This configuration will result in all traffic in `cluster1` for
`bar.ns2.svc.cluster.local` on any port to be routed to the endpoint
`<IPofCluster2IngressGateway>:15443` over an mTLS connection.

Apply a similar configuration for the `foo.ns1` namespace in `cluster2`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: remote-endpoint-for-foo-in-cluster2
spec:
  hosts:
  - foo.ns1.svc.cluster.local
  ports:
  # Add all ports from foo service
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  location: MESH_INTERNAL
  endpoints:
  - address: <IPofCluster1IngressGateway>
    ports:
      http: 15443 # Map everything to 15443 of ingress gateway
      tcp: 15443
{{< /text >}}

The gateway for port 15443 is a special SNI-aware Envoy that was
configured and installed as a result of the `--set multiCluster.connectUsingGateway=true`
helm option that you used when you installed Istio. Traffic entering port 15443 will
be load balanced among pods of the appropriate internal service of the target cluster (in this
case, `bar.ns2`).

> Do not create a Gateway configuration for port 15443.

## Summary

Using Istio gateways, a common root CA, and replication of services, you configured
a single Istio service mesh across multiple Kubernetes clusters.
Although the above procedure involved a significant amount of manual work,
the entire process could theoretically be automated. The automation process
must do the following:

1. Replicate Istio configuration, services, and namespaces across all clusters in the mesh.
1. Generate service entries for each replicated service, with endpoints containing the IP address
   of gateways in every cluster that has pods for the service in question.

Once configured this way, traffic can be transparently routed to remote clusters
without any application involvement. In fact, traffic for a given service can also
be routed to workloads in multiple clusters. For example, if you add pods to the
`bar.ns2` service in `cluster1`, traffic will be load
balanced across the local pods and the remote pods in `cluster2`.
The load will be skewed, however, as Istio in `cluster1` is unaware of the number
of pods for `bar.ns2` in `cluster2`. The remote Gateway looks like just another
single endpoint in the same cluster/zone. Zone-aware routing is currently unsupported.
