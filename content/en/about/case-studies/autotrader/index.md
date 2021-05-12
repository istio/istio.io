---
title: "Istio Pioneer AutoTrader UK Still Benefiting"
linkTitle: "Istio Pioneer AutoTrader UK Still Benefiting"
quote: "We decided to just try out Istio to see how it would go, and we ended up delivering in the space of about a week – more than we had done in the last four months trying to roll it ourselves."
author:
    name: "Karl Stoney"
    image: "/img/authors/karl-stoney.png"
companyName: "Auto Trader UK"
companyURL: "https://autotrader.co.uk/"
logo: "/logos/autotrader.svg"
skip_toc: true
skip_byline: true
skip_pagenav: true
doc_type: article
sidebar_force: sidebar_case_study
type: case-studies
weight: 10
---

Auto Trader UK began in 1977 as the premier automotive market magazine in the United Kingdom. When it pivoted to an online presence near the end of the 20th century, it grew to become the UK’s largest digital automotive marketplace.

The IT estate that supports Auto Trader UK is vast. Today, they manage around 50 customer-facing applications backed by about 400 microservices that process over 30,000 requests per second. Their infrastructure runs on Google Kubernetes Engine (GKE) and utilizes the Istio service mesh. As a major Istio success story, Auto Trader UK has received plenty of attention for its migration to public cloud since 2018.

## Challenge

Changing requirements precipitated Auto Trader UK's migration to containerized applications using Istio as a service mesh. One of the most pressing reasons was the recent focus on GDPR. AutoTrader wasn’t satisfied with just typical perimeter security. It aspired to also encrypt all traffic between microservices, even those in the same local network, using mutual-TLS. The effort felt significant for a primarily custom-built on-premises private cloud infrastructure operating at Auto Trader’s large scale.

There was another motivation for enabling mTLS for all traffic; Auto Trader UK was planning to move the bulk of their infrastructure to the public cloud. [Strong end-to-end mTLS](/docs/tasks/security/authentication/mtls-migration/) would be important to protect their entire microservice ecosystem.

## Solution: Istio and Google Kubernetes Engine (GKE)

The Auto Trader UK Platform team worked on a proof of concept implementation of mTLS for the on-premises private cloud. As expected, implementation was a laborious task. They decided to experiment with a container-based solution that could leverage a service mesh like Istio to manage mTLS for a key end-to-end slice of their microservice architecture. AutoTrader didn’t have ambition to build and manage Kubernetes themselves, so they decided to run their experiment on GKE.

The container experiment was a success. Implementing encryption was taking weeks of effort on the private cloud but just days in the containerized project. The migration path to containerized services was clear.

{{< quote caption="Karl Stoney, Delivery Infrastructure Lead at Auto Trader UK" >}}
We decided to just try out Istio to see how it would go, and we ended up delivering in the space of about a week – more than we had done in the last four months trying to roll it ourselves.
{{< /quote >}}

## Why Istio?

While the easy transition to mTLS for all microservices was a strong incentive, Istio also has the backing of many large organizations. Auto Trader UK was already working with Google Cloud, so knowing that Google was a strong contributor and user of Istio gave them confidence it had long term support and will grow into the future.

Early success with experiments on GKE with Istio led to quick buy-in from the business. Along with an easy path to mTLS, they started enabling important observability capabilities which significantly de-risked the migration to cloud. As Istio has evolved, the platform team has been able to expose core capabilities such as robust retries, outlier detection and traffic splitting with minimal effort.

## Results: Confidence and Observability

Istio gave Auto Trader UK the confidence to deploy more and more applications to the public cloud. Istio allowed them to consider services in aggregates instead of as just individual instances. With increased observability, they had a new way to both manage and think about infrastructure. They suddenly had insights into performance and security. Meanwhile Istio was helping them discover existing bugs that had been there all along, unnoticed. By fixing small memory leaks and small bugs in existing applications, they were able to bring significant performance improvements to their overall architecture.

### Emergence of a Platform Delivery Team

They were able to not only deploy quickly, but package a Kubernetes and Istio solution as an internal product for other product teams to consume. A team of ten now manages a delivery platform that serves over 200 other developers.

Istio and Kubernetes enabled the better application deployment and resource management that the team sought, but Istio also brought phenomenal insights into application performance. Observability was key; Auto Trader UK now measures precise resource utilization and microservice transactions. With these service metrics, they are able to size deployments correctly in order to reduce and manage cloud costs.

While it wasn't a completely transparent migration, the benefits of Istio and Kubernetes encouraged all of the product teams to migrate. With fewer dependencies to manage and many features provided automatically by Istio, cross-functional requirements are met with almost no effort by project teams. Teams are able to deploy web apps globally in minutes, with the new infrastructure easily handling about 200 to 250 deployments per day.

### Enabling CI/CD

Even a brand new application can be deployed into production in just five minutes. Rapid deployment for existing applications has changed release methodologies at Auto Trader UK. With more confidence in observability and roll-back, more teams are adopting CD practices. Fine-tuned monitoring with Istio allows the deployment team to quickly and accurately pinpoint problems with new deployments. Individual teams are able to look at their own performance dashboards. If they see new errors, changes can be rolled back immediately via the CI/CD tooling.

Auto Trader UK took a large, fully custom IT estate and systematically shifted it to microservices on a public cloud. Their implementation of Istio was a key part of the success of the migration and has opened up their entire organization to better process, better visibility, and better applications.
