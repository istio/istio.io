---
title: Virtual Machine Architecture
description: Describes Istio's high-level architecture for virtual machines.
weight: 20
keywords:
- virtual-machine
test: n/a
owner: istio/wg-environments-maintainers
---

Before reading this document, be sure to review [Istio's architecture](/docs/ops/deployment/architecture/) and [deployment models](/docs/ops/deployment/deployment-models/).
This page builds on these pages to explain how Istio can be extended to support joining virtual machines into the mesh.

Istio's virtual machine support involves connecting workloads outside of a Kubernetes cluster to the mesh.
This enables legacy applications, or applications not suitable to run inside of Kubernetes, to get all the same benefits Istio provides to applications running inside Istio.

Many of the features the Kubernetes automatically provides applications are supplemented by Istio.
This includes service discovery, DNS resolution, and health checks.
Additionally, standard Istio features such as automatic mutual TLS, rich telemetry, and expressive traffic management configuration are enabled.

The following diagram shows the architecture of a mesh with virtual machines:

{{< tabset category-name="network-mode" >}}

{{< tab name="Single-Network" category-value="single" >}}

In this mesh, there is a single [network](/docs/ops/deployment/deployment-models/#network-models), meaning pods and virtual machines can directly reach each other.

Control plane traffic, including XDS configuration and certificate signing, are sent through a Gateway in the cluster.
This ensures that the VMs have a stable address to connect to when they are bootstrapping. All other communication between pods and
virtual machines are able to communicate directly.

{{< image width="75%"
    link="single-network.svg"
    alt="A service mesh with a single network and virtual machines"
    title="Single network"
    caption="A service mesh with a single network and virtual machines"
    >}}

{{< /tab >}}

{{< tab name="Multi-Network" category-value="multiple" >}}

In this mesh, there is are multiple [networks](/docs/ops/deployment/deployment-models/#network-models), meaning pods and virtual machines are not able to directly reach each other.

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

Istio introduces two new types to represent virtual machine workloads:

* [`WorkloadGroup`](/docs/reference/config/networking/workload-group/) represent a grouping of workloads that share common properties. This is comparable to a `Deployment` in Kubernetes
* [`WorkloadEntry`](/docs/reference/config/networking/workload-entry/) represent a single instance of a workload. This is comparable to a `Pod` in Kubernetes.

Unlike their corresponding Kubernetes resources, creating these resources does not result in provisioning of any resources or running any applications.
Rather, these resources just reference these workloads and inform Istio how to configure the mesh appropriately.

When adding a virtual machine workload to the mesh, you will need to create a `WorkloadGroup`, that acts as template for each instance:

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

Once the virtual machine has been [configured and added to the mesh](/docs/setup/install/virtual-machine/#configure-the-virtual-machine), a corresponding `WorkloadEntry` will be automatically created.
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

These `WorkloadEntry` describe a single instance of a workload, similar to a pod. When the workload is removed from the mesh, the `WorkloadEntry` will
be automatically removed, and its health status will be automatically updated based on the probe configured in the `WorkloadGroup`, if any.

In order for consumers to actually call the workload, generally it's desired to join a part of a `Service`. This allows
clients to reach a stable hostname, like `product.default.svc.cluster.local`, rather than an IP address that may change.
Additionally, it allows Istio configuration such as `DestinationRule`s and `VirtualService`s to apply.

Joining a `Service` works the same as with `Pod`s; the `Service`'s selector will match over the `WorkloadEntry` labels.

For example, if we had a `Service` named `product` that was composed of a `Pod` and a `WorkloadEntry`:

{{< image width="30%"
    link="service-selector.svg"
    title="Service Selection"
    >}}

With this configuration, requests to `product` would be sent to both the pod and virtual machine workload.

## DNS

One Kubernetes, pods will automatically be configured with a DNS resolver that enables `Service` names.
This enables pods to easily communicate with one another by simple, stable hostnames.

Istio provides similar functionality to virtual machine workloads through its [DNS Proxy](/docs/ops/configuration/traffic-management/dns-proxy/).
This feature redirects all DNS queries from the workload through the Istio proxy, which maintains a mapping of hostnames to IP addresses.

As a result, workloads running on virtual machines will be able to call `Service`s just like pods.
