---
title: Deploying Istio Control Planes Outside the Mesh
subtitle: Clear Separation between Mesh Operator and Mesh Admin
description: A new deployment model for Istio.
publishdate: 2020-08-27
attribution: "Lin Sun (IBM), Iris Ding (IBM)"
keywords: [istiod,deployment model,install,deploy,'1.7']
---

## Overview

From experience working with various service mesh users and vendors, we believe there are 3 key personas for a typical service mesh:

* Mesh Operator, who manages the service mesh control plane installation and upgrade.

* Mesh Admin, often referred as Platform Owner, who owns the service mesh platform and defines the overall strategy and implementation for service owners to adopt service mesh.

* Mesh User, often referred as Service Owner, who owns one or more services in the mesh.

Prior to version 1.7, Istio required the control plane to run in one of the {{< gloss "primary cluster" >}}primary clusters{{< /gloss >}} in the mesh, leading to a lack of separation between the mesh operator and the mesh admin. Istio 1.7 introduces a new {{< gloss >}}external control plane{{< /gloss >}} deployment model which enables mesh operators to install and manage mesh control planes on separate external clusters. This deployment model allows a clear separation between mesh operators and mesh admins. Istio mesh operators can now run Istio control planes for mesh admins while mesh admins can still control the configuration of the control plane without worrying about installing or managing the control plane. This model is transparent to mesh users.

## External control plane deployment model

After installing Istio using the [default installation profile](/docs/setup/install/istioctl/#install-istio-using-the-default-profile), you will have an Istiod control plane installed in a single cluster like the diagram below:

{{< image width="100%"
    link="single-cluster.svg"
    alt="Istio mesh in a single cluster"
    title="Single cluster Istio mesh"
    caption="Istio mesh in a single cluster"
    >}}

With the new deployment model in Istio 1.7, it's possible to run Istiod on an external cluster, separate from the mesh services as shown in the diagram below. The external control plane cluster is owned by the mesh operator while the mesh admin owns the cluster running services deployed in the mesh. The mesh admin has no access to the external control plane cluster. Mesh operators can follow the [external istiod single cluster step by step guide](https://github.com/istio/istio/wiki/External-Istiod-single-cluster-steps) to explore more on this. (Note: In some internal discussions among Istio maintainers, this model was previously referred to as "central istiod".)

{{< image width="100%"
    link="single-cluster-external-Istiod.svg"
    alt="Istio mesh in a single cluster with Istiod outside"
    title="Single cluster Istio mesh with Istiod outside"
    caption="Single cluster Istio mesh with Istiod in an external control plane cluster"
    >}}

Mesh admins can expand the service mesh to multiple clusters, which are managed by the same Istiod running in the external cluster. None of the mesh clusters are {{< gloss "primary cluster" >}}primary clusters{{< /gloss >}}, in this case. They are all {{< gloss "remote cluster" >}}remote clusters{{< /gloss >}}. However, one of them also serves as the Istio configuration cluster, in addition to running services. The external control plane reads Istio configurations from the `config cluster` and Istiod pushes configuration to the data plane running in both the config cluster and other remote clusters as shown in the diagram below.

{{< image width="100%"
    link="multiple-clusters-external-Istiod.svg"
    title="Multicluster Istio mesh with Istiod outside"
    caption="Multicluster Istio mesh with Istiod in an external control plane cluster"
    >}}

Mesh operators can further expand this deployment model to manage multiple Istio control planes from an external cluster running multiple Istiod control planes:

{{< image width="100%"
    link="multiple-external-Istiods.svg"
    alt="Istio meshes in single clusters with Istiod outside"
    title="Multiple single clusters Istio meshes with Istiod outside"
    caption="Multiple single clusters with multiple Istiod control planes in an external control plane cluster"
    >}}

In this case, each Istiod manages its own remote cluster(s). Mesh operators can even install their own Istio mesh in the external control plane cluster and configure its `istio-ingress` gateway to route traffic from remote clusters to their corresponding Istiod control planes. To learn more about this, check out [these steps](https://github.com/istio/istio/wiki/External-Istiod-single-cluster-steps#deploy-istio-mesh-on-external-control-plane-cluster-to-manage-traffic-to-istiod-deployments).

## Conclusion

The external control plane deployment model enables the Istio control plane to be run and managed by mesh operators who have operational expertise in Istio, and provides a clean separation between service mesh control and data planes. Mesh operators can run the control plane in their own clusters or other environments, providing the control plane as a service to mesh admins. Mesh operators can run multiple Istiod control planes in a single cluster, deploying their own Istio mesh and using `istio-ingress` gateways to control access to these Istiod control planes. Through the examples provided here, mesh operators can explore different implementation choices and choose what works best for them.

This new model reduces complexity for mesh admins by allowing them to focus on mesh configurations without operating the control plane themselves. Mesh admins can continue to configure mesh-wide settings and Istio resources without any access to external control plane clusters. Mesh users can continue to interact with the service mesh without any changes.
