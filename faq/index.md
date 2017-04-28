---
title: FAQ
group: 'navigation'

bodyclass: faq
type: markdown
---

# Frequently Asked Questions

#### What is Istio?

Istio is an open platform-independent service mesh that provides traffic management, policy enforcement, and telemetry collection.

*Open*: Istio is being developed and maintained as open-source software. We encourage contributions and feedback from the community at-large.

*Platform-independent*: Istio is not targeted at any specific deployment environment. During the initial stages of development, Istio will support kubernetes-based deployments. However, Istio is being built to enable rapid and easy adaptation to other environments.

*Service mesh*: Istio is designed to manage communications between microservices and applications. Without requiring changes to the underlying services, Istio provides automated baseline traffic resilience, service metrics collection, distributed tracing, traffic encryption, protocol upgrades, and advanced routing functionality for all service-to-service communication.

For more detail, please see: [What is Istio?](/docs/concepts/what-is-istio/)

#### Why would I want to use Istio?

Traditionally, much of the logic handled by Istio has been built directly into applications. Across a fleet of services, managing updates to this communications logic can be a large burden. Istio provides an infrastructure-level solution to managing service communications.

*Application developers*: With Istio managing how traffic flows across their services, developers can focus exclusively on business logic and iterate quickly on new features.

*Service operators*: Istio enables policy enforcement and mesh monitoring from a single centralized control point, independent of application evolution. As a result, operators can ensure continuous policy compliance through a simplified management plane.

#### How do I get started using Istio?

We recommend starting with the [BookInfo sample](/docs/samples/bookinfo.html). The BookInfo example walks through setting up a cluster with four distinct microservices managed by Istio. It exercises some basic features, including content-based routing, fault injection, and rate-limiting.

After you have mastered the BookInfo sample, you are ready to begin using Istio for your own services. To start using Istio on your existing Kubernetes cluster, please refer to our [Installation](/docs/tasks/istio-installation.html) task guide.

#### What is the license?

Istio uses the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0.html).

#### What deployment environments are supported?

Istio is designed and built to be platform-independent. For our initial Alpha release, however, Istio only supports environments running kubernetes v1.5 or greater. 

#### How can I contribute?

Contributions are highly welcome. We look forward to community feedback, additions, and bug reports.

The code repositories are hosted on [GitHub](https://github.com/istio). Please see our [Contribution Guidelines](https://github.com/istio/istio/blob/master/CONTRIBUTING.md) to learn how to contribute.

In addition to the code, there are other ways to contribute to the Istio [community](/community/), including on [Stack Overflow](https://stackoverflow.com/questions/tagged/istio), the [mailing list](https://groups.google.com/forum/#!forum/istio-users), and our [Slack channel](https://istio-dev.slack.com/).

#### Where is the documentation?

Check out the [documentation](/docs/) right here on istio.io. The docs include [concept overviews](/docs/concepts/), [task guides](/docs/tasks/), [samples](/docs/samples/), and the [complete reference documentation](/docs/reference/).

Detailed developer-level documentation is maintained for each component in github, alongside the code. Please visit each repository for those docs:

*   [Envoy](https://lyft.github.io/envoy/docs/)

*   [Manager](https://github.com/istio/manager/tree/master/doc)

*   [Mixer](https://github.com/istio/mixer/tree/master/doc)

#### Istio doesn't work - what do I do?

Follow the [instructions](https://github.com/istio/istio/blob/master/CONTRIBUTING.md#issues) to open an issue [here](https://github.com/istio/istio/issues/new) or ask questions on [slack](https://istio-dev.slack.com/messages/C524NCGR1/).

Our [users mailing list](https://groups.google.com/forum/#!forum/istio-users) is another great way to get help and answers. We also monitor [Stack Overflow](https://stackoverflow.com/questions/tagged/istio) for questions tagged with "istio".

Additionally, we provide [Reference Guides](/docs/reference/) for all of the Istio components. These can be helpful when troubleshooting issues with configuration, etc.

#### What does the Alpha release cover?

Istio's Alpha release provides an early preview of the intended functionality and user experience of our service mesh. We are hoping to solicit 
early feedback on direction and design decisions.

The Alpha release includes the following features:

*   Simple command-line installation into a kubernetes cluster

*   Scripted proxy injection with traffic capture via iptables

*   L7 traffic routing rules

*   In-cluster load balancing for HTTP, gRPC & TCP

*   Cluster Ingress and Egress

*   Fault injection

*   In-memory rate limiting

*   L7 Metrics and Logs collection

*   Secure service-to-service authentication with strong identity

*   Pluggable policy layer and configuration API

#### Does Istio Auth support authorization?

Not currently - but we are working on it. At the moment, we only support the kubernetes service account as the principal identity in Istio Auth. We are investigating using [JWT](https://jwt.io/) together with mutual TLS to support enhanced authentication and authorization.

#### Does Istio Auth use kubernetes secrets?

Yes. The key and certificate distribution in Istio Auth is based on [kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

Secrets have known [security risks](https://kubernetes.io/docs/concepts/configuration/secret/#risks). The kubernetes team is working on [several features](https://docs.google.com/document/d/1T2y-9geg9EfHHtCDYTXptCa-F4kQ0RyiH-c_M1SyD0s) to improve kubernetes secret security, from secret encryption to node-level access control. And as of version 1.6, kubernetes introduces [RBAC authorization](https://kubernetes.io/docs/admin/authorization/rbac/), which can provide fine-grained secrets management.

#### What kind of traffic does Istio Auth support?

For Alpha, we only support HTTP traffic. And we are actively working on supporting more kinds of traffic like SQL, etc.

#### What is Istio's roadmap?

Istio's initial Alpha release will be in May of 2017. The Alpha release is to get early feedback and provide a glimpse into what we're planning.

We are planning a Beta release later in 2017 which will be suitable for use in production environments.

#### What does the word 'Istio' mean?

It's the Greek word for 'sail'.
