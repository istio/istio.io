---
title: Using Istio Gateway
description: Connect multiple clusters using Istio Gateway to reach remote pods.
weight: 2
keywords: [kubernetes,multicluster,gateway]
---

Instructions for spanning an Istio mesh across multiple clusters when pods
in each cluster can only talk to remote gateway IPs.

## Prerequisites

* Two or more Kubernetes clusters with **1.9 or newer**.

* The ability to deploy the [Istio control plane](/docs/setup/kubernetes/quick-start/)
on **each** Kubernetes cluster.

* The gateway IP (load balancer IP) in each cluster must be accessible
from every other cluster.

* **Root CA**: To enable mTLS communication across clusters, each cluster's
  Citadel must be configured with an intermediate CA credentials generated
  by a shared root CA.

## Overview

In this mode, each cluster has an **identical** Istio control plane
installation. Cross-cluster communication occurs over Istio Gateways
of the respective clusters. 

{{< image width="80%" ratio="36.01%"
    link="./multicluster-zvpn.svg"
    caption="Spanning a single mesh across multiple clusters using Istio Gateways"
    >}}

This guide describes steps to install a multicluster Istio topology using
the manifests and Helm charts provided as part of Istio install.

## Deploy Istio control plane in each cluster

Install the Istio control plane using the Helm command below:
{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --set multiCluster.connectUsingGateway=true \
    --set security.selfSigned=false > $HOME/istio.yaml
$ kubectl create namespace istio-system
$ kubectl create secret generic cacerts -n istio-system --from-file=path/to/intermediate/ca-cert.pem \
    --from-file=path/to/intermediate/ca-key.pem --from-file=path/to/intermediate/root-cert.pem \
    --from-file=path/to/intermediate/cert-chain.pem
$ kubectl apply -f $HOME/istio.yaml
{{< /text >}}

For further details and customization options, refer to the [Installation
with Helm](/docs/setup/kubernetes/helm-install/) page.

Note that the installation steps above assume that you have generated an
intermediate CA for each cluster that will be part of the mesh.

## Accessing services in other clusters

In order for pods in a cluster to be able to resolve DNS names of services
in remote clusters, we need to replicate the namespace and service
declaration from one cluster to other clusters. In addition, to route
traffic to a remote service via the Istio Gateway, an Istio Service Entry
configuration should be added for each replicated service. For example, the
diagram above depicts two services `foo.ns1 (cluster1)` and `bar.ns2
(cluster2)`. Create namespace `ns2` and add a kubernetes service
declaration for the `bar` service in cluster1 (which is essentially a copy
of the declaration from cluster2).

## Enabling mTLS

Cross cluster communication via the Istio gateway requires mTLS to be
enabled for all services in each cluster. The global authentication policy
must be set to permissive or stricter. For example, apply the following
global configuration in each cluster:

{{< text yaml >}}
apiVersion: authentication.istio.io/v1alpha1
kind: MeshPolicy
metadata:
  name: default
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
{{< /text >}}

## Routing traffic to remote cluster gateway

Creating a service object for a remote service enables DNS resolution for
remote services. The DNS is solely for the application convenience. Istio
still needs to know the set of remote endpoints for the service to which
traffic must be routed to.  Using the example depicted in the diagram, we
created a service declaration for `bar.ns2` in cluster1. Now, add an
endpoint to this service in cluster1 using the Istio service entry as follows:

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
      http: 15443 #Map everything to 15443 of ingress gateway
      tcp: 15443
{{< /text >}}

The configuration above will result in all traffic for
`bar.ns2.svc.cluster.local` for any port to be routed to the endpoint
`<IPofCluster2IngressGateway>:15443` over a mTLS connection.

The gateway for port 15443 has been pre-programmed and installed using the
Istio installation step you saw earlier. Traffic entering port 15443 will
ne load balanced among pods of the appropriate internal service (in this
case, `bar.ns2`).

**Note:** Do not add any Gateway configuration for port 15443.


## Distributing pods of a service across multiple clusters

If you can add pods to the `bar.ns2` service in cluster1, traffic will be
load balanced across local pods and remote pods in cluster2, albeit the
load will be skewed as Istio in cluster1 is unaware of the number of pods
for `bar.ns2` in cluster2. Zone-aware routing is currently
unavailable. Future versions of Istio will support automatic zone aware
routing.

## Automation

The entire setup above can be automated by replicating Istio configuration,
service objects, namespaces across all clusters in the mesh. In addition,
the automation system should generate service entries for each replicated
service, with endpoints containing the IP address of the gateway in every
cluster that has pods of the service in question.

## Uninstalling

Use `kubectl` to uninstall Istio from each cluster as follows:

{{< text bash >}}
$ kubectl delete -f $HOME/istio.yaml
{{< /text >}}
