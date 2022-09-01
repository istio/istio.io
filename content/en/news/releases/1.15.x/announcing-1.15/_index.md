---
title: Announcing Istio 1.15
linktitle: 1.15
subtitle: Major Update
description: Istio 1.15 release announcement.
publishdate: 2022-08-31
release: 1.15.0
skip_list: true
aliases:
- /news/announcing-1.15
- /news/announcing-1.15.0
---

We are pleased to announce the release of Istio 1.15!

{{< relnote >}}

This is the third Istio release of 2022. We would like to thank the entire Istio community
for helping to get Istio 1.15.0 published. Special thanks are due to the release managers Sam Naser and Aryan Gupta from Google, Ziyang Xiao from Intel and Daniel Hawton from Solo.io. As always, our gratitude goes to Test & Release WG lead Eric Van Norman (IBM) for his help and guidance.

{{< tip >}}
Istio 1.15.0 is officially supported on Kubernetes versions `1.22` to `1.25`.
{{< /tip >}}

## What's new

Here are some of the highlights of the release:

### arm64 support

We now build Istio for arm64, so you can run it on your Raspberry Pi, or your [Tau T2A](https://cloud.google.com/blog/products/compute/tau-t2a-is-first-compute-engine-vm-on-an-arm-chip) VMs.

### istioctl uninstall

We hope you never need to uninstall Istio from a cluster, but in case you do — maybe you want to reinstall it with different parameters? — we've had experimental support for uninstalling Istio for many releases.  In 1.15, we've fixed the remaining issues and promoted the feature to stable.

## Upgrading to 1.15

When you upgrade, we would like to hear from you! Please take a few minutes to respond to a brief [survey](https://forms.gle/SWHFBmwJspusK1hv6) to let us know how we’re doing.

You can also join the conversation at [Discuss Istio](https://discuss.istio.io/), or join our [Slack workspace](https://slack.istio.io/).
Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.

## Istio at KubeCon NA

Istio will be at [KubeCon NA](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/) this October in Detroit.  Don't miss [the talk from TOC member John Howard, with Keith Mattix from Microsoft](https://sched.co/182KL), where you will learn about [the new GAMMA initiative for common service mesh APIs](https://gateway-api.sigs.k8s.io/contributing/gamma/). There are also talks on [dynamically testing releases in production](https://sched.co/182Ep) and [decentralized routing for a sharded application](https://sched.co/182KO). And, if that's not enough, there's a whole co-located event dedicated to service mesh - [ServiceMeshCon NA](https://events.linuxfoundation.org/servicemeshcon-north-america/). Join program chairs Craig Box (from Google) and Lin Sun (from Solo.io) for a day discussing the ins and outs of service mesh technology.

## CNCF progress update

In April, [we announced that Istio has been proposed to become a CNCF incubation project](/blog/2022/istio-has-applied-to-join-the-cncf/). Our team has been hard at work preparing our application, and the project is currently in the public request for comments phase.  Please see [this thread](https://lists.cncf.io/g/cncf-toc/message/7367) if you want to participate!
