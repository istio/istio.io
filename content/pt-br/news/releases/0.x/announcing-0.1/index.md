---
title: Introducing Istio
linktitle: 0.1
description: Istio 0.1 announcement.
publishdate: 2017-05-24
subtitle: A robust service mesh for microservices
aliases:
    - /blog/istio-service-mesh-for-microservices.html
    - /blog/0.1-announcement.html
    - /about/notes/older/0.1
    - /blog/2017/0.1-announcement
    - /docs/welcome/notes/0.1.html
    - /about/notes/0.1/index.html
    - /news/2017/announcing-0.1
    - /news/announcing-0.1
---

Google, IBM, and Lyft are proud to announce the first public release of [Istio](/pt-br/): an open source project that provides a uniform way to connect, secure, manage and monitor microservices. Our current release is targeted at the [Kubernetes](https://kubernetes.io/) environment; we intend to add support for other environments such as virtual machines and Cloud Foundry in the coming months.
Istio adds traffic management to microservices and creates a basis for value-add capabilities like security, monitoring, routing, connectivity management and policy.  The software is built using the battle-tested [Envoy](https://envoyproxy.github.io/envoy/) proxy from Lyft, and gives visibility and control over traffic *without requiring any changes to application code*. Istio gives CIOs a powerful tool to enforce security, policy and compliance requirements across the enterprise.

## Background

Writing reliable, loosely coupled, production-grade applications based on microservices can be challenging. As monolithic applications are decomposed into microservices, software teams have to worry about the challenges inherent in integrating services in distributed systems: they must account for service discovery, load balancing, fault tolerance, end-to-end monitoring, dynamic routing for feature experimentation, and perhaps most important of all, compliance and security.

Inconsistent attempts at solving these challenges, cobbled together from libraries, scripts and Stack Overflow snippets leads to solutions that vary wildly across languages and runtimes, have poor observability characteristics and can often end up compromising security.

One solution is to standardize implementations on a common RPC library like [gRPC](https://grpc.io), but this can be costly for organizations to adopt wholesale
and leaves out brownfield applications which may be practically impossible to change. Operators need a flexible toolkit to make their microservices secure, compliant, trackable and highly available, and developers need the ability to experiment with different features in production, or deploy canary releases, without impacting the system as a whole.

## Solution: service mesh

Imagine if we could transparently inject a layer of infrastructure between a service and the network that gives operators the controls they need while freeing developers from having to bake solutions to distributed system problems into their code. This uniform layer of infrastructure combined with service deployments is commonly referred to as a **_service mesh_**. Just as microservices help to decouple feature teams from each other, a service mesh helps to decouple operators from application feature development and release processes. Istio turns disparate microservices into an integrated service mesh by systemically injecting a proxy into the network paths among them.

Google, IBM and Lyft joined forces to create Istio from a desire to provide a reliable substrate for microservice development and maintenance, based on our common experiences building and operating massive scale microservices for internal and enterprise customers. Google and IBM have extensive experience with these large scale microservices in their own applications and with their enterprise customers in sensitive/regulated environments, while Lyft developed Envoy to address their internal operability challenges. [Lyft open sourced Envoy](https://eng.lyft.com/announcing-envoy-c-l7-proxy-and-communication-bus-92520b6c8191) after successfully using it in production for over a year to manage more than 100 services spanning 10,000 VMs, processing 2M requests/second.

## Benefits of Istio

**Fleet-wide Visibility**: Failures happen, and operators need tools to stay on top of the health of clusters and their graphs of microservices. Istio produces detailed monitoring data about application and network behaviors that is rendered using [Prometheus](https://prometheus.io/) & [Grafana](https://github.com/grafana/grafana), and can be easily extended to send metrics and logs to any collection, aggregation and querying system. Istio enables analysis of performance hotspots and diagnosis of distributed failure modes with [Zipkin](https://github.com/openzipkin/zipkin) tracing.

{{< image link="./istio_grafana_dashboard-new.png" caption="Grafana Dashboard with Response Size" >}}

{{< image link="./istio_zipkin_dashboard.png" caption="Zipkin Dashboard" >}}

**Resiliency and efficiency**: When developing microservices, operators need to assume that the network will be unreliable. Operators can use retries, load balancing, flow-control (HTTP/2), and circuit-breaking to compensate for some of the common failure modes due to an unreliable network. Istio provides a uniform approach to configuring these features, making it easier to operate a highly resilient service mesh.

**Developer productivity**: Istio provides a significant boost to developer productivity by letting them focus on building service features in their language of choice, while Istio handles resiliency and networking challenges in a uniform way. Developers are freed from having to bake solutions to distributed systems problems into their code. Istio further improves productivity by providing common functionality supporting A/B testing, canarying, and fault injection.

**Policy Driven Ops**: Istio empowers teams with different areas of concern to operate independently. It decouples cluster operators from the feature development cycle, allowing improvements to security, monitoring, scaling, and service topology to be rolled out *without* code changes. Operators can route a precise subset of production traffic to qualify a new service release. They can inject failures or delays into traffic to test the resilience of the service mesh, and set up rate limits to prevent services from being overloaded. Istio can also be used to enforce compliance rules, defining ACLs between services to allow only authorized services to talk to each other.

**Secure by default**: It is a common fallacy of distributed computing that the network is secure. Istio enables operators to authenticate and secure all communication between services using a mutual TLS connection, without burdening the developer or the operator with cumbersome certificate management tasks. Our security framework is aligned with the emerging [SPIFFE](https://spiffe.github.io/) specification, and is based on similar systems that have been tested extensively inside Google.

**Incremental Adoption**: We designed Istio to be completely transparent to the services running in the mesh, allowing teams to incrementally adopt features of Istio over time. Adopters can start with enabling fleet-wide visibility and once they’re comfortable with Istio in their environment they can switch on other features as needed.

## Join us in this journey

Istio is a completely open development project. Today we are releasing version 0.1, which works in a Kubernetes cluster, and we plan to have major new
releases every 3 months, including support for additional environments. Our goal is to enable developers and operators to rollout and operate microservices
with agility, complete visibility of the underlying network, and uniform control and security in all environments. We look forward to working with the Istio
community and our partners towards these goals, following our [roadmap](/pt-br/about/feature-stages/).

Visit [here](https://github.com/istio/istio/releases) to get the latest released bits.

View the [presentation](/talks/istio_talk_gluecon_2017.pdf) from GlueCon 2017, where Istio was unveiled.

## Community

We are excited to see early commitment to support the project from many companies in the community:
[Red Hat](https://blog.openshift.com/red-hat-istio-launch/) with Red Hat OpenShift and OpenShift Application Runtimes,
Pivotal with [Pivotal Cloud Foundry](https://content.pivotal.io/blog/pivotal-and-istio-advancing-the-ecosystem-for-microservices-in-the-enterprise),
WeaveWorks with [Weave Cloud](https://www.weave.works/blog/istio-weave-cloud/) and Weave Net 2.0,
[Tigera](https://www.projectcalico.org/welcoming-istio-to-the-kubernetes-networking-community) with the Project Calico Network Policy Engine
and [Datawire](https://www.datawire.io/istio-and-datawire-ecosystem/) with the Ambassador project. We hope to see many more companies join us in
this journey.

To get involved, connect with us via any of these channels:

- [istio.io]() for documentation and examples.

- The [Istio discussion board](https://discuss.istio.io) general discussions,

- [Stack Overflow](https://stackoverflow.com/questions/tagged/istio) for curated questions and answers

- [GitHub](https://github.com/istio/istio/issues) for filing issues

- [@IstioMesh](https://twitter.com/IstioMesh) on Twitter

From everyone working on Istio, welcome aboard!

## Release notes

- Installation of Istio into a Kubernetes namespace with a single command.
- Semi-automated injection of Envoy proxies into Kubernetes pods.
- Automatic traffic capture for Kubernetes pods using iptables.
- In-cluster load balancing for HTTP, gRPC, and TCP traffic.
- Support for timeouts, retries with budgets, and circuit breakers.
- Istio-integrated Kubernetes Ingress support (Istio acts as an Ingress Controller).
- Fine-grained traffic routing controls, including A/B testing, canarying, red/black deployments.
- Flexible in-memory rate limiting.
- L7 telemetry and logging for HTTP and gRPC using Prometheus.
- Grafana dashboards showing per-service L7 metrics.
- Request tracing through Envoy with Zipkin.
- Service-to-service authentication using mutual TLS.
- Simple service-to-service authorization using deny expressions.
