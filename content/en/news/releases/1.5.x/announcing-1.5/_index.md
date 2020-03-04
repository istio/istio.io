---
title: Announcing Istio 1.5
linktitle: 1.5
subtitle: Major Update
description: Istio 1.5 release announcement.
publishdate: 2020-o2-11
release: 1.5.0
skip_list: true
aliases:
    - /news/announcing-1.5.0
    - /news/announcing-1.5
---

We are pleased to announce the release of Istio 1.5!

{{< relnote >}}

We've made it simpler to
install and run Istio by consolidating the control plane components into a
single binary; we've introduced a powerful and fast new extension model for
proxy servers across the industry, and we've continued to improve usability,
security, telemetry and traffic control.

After a year of amazing growth and learning, we have packed more in this release
than any since 1.1.  A year ago we decided to move to quarterly releases, and
we are happy to report that this is the fifth consecutive time we have met that
goal. Users are getting more new functionality faster than ever!

Here’s some of what’s coming to you in today's release:

## Introducing `istiod`

We are dramatically simplifying the experience of installing, running, and
upgrading Istio by “embracing the monolith” and consolidating our control plane
into a single new binary - `istiod`. Operators' lives will get much easier with
fewer moving parts which are easier to debug and understand.  For mesh users,
`istiod` doesn’t change any of their experience: all APIs and runtime
characteristics are consistent with the previous components.

Keep your eyes out for a blog post in the coming days devoted to `istiod`, and
the benefits of moving to a simpler deployment model.

## A new model for extensibility

Istio has long been the most extensible service mesh, with Mixer plugins
allowing custom policy and telemetry support and Envoy extensions allowing data
plane customization. In Istio 1.5 we’re announcing a new model that unifies
Istio’s extensibility model with Envoy’s, using
[WebAssembly](https://webassembly.org/) (Wasm). Wasm will give developers the
ability to safely distribute and execute code in the Envoy proxy -- to integrate
with telemetry systems, policy systems, control routing and even transform the
body of a message. It will be more flexible and more efficient, eliminating the
need for running a Mixer component separately (which also simplifies
deployments).

Look for blog posts here and from Google, Solo.io and the Envoy community for
much more detail about this exciting work!

## Easier to use

We’re always making Istio easier to adopt and use, and this release in
particular has some cool enhancements. Command line installation of Istio using
[`istioctl`](/docs/reference/commands/istioctl) is now beta for installation and
will work for most customers in most use cases. Managing your installation via
an Operator is still alpha, but we continue to improve it with a new
[`IstioOperator API`](/docs/reference/config/istio.operator/).

Speaking of `istioctl`, it has over a dozen improvements -- new items it can
analyze, better validation rules, and better ability to integrate with CI
systems (look for examples coming soon!). It is
now an essential tool for understanding the state of a running Istio system and
for ensuring that configuration changes are safe. And `istioctl analyze` has
graduated from the Experimental to the Alpha stage.

We have made numerous enhancements to Istio security to make it easier to use.
mTLS configuration is simplified and automated with the Beta launch of auto
mTLS.  We have simplified access control by removing indirection and
consolidating to a single CRD with the beta launch of authorization policy in
Istio 1.4.

## More secure

As always, we are working to make Istio more secure with every release. With
1.5, all security policies including
[Auto mutual-TLS](docs/tasks/security/authentication/auto-mtls/),
[AuthenicationPoli
y](/docs/reference/config/security/istio.authentication.v1alpha1/)
(PeerAuthentication and RequestAuthentication) and authorization are now in
Beta. SDS is now stable. Authorization now supports Deny semantics to enforce
mandatory controls that cannot be overridden. We have combined the Node agent
and the Istio agent into a single binary, which means we no longer require
PodSecurityPolicy.

Look for blog posts in the coming days for a deeper dive on Istio security and
the threats that it helps mitigate.

## Better observability

We continue to invest in making Istio the best way to understand your
distributed applications. Telemetry v2 now reports metrics for raw TCP
connections, and we’ve enhanced the support for gRPC workloads by adding
response status codes in telemetry and logs.

The new telemetry system cuts latency in half - 90th percentile latency has been
reduced from 7ms to 3.3 ms. Not only that, but the elimination of Mixer has
reduced total CPU consumption by 50% to 0.55 vCPUs per 1,000 requests per
second.

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
