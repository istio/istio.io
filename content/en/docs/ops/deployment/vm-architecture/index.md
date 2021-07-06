---
title: Virtual Machine Architecture
description: Describes Istio's high-level architecture for virtual machines.
weight: 25
keywords:
- virtual-machine
test: n/a
owner: istio/wg-environments-maintainers
---

Before reading this document, be sure to review [Istio's architecture](/docs/ops/deployment/architecture/) and [deployment models](/docs/ops/deployment/deployment-models/).
This page builds on those documents to explain how Istio can be extended to support joining virtual machines into the mesh.

Istio's virtual machine support allows connecting workloads outside of a Kubernetes cluster to the mesh.
This enables legacy applications, or applications not suitable to run in a containerized environment, to get all the benefits that Istio provides to applications running inside Kubernetes.

For workloads running on Kubernetes, the Kubernetes platform itself provides various features like service discovery, DNS resolution, and health checks which are often missing in virtual machine environments.
Istio enables these features for workloads running on virtual machines, and in addition allows these workloads to utilize Istio functionality such as mutual TLS (mTLS), rich telemetry, and advanced traffic management capabilities.

The following diagram shows the architecture of a mesh with virtual machines:

{{< tabset category-name="network-mode" >}}

{{< tab name="Single-Network" category-value="single" >}}

In this mesh, there is a single [network](/docs/ops/deployment/deployment-models/#network-models), where pods and virtual machines can communicate directly with each other.

Control plane traffic, including XDS configuration and certificate signing, are sent through a Gateway in the cluster.
This ensures that the virtual machines have a stable address to connect to when they are bootstrapping. Pods and virtual machines can communicate directly with each other without requiring any intermediate Gateway.

{{< image width="75%"
    link="single-network.svg"
    alt="A service mesh with a single network and virtual machines"
    title="Single network"
    caption="A service mesh with a single network and virtual machines"
    >}}

{{< /tab >}}

{{< tab name="Multi-Network" category-value="multiple" >}}

In this mesh, there are multiple [networks](/docs/ops/deployment/deployment-models/#network-models), where pods and virtual machines are not able to communicate directly with each other.

Control plane traffic, including XDS configuration and certificate signing, are sent through a Gateway in the cluster.
Similarly, all communication between pods and virtual machines goes through the gateway, which acts as a bridge between the two networks.

{{< image width="75%"
    link="multi-network.svg"
    alt="A service mesh with multiple networks and virtual machines"
    title="Multiple networks"
    caption="A service mesh with multiple networks and virtual machines"
    >}}

{{< /tab >}}

{{< /tabset >}}

## Service association

Istio provides two mechanisms to represent virtual machine workloads:

* [`WorkloadGroup`](/docs/reference/config/networking/workload-group/) represents a logical group of virtual machine workloads that share common properties. This is similar to a `Deployment` in Kubernetes.
* [`WorkloadEntry`](/docs/reference/config/networking/workload-entry/) represents a single instance of a virtual machine workload. This is similar to a `Pod` in Kubernetes.

Creating these resources (`WorkloadGroup` and `WorkloadEntry`) does not result in provisioning of any resources or running any virtual machine workloads.
Rather, these resources just reference these workloads and inform Istio how to configure the mesh appropriately.

When adding a virtual machine workload to the mesh, you will need to create a `WorkloadGroup` that acts as template for each `WorkloadEntry` instance:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: product-vm
spec:
  metadata:
    labels:
      app: product
  template:
    serviceAccount: default
  probe:
    httpGet:
      port: 8080
{{< /text >}}

Once a virtual machine has been [configured and added to the mesh](/docs/setup/install/virtual-machine/#configure-the-virtual-machine), a corresponding `WorkloadEntry` will be automatically created by the Istio control plane.
For example:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: WorkloadEntry
metadata:
  annotations:
    istio.io/autoRegistrationGroup: product-vm
  labels:
    app: product
  name: product-vm-1.2.3.4
spec:
  address: 1.2.3.4
  labels:
    app: product
  serviceAccount: default
{{< /text >}}

This `WorkloadEntry` resource describes a single instance of a workload, similar to a pod in Kubernetes. When the workload is removed from the mesh, the `WorkloadEntry` resource will
be automatically removed.  Additionally, if any probes are configured in the `WorkloadGroup` resource, the Istio control plane automatically updates the health status of associated `WorkloadEntry` instances.

In order for consumers to reliably call your workload, it's recommended to declare a `Service` association. This allows clients to reach a stable hostname, like `product.default.svc.cluster.local`, rather than an ephemeral IP addresses. This also enables you to use advanced routing capabilities in Istio via the `DestinationRule` and `VirtualService` APIs.

Any Kubernetes service can transparently select workloads across both pods and virtual machines via the selector fields which are matched with pod and `WorkloadEntry` labels respectively.

For example, a `Service` named `product` is composed of a `Pod` and a `WorkloadEntry`:

{{< image width="30%"
    link="service-selector.svg"
    title="Service Selection"
    >}}

With this configuration, requests to `product` would be load-balanced across both the pod and virtual machine workload instances.

## DNS

Kubernetes provides DNS resolution in pods for `Service` names allowing pods to easily communicate with one another by stable hostnames.

For virtual machine expansion, Istio provides similar functionality via a [DNS Proxy](/docs/ops/configuration/traffic-management/dns-proxy/).
This feature redirects all DNS queries from the virtual machine workload to the Istio proxy, which maintains a mapping of hostnames to IP addresses.

As a result, workloads running on virtual machines can transparently call `Service`s (similar to pods) without requiring any additional configuration.
