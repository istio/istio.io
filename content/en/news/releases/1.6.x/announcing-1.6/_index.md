---
title: Announcing Istio 1.6
linktitle: 1.6
subtitle: Major Update
description: Istio 1.6 release announcement.
publishdate: 2020-05-19
release: 1.6.0
skip_list: true
aliases:
    - /news/announcing-1.6.0
    - /news/announcing-1.6
---

We are pleased to announce the release of Istio 1.6!

{{< relnote >}}

With this release, we are continuing the path we charted earlier this year in
our [roadmap post](/blog/2020/tradewinds-2020/), sailing toward more
simplicity, a better installation experience, and some other goodies as well.

Here’s some of what’s coming to you in today's release:

## Simplify, simplify, simplify

Last release, we introduced **Istiod**, a component that reduced the number of
components in an Istio installation by combining the functionality of several
other components. In Istio 1.6, you'll find that Citadel, the sidecar
injector and Galley are no longer deployed.

You'll also find that we are using the new `AppProtocol` API from Kubernetes.
What does that mean for you? It means that you won't need to use the name
field in your service to denote the protocol -- a simpler user experience.

## Better lifecycle

We continue to make installing and upgrading Istio a better experience. Our
command line tool `istioctl` gives better diagnostic information, has a simpler
install command, and even gives status in color!

Upgrading Istio has been improved as well, in several powerful ways. First, we
now support canarying of the Istio control plane itself. That means you can
install a new version of the control plane alongside the existing version and
selectively have proxies use the new one.

We also have an `istioctl upgrade` command that will perform an in-place
upgrade in your clusters (still giving you the control over updating the proxies
themselves).

Check out the [documentation](/docs/setup/upgrade/) for all of the details on
the new upgrade experience.

## Observe this

Many companies adopt Istio solely to get better observability of distributed
applications, so we continue to invest there. You'll have to read the release
notes to see all of the features, but you'll see more configurability, better
ability to control your trace sampling rates, and updated Grafana dashboards
(and we're even publishing them on [Grafana](https://grafana.com) on the
[Istio org page](https://grafana.com/orgs/istio)).

## Better VM support
For those of you who are adding non-Kubernetes workloads to meshes (for
example, workloads deployed on VMs), the new
[WorkloadEntry](/docs/reference/config/networking/workload-entry/) resource
makes that easier than ever. We created this API to give non-Kubernetes
workloads first-class representation in Istio. It elevates a VM or bare metal
workloads to the same level as a Kubernetes pod, instead of just an endpoint
with an IP address. You now even have the ability to define a Service that is
backed by both Pods and VMs. Why is that useful? Well, now you now have the
ability to have a heterogeneous mix of deployments (VMs and Pods) for the same
service, providing a great way for migrating VM workloads to the mesh.

Expanding support for VM-based workloads was another theme we called out
in our roadmap post, and you can expect to see more in this area over the
coming releases.

## Other improvements

There are great traffic management features (like supporting the experimental
Kubernetes Service APIs, better support for Ingress, and better header
handling).

## Join the Istio community

As always, there is a lot happening in the
[Community Meeting](https://github.com/istio/community#community-meeting);
join us every other Thursday at 11 AM Pacific. We'd love to have you join the
conversation at [Istio Discuss](https://discuss.istio.io), and you can also join
our [Slack channel](https://istio.slack.com).

We were very proud to be called out as one of the top five
[fastest growing](https://octoverse.github.com/#top-and-trending-projects)
open source projects in all of GitHub. Want to get involved? Join one of our
[Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)
and help us make Istio even better.
