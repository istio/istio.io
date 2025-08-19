---
title: "Extending Gateway API support in Istio"
description: "A standard API for service mesh, in Istio and in the broader community."
publishdate: 2022-07-13
attribution: "Craig Box (Google)"
keywords: [traffic-management,gateway,gateway-api,api,gamma,sig-network]
---

Today we want to [congratulate the Kubernetes SIG Network community on the beta release of the Gateway API specification](https://kubernetes.io/blog/2022/07/13/gateway-api-graduates-to-beta/). Alongside this milestone, we are pleased to announce that support for using the Gateway API in Istio ingress is being promoted to Beta, and our intention for the Gateway API to become the default API for all Istio traffic management in the future. We are also excited to welcome our friends from the Service Mesh Interface (SMI) community, who are joining us in a new effort to standardize service mesh use cases using the Gateway API.

## The history of Istio's traffic management APIs

API design is more of an art than a science, and Istio is often used as an API to configure the serving of other APIs! In the case of traffic routing alone, we must consider producer vs consumer, routing vs. post-routing, and how to express a complex feature set with the correct number of objects — factoring in that these must be owned by different teams.

When we launched Istio in 2017, we brought many years of experience from Google's production API serving infrastructure and IBM's Amalgam8 project, and mapped it onto Kubernetes. We soon came up against the limitations of Kubernetes' Ingress API. A desire to support all proxy implementations meant that Ingress only supported the most basic of HTTP routing features, with other features often implemented as vendor-specific annotations. The Ingress API was shared between infrastructure admins ("create and configure a load balancer"), cluster operators ("manage a TLS certificate for my entire domain") and application users ("use it to route /foo to the foo service").

We [rewrote our traffic APIs in early 2018](/blog/2018/v1alpha3-routing/) to address user feedback, and to more adequately address these concerns.

A primary feature of Istio's new model was having separate APIs that describe infrastructure (the load balancer, represented by the [Gateway](/docs/concepts/traffic-management/#gateways)), and application (routing and post-routing, represented by the [VirtualService](/docs/concepts/traffic-management/#virtual-services) and [DestinationRule](/docs/concepts/traffic-management/#destination-rules)).

Ingress worked well as a lowest common denominator between different implementations, but its shortcomings led SIG Network to investigate the design of a "version 2". A [user survey in 2018](https://github.com/bowei/k8s-ingress-survey-2018/blob/master/survey.pdf) was followed by [a proposal for new APIs in 2019](https://www.youtube.com/watch?v=Ne9UJL6irXY), based in large part on Istio's traffic APIs. That effort came to be known as the "Gateway API".

The Gateway API was built to be able to model many more use cases, with extension points to enable functionality that differs between implementations. Furthermore, adopting the Gateway API opens a service mesh up to compatibility with the whole ecosystem of software that is written to support it. You don't have to ask your vendor to support Istio routing directly: all they need to do is create Gateway API objects, and Istio will do what it needs to do, out of the box.

## Support for the Gateway API in Istio

Istio added [support for the Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/) in November 2020, with support marked Alpha along with the API implementation. With the Beta release of the API spec we are pleased to announce support for ingress use in Istio is being promoted to Beta. We also encourage early adopters to start experimenting with the Gateway API for mesh (service-to-service) use, and we will move that support to Beta when SIG Network has standardized the required semantics.

Around the time of the v1 release of the API, we intend to make the Gateway API the default method for configuring all traffic routing in Istio - for ingress (north-south) and service-to-service (east-west). At that time, we will change our documentation and examples to reflect the recommendation.

Just like Kubernetes intends to support the Ingress API for many years after the Gateway API goes stable, the Istio APIs (Gateway, VirtualService and DestinationRule) will remain supported for the foreseeable future.

Not only that, but you can continue to use the existing Istio traffic APIs alongside the Gateway API, for example, using an [HTTPRoute](https://gateway-api.sigs.k8s.io/v1beta1/api-types/httproute/) with an Istio [VirtualService](/docs/reference/config/networking/virtual-service/).

The similarity between the APIs means that we will be able to offer a tool to easily convert Istio API objects to Gateway API objects, and we will release this alongside the v1 version of the API.

Other parts of Istio functionality, including policy and telemetry, will continue to be configured using Istio-specific APIs while we work with SIG Network on standardization of these use cases.

## Welcoming the SMI community to the Gateway API project

Throughout its design and implementation, members of the Istio team have been working with members of SIG Network on the implementation of the Gateway API, making sure the API was suitable for use in mesh use cases.

We are delighted to be [formally joined in this effort](https://smi-spec.io/blog/announcing-smi-gateway-api-gamma) by members of the Service Mesh Interface (SMI) community, including leaders from Linkerd, Consul and Open Service Mesh, who have collectively decided to standardize their API efforts on the Gateway API. To that end, we have set up a [Gateway API Mesh Management and Administration (GAMMA) workstream](https://gateway-api.sigs.k8s.io/contributing/gamma/) within the Gateway API project. John Howard, a member of the Istio Technical Oversight Committee and a lead of our Networking WG, will be a lead of this group.

Our combined next steps are to provide [enhancement proposals](https://gateway-api.sigs.k8s.io/v1alpha2/contributing/gep/) to the Gateway API project to support mesh use cases. We have [started looking at API semantics](https://docs.google.com/document/d/1T_DtMQoq2tccLAtJTpo3c0ohjm25vRS35MsestSL9QU/edit) for mesh traffic management, and will work with vendors and communities implementing Gateway API in their projects to build on a standard implementation. After that, we intend to build a representation for authorization and authentication policy.

With SIG Network as a vendor neutral forum for ensuring the service mesh community implements the Gateway API using the same semantics, we look forward to having a standard API which works with all projects, regardless of their technology stack or proxy.
