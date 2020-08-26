---
title: A Alternative Istiod Deployment Model
subtitle: Clear Separation between Mesh Operator and Mesh Admin
description: A new deployment model for Istio.
publishdate: 2020-08-26
attribution: "Lin Sun (IBM), Iris Ding (IBM)"
keywords: [istiod,deployment model,install,deploy,'1.7']
---

## Overview

From experience working with various service mesh users and vendors, we believe there are 3 key personas for a typical service mesh:

* Mesh Operator, who manages the service mesh control plane installation and upgrade.

* Mesh Admin, often referred as Platform Owner, who owns the service mesh platform and defines the overall strategy and implementation for service owners to adopt service mesh.

* Mesh User, often referred as Service Owner, who owns one or more services in the mesh.

Istio currently requires the control plane to run in one of the clusters in the mesh, leading to a lack of separation between the mesh operator and the mesh admin. We're introducing an alternative deployment model for Istiod which enables mesh operators to install and manage the mesh control plane on separate clusters. This new deployment model allows a clear separation between mesh operators and mesh admins. With this new model, Istio mesh operators can run Istio control plane for mesh admins while mesh admins can still control the configuration of the control plane without worrying about installing or managing the Istio control plane. This model is transparent to mesh users.

## External Control Plane Deployment model

After installing Istio using the [default installation profile](/docs/setup/install/istioctl/#install-istio-using-the-default-profile), you will have an Istiod control plane installed in a single cluster like the diagram below:

{{< image width="100%"
    link="single-cluster.svg"
    alt="Istio mesh in a single cluster"
    title="Single cluster Istio mesh"
    caption="Istio mesh in a single cluster"
    >}}

With this new deployment model in Istio 1.7, it is possible to run Istiod on a separate cluster (the `external control plane cluster`) from services, as shown in the diagram below. The `external control plane cluster` is owned by mesh operator while the mesh admin owns the cluster that has services deployed in the mesh. Mesh admin has no access to the `external control plane cluster`. For mesh operators, you can follow the [external istiod single cluster step by step guide](https://github.com/istio/istio/wiki/External-Istiod-single-cluster-steps) to explore more on this.

{{< image width="100%"
    link="single-cluster-external-Istiod.svg"
    alt="Istio mesh in a single cluster with Istiod outside"
    title="Single cluster Istio mesh with Istiod outside"
    caption="Single cluster Istio mesh with Istiod in an external control plane cluster"
    >}}

Mesh admins can expand the service mesh to multiple clusters, which are managed by the same Istiod running in the `external control plane cluster`. The `config cluster` also serves as the Istio configuration cluster, in addition to run services. The `external control plane cluster` reads Istio configurations from the `primary data plane cluster` and pushes them to both the `config cluster` and `remote cluster` per the diagram below.

{{< image width="100%"
    link="multiple-clusters-external-Istiod.svg"
    title="Multicluster Istio mesh with Istiod outside"
    caption="Multicluster Istio mesh with Istiod in an external control plane cluster"
    >}}

Mesh operators may further expand this deployment model to manage multiple Istio control planes from an external control plane cluster that runs multiple Istiod control planes:

{{< image width="100%"
    link="multiple-external-Istiods.svg"
    alt="Istio meshes in single clusters with Istiod outside"
    title="Multiple single clusters Istio meshes with Istiod outside"
    caption="Multiple single clusters with multiple Istiod control planes in an external control plane cluster"
    >}}

The `external control plane cluster` can be used to host multiple Istiod control planes and each Istiod manages its own `config cluster`. Mesh operators could install another Istio mesh in the `external control plane cluster` and configure its `istio-ingress` gateway to route traffic from a config cluster to its corresponding Istiod control plane.

## Conclusion

This new deployment model enables the Istio control plane to be run and managed by mesh operators who have operational expertise in Istio, and provides a clean separation between service mesh control and data planes. Mesh operators can run the control plane in their own control plane clusters or other environments, provide it as a service to mesh admins. Mesh operators can optionally run multiple Istiod control planes in the control plane cluster, deploy their own Istio mesh and use their `istio-ingress` gateway to control access to these Istiod control planes. Through these examples provided here, mesh operators can explore different implementation choices and choose what works best for them.

This model reduces complexity for mesh admins by allowing them to focus on mesh configurations without operating the control plane themselves. Mesh admin could continue to configure mesh-wide settings and Istio resources without any access to external control plane clusters. Mesh users can continue to interact with the service mesh without any change.
