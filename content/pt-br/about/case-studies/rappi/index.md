---
title: "Rappi Manages Growing Pains with Istio"
linkTitle: "Rappi Manages Growing Pains with Istio"
quote: "Istio seamlessly gave our team the ability to monitor services at any scale." 
author:
    name: "Ezequiel Arielli"
    image: "/img/authors/ezequiel-arielli.jpg"
companyName: "Rappi"
companyURL: "https://www.rappi.com/"
logo: "/logos/rappi.png"
skip_toc: true
skip_byline: true
skip_pagenav: true
doc_type: article
sidebar_force: sidebar_case_study
type: case-studies
weight: 52
---

![1500 deployments per day, 50+ clusters, 30,000 containers](./rappi-statistics.png)

Rappi connects businesses, consumers, and delivery people with the mission of giving its users more free time. Their app gives users the power to order a wide variety of goods and services. It is the first Latin American super-app, with a presence in nine countries and more than 250 cities. The app has seen more than 100 million downloads since the company was founded in 2015.

With great success comes the challenge of rapid growth, and Rappi has been growing constantly. Over the past few years, the company has grown in value from $100 million to $8 _billion_. Their technology has had to keep up with the pace of the business, which is why they chose to deploy and manage their application on Kubernetes. Kubernetes continues to be a tool enabling the incredible growth of their infrastructure.

However, even with Kubernetes in place, Rappi's infrastructure faced big challenges. How did they manage their growth to more than 50 Kubernetes clusters, with the largest running over 20,000 containers?

## The Challenge: The Crush of Success

Though the Rappi team had managed to move their infrastructure to Kubernetes, they were still struggling with growing pains. They would have to evolve as a technology company in order to keep pace with their business. To help manage their expanding infrastructure, they developed an in-house service mesh. Unfortunately, this required too much maintenance, and it struggled to keep up with the growth they were seeing.

"I remembered the story of Lyft using Envoy, and I decided we should test it out in our environment," says Ezequiel Arielli, Senior DevOps Engineer at Rappi.

## The Solution: Istio to the Rescue

The Rappi team decided to deploy Istio, which uses Envoy sidecars. It was an excellent fit. As they took on the new project, they found the documentation to offer excellent support and the Istio APIs to be both clean and efficient. Istio was the solution to manage their growing pains.

As news of the success of the initial Istio deployment spread throughout the organization, more and more Rappi DevOps teams began moving to Istio. Initially, just a team of 30 was using Istio, but today that number has grown to more than 1,500 developers.

Istio gave Rappi’s DevOps teams the flexibility to set different specifications for different services. They were able to customize rate limits, circuit breakers, connection pools, timeouts, and other critical parameters.

They found that Istio also offered extremely useful features for security and compliance. For example, the service mesh could segment vertical traffic and restrict communication between different endpoints.

"Istio gives us the flexibility to set different specs for different services," says Juan Franco Cusa, DevOps Tech Lead for Rappi. "It also provides extremely useful features for security and compliance, which is very handy for high security environments."

"When our previous solution hit its limit, we were able to use Istio to refactor our monitoring stack," explains Arielli. "Istio seamlessly gave our team the ability to monitor services at any scale."

This became essential as their infrastructure surpassed 30,000 containers.

## Outcome: Infrastructure Continues to Grow

The development team built an automated, production-ready Kubernetes and Istio cluster deployment. Their in-house API layered on top of the Kubernetes clusters, giving them the ability to manage microservices across each cluster. In addition, each microservice has traffic resources automatically created and allocated during deployment. Thanks to this system, they are able to manage over 1,500 deployments per day.

![The Rappi Istio deployment covers multiple clusters.](./rappi-infrastructure.png)

"Our configuration has allowed our Kubernetes usage and infrastructure to continue to grow," says Arielli. "We now manage more than 50 Kubernetes clusters, the largest containing more than 20,000 containers. Our environment is constantly changing, and Istio helps ensure efficient, scalable, and safe communication across all of it."

Istio manages traffic between more than 1,500 applications on the most critical clusters, and thanks to its powerful feature set, they are able to choose different deployment strategies when needed. The Istio control plane rebalances connections easily, even as traffic continues to increase.

## What’s Next for Rappi

The DevOps team behind Istio adoption is still moving forward with infrastructure improvements.

"In the future, we hope to be able to implement multi-cluster support at the mesh level," says Arielli. "With this feature, it won't matter where an application is running. All applications will be able to access each other across clusters."

## Conclusion: Successful Scaling with Istio

With the Istio service mesh, Rappi has managed to grow as the market requires. They can easily handle deployment of new clusters and turning on services in more markets and cities.

"Thanks to Istio, we are confident that Rappi will be able to deploy more services and more applications to meet growing demand," says Arielli.
