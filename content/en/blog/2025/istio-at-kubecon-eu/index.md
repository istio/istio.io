---
title: "Istio at KubeCon Europe 2025"
description: A quick recap of Istio at KubeCon Europe, at Excel London.
publishdate: 2025-04-17
attribution: "Faseela K, for the Istio Steering Committee"
keywords: [Istio Day,IstioCon,Istio,conference,KubeCon,CloudNativeCon]
---

The open source and cloud native community gathered from the 1st to 4th of April in London for the first KubeCon of 2025. The four-day conference, organized by the Cloud Native Computing Foundation, was "big" for Istio, as our presence was seen almost everywhere - from the keynotes to the project pavilion.

We kick-started the activities in London with Istio Day - a KubeCon + CloudNativeCon co-located event on April 1st. The event was well-received, showcasing lessons learned from running Istio in production, hands-on experiences, and featuring maintainers from across the Istio ecosystem.

{{< image width="40%"
    link="./istioday-welcome.jpg"
    caption="Istio Day Europe 2025, Welcome"
    >}}

Istio Day kicked off with an opening keynote from the Program Committee chairs, Keith Mattix and Denis Jannot. The keynote was followed by [the much-awaited talk from Microsoft about Istio Ambient Mesh support on Windows](link to be added). We had a very interesting talk by Lior Lieberman from Google and Erik Parienty from Riskified [on architecting Istio for large scale deployments](link to be added), followed by a talk from Kiali maintainers Josune Cordoba and Hayk Hovsepyan, from RedHat, about [troubleshooting Istio ambient mesh with Kiali 2.0](link to be added).

{{< image width="75%"
    link="./istioday-session-1.jpg"
    caption="Istio Day Europe 2025, Kiali session"
    >}}

Istio multi-cluster is always a hot topic, and Pamela Hernandez from BlackRock nailed it in the talk on [navigating the maze of multi-cluster Istio](link to be added), diving into the complexities of implementing a multi-cluster Istio service mesh at scale, covering a hub-and-spoke model. The audience was excited when Denis Jannot from Solo.io [ran a live, representative benchmark at scale with Istio Ambient](link to be added), debunking all myths about Service Mesh overhead and complexity. The event witnessed how Istio played a pivotal role in managing traffic and ensuring data security, ultimately enabling a secure and efficient AI platform that meets enterprise standards when [SAP presented GenAI platform challenges in multi-tenant environments](link to be added). Rounding out the talks was a lightning talk by Rob Salmond from SuperOrbit on [How to get help](link to slides to be added), which involved the best places to go, how to ask good questions, and avoid common missteps.

{{< image width="75%"
    link="./istioday-session-2.jpg"
    caption="Istio Day Europe 2025, Jam packed sessions"
    >}}

The slides for all the sessions can be found in the [Istio Day NA 2025 schedule](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/istio-day/).

Our presence at the conference did not end with Istio Day. The first day keynote of KubeCon + CloudNativeCon started with a project lightning talk from Mitch Connors.

{{< image width="75%"
    link="./project-update.jpg"
    caption="Istio Day Europe 2025, Project lightning talk"
    >}}

There were several keynotes on the main stage where Istio was mentioned. At the opening day keynotes, Vasu Chandrasekhara, from SAP, announced the NeoNephos Foundation under the Linux Foundation Europe - a major step forward for Digital Sovereignty in Europe.  

{{< image width="75%"
    link="./kubecon-keynote-1.jpg"
    caption="KubeCon Europe 2025, Announcing NeoNephos"
    >}}

Stephen Connolly shared HSBC’s journey with Kubernetes and also discussed plans to adopt Istio ambient mesh to save on costs. Ant Group, who won the CNCF End User Award, also highlighted their Istio usage. Idit Levine and Keith Babo, from Solo.io, announced a free cost-saving estimator and migration tool for Istio ambient mesh. Faseela K had a Telco end user panel keynote on “Cloud Native Evolution in Telecom” with Vodafone, Orange, and Swisscom, which again highlighted Istio usage for Telco Network Functions.

{{< image width="75%"
    link="./kubecon-keynote-2.jpg"
    caption="KubeCon Europe 2025, Cloud Native evolution in Telecom"
    >}}

Istio’s maintainer track session was also well received, where Raymond Wong, from Forbes, joined maintainers Louis Ryan and Lin Sun to discuss about Forbe’s journey to Istio ambient in production. It was a packed room with a lot of questions afterwards.

{{< image width="75%"
    link="./maintainer-track.jpg"
    caption="KubeCon Europe 2025, Istio maintainer track session"
    >}}

A ContribFest session led by Mitch Conners (Microsoft), Daniel Hawton (Solo.io), and Jackie Maertens (Microsoft) walked through the structure of the Istio repositories, where each component’s code lives, finding issues to resolve, setting up and using integration tests, and making first contributions to the project as well as resources for getting development environments up and running and places to go to get assistance.

{{< image width="75%"
    link="./contrib-fest.jpg"
    caption="KubeCon Europe 2025, Istio contrib fest session"
    >}}

Istio maintainers Lin Sun and Faseela K had a book signing event post their Istio Phippy book reading session on “Izzy saves the Birthday”.

{{< image width="75%"
    link="./izzy-book-signing.jpg"
    caption="KubeCon Europe 2025, Izzy saves the birthday, book signing"
    >}}

The following sessions at KubeCon were based on Istio and almost all of them had a huge crowd in attendance:
    - [Project Lightning Talk: What's New in Istio?](https://sched.co/1tcvB)
    - [Sponsored Demo: Bringing Agentic AI to Cloud Native - Introducing kagent](https://sched.co/1x0Gh)
    - ["Izzy Saves the Birthday" - A Story-Driven Live Demo Exploring the Magic of Service Mesh](https://sched.co/1txFn)
    - [Trino and Data Governance on Kubernetes](https://sched.co/1txF1)
    - [Journey at the New York Times: Is Sidecar-Less Service Mesh Disappearing Into Infrastructure?](https://sched.co/1txEX)
    - [Lightning Talk: High Availability With '503: Unavailable'](https://sched.co/1txCk)

Istio had a kiosk in the project pavilion, with the majority of questions asked being around extensibility and multi cluster enhancements. Many of our members and maintainers offered support at our kiosk, helping us answer all the questions from our users.

{{< image width="75%"
    link="./istio-booth-1.jpg"
    caption="KubeCon Europe 2025, Istio Kiosk"
    >}}

Many of our TOC members and maintainers also offered support at the booth, where a lot of interesting discussions happened around Istio ambient mesh as well.

{{< image width="75%"
    link="./istio-booth-2.jpg"
    caption="KubeCon Europe 2025, More support at Istio Kiosk"
    >}}

We would like to express our heartfelt gratitude to our gold sponsor Microsoft Azure, for supporting Istio Day Europe! Last but not least, we would like to thank our Istio Day Program Committee members, for all their hard work and support!

[See you in Atlanta in November 2025!](link to be added!)
