---
title: Announcing Istio 1.3
subtitle: Major Update
description: Istio 1.3 release announcement.
publishdate: 2019-09-10
attribution: The Istio Team
release: 1.3.0
---

We are pleased to announce the release of Istio 1.3!

{{< relnote linktonote="true" >}}

The theme of 1.3 is User Experience - improving the experience of new users adopting Istio, debugging problems and supporting more applications out of the box. 

Users are adopting Istio faster than ever before and we’ve been listening to their feedback! We’ve heard that Istio can be complex and challenging to adopt and we've been working hard to make improvements. 

Earlier this year, we formed the new User Experience team to lead improvements across all Istio components. Everyone is welcome to join the working group meetings and share their thoughts. In this release, we start delivering many notable improvements and some are ready for you to use in 1.3 while others are in the experimental phase. 

In past releases, you had to explicitly declare the protocol for service ports. This requirement caused problems for users that didn't name their ports when they added their application to the mesh. By default, Pilot now sniffs the protocol getting rid of this requirement! Similarly, you had to define all the pod ports (`containerPort`) for each container, another obsolete requirement since Istio now captures all inbound ports by default!

If you haven't tried out `istioctl` yet, now is a great time to start! The following experimental sub-commands are now supported Istio features:

- `metrics`
- `dashboard`
- `convert-ingress` 

In addition, we have added several new `istioctl` experimental subcommands to improve usability.

The Istio team is also constantly working on improving the control plane performance and reducing its footprint. In this release, Pilot performance has been significantly improved resulting in as much as a 90% CPU usage savings!

Locality aware load balancing graduated from experimental to default in this release too. Istio can now take advantage of existing locality information to prioritize load balancing pools and favor sending requests to the closest backends.

We enhanced control plane monitoring in the following ways:

- Added new metrics to monitor configuration state
- Added metrics for sidecar injector
- Added a new Grafana dashboard for Citadel
- Improved the Pilot dashboard

See the [release notes](/about/notes/1.3) for the complete list of changes. As always, there is a lot happening in the [Community Meeting]https://github.com/istio/community#community-meeting); join us every other Thursday at 11 a.m. Pacific.
Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md). And if you haven’t yet joined the conversation at [discuss.istio.io](https://discuss.istio.io), head over, log in with your GitHub credentials and join us!
