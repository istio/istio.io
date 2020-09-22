---
title: Announcing Istio 1.6
linktitle: 1.6
subtitle: Major Update
description: Istio 1.6 release announcement.
publishdate: 2020-05-21
release: 1.6.0
skip_list: true
aliases:
    - /news/announcing-1.6.0
    - /news/announcing-1.6
---

We are pleased to announce the release of Istio 1.6!

{{< relnote >}}

With this release, we continue the path we charted earlier this year in
our [roadmap post](/blog/2020/tradewinds-2020/), sailing toward more
simplicity, a better installation experience, and we have added other goodies as
well.

Here’s some of what’s coming to you in today's release:

## Simplify, simplify, simplify

Last release, we introduced **Istiod**, a new module that reduced the number of
components in an Istio installation by combining the functionality of several
services. In Istio 1.6, we have completed this transition and have fully
moved functionality into Istiod. This has allowed us to remove the separate
deployments for Citadel, the sidecar injector, and Galley.

Great news! We've got a simplified experience for developers who are taking
advantage of a new alpha feature in Kubernetes. If you
use the new `appProtocol` field  (which is Alpha in 1.18) in the Kubernetes
[`EndpointPort`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#endpointport-v1beta1-discovery-k8s-io)
or
[`ServicePort`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#serviceport-v1-core)
API, you will no longer need to append the name field
in your `Service` to denote the protocol.

## Better lifecycle

We continue to make installing and upgrading Istio a better experience. Our
command line tool `istioctl` gives better diagnostic information, has a simpler
install command, and even gives status in color!

Upgrading Istio has been improved as well, in several powerful ways. First, we
now support canarying of the Istio control plane itself. That means you can
install a new version of the control plane alongside the existing version and
selectively have proxies use the new one. Check out this
[blog post](/blog/2020/multiple-control-planes/) for more details on that.

We also have an `istioctl upgrade` command that will perform an in-place
upgrade in your clusters (still giving you the control over updating the proxies
themselves).

Check out the [documentation](/docs/setup/upgrade/) for all of the details on
the new upgrade experience.

## Observe this

Many companies adopt Istio solely to get better observability of distributed
applications, so we continue to invest there. There are too many changes to list
them all here, so please see the [release notes](/news/releases/1.6.x/announcing-1.6/change-notes/)
for the full details. Some
highlights: you'll see more configurability, better
ability to control your trace sampling rates, and updated Grafana dashboards
(and we're even publishing them on [Grafana](https://grafana.com) on the
[Istio org page](https://grafana.com/orgs/istio)).

## Better Virtual Machine support

Expanding our support for workloads not running in Kubernetes was one of the
our major areas of investment for 2020, and we're excited to announce some
great progress here.

For those of you who are adding non-Kubernetes workloads to meshes (for
example, workloads deployed on VMs), the new
[`WorkloadEntry`](/docs/reference/config/networking/workload-entry/) resource
makes that easier than ever. We created this API to give non-Kubernetes
workloads first-class representation in Istio. It elevates a VM or bare metal
workload to the same level as a Kubernetes `Pod`, instead of just an endpoint
with an IP address. You now even have the ability to define a Service that is
backed by both Pods and VMs. Why is that useful? Well, you now have the
ability to have a heterogeneous mix of deployments (VMs and Pods) for the same
service, providing a great way to migrate VM workloads to a Kubernetes
cluster without disrupting traffic to and from it.

VM-based workloads remain a high priority for us, and you can expect to see more
in this area over the coming releases.

## Networking improvements

Networking is at the heart of a service mesh, so we have put in some great
traffic management features as well. Istio has improved
handling of secrets, which provides better support for Kubernetes Ingress.
We are also have enabled Gateway SDS by default for a more secure experience.
And we have added experimental support for the (also experimental)
Kubernetes Service APIs.

## Join the Istio community

As always, there is a lot happening in the
[Community Meeting](https://github.com/istio/community#community-meeting);
join us every other Thursday at 10 AM Pacific. We'd love to have you join the
conversation at [Istio Discuss](https://discuss.istio.io), and you can also join
our [Slack workspace](https://slack.istio.io).

We were very proud to be called out as one of the top five
[fastest growing](https://octoverse.github.com/#top-and-trending-projects)
open source projects in all of GitHub. Want to get involved? Join one of our
[Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)
and help us make Istio even better.
