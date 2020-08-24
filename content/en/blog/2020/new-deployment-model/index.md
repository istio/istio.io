---
title: A New Istiod Deployment Model
subtitle: Clear Separation between Mesh Operator and Mesh Users
description: A new deployment model for Istio.
publishdate: 2020-08-19
attribution: "Lin Sun (IBM), Iris Ding (IBM)"
keywords: [istiod, deployment model, central istiod,install,deploy,'1.7']
---

## Background

From experience working with various service mesh users and vendors, we believe there are 3 key personas for a typical service mesh:
* Mesh Operator, who manages the service mesh installation and upgrade.

* Platform Owner, who owns the service mesh platform and defines the overall strategy and implementation for service owners to adopt service mesh.

* Service Owner, who owns one or more services.

It is common to have all these personas work on the same clusters without any clear separation.  For example, there are multiple ways to deploy Istio according to the docs, which all start with mesh operator, platform owner and service owner sharing the single cluster first and then gradually expanding the mesh to multiple clusters or VMs.  None of these provided a clear separation between mesh operator and platform/service owner at the boundary of a cluster.  You may be thinking you could set up [Kubernetes RBAC rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) and namespaces to control which personas can do what within the cluster, however, sometimes you need stronger separation between the Istio control plane and the rest at the cluster level.  We're introducing a new deployment model for Istiod which enables mesh operators to install and manage the mesh control plane on dedicated clusters, separated from the data plane clusters.  This new deployment model could easily enable Istio vendors to run Istio control plane for service mesh users while users can focus on their workloads and Istio resources without worrying about installing or managing the Istio control plane.


## New Deployment model

Following the [default install](/docs/setup/install/istioctl/#install-istio-using-the-default-profile), you will have Istiod installed. You can deploy your services to the mesh, like the diagram below:

{{< image
    link="./single-cluster.svg"
    caption="Single Cluster Istio Default Installation"
>}}

In Istio 1.7, it is possible to run Istiod on a separate, dedicated cluster (central control plane cluster) as shown in the diagram below. With this new deployment model, mesh operators can work purely on the central control plane cluster when there is a need to upgrade or re-configure Istio. Platform/service owners will work solely on `cluster1` to deploy their applications and apply any Istio resources or configs. They don't have direct access to the central control plane cluster to deploy anything there, neither will the central control plane cluster processes any Istio resources on that cluster.


{{< image
    link="./single-cluster-central-Istiod.svg"
    caption="Single Cluster With Istiod On A Central Control Plane Cluster"
    >}}

If you are interested in exploring this, you can follow the [central istiod single cluster step by step guide.](https://github.com/istio/istio/wiki/Central-Istiod-single-cluster-steps)

The diagram above shows a single cluster as the data plane for an Istio mesh. However, you can expand this deployment model to manage multiple Istio meshes from a central control plane cluster that runs multiple Istiods, per diagram below:

{{< image width="100%" link="./multiple-central-Istiods.svg" caption="Single Clusters with Multiple Istiods On A Central Control Plane Cluster" >}}

Central control plane cluster can be used to host multiple Istiods and each Istiod manages its own remote data plane.  In this model we can install Istio into the central control plane cluster and use Istio ingress gateway to route traffic between different Istiods.

You may further expand your data plane to multiple clusters, all managed by the same Istiod running on the central control plane cluster. All of the data plane clusters will receive their configs from the primary cluster per diagram below. 

{{< image width="100%" link="./multiple-clusters-central-Istiod.svg" caption="Multi-Cluster With Istiod On A Central Control Plane Cluster" >}}


## Conclusion

This new deployment model enables the Istio control plane to be run and managed by others who have the operational expertise in Istio.  This reduces the complexity and provides the best experience to platform/service owners by allowing them to focus on the core business logic of their applications and the configuration of their services. 
