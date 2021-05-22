---
title: "Bol.com Scales Up Ecommerce with Istio"
linkTitle: "Bol.com Scales Up Ecommerce with Istio"
quote: "Istio deployment is a no-brainer. You install it and it runs."
author:
    name: "Roland Kool"
    image: "/img/authors/roland-kool.png"
companyName: "bol.com"
companyURL: "https://bol.com/"
logo: "/logos/bol-com.png"
skip_toc: true
skip_byline: true
skip_pagenav: true
doc_type: article
sidebar_force: sidebar_case_study
type: case-studies
weight: 30
---

Bol.com is the largest online retailer in the Netherlands, selling everything from books to electronics to gardening equipment. Originally founded in 1999, they have grown to serve more than 11 million customers across the Netherlands and Belgium. Understandably, their technology stack and IT infrastructure have grown and developed substantially over the years.

The infrastructure behind their operation used to be hosted by a third party, but eventually bol.com decided to build and automate its own infrastructure. In the late 2010s, bol.com began migrating to the cloud. As more and more services made their way to the cloud, teams became empowered to build and deploy their own cloud-based services and infrastructure.

## Challenge

As they began to migrate operations to the cloud, bol.com faced inevitable growing pains. They began moving applications to a Kubernetes cluster, adding more and more pods over time. It seemed like the cluster address space had plenty of room. Unfortunately, scaling for demand was quickly an issue. They initially configured the cluster with a service CIDR with space for about 1,000 addresses, but just one year later, they were already at 80% capacity.

Roland Kool is one of the system engineers on the bol.com team that addressed this issue. Faced with the knowledge that available IP address space in their Kubernetes cluster would not keep up with growing needs, the team needed a solution that would enable overflow into additional clusters. In addition, this new multi-cluster Kubernetes deployment would bring new networking challenges, as applications would need a new approach to service discovery, load balancing, and secure communication.

## Solution: Multiple Clusters with a Service Mesh

The solution seemed to be introducing additional clusters, but they ran into issues with security requirements and network policies that secured traffic between services.

This challenge was exacerbated by the need to protect personally identifying information (PII). Due to European regulations such as GDPR, every service touching PII needs to be identified and access needs to be strictly controlled.

Since network policies are cluster local, they don’t work across cluster boundaries. All of those per-cluster network policies got messy fast. They needed a solution that would allow them to apply security at a higher layer.

Istio's [multi-cluster deployment model](/docs/ops/deployment/deployment-models/#multiple-clusters) ended up being the perfect solution. [Authorization policies](/docs/reference/config/security/authorization-policy/) could be used to securely allow workloads from different clusters to talk to each other. With Istio, Kool's team was able to move away from OSI layer 3 or 4 network policies to [authz policies](/docs/tasks/security/authorization/authz-http/) implemented in layer 7. This move was made possible by Istio's strong identity support, service-to-service authentication, and security with mutual TLS (mTLS).

These changes gave bol.com the ability to scale by adding new Kubernetes clusters while maintaining service discovery, load balancing, and required security policies.

## Why Istio?

When bol.com initially began migrating to Kubernetes, Istio was only at version 0.2. It did not seem to be ready for production, so they went forward without Istio. They first started to look seriously at Istio around version 1.0, but they ran into too many issues with deployment and implementation. Without an urgent use case, they tabled the idea.

Eventually, however, it wasn't just the scaling issues that brought bol.com back to an Istio solution. In addition to needing Kubernetes clusters to securely communicate with each other, they also were facing new regulatory requirements that would necessitate secure communications with various third party services and APIs. These controls could not be based on firewall rules and IP ranges, which are subject to constant change – they needed to be based on the identity of the application.

Their solution took advantage of the [Istio egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/). This enables them to apply authz controls which can allow or deny traffic based on attributes like the identity or namespace of the client workload, the destination hostname, and even attributes like the the URL of the HTTP request.

Bol.com needed a service mesh that supports multi-cluster deployments, and Istio fits the bill. In addition, Istio provided the fine-grained control they needed to meet their particular requirements.

## Results: Enabling DevOps

"Istio deployment is a no-brainer," explained Roland Kool. "You install it and it runs."

After Istio was installed, they moved on to the implementation of the service mesh features that mattered to them. Rolling out sidecars took some additional work from individual teams and support from the team responsible for implementing Istio.

One of the biggest changes for Kool and the team at bol.com was that it was suddenly much easier to implement authorization policies around services. Istio deployment at bol.com is currently at about 95% adoption and it continues to grow. It can be difficult to please all developers, but the Istio deployment team has worked hard to make it simple to adopt and easy to integrate.

Developers have provided good feedback and have enthusiastically embraced many of Istio's capabilities. They are pleased at how easy it is to get apps talking to each other across clusters now. All of these connections are easy to set up and manage, thanks to Istio.

The bol.com infrastructure continues to evolve, and thanks to the observability it offers, Istio is a key part of that roadmap. By [integrating Istio with Prometheus](/docs/ops/integrations/prometheus/), they are able to collect the metrics and diagnostics needed to understand where that roadmap needs to take them. Future plans now include consolidating load balancing services, new testing methods, distributed tracing, and installing Istio across more of the company's infrastructure.
