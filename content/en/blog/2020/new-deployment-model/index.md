---
title: A New Istiod Deployment Model
subtitle: Clear Separation between Mesh Operator and Mesh Users
description: A new deployment model for Istio.
publishdate: 2020-08-24
attribution: "Lin Sun (IBM), Iris Ding (IBM)"
keywords: [istiod,deployment model,central istiod,install,deploy,'1.7']
---

## Background

From experience working with various service mesh users and vendors, we believe there are 3 key personas for a typical service mesh:

* Mesh Operator, who manages the service mesh installation and upgrade.

* Mesh Admin, often referred as Platform Owner, who owns the service mesh platform and defines the overall strategy and implementation for service owners to adopt service mesh.
* Mesh User, often referred as Service Owner, who owns one or more services.

It is common to have all these personas work on the same clusters without any clear separation.  For example, there are multiple ways to deploy Istio according to the [docs](/docs/setup/install/), which all start with mesh operator, platform owner and service owner sharing the single cluster first and then gradually expanding the mesh to multiple clusters or VMs.  None of these provided a clear separation between mesh operator and platform/service owner at the boundary of a cluster.  You may be thinking you could set up [Kubernetes RBAC rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) and namespaces to control which personas can do what within the cluster, however, sometimes you need stronger separation between the Istio control plane and the rest at the cluster level.

We're introducing a new deployment model for Istiod which enables mesh operators to install and manage the mesh control plane on separate clusters. This new deployment model allows a clear separation between mesh operators and mesh admins. With this new model, Istio vendors can run Istio control plane for mesh admins while mesh admins can still control the configuration of the control plane without worrying about installing or managing the Istio control plane. This model is transparent to service owners.

## Control Plane Cluster Deployment model

After installing Istio using the [default installation profile](/docs/setup/install/istioctl/#install-istio-using-the-default-profile), you have Istiod control plane installed in a single cluster like the diagram below:

{{< image width="100%"
    link="single-cluster.svg"
    alt="Istio mesh in a single cluster"
    title="Single cluster Istio mesh"
    caption="Istio mesh in a single cluster"
    >}}

With this new deployment model in Istio 1.7, it is possible to run Istiod on a separate cluster (the "control plane cluster") from the services as shown in the diagram below. The `control plane cluster` is owned by mesh operator while the mesh admin owns the cluster that has services deployed in the mesh. Mesh admin has no access to the `control plane cluster`. If you are interested in exploring this, you can follow the [central istiod single cluster step by step guide](https://github.com/istio/istio/wiki/Central-Istiod-single-cluster-steps).

{{< image width="100%"
    link="single-cluster-central-Istiod.svg"
    alt="Istio mesh in a single cluster with Istiod outside"
    title="Single cluster Istio mesh with Istiod outside"
    caption="Single cluster Istio mesh with Istiod in a control plane cluster"
    >}}

The diagram above shows a single cluster as the data plane for an Istio mesh. However, mesh operators can expand this deployment model to manage multiple Istio meshes from a central control plane cluster that runs multiple Istiod control planes:

{{< image width="100%"
    link="multiple-central-Istiods.svg"
    alt="Istio meshes in single clusters with Istiod outside"
    title="Multiple single clusters Istio meshes with Istiod outside"
    caption="Multiple single clusters with multiple Istiod control planes in a control plane cluster"
    >}}

The `control plane cluster` can be used to host multiple Istiod control planes and each Istiod manages its own data plane clusters. Mesh operators could install another Istio mesh in the `control plane cluster` and configure its `istio-ingress` gateway to route traffic from a data plane cluster to its corresponding Istiod control plane.

Mesh admin may further expand your data plane to multiple clusters, which are managed by the same Istiod running on the `control plane cluster`. The first cluster usually serves as the Istio configuration cluster, which is often referred as primary data plane cluster. The `control plane cluster` reads the Istio configuration from that cluster and pushes them to all of the data plane clusters per the diagram below.

{{< image width="100%"
    link="multiple-clusters-central-Istiod.svg"
    title="Multicluster Istio mesh with Istiod outside"
    caption="Multicluster Istio mesh with Istiod in a control plane cluster"
    >}}

## Conclusion

This new deployment model enables the Istio control plane to be run and managed by mesh operators who have operational expertise in Istio. Mesh operators can run the control plane in their own control plane clusters, provide it as a service to mesh admins. Mesh operators can optionally run multiple Istiod control planes in the control plane cluster, deploy their own Istio mesh and use istio-ingress gateway to control access to these multiple Istiod control planes.

This model reduces complexity for mesh admins by allowing them to focus on mesh configurations without operating the control plane themselves. Mesh admin could continue to configure mesh-wide settings and Istio resources without any access to control plane clusters. Mesh users can continue to interact with the service mesh without any change.
