---
title: Announcing Istio 1.1
description: Istio 1.1 release announcement.
publishdate: 2019-03-14
attribution: The Istio Team
---
We are pleased to announce the release of Istio 1.1.

Since we released 1.0 back in July, we’ve done a lot of work to help people
get into production. Not surprisingly, we had to do some patch releases (6 so
far!), but we’ve also been hard at work adding new features to the product.

The theme for 1.1 is Enterprise Ready. We’ve been very pleased to see more
and more companies using Istio in production, but as some larger companies
tried to adopt Istio they hit some limits.

One of our prime areas of focus has been performance and scalability. As people
moved into production with larger clusters running more services at higher
volume, they hit some scaling and performance issues. The sidecars took too
many resources and added too much latency. The control plane (especially Pilot)
was overly resource hungry.

We’ve done a lot of work to make both the data plane and the control plane
more efficient. In our 1.1 performance testing, we’re now seeing a sidecar
that typically takes half of a vCPU to process 1000 rps. A single Pilot
instance is capable of handling 1000 services (and 2000 total pods) while
consuming 1.5 vCPU and 2GB of RAM. The sidecar adds `5ms` at the 50th
percentile and `10ms` at 99th percentile (enforcing policy will add latency).

We’ve done work around namespace isolation as well. This lets you use
Kubernetes namespaces to enforce boundaries of control, and ensures that your
teams cannot interfere with each other.

We have also improved the multicluster capabilities and usability. We
listened to the community and improved defaults for traffic control and policy.
We introduced a new component called Galley. Galley validates that sweet, sweet
YAML, reducing the chance of configuration errors. Galley will also be
instrumental in multicluster setups, gathering service discovery information
from each Kubernetes cluster. We are also supporting additional multicluster
topologies including single control plane and multiple synchronized control
planes without requiring a flat network.

There is lots more -- see the
[release notes](/about/notes/1.1/) for complete details.

There is more going on in the project as well. We know that Istio has a lot of
moving parts and can be a lot to take on. To help address that, we recently
formed a [Usability Working Group](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings)
(feel free to join). There is also a lot
happening in the [Community
Meeting](https://github.com/istio/community#community-meeting)
(Thursdays at `11 a.m.`) and in the
[Working
Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md).
And if you haven’t yet joined the conversation at
[discuss.istio.io](https://discuss.istio.io), head over, log in with your
GitHub credentials and join us!

We are grateful to everyone who has worked hard on Istio over the last few
months -- patching 1.0, adding features to 1.1, and, lately, doing tons of
testing on 1.1. Thanks especially to those companies and users
who worked with us
installing and upgrading to the early builds and helping us catch problems
before the release.

So: now’s the time! Grab 1.1, check out the updated documentation, install
it and...happy meshing!
