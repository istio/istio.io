---
title: "Bluecore Leverages Istio to Migrate to Kubernetes"
linkTitle: "Bluecore Leverages Istio to Migrate to Kubernetes"
quote: "Istio enables an approach that allows you to start building right out of the box." 
author:
    name: "Shray Kumar"
    image: "/img/authors/shray-kumar.jpg"
companyName: "Bluecore"
companyURL: "https://bluecore.com/"
logo: "/logos/bluecore.png"
skip_toc: true
skip_byline: true
skip_pagenav: true
doc_type: article
sidebar_force: sidebar_case_study
type: case-studies
weight: 51
---

Bluecore is a multichannel personalization platform that specializes in highly personalized emails, onsite messages, and paid media ads delivered at scale. Since Bluecore's unique offering requires processing customer recommendation data as well as sending a large quantity of personalized digital communications, they deal with ingesting, processing, and sending tons of data. It's a huge workload; during a recent Black Friday, they sent over 2 billion emails.

![2 billion emails and 12,000 Kubernetes pods](./bluecore-statistics.png)

Along with volume, Bluecore needs to be speedy. They have service agreements with most of their partners guaranteeing that any customer will receive an email, onsite message, or ad within a few hours of a job being submitted, which means that processing speed is of vital importance. They accomplish this feat using both a monolithic application running on Google App Engine, and a Google Kubernetes Engine (GKE) cluster running about 12,000 pods.

## The Challenge: Monolithic architecture and increasing data traffic

Bluecore is a large operation with serious requirements around data transfer and processing. They were facing a daunting challenge; the amount of data they need to process continually increases. They knew their pipelines would get overloaded if their architecture couldn't be updated to handle increasing demands.

An examination of their architecture revealed that the monolithic application was going to be the biggest challenge. The Bluecore development team realized that to enable future growth, it was time to begin migrating to a more flexible and scalable infrastructure.

Kubernetes offered a path to scale, and since Bluecore was already running on App Engine, it seemed like migrating portions of their workflow to GKE would be a no-brainer. However, the majority of Bluecore's engineers didn't have sufficient experience with containerized applications. This could make migrating to GKE a painful transition.

Fortunately, they found a solution.

## The Solution: Enabling developers with the Istio service mesh

"Istio enables an approach that allows you to start building right out of the box," explains Shray Kumar, a software engineer on the infrastructure team at Bluecore. "And you can make sure you are building things the right way."

Without a service mesh, breaking a monolithic application into containerized services comes with a number of challenges without obvious solutions. One of these, for example, is implementing authentication and authorization. If each containerized service needs its own solution, the chances are too great that individual developers will come up with their own way to do it. This can lead to fragmented code and plenty of future headaches.

Thankfully, Kumar and the infrastructure team were familiar with Istio. They worked closely with Al Delucca, principal engineer for Bluecore's data platform team, on a plan to begin implementing it.

"We had the problem," Delucca explains. "But whether or not Istio was the tool to solve it, that's what we had to figure out."

They discovered that Istio's feature set provided many solutions to existing challenges. Authorization was a big one. Incoming messages from partner applications needed to be authenticated. Istio could perform that authentication at the edge, which meant that each individual service didn't need to implement its own methods.

"We are able to push authentication and authorization to the edge, which takes the burden of understanding those systems away from our engineers," says Delucca. "It's not so much what they do with Istio directly, it's what Istio does for them without them knowing. That's the key—the big win for us."

As their engineers began breaking the monolithic application down into services, they encountered another challenge that Istio was able to solve. Tracing calls to services looked as though it would be problematic. Many of the legacy functions didn't have clear documentation about their dependencies and requirements. This meant that performance issues and remote service calls could leave developers scratching their heads. Luckily, [Istio's distributed tracing](/docs/tasks/observability/distributed-tracing/) came to the rescue. With it, developers were able to pinpoint bottlenecks and services that needed bug fixes and additional work.

Istio's service mesh enabled the developers to focus on breaking the monolithic application into individual services without having to develop deep knowledge of the entire infrastructure. This enabled Bluecore's engineers to become more productive more quickly.

## Conclusion: The Future

While the Bluecore team has already found incredible value in the Istio features they have utilized, they are still looking to utilize more. Among these features is the ability to manage autoscaled [canary deployments](/blog/2017/0.1-canary/). A canary deployment allows a team to introduce a new version of a service by testing it with just a small portion of the application's traffic. If the test goes well, the upgrade can be deployed automatically while phasing out the previous version. On the other hand, if a problem is detected with the new version, the previous version can be rolled back quickly.

![Monolithic applications to containerized services](./bluecore-containers.png)

The Bluecore team will continue breaking their monolithic application down into containerized services, using Istio to push more and more services to the edge and giving their developers more time to do what they do best. They feel confident that they are ready for the next stage of growth as they need to ingest and process more and more data.
