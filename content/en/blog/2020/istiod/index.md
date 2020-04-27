---
title: "Introducing istiod: simplifying the control plane"
subtitle: Consolidating Istio components into ‘istiod’ simplifies mesh operability, while retaining Istio’s powerful functionality
description: Istiod consolidates the Istio control plane components into a single binary.
publishdate: 2020-03-19
attribution: "Craig Box (Google)"
keywords: [istiod,control plane,operator]
---

Microservices are a great pattern when they map services to disparate teams that deliver them, or when the value of independent rollout and the value of independent scale are greater than the cost of orchestration. We regularly talk to customers and teams running Istio in the real world, and they told us that none of these were the case for the Istio control plane. So, in Istio 1.5, we've changed how Istio is packaged, consolidating the control plane functionality into a single binary called **istiod**.

## History of the Istio control plane

Istio implements a pattern that has been in use at both Google and IBM for many years, which later became known as "service mesh". By pairing client and server processes with proxy servers, they act as an application-aware _data plane_ that’s not simply moving packets around hosts, or pulses over wires.

This pattern helps the world come to terms with _microservices_: fine-grained, loosely-coupled services connected via lightweight protocols. The common cross-platform and cross-language standards like HTTP and gRPC that replace proprietary transports, and the widespread presence of the needed libraries, empower different teams to write different parts of an overall architecture in whatever language makes the most sense. Furthermore, each service can scale independently as needed. A desire to implement security, observability and traffic control for such a network powers Istio’s popularity.

Istio's _control plane_ is, itself, a modern, cloud-native application. Thus, it was built from the start as a set of microservices. Individual Istio components like service discovery (Pilot), configuration (Galley), certificate generation (Citadel) and extensibility (Mixer) were all written and deployed as separate microservices.  The need for these components to communicate securely and be observable, provided opportunities for Istio to eat its own dogfood (or "drink its own champagne", to use a more French version of the metaphor!).

## The cost of complexity

Good teams look back upon their choices and, with the benefit of hindsight, revisit them. Generally, when a team adopts microservices and their inherent complexity, they look for improvements in other areas to justify the tradeoffs. Let's look at the Istio control plane through that lens.

- **Microservices empower you to write in different languages.** The data plane (the Envoy proxy) is written in C++, and this boundary benefits from a clean separation in terms of the xDS APIs. However, all of the Istio control plane components are written in Go. We were able to choose the appropriate language for the appropriate job: highly performant C++ for the proxy, but accessible and speedy-development for everything else.

- **Microservices empower you to allow different teams to manage services individually.**. In the vast majority of Istio installations, all the components are installed and operated by a single team or individual. The componentization done within Istio is aligned along the boundaries of the development teams who build it.  This would make sense if the Istio components were delivered as a managed service by the people who wrote them, but this is not the case! Making life simpler for the development teams had an outsized impact of the usability for the orders-of-magnitude more users.

- **Microservices empower you to decouple versions, and release different components at different times.** All the components of the control plane have always been released at the same version, at the same time.  We have never tested or supported running different versions of (for example) Citadel and Pilot.

- **Microservices empower you to scale components independently.** In Istio 1.5, control plane costs are dominated by a single feature: serving the Envoy xDS APIs that program the data plane. Every other feature has a marginal cost, which means there is very little value to having those features in separately-scalable microservices.

- **Microservices empower you to maintain security boundaries.** Another good reason to separate an application into different microservices is if they have different security roles. Multiple Istio microservices like the sidecar injector, the Envoy bootstrap, Citadel, and Pilot hold nearly equivalent permissions to change the proxy configuration. Therefore, exploiting any of these services would cause near equivalent damage. When you deploy Istio, all the components are installed by default into the same Kubernetes namespace, offering limited security isolation.

## The benefit of consolidation: introducing istiod

Having established that many of the common benefits of microservices didn't apply to the Istio control plane, we decided to unify them into a single binary: **istiod** (the 'd' is for [daemon](https://en.wikipedia.org/wiki/Daemon_%28computing%29)).

Let's look at the benefits of the new packaging:

- **Installation becomes easier.** Fewer Kubernetes deployments and associated configurations are required, so the set of configuration options and flags for Istio is reduced significantly. In the simplest case, **_you can start the Istio control plane, with all features enabled, by starting a single Pod._**

- **Configuration becomes easier.** Many of the configuration options that Istio has today are ways to orchestrate the control plane components, and so are no longer needed. You also no longer need to change cluster-wide `PodSecurityPolicy` to deploy Istio.

- **Using VMs becomes easier.** To add a workload to a mesh, you now just need to install one agent and the generated certificates. That agent connects back to only a single service.

- **Maintenance becomes easier.** Installing, upgrading, and removing Istio no longer require a complicated dance of version dependencies and startup orders. For example: To upgrade, you only need to start a new istiod version alongside your existing control plane, canary it, and then move all traffic over to it.

- **Scalability becomes easier.** There is now only one component to scale.

- **Debugging becomes easier.** Fewer components means less cross-component environmental debugging.

- **Startup time goes down.** Components no longer need to wait for each other to start in a defined order.

- **Resource usage goes down and responsiveness goes up.** Communication between components becomes guaranteed, and not subject to gRPC size limits. Caches can be shared safely, which decreases the resource footprint as a result.

istiod unifies functionality that Pilot, Galley, Citadel and the sidecar injector previously performed, into a single binary.

A separate component, the istio-agent, helps each sidecar connect to the mesh by securely passing configuration and secrets to the Envoy proxies. While the agent, strictly speaking, is still part of the control plane, it runs on a per-pod basis. We’ve further simplified by rolling per-node functionality that used to run as a DaemonSet, into that per-pod agent.

## Extra for experts

There will still be some cases where you might want to run Istio components independently, or replace certain components.

Some users might want to use a Certificate Authority (CA) outside the mesh, and we have [documentation on how to do that](/docs/tasks/security/plugin-ca-cert/). If you do your certificate provisioning using a different tool, we can use that instead of the built-in CA.

## Moving forward

At its heart, istiod is just a packaging and optimization change.  It's built on the same code and API contracts as the separate components, and remains covered by our comprehensive test suite.  This gives us confidence in making it the default in Istio 1.5. The service is now called `istiod` - you’ll see an `istio-pilot` for existing proxies as the upgrade process completes.

While the move to istiod may seem like a big change, and is a huge improvement for the people who _administer_ and _maintain_ the mesh, it won’t make the day-to-day life of _using_ Istio any different. istiod is not changing any of the APIs used to configure your mesh, so your existing processes will all stay the same.

Does this change imply that microservice are a mistake for _all_ workloads and architectures? Of course not. They are a tool in a toolbelt, and they work best when they are reflected in your organizational reality. Instead, this change shows a willingness in the project to change based on user feedback, and a continued focus on simplification for all users. Microservices have to be right sized, and we believe we have found the right size for Istio.
