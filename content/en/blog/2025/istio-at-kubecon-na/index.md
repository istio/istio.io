---

title: "Istio at KubeCon + CloudNativeCon North America 2025"
description: "Highlights from Istio Day and KubeCon North America 2025 in Atlanta."
publishdate: 2025-11-20
attribution: "Istio Team"
keywords: ["Istio", "KubeCon", "service mesh", "Ambient Mesh", "Gateway API"]

---

{{< image width="75%" link="./kubecon-opening.jpg" caption="Istio at KubeCon NA 2025" >}}

KubeCon + CloudNativeCon North America 2025 lit up Atlanta from **November 10–13**, bringing together one of the largest gatherings of open-source practitioners, platform engineers, and maintainers across the cloud native ecosystem. For the Istio community, the week was defined by packed rooms, long hallway conversations, and a genuine sense of shared progress across service mesh, Gateway API, security, and AI-driven platforms.

Before the main conference began, the community kicked things off with **Istio Day on November 10**, a colocated event filled with deep technical sessions, migration stories, and future-looking discussions that set the tone for the rest of the week.

## Istio Day at KubeCon NA

Istio Day brought together practitioners, contributors, and adopters for an afternoon of learning, sharing, and open conversations about where service mesh—and Istio—are headed next.

{{< image width="75%" link="./istioday-opening.jpg" caption="IstioDay: North America" >}}

Istio Day opened with [Welcome + Opening Remarks](YouTube link to be added) from John Howard and Keith Mattix, setting the tone for an afternoon focused on real-world mesh evolution and the growing energy across the Istio community.

The day quickly moved into applied AI with [Is Your Service Mesh AI Ready?](YouTube link to be added), where John Howard explored how traffic management, security, and observability shape production-grade AI workloads.

{{< image width="75%" link="./istioday-talk.jpg" caption="IstioDay: Is Your Service Mesh AI Ready" >}}

Momentum continued with [Istio Ambient Goes Multicluster](YouTube link to be added) as Jackie Maertens and Steven Jin Xuan from Microsoft demonstrated how Ambient Mesh behaves across distributed clusters—highlighting identity, connectivity, and operational simplifications in multi-cluster deployments.

A burst of energy came with the lightning talk [Validating Your Istio Setups? The Tests Are Already Written](YouTube link to be added), where Francisco Herrera Lira showed how built-in validation tooling can catch common configuration issues before they reach production.

In [Optimizing Istio Autoscaling: From Resource-Centric to Connection-Aware](YouTube link to be added), Punakshi Chaand and Pankaj Sikka shared how Intuit improved reliability by tuning autoscaling behaviors based on connection patterns rather than raw resource metrics.

Next, [Running Databases in Istio’s Service Mesh](YouTube link to be added) with Tyler Schade and Michael Bolot from GEICO Tech challenged long-held assumptions, offering practical lessons on securing and operating stateful workloads inside a mesh.

Modernizing traffic entry points took the stage as Lin Sun and Ahmad Al-Masry walked through [Is Zero-Downtime Migration Possible? Moving From Ingress & Sidecars to Gateway API](YouTube link to be added), focusing on progressive migration strategies that avoid outages during architectural shifts.

The final session, [Credit Karma’s Istio Migration: 50k+ Pods, Minimal Impact, Lessons Learned](YouTube link to be added), saw Sumit Vij and Mark Gergely outline how they executed one of the largest Istio migrations to date with careful automation and rollout discipline.

The day closed with remarks from John Howard and Keith Mattix, celebrating the speakers, contributors, and a community that continues to push the boundaries of what Istio makes possible.

## Istio at the Main KubeCon Conference

Outside of Istio Day, the project was highly visible across KubeCon, with maintainers, end users, and contributors sharing technical deep dives, production stories, and cutting-edge research.

This KubeCon was especially meaningful for the Istio community because Istio appeared not only across expo booths and breakout sessions, but also throughout several of the KubeCon keynotes, where companies showcased how Istio plays a critical role in powering their platforms at scale.

{{< image width="75%" link="./istio-at-keynotes.png" caption="Istio at KubeCon Keynotes" >}}

The week’s momentum fully met its stride when the Istio community reconvened with the [Istio Project Update](YouTube link to be added), where project leads shared latest releases, roadmap advances, and how Istio is meeting emerging demands from AI workloads, multicluster mesh, and operational scale.

In [Istio: Set Sailing With Istio Without Sidecars](YouTube link to be added), attendees explored how sidecar-less Ambient Mesh architecture is rapidly moving from experiment to adoption, opening new possibilities for simpler deployments and leaner data-planes.

The session [Lessons Applied Building a Next-Generation AI Proxy](YouTube link to be added) took the crowd behind the scenes of how mesh technologies adapt to AI-driven traffic patterns—applying the mesh not just to services, but to model-serving, inference, and data flow.

Over at [Automated Rightsizing for Istio DaemonSet Workloads (Poster)](YouTube link to be added), practitioners gathered to compare strategies for optimizing control-plane resources, tuning for high scale, and reducing cost without sacrificing performance.

The narrative of traffic-management evolution featured prominently in [Gateway API: Table Stakes](YouTube link to be added) and its faster sibling [Know Before You Go! Speedrun Intro to Gateway API](YouTube link to be added). These sessions brought forward foundational and introductory paths to modern ingress and mesh control.

Meanwhile, [Return of the Mesh: Gateway API’s Epic Quest for Unity](YouTube link to be added) scaled that conversation: how traffic, API, mesh, and routing converge into one architecture that simplifies complexity rather than multiplies it.

For long-term reflection, [5 Key Lessons From 8 Years of Building Kgateway (Lightning Talk)](YouTube link to be added) delivered hard-earned wisdom from years of system design, refactoring, and iterative improvements.

In [GAMMA in Action: How Careem Migrated To Istio Without Downtime](YouTube link to be added), the real-world migration story—a major production rollout that stayed up during transition—provided a roadmap for teams seeking safe mesh adoption at scale.

Safety and rollout risks took center stage in [Taming Rollout Risks in Distributed Web Apps: A Location-Aware Gradual Deployment Approach](YouTube link to be added), where strategies for regional rollouts, steering traffic, and minimizing user impact were laid out.

Finally, operations and day-two reality were tackled in [End-to-End Security With gRPC in Kubernetes](YouTube link to be added) and [On-Call the Easy Way With Agents](YouTube link to be added)—sessions reminding everyone that mesh isn’t just about architecture, but about how teams run software safely, reliably, and confidently.

## Community Spaces: ContribFest, Maintainer Track & the Project Pavilion

At the Project Pavilion, the Istio kiosk was constantly buzzing, drawing users with questions about Ambient Mesh, AI workloads, and deployment best practices.

{{< image width="75%" link="./istio-kiosk.png" caption="Istio Project Pavilion" >}}

The Maintainer Track brought contributors together to collaborate on roadmap topics, triage issues, and discuss key areas of investment for the next year.

{{< image width="75%" link="./istio-contributors.jpg" caption="Istio Maintainers" >}}

At ContribFest, new contributors joined maintainers to work through good-first issues, discuss contribution pathways, and get their first PRs lined up.

{{< image width="75%" link="./istio-contribfest.png" caption="Istio ContribFest Collaboration" >}}

## Istio Maintainers Recognized at the CNCF Community Awards

This year’s [CNCF Community Awards](https://www.cncf.io/announcements/2025/11/12/cncf-honors-innovators-and-defenders-with-2025-community-awards-at-kubecon-cloudnativecon-north-america/) were a proud moment for the project. Two Istio maintainers received well-deserved recognition:

* John Howard — Top Committer Award
* Daniel Hawton — “Chop Wood, Carry Water” Award

{{< image width="75%" link="./cncf-awards.jpg" caption="Istio at CNCF Community Awards" >}}

Beyond these awards, Istio was also represented prominently in conference leadership. Faseela K, one of the KubeCon NA co-chairs and an Istio maintainer, participated in a keynote panel on [Cloud Native for Good](YouTube link to be added).

During closing remarks, it was also announced that Lin Sun, another long-time Istio maintainer, will serve as an upcoming KubeCon co-chair, highlighting the project’s strong leadership presence within CNCF.

{{< image width="75%" link="./keubecon-co-chairs.jpg" caption="Istio Leadership on Keynote Stage" >}}

## What We Heard in Atlanta

Across sessions, kiosks, and hallways, a few themes emerged:

* Ambient Mesh is shifting from exploration to real-world adoption.
* AI workloads are driving innovation in mesh traffic patterns and operational practices.
* Multicluster deployments are becoming commonplace, with attention to identity, control, and failover.
* Gateway API is solidifying as a core tool for modern traffic management.
* New contributors are joining in meaningful numbers, supported by ContribFest, hands-on guidance, and community engagement.

## Looking Ahead

KubeCon NA 2025 showcased a community that is vibrant, growing, and tackling some of the hardest challenges in modern cloud infrastructure—from AI traffic management to zero-downtime migrations, from scaling planet-wide control planes to building the next generation of sidecar-less mesh.

As we look ahead to 2026, the energy from Atlanta gives us confidence: the future of service mesh is bright, and the Istio community is leading the way—together.

{{< image width="75%" link="./kubecon-eu-2026.jpg" caption="See you in Amsterdam" >}}