---
title: "The Evolution of Istio's APIs"
description: "The design principles behind Istio's APIs and how those APIs are evolving."
publishdate: 2019-08-05
attribution: Louis Ryan (Google), Sandeep Parikh (Google)
keywords: [apis,composability,evolution]
target_release: 1.2
---

One of Istio’s main goals has always been, and continues to be, enabling teams to develop abstractions that work best for their specific organization and workloads. Istio provides robust and powerful building blocks for service-to-service networking. Since [Istio 0.1](/news/releases/0.x/announcing-0.1), the Istio team has been learning from production users about how they map their own architectures, workloads, and constraints to Istio’s capabilities, and we’ve been evolving Istio’s APIs to make them work better for you.

## Evolving Istio’s APIs

The next step in Istio’s evolution is to sharpen our focus and align with the roles of Istio’s users. A security admin should be able to interact with an API that logically groups and simplifies security operations within an Istio mesh; the same goes for service operators and traffic management operations.

Taking it a step further, there’s an opportunity to provide improved experiences for beginning, intermediate, and advanced use cases for each role. There are many common use cases that can be addressed with obvious default settings and a better defined initial experience that requires little to no configuration. For intermediate use cases, the Istio team wants to leverage contextual cues from the environment and provide you with a simpler configuration experience. Finally, for advanced scenarios, our goal is to make [easy things easy and hard things possible](https://www.quora.com/What-is-the-origin-of-the-phrase-make-the-easy-things-easy-and-the-hard-things-possible).

To provide these sorts of role-centric abstractions, however, the APIs underneath them must be able to describe all of Istio’s power and capabilities. Historically, Istio’s approach to API design followed paths similar to those of other infrastructure APIs. Istio follows these design principles:

1. The Istio APIs should seek to:
    - Properly represent the underlying resources to which they are mapped
    - Shouldn’t hide any of the underlying resource’s useful capabilities
1. The Istio APIs should also be [composable](https://en.wikipedia.org/wiki/Composability), so end users can combine infrastructure APIs in a way that makes sense for their own needs.
1. The Istio APIs should be flexible: Within an organization, it should be possible to have different representations of the underlying resources and surface the ones that make sense for each individual team.

Over the course of the next several releases we will share our progress as we strengthen the alignment between Istio’s APIs and the roles of Istio users.

## Composability and abstractions

Istio and Kubernetes often go together, but Istio is much more than an add-on to Kubernetes – it is as much a _platform_ as Kubernetes is. Istio aims to provide infrastructure, and surface the capabilities you need in a powerful service mesh. For example, there are platform-as-a-service offerings that use Kubernetes as their foundation, and build on Kubernetes’ composability to provide a subset of APIs to application developers.

The number of objects that must be configured to deploy applications is a concrete example of Kubernetes’ composability. By our count, at least 10 objects need to be configured: `Namespace`, `Service`, `Ingress`, `Deployment`, `HorizontalPodAutoscaler`, `Secret`, `ConfigMap`, `RBAC`, `PodDisruptionBudget`, and `NetworkPolicy`.

It sounds complicated, but not everyone needs to interact with those concepts. Some are the responsibility of different teams like the cluster, network, or security admin teams, and many provide sensible defaults. A great benefit of cloud native platforms and deployment tools is that they can hide that complexity by taking in a small amount of information and configuring those objects for you.

Another example of composability in the networking space can be found in the [Google Cloud HTTP(S) Load Balancer](https://cloud.google.com/load-balancing/docs/https/) (GCLB). To correctly use an instance of the GCLB, six different infrastructure objects need to be created and configured. This design is the result of our 20 years of experience in operating distributed systems and [there is a reason why each one is separate from the others](https://www.youtube.com/watch?v=J5HJ1y6PeyE). But the steps are simplified when you’re creating an instance via the Google Cloud console. We provide the more common end-user/role-specific configurations, and you can configure less common settings later. Ultimately, the goals of infrastructure APIs are to offer the most flexibility without sacrificing functionality.

[Knative](https://knative.dev) is a platform for building, running, and operating serverless workloads that provides a great real-world example of role-centric,
higher-level APIs. [Knative Serving](https://knative.dev/docs/serving/), a component of Knative that builds on Kubernetes and Istio to support deploying and
serving serverless applications and functions, provides an opinionated workflow for application developers to manage routes and revisions of their services.
Thanks to that opinionated approach, Knative Serving exposes a subset of Istio’s networking APIs that are most relevant to application developers via a simplified
[Routes](https://github.com/knative/docs/blob/master/docs/serving/spec/knative-api-specification-1.0.md#route) object that supports revisions and traffic routing,
abstracting Istio’s [`VirtualService`](/docs/reference/config/networking/virtual-service/) and [`DestinationRule`](/docs/reference/config/networking/destination-rule/)
resources.

As Istio has matured, we’ve also seen production users develop workload- and organization-specific abstractions on top of Istio’s infrastructure APIs.

AutoTrader UK has one of our favorite examples of a custom platform built on Istio. In [an interview with the Kubernetes Podcast from Google](https://kubernetespodcast.com/episode/052-autotrader/), Russel Warman and Karl Stoney describe their Kubernetes-based delivery platform, with [cost dashboards using Prometheus and Grafana](https://karlstoney.com/2018/07/07/managing-your-costs-on-kubernetes/). With minimal effort, they added configuration options to determine what their developers want configured on the network, and it now manages the Istio objects required to make that happen. There are countless other platforms being built in enterprise and cloud-native companies: some designed to replace a web of company-specific custom scripts, and some aimed to be a general-purpose public tool. As more companies start to talk about their tooling publicly, we'll bring their stories to this blog.

## What’s coming next

Some areas of improvement that we’re working on for upcoming releases include:

- Installation profiles to set up standard patterns for ingress and egress, with the Istio operator
- Automatic inference of container ports and protocols for telemetry
- Support for routing all traffic by default to constrain routing incrementally
- Add a single global flag to enable mutual TLS and encrypt all inter-pod traffic

Oh, and if for some reason you judge a toolbox by the list of CRDs it installs, in Istio 1.2 we cut the number from 54 down to 23. Why? It turns out that if you have a bunch of features, you need to have a way to configure them all. With the improvements we’ve made to our installer, you can now install Istio using a [configuration](/docs/setup/additional-setup/config-profiles/) that works with your adapters.

All service meshes and, by extension, Istio seeks to automate complex infrastructure operations, like networking and security. That means there will always be complexity in its APIs, but Istio will always aim to solve the needs of operators, while continuing to evolve the API to provide robust building blocks and prioritize flexibility through role-centric abstractions.

We can't wait for you to join our [community](/get-involved/) to see what you build with Istio next!
