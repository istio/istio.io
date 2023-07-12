---
title: "DaoCloud"
linkTitle: "DaoCloud"
quote: "We have successfully promoted Istio adoption among many Chinese enterprises for multi-cloud mesh, canary deployment, and microservice migration"
author:
    name: "Michael Yao"
    image: "https://avatars.githubusercontent.com/u/79828097?v=4"
companyName: "DaoCloud"
companyURL: "https://www.daocloud.io/en/"
logo: "/logos/daocloud.svg"
skip_toc: true
skip_byline: true
skip_pagenav: true
skip_feedback: true
doc_type: article
sidebar_force: sidebar_case_study
type: case-studies
weight: 52
---

Istio has gained recognition among DaoCloud's users for its excellent architecture and features,
leading to improved business efficiency. As a leading cloud native service provider in China,
DaoCloud offers high-quality services to customers across various industries. They utilize Istio
as the foundation for their service mesh offerings, enabling customers to address specific needs
in the following areas:

## Multi-Cloud Mesh

With the growing adoption of multi-cloud strategies, the multi-cloud service mesh functionality
provided by Istio is essential. DaoCloud leverages Istio to offer customers the following
multi-cloud mesh-related features:

1. Unified management and control: Istio provides a unified service mesh layer that can be
   managed across multiple clouds and on-premises environments. This enables enterprises to
   maintain a unified control plane for service discovery, traffic management, and policy enforcement.

1. Enhanced observability: In multi-cloud environments, Istio's observability tools provide deep
   insights into service behavior and performance, facilitating issue detection and troubleshooting.

1. Unified security policies: Istio's security features, including mTLS and authorization policies,
   ensure consistent security controls regardless of where the services are running.

1. Unified traffic policies: Istio enables control over traffic between services,
   adapting to diverse requirements such as active-active setups or disaster recovery scenarios.

1. Inter-cluster network connectivity: Istio makes it easier to connect different
   cluster networks, handling hybrid cloud scenarios effortlessly.

By utilizing Istio, enterprises can effectively manage and control services across multiple cloud
environments, providing stable and efficient services in any deployment context.

## Canary Deployment

Istio's traffic management capabilities make it an excellent tool for canary deployments,
allowing enterprises to release and update software in a safer and more effective manner.
Here's how Istio facilitates canary deployments:

In traditional release models, new software versions are immediately pushed to all users.
While this approach allows for quick feature releases, it also carries the risk of severe issues
affecting all users simultaneously. To mitigate such risks, many Chinese enterprises prefer canary deployments.

Canary deployment is a software release model where new versions are initially released to
a small subset of users instead of all users. This way, any issues with the new version only
impact a limited number of users. Once the new version is confirmed to be problem-free,
it can gradually roll out to all users.

Istio's service mesh simplifies the implementation of canary deployment models,
as its traffic policies enable specific traffic to be directed to the different
versions of the service. For example, only 10% of the traffic can be routed to
the new version while the remaining 90% continues to use the old version. This
enables thorough testing of the new version's features and performance, ensuring
a low impact on the existing system.

Moreover, Istio's canary deployments offer flexibility by supporting more complex conditions
through header-based or cookie-based routing. For instance, traffic from specific users or
with specific cookies can be routed to the new version selectively.

By adopting Istio's canary deployment capabilities, enterprises can perform software releases
and updates more safely and efficiently, without the concern of impacting all users with
potential issues in the new version. Additionally, collecting performance data from the
new version's actual usage aids in making informed decisions for a comprehensive release strategy.

In summary, Istio provides a powerful and flexible solution for enterprises to
effectively manage their software release processes through canary deployments.

## Traditional Microservices Migration

DaoCloud has helped many Chinese enterprises migrate their traditional microservices
to the Istio service mesh, addressing the challenge of transforming application architectures.
The benefits of using Istio for microservices migration include:

1. Progressive cloud native migration: Istio enables enterprises to gradually
   migrate applications to a cloud native architecture, minimizing disruptions
   and ensuring a smooth transition.

1. Integration with existing frameworks: DaoCloud's Istio-based service mesh supports
   integration with popular traditional microservice frameworks like Spring Cloud and Dubbo,
   allowing enterprises to leverage their existing investments while moving towards a
   more cloud native architecture.

1. Service discovery and traffic management: Istio provides robust service discovery
   and traffic management capabilities, enabling effective management and control of services.

1. Observability and monitoring: Istio's observability tools provide detailed insights
   into service behavior and performance, facilitating issue identification and troubleshooting.

1. Security and compliance: Istio's security features, such as mTLS authentication and
   access control policies, ensuring the enforcement of security and compliance requirements
   during the migration process.

Leveraging Istio's capabilities, DaoCloud has successfully assisted numerous Chinese enterprises
in transforming their traditional microservices architectures into scalable, resilient, and cloud native
systems. The gradual migration approach offered by Istio minimizes risks and disruptions while enabling
the benefits of a modern cloud native architecture.
