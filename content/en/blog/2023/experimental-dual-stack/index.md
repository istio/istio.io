---
title: "Support for Dual Stack Kubernetes Clusters"
description: "Experimental support for Dual Stack Kubernetes Clusters."
publishdate: 2023-02-20
attribution: "Steve Zhang (Intel), Alex Xu (Intel), Iris Ding (Intel), Jacob Delgado (F5), Ying-chun Cai (formerly F5)"
keywords: [dual-stack]
---

Over the past year, both Intel and F5 have collaborated on an effort to bring support for
[Kubernetes Dual-Stack networking](https://kubernetes.io/docs/concepts/services-networking/dual-stack/) to Istio.

## Background

The journey has taken us longer than anticipated and we continue to have work to do. The team initially started with a design based
on a reference implementation from F5. The design led to an [RFC](https://docs.google.com/document/d/1oT6pmRhOw7AtsldU0-HbfA0zA26j9LYiBD_eepeErsQ/edit?usp=sharing) that
caused us to re-examine our approach. Notably, there were concerns about memory and performance issues that the community wanted
to be addressed before implementation.

## Experimental Dual Stack branch

While the team was re-evaluating the options, we created a new branch, [experimental-dual-stack]({{< github_raw >}}/tree/experimental-dual-stack),
to experiment and implement the reference design. We will detail how to use and install artifacts
from that branch in an upcoming blog, however, be aware that its initial intent was to learn how to approach development
in a way that we can implement a big impacting feature within Istio without causing regressions to single stack clusters.
It was also branched between Istio 1.13 and 1.14 and hasn't kept up to date with the master branch. Using artifacts built
from this branch would be considered highly experimental. While the branch builds locally, it fails the CI pipeline when
another PR is added. With that said, there are still people and companies that are using artifacts from this branch
in both staging and production environments.

The original design was created with customer requirements that specified client originating IPv4 requests should be proxied over IPv4, and the same for an originating IPv6 requests to be satisfied over IPv6 (we will refer to this as native IP family going forward). To do this, we initially had to duplicate Envoy configuration for listeners, clusters, routes and endpoints. Given that many people already experience Envoy memory and CPU consumption issues, early feedback wanted us to completely re-evaluate this approach. Many proxies transparently handle outbound dual-stack traffic regardless of how the traffic was originated. Much of the earliest feedback was to implement the same behavior in Istio and Envoy.

## Redefining Dual Stack Support

Much of the feedback provided by the community for the original RFC was to update Envoy to better support dual-stack use cases
internally instead of supporting this within Istio. This has led us to a [new design](https://docs.google.com/document/d/15LP2XHpQ71ODkjCVItGacPgzcn19fsVhyE7ruMGXDyU/edit?usp=sharing)
where we have taken lessons learned as well as feedback and have applied them to fit a simplified design.

## Support for Dual Stack in Istio 1.17

We have worked with the Envoy community to address numerous concerns which is a reason why dual-stack enablement has
taken us a while to implement. We have implemented [matched IP Family for outbound listener](https://github.com/envoyproxy/envoy/issues/16804)
and [supported multiple addresses per listener](https://github.com/envoyproxy/envoy/issues/11184). Alex Xu has also
been working fervently to get long outstanding issues resolved, with the ability for Envoy to have a
[smarter way to pick endpoints for dual-stack](https://github.com/envoyproxy/envoy/issues/21640). Some of these improvements
to Envoy, such as the ability to [enable socket options on multiple addresses](https://github.com/envoyproxy/envoy/pull/23496),
have landed in the Istio 1.17 release (e.g. [extra source addresses on inbound clusters](https://github.com/istio/istio/pull/41618)).

The Envoy API changes made by the team can be found at their site at [Listener addresses](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener.proto.html?highlight=additional_addresses)
and [bind config](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/address.proto#config-core-v3-bindconfig).
Making sure we can have proper support at both the downstream and upstream connection for Envoy is important for realizing
dual-stack support.

In total the team has submitted over a dozen PRs to Envoy and are working on at least a half dozen more to make Envoy adoption of
dual stack easier for Istio.

Meanwhile, on the Istio side you can track the progress in [Issue #40394](https://github.com/istio/istio/issues/40394).
Progress has slowed down a bit lately as we continue working with Envoy on various issues, however, we are happy to
announce experimental support for dual stack in Istio 1.17!

### Get involved

Plenty of work remains and you are welcome to help us with the remaining tasks needed for dual stack support to get to Alpha [here](https://github.com/istio/enhancements/pull/141).

For instance, Iris Ding (Intel) and Li Chun (Intel) are already working with the community for getting redirection of
network traffic for ambient and we are hoping to have ambient support dual stack for its upcoming alpha release in
Istio 1.18.

We would love your feedback and if you are eager to work with us please stop by our slack channel, #dual-stack within
the [Istio Slack](https://slack.istio.io/).

_Thank you to the team that has worked on Istio dual-stack!_
* Intel: [Steve Zhang](https://github.com/zhlsunshine), [Alex Xu](https://github.com/soulxu), [Iris Ding](https://github.com/irisdingbj)
* F5: [Jacob Delgado](https://github.com/jacob-delgado)
* [Yingchun Cai](https://github.com/ycai-aspen) (formerly of F5)
