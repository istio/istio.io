---
title: Announcing Istio 1.9
linktitle: 1.9
subtitle: Major Update
description: Istio 1.9 release announcement.
publishdate: 2021-02-09
release: 1.9.0
skip_list: true
aliases:
    - /news/announcing-1.9
    - /news/announcing-1.9.0
---

We are pleased to announce the release of Istio 1.9!

Our core focus for the 1.9 release was to improve the [Day 2 operations](https://dzone.com/articles/defining-day-2-operations)
for users running Istio in production. Building upon the feedback collected by the User Experience Working Group, we
wanted to improve the stability and overall upgrade experience for our users. A key aspect of stability is publishing
accurate [feature status](/docs/releases/feature-stages/) for Istio core APIs and features, and progressing their stability to
enable our users to utilize Istio's capabilities with confidence, which was another focus for the 1.9 release.

Keep an eye on our blog for our 2021 roadmap, where we will demonstrate our focus on continued improvement in the Day 2
experience.

{{< relnote >}}

{{< tip >}}
Istio 1.9.0 is officially supported on Kubernetes versions `1.17.0` to `1.20.x`.
{{< /tip >}}

Thank you to our users who participated in user experience surveys and empathy sessions, to help us ensure Istio 1.9 is
our most stable release to date.

This is the first Istio release for 2021.  We would like to thank the entire Istio community, and especially the release
managers [Shamsher Ansari](https://github.com/shamsher31) (Red Hat), [Steven Landow](https://github.com/stevenctl)
(Google) and [Jacob Delgado](https://github.com/jacob-delgado) (Aspen Mesh) for helping to get Istio 1.9.0
published.

Here are some highlights for this release:

## Virtual Machine Integration (Beta)

Enabling workloads running in VMs to be part of the Istio service mesh, being able to apply consistent policy, and
collect telemetry across containers and VMs has always been a focus of the Istio community.  We have continued improving
the stability, testing and documentation for VM integration, and are happy to announce that in Istio 1.9 we have
promoted this feature to Beta.

Here's a list of supporting documents which you can follow to easily expand your Istio service mesh to include VMs:

* [Virtual Machine Installation](/docs/setup/install/virtual-machine/) to get started.
* [Virtual Machine Architecture](/docs/ops/deployment/vm-architecture/) to learn about the high level architecture of Istio's virtual machine integration.
* [Debugging Virtual Machines](/docs/ops/diagnostic-tools/virtual-machines/) to learn more about troubleshooting issues with virtual machines.
* [Bookinfo with a Virtual Machine](/docs/examples/virtual-machines/) to learn more about connecting virtual machine workloads to Kubernetes workloads.

## Request Classification (Beta)

Istio continues to make mesh telemetry collection more configurable. In this release,
[Request Classification](/docs/tasks/observability/metrics/classify-metrics/) has been promoted to Beta. This feature
enables users to more precisely understand and monitor the traffic in their service mesh.

## Kubernetes Gateway API support (Alpha)

Configuring Istio to expose a service using [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) has been an active area of development since Istio 1.6, and we are pleased to announce support for them as Alpha in 1.9. Using these APIs benefits users who move between other service meshes that support these APIs. To try them out, check out the [Gateway API getting started documentation](/docs/tasks/traffic-management/ingress/gateway-api/).

We are eager to evolve these CRDs in partnership with the Kubernetes community, notably the
[Kubernetes SIG-NETWORK group](https://github.com/kubernetes/community/tree/master/sig-network), in upcoming releases to
help unify and up-level Ingress capabilities across ecosystems.

## Integration with external authorization systems (Experimental)

Authorization policy now supports an experimental feature of
[CUSTOM action](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) that allows users to
integrate with external auth systems (e.g. OPA, OAuth2, etc.) more easily.

We have published a [blog on this feature](/blog/2021/better-external-authz/), and you can look at [our documentation](/docs/tasks/security/authorization/authz-custom)
to use this functionality. If you are using the [Envoy Filter](/docs/reference/config/networking/envoy-filter/) API today
to integrate with an external authorization system, we recommend you try this feature out and give us feedback!

## Remote fetch and load of WebAssembly (Wasm) HTTP filters (Experimental)

Now Istio supports an experimental feature to [fetch WebAssembly modules](/docs/tasks/extensibility/wasm-module-distribution) from remote repositories and dynamically (re)load them without restarting the proxies in your mesh.  With this you can inject [custom C++ code](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md) into your mesh to handle uses cases that go well beyond the Istio APIs.

Please try it and tell us how it worked for you.  Also, stay tuned for more blogs, support for more languages, and integration with more repositories.

## Mirroring of images on gcr.io

To prevent our users from getting affected by Docker Hub's [rate-limiting policy](/blog/2020/docker-rate-limit/),
we are now publishing all our images on the `gcr.io/istio-release` registry. You can optionally set the hub in your
installation step to `gcr.io/istio-release` to get around issues related to failed image downloads from Docker hub. Note
that Docker hub is still the default hub for Istio installation.

## istioctl updates

We have continued to make significant improvements in the `istioctl` tool to improve the troubleshooting and debugging
capabilities for our users. Key features include:

* A new `verify-install` command that notifies users of any installation configuration errors.
* The `analyze` sub-command can now check if deprecated or alpha-level [annotations](/docs/reference/config/annotations/) are used.

## Join the Istio community

We will be running our inaugural Istio focused conference [IstioCon](https://events.istio.io/istiocon-2021/) from
February 22-26 2021, so please register and join us in learning about the Istio community, roadmap and user adoption
journeys. You can also join our [Community Meeting](https://github.com/istio/community#community-meeting) which occurs
on the fourth Thursday of the month, at 10 AM Pacific Standard Time (PST) to provide feedback and get project updates.

You can also join the conversation at [Discuss Istio](https://discuss.istio.io/), or join our
[Slack workspace](https://slack.istio.io/).

Would you like to get involved? Find and join one of our
[Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help improve Istio.
