---
title: "Announcing Istio's graduation within the CNCF"
publishdate: 2023-07-12
attribution: "Craig Box, for the Istio Steering Committee"
keywords: [Istio,CNCF]
---

We are delighted to announce that [Istio is now a graduated Cloud Native Computing Foundation (CNCF) project](https://www.cncf.io/announcements/2023/07/12/cloud-native-computing-foundation-reaffirms-istio-maturity-with-project-graduation/).

We would like to thank our TOC sponsors [Emily Fox](https://www.cncf.io/people/technical-oversight-committee/?p=emily-fox) and [Nikhita Raghunath](https://www.cncf.io/people/technical-oversight-committee/?p=nikhita-raghunath), and everyone who has collaborated over the past six years on Istio's design, development, and deployment.

As before, project work continues uninterrupted. We were excited to [bring ambient mesh to Alpha in Istio 1.18](/news/releases/1.18.x/announcing-1.18/#ambient-mesh) and are continuing to drive it to production readiness. Sidecar deployments remain the recommended method of using Istio, and our [1.19 release](https://github.com/istio/istio/wiki/Istio-Release-1.19) will support a [new sidecar container feature](https://github.com/kubernetes/kubernetes/pull/116429) in Alpha in Kubernetes 1.28.

We have been delighted to welcome Microsoft to our community after [their decision to archive the Open Service Mesh project and collaborate together on Istio](https://openservicemesh.io/blog/osm-project-update/). As the [third most active CNCF project](https://all.devstats.cncf.io/d/53/projects-health-table?orgId=1) in terms of PRs, and with [support from over 20 vendors](/about/ecosystem/) and [dozens of contributing companies](https://istio.devstats.cncf.io/d/5/companies-table?orgId=1&var-period_name=Last%20year&var-metric=prs), there is simply no better choice for a service mesh.

We would like to invite the Istio community to [submit a talk to the upcoming virtual IstioCon 2023](https://sessionize.com/istiocon-2023), the companion [full day, in-person event](https://www.lfasiallc.com/kubecon-cloudnativecon-open-source-summit-china/co-located-events/istiocon-call-for-proposals-cn/#preparing-to-submit-your-proposal-cn) co-located with KubeCon China in Shanghai, or [Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/#call-for-proposals) co-located with KubeCon NA in Chicago.

## Watch a video

In this video for [Techstrong TV](https://techstrong.tv/), I talk about the history of the project, and what graduation means to us.

<iframe width="754" height="424" src="https://player.vimeo.com/video/844586107" title="Vimeo video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Words of support from our alumni

When we [announced our incubation](/blog/2022/istio-accepted-into-cncf/), we mentioned that the journey began with Istio's inception in 2016. One of the great things about collaborative open source projects is that people come and go from employers, but their affiliation with a project can remain. Some of our original contributors founded companies based on Istio; some moved to other companies that support it; and some are still working on it at Google or IBM, six years later.

The announcement from the CNCF and blog posts from [Intel](https://community.intel.com/t5/Blogs/Tech-Innovation/open-intel/How-Intel-s-Contributions-Can-Boost-Istio-Service-Mesh/post/1503821), [Red Hat](https://cloud.redhat.com/blog/red-hat-congratulates-istio-on-graduating-at-the-cncf), [Solo.io](https://www.solo.io/blog/istio-graduates-cncf), [Tetrate](https://tetrate.io/blog/istio-service-mesh-graduates-cncf/), [VMware](https://tanzu.vmware.com/content/blog/vmware-celebrates-istio-s-graduation-to-cncf) and [DaoCloud](https://blog.daocloud.io/8970.html) summarize the thoughts and feelings of those working on the project today.

We also reached out to some contributors who have moved on from the project, to share their thoughts.

{{< quote caption="Sven Mawson, Istio co-founder and Chief Software Architect, SambaNova Systems" >}}
From the very beginning of Istio, we wished for it to join its big brother Kubernetes as a core part of the CNCF landscape. Seeing all that the Istio project has accomplished since those early days is an amazing gift. I couldn't be prouder of what the community has accomplished and what this graduation means to the continued success of the project.
{{< /quote >}}

{{< quote caption="Shriram Rajagopalan, co-creator of Amalgam8" >}}
As a co-founder of the Istio service mesh, it is very gratifying to see how far we have come. We started off with a vision for an infrastructure that provided security, observability and programmability out of the box to cloud native and legacy applications. We were humbled by the dramatic adoption across enterprises and grateful for the trust people placed in the Istio team when they deployed critical production workloads on Istio. Graduating from CNCF is a great formal validation and recognition of our vision, our project and the huge community we have built so far.
{{< /quote >}}

{{< quote caption="Jasmine Jaksic, original Istio TPM" >}}
When we launched Istio six years ago, we knew it would make waves, but we didn’t realize that we had opened the floodgate. It grew beyond any of our wildest imagination, and today Istio marks another milestone. As a founding member and as someone who got to play almost every role on this product over the years, I’m infinitely grateful to have been part of Istio’s incredible journey.
{{< /quote >}}

{{< quote caption="Martin Taillefer, original Istio engineer" >}}
When we started Istio, before the concept of a service mesh existed, we had a broad idea of what it would be, but the details were murky. It was exciting to see the tech quickly evolve and grow into an invaluable asset for the community. It’s gratifying that all this hard work has led us to this point.
{{< /quote >}}

{{< quote caption="Douglas Reid, original Istio engineer and Founding Engineer, Steamship" >}}
When we were building the initial prototypes for what would become Istio, we had hopes that others would see the value in what we were creating, and that it would make a positive impact on the way in which organizations built, managed, and monitored their production services. Graduation from CNCF marks a realization, beyond any reasonable measure, of those initial aspirations. Of course, such a milestone is only achievable with contributions from a large community of passionate, knowledgeable, and dedicated individuals. This achievement is a celebration of the kindness, patience, and expertise they have shared over the years. May the project continue to grow and help its users deliver secure, monitored services for many years to come!
{{< /quote >}}

{{< quote caption="Brian Avery, former TOC member, Istio Product Security Lead, and Test and Release Lead" >}}
During my time as a contributor and leader within the Istio community, Istio repeatedly showed itself to be a powerful platform with the tools organizations need at the center of their security, networking, and observability strategies. I’m especially proud of the optimizations we made in the Product Security and Test and Release work groups to prioritize users’ needs through secure, reliable, and predictable features and releases. Istio’s graduation in CNCF is a huge step forward for the community, validating all of the hard work we’ve contributed. Congratulations to the community. I'm excited to see where Istio goes next.
{{< /quote >}}
