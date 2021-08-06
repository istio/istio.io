---
title: Announcing Istio 1.7
linktitle: 1.7
subtitle: Major Update
description: Istio 1.7 release announcement.
publishdate: 2020-08-21
release: 1.7.0
skip_list: true
aliases:
    - /news/announcing-1.7
    - /news/announcing-1.7.0
---

We are pleased to announce the release of Istio 1.7!

{{< relnote >}}

## Istio's great community

As with all of our releases, Istio 1.7 was a community effort. 200 people
across over 40 companies contribute to Istio. We'd like to thank our fantastic
community for their ongoing efforts: it is because of our amazing community
that Istio is able to make so many improvements, quarter after quarter.

## About Istio 1.7

This release continues to navigate in the direction outlined in our [roadmap
post](/blog/2020/tradewinds-2020/), improving usability, security, reliability, and especially improving on
the VM (non-Kubernetes) use case.

Here are some highlights for this release:

## Security enhancements

[We made sure](https://github.com/istio/istio/issues/21833) that destination
rule certificates get the full benefits of secure secret distribution
with SDS (especially automatic rotation), even if they are mounted as files.
This is an important security best practice.

The above item applies to Gateway pods. It is [now possible](https://github.com/istio/istio/issues/14039) for
[Egress Gateways that do TLS/mTLS origination](/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/)
to provision client certificates as secrets.

[We improved](https://github.com/istio/istio/issues/26224) Trust Domain Validation to validate TCP traffic as well.
Previously only HTTP traffic was validated. Trust Domain Validation now also supports `trustDomainAliases`
in the [`MeshConfig` resource](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig).

[ECC cryptography](https://en.wikipedia.org/wiki/Elliptic-curve_cryptography)
is helpful for providing high security while being highly efficient. We added
the [ability to communicate to your certificate authority using ECC](https://github.com/istio/istio/pull/23226).

An important part of best-practice security is to not run a process with more
permissions than it needs, e.g. to protect against [confused deputy attacks](https://en.wikipedia.org/wiki/Confused_deputy_problem).
As such, we modified Gateway deployments [to run as non-root](https://github.com/istio/istio/pull/23379),
by default.

If you were using source principal-based security policies, there was a bug
with the Istio Gateway and mTLS that could have caused them to not be
respected. [This got fixed]({{<github_blob>}}/releasenotes/notes/25818.yaml).

## Ease of use improvements

A big part of making systems like Istio easy to use is in their "day 2" usage,
especially in their ability to help you see potential problems. We're adding to
the ability of the very useful [istioctl analyze tool](/docs/ops/diagnostic-tools/istioctl-analyze/):

- [Warn on a potentially insecure `DestinationRule` configuration]({{<github_blob>}}/releasenotes/notes/dr-analyzer.yaml)
- [Warn on deprecated Mixer resource usage]({{<github_blob>}}/releasenotes/notes/24471.yaml)

For frequent users of istioctl, it can be useful to customize your default
configuration, rather than typing it every time. We added the ability to [put
your personal defaults in your home directory]({{<github_blob>}}/releasenotes/notes/25280.yaml). (Or wherever else you prefer.)

Human-readable text is easier than numbers — that's why we have DNS! — so we
also added it for port numbers. You can now specify [port types using mnemonics](https://github.com/istio/istio/issues/23052)
like http instead of 80.

Unlike the Hotel California, you can both check out and leave, so we added
['istioctl x uninstall']({{<github_blob>}}/releasenotes/notes/istioctl-uninstall.yaml) to make that very easy.

## Production operability improvements

Given Istio's wide use in production systems, we've also made several
improvements to its day 2 usability:

You can [delay the application start until after the sidecar is started](https://medium.com/@marko.luksa/delaying-application-start-until-sidecar-is-ready-2ec2d21a7b74). This
increases the reliability for deployments where the application needs to access
resources via its proxy immediately upon its boot.

Sometimes stale endpoints could make Pilot become unhealthy. [We fixed that](https://github.com/istio/istio/issues/25112).

The [Istio Operator](/docs/setup/install/operator/)
is a great way to install Istio, as it automates a fair amount of toil. Canary
control plane deployments are also important; they allow ultra-safe upgrades of
Istio. Unfortunately, you couldn't use them together - [until now](/docs/setup/upgrade/#canary-upgrades).

[We exposed metrics from the Istio-agent](https://github.com/istio/istio/issues/22825),
so you can watch what's going on with it.

We have [made several improvements](https://github.com/istio/istio/issues/21366)
to our Prometheus metrics pipeline, getting more data there in an easier and
more efficient manner.

## VM support with added security

Since the early days of Istio, we've been working on support for incorporating
workloads on VMs into a service mesh. While we've had users doing it for
several releases now, with Istio 1.7 we have leaned in to add several
improvements. Please note that this is still an Alpha feature.

One of the most used features of Istio is its security feature set. At its core
is assigning a strong identity to each workload, in the form of short-lived
certificates. In this release we are ensuring that workloads running on [VMs in
the mesh](/docs/setup/install/virtual-machine/) get a [secure bootstrapping
process, along with automatic certificate rotation.](https://github.com/istio/istio/issues/24554)

For example, you might have a Kubernetes cluster hosting stateless web services
(frontends) that serve data coming from stateful databases (backends) running
in VMs outside of Kubernetes. You'd still like to encrypt the frontends'
accesses to these backends with mTLS. With this change, you can easily do that.
Furthermore, this is done in a "zero trust" manner, where the compromise of one
frontend or backend doesn't allow the impersonation or compromise of the others,
because the bootstrapping and certificate rotation is following best practices.

We also extended istioctl to be able to [validate the proxy's status]({{<github_blob>}}/releasenotes/notes/psfile.yaml) for
VM-based workloads, where validation was previously only available for
Kubernetes-based workloads.

Finally [we added official RPM packages](https://github.com/istio/istio/issues/9117),
alongside the already-existing Debian packages. This should make installation
on Red Hat-based images a very easy proposition.

## Other fixes

We removed some [invalid control plane metrics](https://github.com/istio/istio/issues/25154),
and [stopped installing telemetry addons](/blog/2020/addon-rework/)
by default.

We fixed an issue with [SNI routing](https://github.com/istio/istio/pull/25691).

Istio now [works better with headless services](https://github.com/istio/istio/pull/24319),
as it will no longer send mTLS traffic to headless services without sidecars.

## Join the Istio community

As always, there is a lot happening in the
[Community Meeting](https://github.com/istio/community#community-meeting);
join us every other Thursday at 10 AM Pacific. We'd love to have you join the
conversation at [Istio Discuss](https://discuss.istio.io), and you can also join
our [Slack workspace](https://slack.istio.io).

We were very proud to be called out as one of the top five
[fastest growing](https://octoverse.github.com/#top-and-trending-projects)
open source projects in all of GitHub in 2019. Want to get involved? Join one of our
[Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)
and help us make Istio even better.
