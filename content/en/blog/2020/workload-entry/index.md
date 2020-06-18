---
title: Introducing Workload Entries
subtitle: Bridging Kubernetes and VMs
description: Describing the new functionality of Workload Entries.
publishdate: 2020-05-21
attribution: "Cynthia Coan (Tetrate), Shriram Rajagopalan (Tetrate), Tia Louden (Tetrate), John Howard (Google), Sven Mawson (Google)"
keywords: [vm,workloadentry,migration,'1.6',baremetal,serviceentry,discovery]
---

## Introducing Workload Entries: Bridging Kubernetes and VMs

Historically, Istio has provided great experience to workloads that run on Kubernetes, but it has been less smooth for other types of workloads, such as Virtual Machines (VMs) and bare metal. The gaps included the inability to declaratively specify the properties of a sidecar on a VM, inability to properly respond to the lifecycle changes of the workload (e.g., booting to not ready to ready, or health checks), and cumbersome DNS workarounds as the workloads are migrated into Kubernetes to name a few.

Istio 1.6 has introduced a few changes in how you manage non-Kubernetes workloads, driven by a desire to make it easier to gain Istio's benefits for use cases beyond containers, such as running traditional databases on a platform outside of Kubernetes, or adopting Istio's features for existing applications without rewriting them.

### Background

Prior to Istio 1.6, non-containerized workloads were configurable simply as an IP address in a `ServiceEntry`, which meant that they only existed as part of a service. Istio lacked a first-class abstraction for these non-containerized workloads, something similar to how Kubernetes treats Pods as the fundamental unit of compute - a named object that serves as the collection point for all things related to a workload - name, labels, security properties, lifecycle status events, etc. Enter `WorkloadEntry`.

Consider the following `ServiceEntry` describing a service implemented by a few tens of VMs with IP addresses:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: svc1
spec:
  hosts:
  - svc1.internal.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  endpoints:
  - address: 1.1.1.1
  - address: 2.2.2.2
  ....
{{< /text >}}

If you wanted to migrate this service into Kubernetes in an active-active manner - i.e. launch a bunch of Pods, send a portion of the traffic to the Pods over Istio mutual TLS (mTLS) and send the rest to the VMs without sidecars - how would you do it? You would have needed to use a combination of a Kubernetes service, a virtual service, and a destination rule to achieve the behavior. Now, let's say you decided to add sidecars to these VMs, one by one, such that you want only the traffic to the VMs with sidecars to use Istio mTLS. If any other Service Entry happens to include the same VM in its addresses, things start to get very complicated and error prone.

The primary source of these complications is that Istio lacked a first-class definition of a non-containerized workload, whose properties can be described independently of the service(s) it is part of.

{{< image
    link="./workload-entry-first-example.svg"
    alt="Service Entries Pointing to Workload Entries"
    caption="The Internal of Service Entries Pointing to Workload Entries"
    >}}

### Workload Entry: A Non-Kubernetes Endpoint

`WorkloadEntry` was created specifically to solve this problem. `WorkloadEntry` allows you to describe non-Pod endpoints that should still be part of the mesh, and treat them the same as a Pod. From here everything becomes easier, like enabling `MUTUAL_TLS` between workloads, whether they are containerized or not.

To create a [`WorkloadEntry`](/docs/reference/config/networking/workload-entry/) and attach it to a [`ServiceEntry`](/docs/reference/config/networking/service-entry/) you can do something like this:

{{< text yaml >}}
---
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: vm1
  namespace: ns1
spec:
  address: 1.1.1.1
  labels:
    app: foo
    instance-id: vm-78ad2
    class: vm
---
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: svc1
  namespace: ns1
spec:
  hosts:
  - svc1.internal.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  workloadSelector:
    labels:
      app: foo
{{< /text >}}

This creates a new `WorkloadEntry` with a set of labels and an address, and a `ServiceEntry` that uses a `WorkloadSelector` to select all endpoints with the desired labels, in this case including the `WorkloadEntry` that are created for the VM.

{{< image width="75%"
    link="./workload-entry-final.svg"
    alt="Service Entries Pointing to Workload Entries"
    caption="The Internal of Service Entries Pointing to Workload Entries"
    >}}

Notice that the `ServiceEntry` can reference both Pods and `WorkloadEntries`, using the same selector. VMs and Pods can now be treated identically by Istio, rather than being kept separate.

If you were to migrate some of your workloads to Kubernetes, and you choose to keep a substantial number of your VMs, the `WorkloadSelector` can select both Pods and VMs, and Istio will automatically load balance between them. The 1.6 changes also mean that `WorkloadSelector` syncs configurations between the Pods and VMs and removes the manual requirement to target both infrastructures with duplicate policies like mTLS and authorization.
The Istio 1.6 release provides a great starting point for what will be possible for the future of Istio. The ability to describe what exists outside of the mesh the same way you do with a Pod leads to added benefits like improved bootstrapping experience. However, these benefits are merely side effects. The core benefit is you can now have VMs, and Pods co-exist without any configuration needed to bridge the two together.
