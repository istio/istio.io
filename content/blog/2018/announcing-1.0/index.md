---
title: Announcing Istio 1.0
description: Istio 1.0
publishdate: 2018-07-31
weight: 84
attribution: The Istio Team
---

Today, we’re excited to announce [Istio 1.0](/about/notes/1.0). It’s been a little over a year since our initial 0.1 release. Since then,
Istio has evolved significantly with the help of a thriving and growing community of contributors and users. We’ve now reached the point
where many companies have successfully adopted Istio in production and have gotten real value from the insight and control that it provides
over their deployments. We’ve helped large enterprises and fast-moving startups like
[[List off reference customers here]]
use Istio to connect, manage and secure their services from the ground up. The 1.0 release has focused on platform and feature
stability as well as improvements in performance. We have introduced a [performance regression framework]https://ibmcloud-perf.istio.io/regpatrol/)
that conducts performance tests for each release looking for regressions in performance. Also, stay tuned for a more comprehensive Istio performance
report due to be released soon. Shipping this release as 1.0 is recognition that we’ve built a stable set of functionality that our users can rely on
for production use.

We’ve also seen growth in the ecosystem around Istio. Observability providers like [Sysdig](https://sysdig.com/blog/monitor-istio/)], Datadog, and Solarwinds to
name a few, have written plugins to integrate with their products. Cilium [[link]], Tigera & Styra
[[link]] provided extensions to our networking and security capabilities. RedHat built [Kiali](https://www.kiali.io) to provide a nice
user-experience around mesh management and observability.

Our early adopters range from startups to large enterprises. The clients are using Istio to Our biggest motivation comes from the fact that Istio is helping
them to solve complex microservices challenges with an ease. For us, Istio 1.0 is a recognition that our community has built a stable set of features that our
users can rely on. We are continually amazed by the new set of features and integrations coming out of Istio.

Here are few key features we launched in 1.0 release

Since the 0.8 release we’ve added some important new features and more importantly marked many of our existing features as Beta signalling that they’re ready for production use. This is captured in more detail in the release notes [[link]] but here are some highlights:

* Multi-cluster support allows for enrolling multiple Kubernetes clusters into a single mesh. This feature is now Beta.

* Mutual TLS can now be rolled out incrementally without requiring all clients of a service to be updated. This is a critical feature that unblocks adoption for large existing production deployments.

* Opaque TLS traffic can now be routed by host names specified in the SNI header.

### Multicluster

The first big change we are excited to announce is multi-cluster support. It functions by enabling Kubernetes control planes running a remote configuration to connect to one Istio control plane. Once one or more remote Kubernetes clusters are connected to the Istio control plane, Envoy can then communicate with the single Istio control plane and form a mesh network across multiple Kubernetes clusters.

### Support for v1alpha3 APIs

So far, Istio has provided a simple API for traffic management using four configuration resources like RouteRule, DestinationPolicy, EgressRule, and (Kubernetes) Ingress. This APIs has proven to be a very compelling part of Istio, however user feedback has also shown that this API does have some shortcomings, specifically when using it to manage very large applications containing thousands of services, and when working with protocols other than HTTP. To address these, and other concerns, a new traffic management API, called v1alpha3, is being introduced, which will completely replace the previous API going forward. The Istio v1alpha3 routing API has significantly more functionality than its predecessorWith v1alpha3 we have resources like DestinationPolicies, VirtualServices, ServiceEntry and Gateway.

### Upgrading Istio versions

Istio is built on the sidecar model – every pod in the mesh has an Envoy sidecar proxy running right alongside it to add the service mesh smarts. All traffic to and from the application container goes through the sidecar first. Previous versions of Istio let you inject sidecar manually or at the time that the kubernetes deployment was created. The drawback of deployment-time injection comes when you want to upgrade your service mesh to run a newer version of the sidecar.  You either have to patch the deployments in your cluster, or delete and then recreate them.

With 1.0, you can use a MutatingWebhook Pod Admission Controller. Whenever Kubernetes is about to create a pod, it lets its pod admission controllers take a look and decide to allow, reject or allow-with-changes that pod. Every admission controller gets a shot.  Istio provides one of these admission controllers that injects the current sidecar and init container. This make it easier to upgrade the service mesh.

### Pilot scalability

One of the issues in the earlier version of Istio was degrading pilot performance as number of service grows. When you make changes in the cluster like add/remove services, add/remove pods etc., each time Istio has to apply new pilot configurations. On top of that, each sidecar had to pull the changes from the pilot. This pull model slow down the performance if you have to do it for lot of services. The new v3 config APIs were added to pilot using the new Envoy v2 config APIs which uses a push model instead of pull. This change improved a performance dramatically compared to earlier version.

### Better external service support

In the earlier version of Istio, if you wanted a service in the mesh to communicate with a TLS service outside the mesh, you had to modify your service to speak http over port 443, so that istio could route it correctly. Now, that Istio can use SNI to route traffic, you can leave your service alone, and configure Istio to allow it to communicate with that external service by hostname. Since this is TLS passthrough, you don’t get L7 visibility of the egress traffic, but since you don’t need to modify your service, it allows you to add services to the mesh that you might not have been able to before.

## So Istio is complete now?

Absolutely not. In fact, we feel we're just getting started. We have a long roadmap ahead of us, full of great features to implement. Istio will not stay in 1.x for time to come. The microservices space is evolving rapidly and we fully intend for Istio to evolve with it. This means that we will remain willing to question what we did in the past and are open to leave behind things that have lost relevance. There will be new major versions of Istio to facilitate future plans.

## Closing thoughts

We want to thank our fantastic community for field testing new versions, filing bug reports, contributing code, helping out other community members, and shaping Istio by participating in countless productive discussions. In the end, you are the ones who make Istio successful.

