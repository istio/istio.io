---
title: Announcing Istio 1.10
linktitle: "1.10"
subtitle: Major Update
description: Istio 1.10 release announcement.
publishdate: 2021-05-18
release: 1.10.0
skip_list: true
aliases:
    - /news/announcing-1.10
    - /news/announcing-1.10.0
---

We’re excited to announce the release of Istio 1.10! We’d like to give a special thanks to our release managers [Sam Naser](https://github.com/Monkeyanator) and [Zhihan Zhang](https://github.com/ZhiHanZ) in addition to the entire Test and Release Working Group for their work on 1.10.

This is our second release of 2021 and like our last few releases we’ve continued to improve Day 2 operations for Istio users.

{{< relnote >}}

{{< tip >}}
Istio 1.10.0 is officially supported on Kubernetes versions `1.18.0` to `1.21.x`.
{{< /tip >}}

A few of this release’s highlights:

## Discovery Selectors

In previous Istio versions, Istio’s control plane has watched and processed updates for all Kubernetes resources it cares about in a cluster. This can be a scalability bottleneck in large clusters or clusters with rapid configuration changes. Discovery Selectors limit the set of resources that Istiod watches for so you can easily ignore changes from namespaces that aren’t a concern for the mesh (e.g. a set of Spark Jobs).

You can think of them as a bit like Istio’s Sidecar API resources but for Istiod itself: a `Sidecar` resource limits the set of configuration that Istiod will send to Envoy. Discovery Selectors limit the set of configurations that Istio will receive and process from Kubernetes.

[Check out the great write-up](/blog/2021/discovery-selectors/) by Lin, Christian, and Harvey for an in-depth walk-through of this new feature!

## Stable Revision Labels

Istio added support for deploying multiple control planes safely with revisions [all the way back in 1.6](/blog/2020/multiple-control-planes/) and we’ve been steadily improving support since. One of the major usability complaints about revisions has been that a lot of namespace relabeling was required to change revisions, because a label mapped directly to a specific Istio control plane deployment.

With revision tags, there’s now a layer of indirection: you can create tags like `canary` and `prod`, label namespaces using those tags as revisions (i.e. `istio.io/rev=prod`), and associate a specific Istiod revision with that tag.

For example, imagine you have two revisions, `1-7-6` and `1-8-0`. You create a revision tag `prod` pointed to revision `1-7-6` and create a revision tag `canary` pointed to the newer `1-8-0` revision.

{{< image width="40%"
    link="/docs/setup/upgrade/canary/revision-tag-1.png"
    caption="Namespaces A and B pointed to 1-7-6, namespace C pointed to 1-8-0"
    >}}

Now, when you’re ready to promote the `1-8-0` revision from `canary` to `prod`, you can re-associate the `prod` tag with the `1-8-0` Istiod revision. Now all namespaces using `istio.io/rev=prod` will use the newer `1-8-0` revision for injection.

{{< image width="40%"
    link="/docs/setup/upgrade/canary/revision-tag-2.png"
    caption="Namespaces A, B, and C pointed to 1-8-0"
    >}}

Check out the [updated Canary Upgrade guide](/docs/setup/upgrade/canary/#stable-revision-labels) for a walk-through you can follow along with!

## Sidecar Networking Changes

In previous Istio releases, Istio has rewritten pod networking to trap traffic from `eth0` and send it to applications on `lo`. Most applications bind to both interfaces and don’t notice any difference; however some applications are specifically written to only expect specific traffic on either interface (e.g. it’s common to expose admin endpoints only on `lo` and never over `eth0`, or for stateful applications to bind only to `eth0`). These applications’ behavior can be impacted by how Istio directs traffic into the pod.

In 1.10, Istio is updating Envoy to send traffic to the application on `eth0` rather than `lo` by default. For new users, this should only be an improvement. For existing users, `istioctl experimental precheck` will identify pods that listen on localhost, and may be impacted, as [IST0143](/docs/reference/config/analysis/ist0143/).

See [the write-up](/blog/2021/upcoming-networking-changes/) by John Howard for a more in depth overview of the change, how and why it might impact you, and how to preserve today’s behavior to enable a seamless migration.

The changes in networking behavior solve a number of problems when using Istio with Kubernetes `StatefulSets`. [Lin, Christian, John and Zhonghu discuss this in a blog post](/blog/2021/statefulsets-made-easier/).

## A Fresh Look for Istio.io

We’ve revamped Istio.io with a totally new look! This is the first major change to Istio’s site since the project launched nearly four years ago (we’ll celebrate that anniversary on May 24th!). We hope these changes help make the site more user-friendly, easier to navigate, and more readable overall.

This effort was sponsored by Google Cloud and we want to send a special thanks to [Craig Box](https://twitter.com/craigbox), [Aizhamal Nurmamat kyzy](https://twitter.com/iamaijamal) and [Srinath Padmanabhan](https://twitter.com/srithreepo) for driving this effort, and to all the folks that helped review and provide feedback to early revisions.

Please give us any feedback you have by filing an issue on the [istio.io repository](https://github.com/istio/istio.io).

## Opening Up Our Design Docs

Beginning on May 20, 2021, Istio design and planning documents will be available without login to everyone on the internet. Previously, viewing them required a Google login and group membership. This change will make sharing technical documentation easier and more open. Files will remain at the same URLs as before, but the Community Drive and its folders will change location. All contributors and Drive members will be contacted this week with the new details.

## Deprecations

Two features are being deprecated in 1.10:

* Kubernetes first party JWT support (`values.global.jwtPolicy=first-party-jwt`) will be removed; it is less secure and intended only for backwards compatibility with older Kubernetes versions.

* The `values.global.arch` option has been superseded by Affinity settings in Kubernetes config.

See the 1.10 [change notes](/news/releases/1.10.x/announcing-1.10/change-notes/) for a more detailed overview of these deprecations.

## Tell Us How We’re Doing

If you have upgraded your service mesh to Istio 1.10, we would like to hear from you!  Please consider taking [this brief (~2 minute) survey](https://docs.google.com/forms/d/e/1FAIpQLSfzonL4euvGgUM7kyXjsucP4UV8mH9M2snKVFQnT-L7eIXp_g/viewform?resourcekey=0-pWz7V0MsuFrdfJ_-NTQwXQ) to help us understand what we’re doing well, and where we still need to improve.
