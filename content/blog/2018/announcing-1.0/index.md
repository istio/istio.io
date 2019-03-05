---
title: Announcing Istio 1.0
subtitle: The production ready service mesh
description: Istio is ready for production use with its 1.0 release.
publishdate: 2018-07-31
attribution: The Istio Team
---

Today, we’re excited to announce [Istio 1.0](/about/notes/1.0). It’s been a little over a year since our initial 0.1 release. Since then, Istio has evolved significantly with the help of a thriving and growing community of contributors and users. We’ve now reached the point where many companies have successfully adopted Istio in production and have gotten real value from the insight and control it provides over their deployments. We’ve helped large enterprises and fast-moving startups like [eBay](https://www.ebay.com/), [Auto Trader UK](https://www.autotrader.co.uk/), [Descartes Labs](http://www.descarteslabs.com/), [HP FitStation](https://www.fitstation.com/), [JUSPAY](https://juspay.in), [Namely](https://www.namely.com/), [PubNub](https://www.pubnub.com/) and [Trulia](https://www.trulia.com/) use Istio to connect, manage and secure their services from the ground up. Shipping this release as 1.0 is recognition that we’ve built a core set of functionality that our users can rely on for production use.

## Ecosystem

We’ve seen substantial growth in Istio's ecosystem in the last year. [Envoy](https://www.envoyproxy.io/) continues its impressive growth and added numerous
features that are crucial for a production quality service mesh. Observability providers like [Datadog](https://www.datadoghq.com/),
[SolarWinds](https://www.solarwinds.com/), [Sysdig](https://sysdig.com/blog/monitor-istio/), [Google Stackdriver](https://cloud.google.com/stackdriver/) and
[Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) have written plugins to integrate Istio with their products.
[Tigera](https://www.tigera.io/resources/using-network-policy-concert-istio-2/), [Aporeto](https://www.aporeto.com/), [Cilium](https://cilium.io/)
and [Styra](https://styra.com/) built extensions to our policy enforcement and networking capabilities. [Red Hat](https://www.redhat.com/en) built [Kiali](https://www.kiali.io) to wrap a nice user-experience around mesh management and observability. [Cloud Foundry](https://www.cloudfoundry.org/) is building on  Istio for it’s next generation traffic routing stack, the recently announced [Knative](https://github.com/knative/docs) serverless project is doing the same and [Apigee](https://apigee.com/) announced that they plan to use it in their API management solution. These are just some of the integrations the community has added in the last year.

## Features

Since the 0.8 release we’ve added some important new features and more importantly marked many of our existing features as Beta signaling that they’re ready for production use. This is captured in more detail in the [release notes](/about/notes/1.0/)  but it’s worth calling out some highlights

* Multiple Kubernetes clusters can now be [added to a single mesh](/docs/setup/kubernetes/multicluster/) and enabling cross-cluster communication and consistent policy enforcement. Multi-cluster support is now Beta.

* Networking APIs that enable fine grained control over the flow of traffic through a mesh are now Beta. Explicitly modeling ingress and egress concerns using Gateways allows operators to [control the network topology](/blog/2018/v1alpha3-routing/) and meet access security requirements at the edge.

* Mutual TLS can now be [rolled out incrementally](/docs/tasks/security/mtls-migration) without requiring all clients of a service to be updated. This is a critical feature that unblocks adoption in-place by existing production deployments.

* Mixer now has support for [developing out-of-process adapters](https://github.com/istio/istio/wiki/Out-Of-Process-gRPC-Adapter-Dev-Guide). This will become the default way to extend Mixer over the coming releases and makes building adapters much simpler.

* [Authorization policies](/docs/concepts/security/#authorization) which control access to services are now entirely evaluated locally in Envoy increasing
their performance and reliability.

* [Helm chart installation](/docs/setup/kubernetes/install/helm/) is now the recommended install method offering rich customization options to adopt Istio on your terms.

* We’ve put a lot of effort into performance including continuous regression testing, large scale environment simulation and targeted fixes. We’re very happy with the results and will share more on this in detail in the coming weeks.

## What’s next?

While this is a significant milestone for the project there’s lots more to do. In working with adopters we’ve gotten a lot of great feedback about what to focus next. We’ve heard consistent themes around support for hybrid-cloud, install modularity, richer networking features and scalability for massive deployments. We’ve already taken some of this feedback into account in the 1.0 release and we’ll continue to aggressively tackle this work in the coming months.

## Getting Started

If you’re new to Istio and looking to use it for your deployment we’d love to hear from you. Take a look at [our docs](/docs/) or stop by our
[chat forum](https://discuss.istio.io). If you’d like
to go deeper and [contribute to the project](/about/community) come to one of our community meetings and say hello.

## Finally

The Istio team would like to give huge thanks to everyone who has made a contribution to the project. It wouldn’t be where it is today without your help. The last year has been pretty amazing and we look forward to the next one with excitement about what we can achieve together as a community.
