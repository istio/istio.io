---
title: "Istio Pioneer AutoTrader UK Still Benefiting"
linkTitle: "Istio Pioneer AutoTrader UK Still Benefiting"
quote: "Istio is a service mesh that provides cross-cutting functions that all micro services environments need"
author:
    name: "Nick Chase"
    image: "/img/authors/nick-chase.png"
companyName: "AutoTrader UK"
companyURL: "https://autotrader.co.uk/"
logo: "/logos/autotrader.png"
skip_feedback: true
skip_toc: true
skip_byline: true
layout: case-study
doc_type: case-study
sidebar_force: sidebar_case_study
---

Auto Trader UK began in 1977 as the premier automotive market magazine in the United Kingdom. When it pivoted to an online presence near the end of the 20th century, it grew to become the country’s 16th largest website.

The IT estate that supports Autotrader UK is vast. Today, Auto Trader UK manages 40 to 50 customer-facing applications backed by about 400 microservices that process over 30,000 requests per second. Their public-facing infrastructure runs on Google Kubernetes Engine (GKE) and utilizes the Istio service mesh. As a major Istio success story, Auto Trader UK has received plenty of attention for its migration to public cloud services in 2018. It is worth understanding the decisions behind their migration and the ongoing benefits.

## Challenge
Changing requirements, both internally and from vendors, precipitated Auto Trader UK’s migration to GKE and Istio. One requirement in particular was the need to transparently deploy mutual TLS (mTLS) for all microservices. This effort proved to be monumental for a primarily custom-built infrastructure.

The mTLS deployment wasn’t just necessary because of requirements from partners and vendors; Auto Trader UK was planning to move the bulk of their infrastructure to the public cloud. Strong end-to-end mTLS would be important to protect their entire microservice ecosystem.

## Solution: Istio and Google Kubernetes Engine
The Auto Trader UK IT team already had a strong track record for migrating services to the public cloud. It had become obvious that this was the eventual destination for more and more of their infrastructure. Facing issues with implementing mTLS, part of the IT team experimented with containerizing existing applications and deploying them on GKE, using Istio as a service mesh.

The experiment was a success. What was taking other teams weeks of effort on their private cloud was accomplished in days on GKE. In addition, the Istio service mesh provided seamless end-to-end mTLS across their entire microservice architecture.

{{< quote caption="Karl Stoney, Delivery Infrastructure Lead at Auto Trader UK" >}}
We decided to just try out Istio to see how it would go, and we ended up delivering in the space of about a week – more than we had done in the last four months trying to roll it ourselves.
{{< /quote >}}

## Why Istio?
While the easy transition to mTLS for all microservices was a strong incentive, Istio also has the backing of many large organizations. Auto Trader UK was already working with Google, so knowing that Google was a strong backer of Istio gave them confidence it would be supported and grow long term.

Early success with experiments on GKE with Istio led to quick buy-in from the business. Capabilities that they had been trying to implement for months were suddenly ready in just a week. Istio was able to not only provide mTLS, but also robust retry and backup policies and outlier detection.

## Results: Phenomenal Obsevability
Istio gave Auto Trader UK the confidence to deploy all applications to the public cloud. With increased observability, they now had a new way to both manage and think about infrastructure. They suddenly had insights into performance and security, meanwhile Istio was helping them discover existing bugs that had been there all along, unnoticed. 

### Emergence of a Platform Delivery Team
They were able to not only deploy quickly, but package a Kubernetes and Istio solution as an internal product to other development and deployment teams. A team of ten now manages a delivery platform that serves over 200 other developers. 

While the initial intent of Kubernetes was to enable better application deployment and resource management, adding Istio brought the benefit of phenomenal insights into application performance. Observability was key; Auto Trader UK was now able to measure precise resource utilization and microservice transactions.

While it wasn’t a completely transparent migration, the benefits of Istio and Kubernetes encouraged all of the product teams to migrate. With fewer dependencies to manage and many features provided automatically by Istio, cross-functional requirements are met with almost no effort by project teams. Teams are able to deploy web apps globally in minutes, with the new infrastructure easily handling about 200 to 250 deployments per day.

### Enabling CI/CD
Even a brand new application can be deployed in just five minutes. Rapid deployment for existing applications has changed release methodologies at Auto Trader UK. They no longer use release cycles, but instead use CI/CD to quickly deploy new changes. Fine-tuned monitoring with Istio allows the deployment team to quickly and accurately pinpoint problems with new deployments. Individual teams are able to look at their own performance dashboards. If they see new errors, changes can be rolled back immediately via the CI/CD dashboard. The recovery time with Istio is mere minutes.

Auto Trader UK took a large, fully custom IT estate and systematically shifted it to microservices on a public cloud. Their implementation of Istio was a key part of the success of the migration and has opened up their entire organization to better process, better visibility, and better applications.