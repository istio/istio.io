---
title: "Atlassian"
linkTitle: "Atlassian"
quote: "Istio has simplified its operating model and it guarantees us the possibility to extend and benefit from the support of a large part of the Kubernetes ecosystem."
author:
    name: "Nicolas Meessen"
    image: "/img/authors/nicolas-meessen.jpg"
companyName: "Atlassian"
companyURL: "https://www.atlassian.com/"
logo: "/logos/atlassian.svg"
skip_toc: true
skip_byline: true
skip_pagenav: true
skip_feedback: true
doc_type: article
sidebar_force: sidebar_case_study
type: case-studies
weight: 90
---

Atlassian has been deploying Envoy to the compute nodes of its internal PaaS over the past 2 years to simplify service-to-service communication for internal developers. As of [their presentation at IstioCon 2021](https://events.istio.io/istiocon-2021/sessions/going-dynamic-with-envoy-at-atlassian/), they deploy Envoy with static configuration and they want to take advantage of dynamic features like client-side routing, direct communication, and fault injection. Atlassian decided Istio was the best choice to deliver this over the next year. Nicolas talks through Atlassian’s journey with service-to-service communication, Envoy and the evolution of their home-grown control planes, then walks through the analysis that led to Istio being the best decision for Atlassian’s business moving forward.

<iframe width="696" height="392" src="https://www.youtube-nocookie.com/embed/iAyVhjuA1HE" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

[Download the slides](https://events.istio.io/istiocon-2021/slides/c1s-GoingDynamicEnvoy-NicolasMeessen.pdf)
