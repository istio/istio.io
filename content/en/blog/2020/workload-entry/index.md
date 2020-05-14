---
title: Introducing Workload Entries
subtitle: Bridging Kubernetes and VMs
description: Describing the new functionality of Workload Entries.
publishdate: 2020-05-14
attribution: "Cynthia Coan (Tetrate), Shriram Rajagopalan (Tetrate), Tia Louden (Tetrate), John Howard (Google), Sven Mawson (Google)"
keywords: [vm,workloadentry,migration,'1.6',baremetal,serviceentry,discovery]
---

## Introducing Workload Entries: Bridging Kubernetes and VMs

Historically, Istio has primarily focused on bringing a great experience to workloads that run on Kubernetes, with lesser attention on anything else, including VM and Bare Metal. Yet, as time goes on and as Istio matures as a project, it brings with it a significant range of new opportunities for expanding the reach and capabilities of an Istio mesh.

The use cases that have driven the changes in 1.6 are varied, from migrating applications onto a more modern platform, or running more traditional databases on a platform outside of Kubernetes (perhaps because it works efficiently for you), there are very legitimate reasons for wanting to run on both platforms, and we’ve heard from users this is something that needs lots of work. To start improving this experience, we’ve started with the core problem blocking us from making this experience easier. Discovery.

### History

Before now, describing something "outside" of the mesh was indistinguishably linked to the actual service running on the machine. Specifically it was directly coupled to a [Service Entry](/docs/reference/config/networking/service-entry/) and registering a machine would have looked like this:

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
{{< /text >}}

This seems fine, but what if you were migrating this service onto the mesh? It was running outside of the mesh, but you want to slowly canary it in an important way to validate that the mesh works in production, and that everything is working as intended. How would this be described inside of Istio, how would we do things like setup Mutual TLS identities between the components inside Kubernetes, and those on the outside of the mesh?

The simple answer is you couldn’t really accurately describe these concepts within Istio. This not only leads to a confusion for users, but also severely limits what Istio can do, since it can’t accurately grasp what's inside the mesh. You had no way of describing things outside of the mesh the same way we did as things inside the mesh. So what if you had a Pod-Like resource for workloads outside of the mesh?

### Workload Entry: A Non-Kubernetes Pod

Workload Entries were created specifically to solve this problem. A way of generically describing things services are running on outside the mesh. From here you can make many paths easier, like Mutual TLS an important security property for things outside of the mesh communicating with things inside, which in many cases may not be over a secure channel. To create a `WorkloadEntry` manually, and attach it to a `ServiceEntry` you’d do something like:

{{< text yaml >}}
---
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: vm1
spec:
  address: 1.1.1.1
  labels:
    app: foo
    instance-id: vm-78ad2
---
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
  workloadSelector:
    labels:
      app: foo
{{< /text >}}

In this case we can see a `ServiceEntry` is pointing to a particular `WorkloadEntry` through labels.

{{< image width="75%"
    link="./workload-entry-example.png"
    alt="Service Entries Pointing to Workload Entries"
    caption="The Internal of Service Entries Pointing to Workload Entries"
    >}}

But who says this has to just be a workload entry? This represents something just outside of the Mesh, but there’s nothing saying the Workload Selector can’t select a `WorkloadEntry`, and a Pod.

If you were to migrate some of your workloads to Kubernetes, and you choose to keep a substantial number of your VMs for example, the aim would be for the mesh to do the heavy lifting, and disperse the traffic for you without manual intervention. The Workload Selector is capable of selecting both Pods and VMs and with that, Istio will automatically load balance between the VMs, and Kubernetes Pods. You also don’t have two things to target with policies like mTLS. All configuration is forced to be in sync between the two, lowering the chances of missing something fundamental and causing errors.. The migration experience is significantly improved by increasing the possible options for doing it, and leaving you to choose the method that would best suit your requirements.

The 1.6 release also unlocks some other benefits such as being able to finally describe things outside of the mesh in a first class manner, allowing them to be bootstrapped easier. However, these benefits are merely side effects. For the first time, it requires ***no extra work*** networking wise, to move services onto the mesh.