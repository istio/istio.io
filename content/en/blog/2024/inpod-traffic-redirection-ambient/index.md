---
title: "Maturing Istio Ambient: Compatibility Across Various Kubernetes Providers and CNIs"
description: An innovative traffic redirection mechanism between workload pods and ztunnel.
publishdate: 2024-01-26
attribution: "Ben Leggett (Solo.io), Yuval Kohavi (Solo.io), Lin Sun (Solo.io)"
keywords: [Ambient,Istio,CNI,ztunnel,traffic]
---

The Istio project [announced ambient mesh - it's new sidecar-less dataplane mode](/blog/2022/introducing-ambient-mesh/) in 2022, and [released an Alpha implementation](/news/releases/1.18.x/announcing-1.18/#ambient-mesh) in early 2023.

Our Alpha was focused on proving out the value of the ambient model, under limited conditions, which it certainly has done. However, the conditions were quite limited. Ambient mode relies on transparently redirecting traffic, and the initial mechanism we used to do that conflicted several categories of 3rd-party CNI implementations.
Through GitHub issues and Slack discussions, we heard our users wanted to be able to use ambient mode in [minikube](https://github.com/istio/istio/issues/46163) and [Docker Desktop](https://github.com/istio/istio/issues/47436), with CNI implementations like [Cilium](https://github.com/istio/istio/issues/44198) and [Calico](https://github.com/istio/istio/issues/40973), and on services that ship in-house CNI implementations like [OpenShift](https://github.com/istio/istio/issues/42341) and [Amazon EKS](https://github.com/istio/istio/issues/42340).
Getting broad support for Kubernetes anywhere has become the No. 1 requirement for ambient mesh moving to Beta — people have come to expect Istio to work on any Kubernetes platform and with any Container Network Interface (CNI) implementation. After all, Ambient wouldn’t be ambient without being all around you!

At Solo, we've been integrating ambient mode into our Gloo Mesh product, and came up with an innovative solution to this problem. We decided to [upstream](https://github.com/istio/istio/issues/48212) our changes in late 2023 to help Ambient reach Beta faster, so more users can operate ambient in Istio 1.21 or newer and enjoy the benefits of ambient sidecar-less mesh in their platforms regardless of their existing or preferred CNI implementation.

## How did we get here?

### Service meshes and CNIs: it's complicated

Istio is a service mesh, and all service meshes by strict definition are not *CNI implementations* - service meshes require a [spec-compliant, primary CNI implementation](https://www.cni.dev/docs/spec/#overview-1) to be present in every Kubernetes cluster, and rest on top of that. 

This primary CNI implementation may be provided by your cloud provider (AKS, GKE, and EKS all ship their own), or by third-party CNI implementations like Calico. Some service meshes may also ship bundled with their own primary CNI implementation, which they explicitly require to function. 

Basically, before you can do things like secure pod traffic with mTLS and apply of high-level authentication and authorization policy at the service mesh layer, you must have a functional Kubernetes cluster with a functional CNI implementation, to make sure the basic networking pathways are set up so that packets can get from one pod to another (and from one node to another) in your cluster.

Though some service meshes may also ship and require their own in-house primary CNI implementation, and it is sometimes possible to run two primary CNI implementations in parallel within the same cluster (for instance, one shipped by the cloud provider, and a 3rd-party implementation), in practice this introduces a whole host of compatibility issues, strange behaviors, reduced featuresets, and simple incompatibilities due to the wildly varying mechanisms each CNI implementation might employ internally.

To avoid this, the Istio project has chosen not to ship or require their own primary CNI implementation, or even require a "preferred" CNI implementation - instead choosing to support CNI chaining with the widest possible ecosystem of CNI implementations, and ensuring maximum compatibility with managed offerings, cross-vendor support, and composability with the broader CNCF ecosystem.

### Traffic redirection in ambient alpha

The [istio-cni](/docs/setup/additional-setup/cni/) component is an optional component in the sidecar data plane mode,
commonly used to remove the [requirement for the `NET_ADMIN` and `NET_RAW` capabilities](/docs/ops/deployment/requirements/) for
users deploying pods into the mesh. 

istio-cni is a required component in the ambient
data plane mode. Whenever pods are added to an ambient mesh, the istio-cni component configures traffic redirection for all
incoming and outgoing traffic between the pods and the [ztunnel](/blog/2023/rust-based-ztunnel/) running on
the pod's node, via the node-level network namespace. The key difference between the sidecar mechanism and the ambient alpha mechanism is that in the latter, pod traffic was redirected out of the pod network namespace, and into the ztunnel network namespace - necessarily passing through the node's network namespace on the way, which is where the bulk of the traffic redirection rules to achieve this were implemented.

As we tested more broadly in multiple Kubernetes environments which many of them have its default CNI, it became clear that capturing and redirecting pod traffic in the node network namespace, as we were during ambient alpha, was not going to meet our requirements. 

These are the two biggest challenges with the host-based approach:
- The default CNI’s node-level networking configuration could interfere with the node-level networking configuration
from istio-cni, whether it is with eBPF or iptables.
- If users deploy a network policy for the default CNI, the network policy may not be enforced when istio-cni is deployed.

### Addressing the challenges

Applying any traffic
routing/networking rules in the node-level network namespace invites unresolvable conflicts/incompatibilities with
CNIs (which might use a wide variety of fundamentally networking topologies on the node) - they *must* configure traffic
routing/networking rules in the node-level network namespace. We realized any eBPF implementation would have the same
basic problem, as there is no standardized way to safely chain/extend arbitrary eBPF programs at this time.

In sidecar mode, it is trivial to configure traffic redirection between sidecar and application pod, as both operate within
the pod's network namespace. This led to a light-bulb moment: why not mimic sidecars, and configure the redirection in
the application network namespace? 

While this sounds like a "crazy simple" thought, is this even possible, given ztunnel runs
in the Istio system namespace? After some research, we discovered a Linux process running in one network namespace
could create and own listening sockets within another network namespace, which is a basic Linux socket capability.
However, to make this work, and cover all pod lifecycle scenarios we had to make architectural changes to the ztunnel
as well as the istio-cni agent.

### Traffic redirection in ambient now

After sufficient prototyping and validating that the innovative approach does work for all the Kubernetes platforms we have
access to, we built the confidence of the work and contributed to upstream to switch to this new traffic redirection
model - an *in-Pod* traffic redirection mechanism between workload pods and the ztunnel node proxy component that has
been built from the ground up to be highly compatible with all major cloud providers and CNIs.

The key innovation is to deliver the pod’s network namespace to the ztunnel so that ztunnel can start its redirection
sockets inside the pod’s network namespace, while still running outside the pod. With this approach, the traffic redirection
between ztunnel and application pods happens in a way that’s very similar to sidecars and application pods today and is
strictly invisible to any Kubernetes CNI. Network policy from any Kubernetes CNIs can continue to be enforced,
regardless of whether the CNI uses eBPF or iptables, there is no conflict between the in-Pod traffic redirection and the CNI.

## Technical deep dive of in-pod traffic redirection

First, let’s go over the basics of how a packet travels between pods in Kubernetes.

### Linux, Kubernetes, and CNI  - What’s A Network Namespace, And Why Does It Matter?

In Linux, a *container* is simply one or more Linux processes running within isolated namespaces, and a Linux namespace
is simply a kernel flag that controls what processes running within that namespace are able to see. For instance, if you
create a new Linux network namespace and run a process inside it, that process can only see the networking rules created
within that network namespace, and not any created outside of it - even though everything running on that machine is still
sharing one Linux networking stack.

Linux namespaces are conceptually a lot like Kubernetes namespaces - logical labels that organize and isolate different
active processes, and allow you to create rules about what things within a given namespace can see and what rules are
applied to them - they simply operate at a much lower level.

When a process running within a network namespace creates a TCP packet outward bound for something else, the packet must be
processed by any local rules within the local network namespace first, then leave the local network namespace, passing
into another one.

For example, in plain Kubernetes without any mesh installed, a pod might create a packet and send it to another pod, and
the packet might (depending on how networking was set up):
- Be processed by any rules within the source pod’s network namespace.
- Leave the source pod network namespace, and bubble up into the node’s network namespace where it is processed by any rules in that namespace.
- From there, finally be redirected into the target pod’s network namespace (and processed by any rules there).

In Kubernetes, the [CRI](https://kubernetes.io/docs/concepts/architecture/cri/) (container *runtime* interface) is responsible for talking to the Linux kernel, creating network namespaces
for new pods, and starting processes within them. The CRI then invokes the [CNI](https://github.com/containernetworking/cni) (container *networking* interface),
which is responsible for wiring up the networking rules in the various Linux network namespaces, so that packets leaving and
entering the new pod can get where they’re supposed to go. It doesn’t matter much what topology or mechanism the CNI uses to
accomplish this - as long as packets get where they’re supposed to be, Kubernetes works and everyone is happy.

### Istio ambient traffic redirection: why did we drop the previous model?

In Istio ambient, every node has a minimum of two containers running as Kubernetes DaemonSet:
- An efficient ztunnel which handles mesh traffic proxying duties, and L4 policy enforcement.
- A CNI node agent that handles enrolling new and existing pods into the ambient mesh.

In the previous ambient model, this is how mesh enrollment worked:
- A Kubernetes pod (existing or newly-started), with its namespace labeled with `istio.io/dataplane-mode=enabled` indicating it should
be included in the ambient mesh, is detected by the istio-cni node agent.
- The istio-cni node agent then establishes network redirection rules in the top-level node network namespace, such that
packets entering or leaving the enrolled pod would be intercepted and redirected to that node’s ztunnel on the relevant
proxy ports (15008, 15006, or 15001).

This meant that for a packet created by a mesh-enrolled pod, that packet would leave that source pod, enter the node’s
top-level network namespace, and then be intercepted and redirected to that node’s ztunnel (running in its own network
namespace) for proxying to the destination pod, with the return trip being similar.

This model worked well enough as a placeholder for the initial Ambient launch, but as mentioned, it has a fundamental
problem - there are many CNI implementations, and in Linux there are many fundamentally different and incompatible ways
in which you can configure how packets get from one network namespace to another. You can use tunnels, overlay networks,
you can go through the host network namespace, or you can bypass it. You can go through the Linux user space networking stack,
or you can skip it and shuttle packets back and forth in the kernel space stack, etc etc. And for every possible approach,
there’s probably a CNI implementation out there that makes use of it.

Which meant that with the previous redirection approach, there were lots of CNI implementations Ambient simply wouldn’t
work with, given its reliance on node network namespace packet redirection - any CNI that didn’t route packets thru the
node network namespace would need a different redirection implementation. And even for CNIs that did do this, we would
have unavoidable and potentially unresolvable problems with conflicting node-level rules - do we intercept before the CNI,
or after? Will some CNIs break if we do one, or the other, and they aren’t expecting that? Where and when is NetworkPolicy
enforced, since NetworkPolicy must be enforced in the node network namespace? Do we need lots of code to special-case
every popular CNI?

### Istio Ambient Traffic Redirection: The Current Model

In the current ambient model, this is how mesh enrollment works:
- A Kubernetes pod (existing or newly-started), with labels indicating it should be enrolled in the ambient mesh, is detected by
the istio-cni node agent.
  - If a *new* pod is started that should be enrolled, a standard CNI plugin (as installed and managed by the istio-cni agent)
is triggered by the CRI, used to push a new pod event to the node’s istio-cni agent, and block pod startup until redirection
is established. Since CNI plugins are invoked by the CRI as early as possible in the Kubernetes pod creation process,
this ensures that we can establish traffic redirection early enough to prevent traffic escaping during startup,
without relying on things like init containers.
  - If an *already-running* pod becomes eligible for ambient enrollment, the istio-cni node agent’s Kubernetes API watcher
triggers a new pod event, and redirection is configured in the same manner.
- The istio-cni node agent hops into the pod’s network namespace and establishes network redirection rules inside the pod
network namespace, such that packets entering and leaving the pod are intercepted and transparently redirected to local
proxy listening [ports](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports) (15008, 15006, 15001).
- The istio-cni node agent then informs the node ztunnel over a Unix domain socket that it should establish local proxy
listening ports inside the pod’s network namespace, (on 15008, 15006, and 15001), and provides ztunnel with a low-level
Linux [file descriptor](https://en.wikipedia.org/wiki/File_descriptor) representing the pod’s network namespace.
  - While typically sockets are created within a Linux network namespace by the process actually running inside that
network namespace, it is perfectly possible to leverage Linux’s low-level socket API to allow a process running in one
network namespace to create listening sockets in another network namespace, assuming the target network namespace is known
at creation time.
- The node-local ztunnel internally spins up a new proxy instance and listen port set, dedicated to the newly-enrolled pod.
- Once the in-pod redirect rules are in place and the ztunnel has established the listen ports, the pod is enrolled in the
mesh and traffic begins flowing thru the node-local ztunnel, as before.

Here’s a basic diagram showing the pod enrollment flow:

{{< image width="100%"
    link="./pod-enrollment.png"
    alt="pod enrollment flow"
    >}}

Once the enrollment is completed, traffic to and from pods in the mesh will be fully encrypted by default, as always with Istio.

Traffic will now enter and leave the pod network namespace as encrypted traffic - it will look like every ambient-enrolled
pod has the ability to enforce mesh policy and securely encrypt traffic, even though the user application running in the pod
has no awareness of either.

Here’s a diagram to illustrate how encrypted traffic flows between meshed pods in the current ambient model:

{{< image width="100%"
    link="./traffic-flows-between-mesh-pods.png"
    alt="HBONE traffic flows between meshed pods"
    >}}

And, as before, unencrypted plaintext traffic from outside the mesh can still be handled and policy enforced, for use cases
where that is necessary:

{{< image width="100%"
    link="./traffic-flows-plaintext.png"
    alt="Plain text traffic flow between meshed pods"
    >}}

### Istio Ambient Traffic Redirection: What This Gets Us

The end result of the new ambient capture model is that all traffic capture and redirection happens inside the pod’s network
namespace. To the node, the CNI, and everything else, it looks like there is a sidecar proxy inside the pod, even though
there is, as before, **no sidecar proxy running in the pod** at all. Remember that the job of CNI implementations is to get
packets **to and from** the pod. By design and by the CNI spec, they do not care what happens to packets after that point.

This approach automatically eliminates conflicts with a wide range of CNI and NetworkPolicy implementations, and drastically
improves Istio ambient mesh compatibility with all major managed Kubernetes offerings across all major CNIs.

## Wrapping Up

With gracious support from the community on testing the change with various Kubernetes platforms and CNIs, and many rounds
of reviews from Istio maintainers, we are glad the [ztunnel](https://github.com/istio/ztunnel/pull/747) and [istio-cni](https://github.com/istio/istio/pull/48253) PRs merged to Istio 1.21 so our users
can start running ambient on any Kubernetes platforms with any CNIs in Istio 1.21 or newer. We’ve tested this with Google,
Microsoft, and AWS’s managed Kubernetes offerings and all the CNI implementations they offer, as well as with 3rd-party CNIs like
Calico and Cilium, as well as platforms like OpenShift, with solid results. We are extremely excited that we are able to
move Istio Ambient forward to run everywhere with this innovative in-pod traffic redirection approach between ztunnel
and users’ application pods. With this top technical hurdle to ambient beta resolved, we can't wait to work with the
rest of the Istio community to get ambient to beta soon! To learn more about ambient’s beta progress, join us in
the #ambient and #ambient-dev channel in Istio’s [slack](https://slack.istio.io), or attend the weekly ambient contributor [meeting](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings) on Wednesdays,
or check out the ambient beta [project board](https://github.com/orgs/istio/projects/9/views/3?filterQuery=beta) and help us fix something!
