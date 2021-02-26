---
title: Multicluster Istio configuration and service discovery using Admiral
subtitle: Configuration automation for Istio multicluster deployments
description: Automating Istio configuration for Istio deployments (clusters) that work as a single mesh.
publishdate: 2020-01-05
attribution: Anil Attuluri (Intuit), Jason Webb (Intuit)
keywords: [traffic-management,automation,configuration,multicluster,multi-mesh,gateway,federated,globalidentifer]
target_release: 1.5
---

At Intuit, we read the blog post [Multi-Mesh Deployments for Isolation and Boundary Protection](/blog/2019/isolated-clusters/) and immediately related to some of the problems mentioned.
We realized that even though we wanted to configure a single multi-cluster mesh, instead of a federation of multiple meshes
as described in the blog post, the same non-uniform naming issues also applied in our environment.
This blog post explains how we solved these problems using [Admiral](https://github.com/istio-ecosystem/admiral), an open source project under `istio-ecosystem` in GitHub.

## Background

Using Istio, we realized the configuration for multi-cluster was complex and challenging to maintain over time. As a result, we chose the model described in [Multi-Cluster Istio Service Mesh with replicated control planes](/docs/setup/install/multicluster/gateways/#deploy-the-istio-control-plane-in-each-cluster) for scalability and other operational reasons. Following this model, we had to solve these key requirements before widely adopting an Istio service mesh:

- Creation of service DNS entries decoupled from the namespace, as described in [Features of multi-mesh deployments](/blog/2019/isolated-clusters/#features-of-multi-mesh-deployments).
- Service discovery across many clusters.
- Supporting active-active & HA/DR deployments. We also had to support these crucial resiliency patterns with services being deployed in globally unique namespaces across discrete clusters.

We have over 160 Kubernetes clusters with a globally unique namespace name across all clusters. In this configuration, we can have the same service workload deployed in different regions running in namespaces with different names. As a result, following the routing strategy mentioned in [Multicluster version routing](/blog/2019/multicluster-version-routing), the example name `foo.namespace.global` wouldn't work across clusters. We needed a globally unique and discoverable service DNS that resolves service instances in multiple clusters, each instance running/addressable with its own unique Kubernetes FQDN. For example, `foo.global` should resolve to both `foo.uswest2.svc.cluster.local` & `foo.useast2.svc.cluster.local` if `foo` is running in two Kubernetes clusters with different names.
Also, our services need additional DNS names with different resolution and global routing properties. For example, `foo.global` should resolve locally first, then route to a remote instance using topology routing, while `foo-west.global` and `foo-east.global` (names used for testing) should always resolve to the respective regions.

## Contextual Configuration

After further investigation, it was apparent that configuration needed to be contextual: each cluster needs a configuration specifically tailored for its view of the world.

For example, we have a payments service consumed by orders and reports. The payments service has a HA/DR deployment across `us-east` (cluster 3) and `us-west` (cluster 2). The payments service is deployed in namespaces with different names in each region. The orders service is deployed in a different cluster as payments in `us-west` (cluster 1). The reports service is deployed in the same cluster as payments in `us-west` (cluster 2).

{{< image width="75%"
    link="./Istio_mesh_example.svg"
    alt="Example of calling a workload in Istio multicluster"
    caption="Cross cluster workload communication with Istio"
    >}}

Istio `ServiceEntry` yaml for payments service in Cluster 1 and Cluster 2 below illustrates the contextual configuration that other services need to use the payments service:

Cluster 1 Service Entry

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: payments.global-se
spec:
  addresses:
  - 240.0.0.10
  endpoints:
  - address: ef394f...us-east-2.elb.amazonaws.com
    locality: us-east-2
    ports:
      http: 15443
  - address: ad38bc...us-west-2.elb.amazonaws.com
    locality: us-west-2
    ports:
      http: 15443
  hosts:
  - payments.global
  location: MESH_INTERNAL
  ports:
  - name: http
    number: 80
    protocol: http
  resolution: DNS
{{< /text >}}

Cluster 2 Service Entry

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: payments.global-se
spec:
  addresses:
  - 240.0.0.10
  endpoints:
  - address: ef39xf...us-east-2.elb.amazonaws.com
    locality: us-east-2
    ports:
      http: 15443
  - address: payments.default.svc.cluster.local
    locality: us-west-2
    ports:
      http: 80
  hosts:
  - payments.global
  location: MESH_INTERNAL
  ports:
  - name: http
    number: 80
    protocol: http
  resolution: DNS
{{< /text >}}

The payments `ServiceEntry` (Istio CRD) from the point of view of the reports service in Cluster 2, would set the locality `us-west` pointing to the local Kubernetes FQDN and locality `us-east` pointing to the `istio-ingressgateway` (load balancer) for Cluster 3.
The payments `ServiceEntry` from the point of view of the orders service in Cluster 1, will set the locality `us-west` pointing to Cluster 2 `istio-ingressgateway` and locality `us-east` pointing to the `istio-ingressgateway` for Cluster 3.

But wait, there's even more complexity: What if the payment services want to move traffic to the `us-east` region for a planned maintenance in `us-west`? This would require the payments service to change the Istio configuration in all of their clients' clusters. This would be nearly impossible to do without automation.

## Admiral to the Rescue: Admiral is that Automation

_Admiral is a controller of Istio control planes._

{{< image width="75%"
    link="./Istio_mesh_example_with_admiral.svg"
    alt="Example of calling a workload in Istio multicluster with Admiral"
    caption="Cross cluster workload communication with Istio and Admiral"
    >}}

Admiral provides automatic configuration for an Istio mesh spanning multiple clusters to work as a single mesh based on a unique service identifier that associates workloads running on multiple clusters to a service. It also provides automatic provisioning and syncing of Istio configuration across clusters. This removes the burden on developers and mesh operators, which helps scale beyond a few clusters.

## Admiral CRDs

### Global Traffic Routing

With Admiral’s global traffic policy CRD, the payments service can update regional traffic weights and Admiral updates the Istio configuration in all clusters that consume the payments service.

{{< text yaml >}}
apiVersion: admiral.io/v1alpha1
kind: GlobalTrafficPolicy
metadata:
  name: payments-gtp
spec:
  selector:
    identity: payments
  policy:
  - dns: default.payments.global
    lbType: 1
    target:
    - region: us-west-2/*
      weight: 10
    - region: us-east-2/*
      weight: 90
{{< /text >}}

In the example above, 90% of the payments service traffic is routed to the `us-east` region. This Global Traffic Configuration is automatically converted into Istio configuration and contextually mapped into Kubernetes clusters to enable multi-cluster global routing for the payments service for its clients within the Mesh.

This Global Traffic Routing feature relies on Istio's locality load-balancing per service available in Istio 1.5 or later.

### Dependency

The Admiral `Dependency` CRD allows us to specify a service's dependencies based on a service identifier. This optimizes the delivery of Admiral generated configuration only to the required clusters where the dependent clients of a service are running (instead of writing it to all clusters). Admiral also configures and/or updates the Sidecar Istio CRD in the client's workload namespace to limit the Istio configuration to only its dependencies. We use service-to-service authorization information recorded elsewhere to generate this `dependency` records for Admiral to use.

An example `dependency` for the `orders` service:

{{< text yaml >}}
apiVersion: admiral.io/v1alpha1
kind: Dependency
metadata:
  name: dependency
  namespace: admiral
spec:
  source: orders
  identityLabel: identity
  destinations:
  - payments
{{< /text >}}

`Dependency` is optional and a missing dependency for a service will result in an Istio configuration for that service pushed to all clusters.

## Summary

Admiral provides a new Global Traffic Routing and unique service naming functionality to address some challenges posed by the Istio model described in [multi-cluster deployment with replicated control planes](/docs/setup/install/multicluster/gateways/#deploy-the-istio-control-plane-in-each-cluster). It removes the need for manual configuration synchronization between clusters and generates contextual configuration for each cluster. This makes it possible to operate a Service Mesh composed of many Kubernetes clusters.

We think Istio/Service Mesh community would benefit from this approach, so we [open sourced Admiral](https://github.com/istio-ecosystem/admiral) and would love your feedback and support!
