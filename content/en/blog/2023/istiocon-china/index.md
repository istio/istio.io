---
title: "IstioCon China 2023 wrap-up"
description: A quick recap of Istio at KubeCon + CloudNativeCon + Open Source Summit China in Shanghai.
publishdate: 2023-09-29
attribution: "IstioCon China 2023 Program Committee"
keywords: [Istio Day,IstioCon,Istio,conference,KubeCon,CloudNativeCon]
---

It’s great to be able to safely get together in person again.  After two years of only running virtual events, we have filled the calendar for 2023. [Istio Day Europe](/blog/2023/istio-at-kubecon-eu/) was held in April, and [Istio Day North America](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/) is coming this November.

IstioCon is committed to the industry-leading service mesh that provides a platform to explore insights gained from real-world Istio deployments, engage in interactive hands-on activities, and connect with maintainers across the entire Istio ecosystem.

Alongside our [virtual IstioCon 2023](https://events.istio.io/) event, [IstioCon China 2023](https://www.lfasiallc.com/kubecon-cloudnativecon-open-source-summit-china/co-located-events/istiocon-cn/) was held on September 26 in Shanghai, China. Part of the KubeCon + CloudNativeCon + Open Source Summit China, the event was arranged and hosted by the Istio maintainers and the CNCF. We were very proud to have a strong program for IstioCon in Shanghai and pleased to bring together members of the Chinese Istio community. The event was a testament to Istio’s immense popularity in the Asia-Pacific ecosystem.

{{< image link="./group-pic.jpg"
    caption="IstioCon China 2023"
    >}}

IstioCon China kicked off with an opening keynote from Program Committee members Jimmy Song and Zhonghu Xu. The event was packed with great content, ranging from new features to end user talks, with major focus on the new Istio ambient mesh.

{{< image width="75%"
    link="./opening-keynote.jpg"
    caption="IstioCon China 2023, Welcome"
    >}}

The welcome speech was followed by a sponsored keynote from Justin Pettit from Google, on "Istio Ambient Mesh as a Managed Infrastructure" which highlighted the importance and priority of the ambient model in the Istio community, especially for our top supporters like Google Cloud.

{{< image width="75%"
    link="./sponsored-keynote-google.jpg"
    caption="IstioCon China 2023, Google Cloud Sponsored Keynote"
    >}}

Perfectly placed after the keynote, Huailong Zhang from Intel and Yuxing Zeng from Alibaba discussed configurations for the co-existence of Ambient and Sidecar: a very relevant topic for existing users who want to experiment with the new ambient model.

{{< image width="75%"
    link="./ambient-l4.jpg"
    caption="IstioCon China 2023, Deep Dive into Istio Network Flows and Configurations for the co-existence of Ambient and Sidecar"
    >}}

Huawei's new Istio data plane based on eBPF intends to implement the capabilities of L4 and L7 in the kernel,to avoid kernel-state and user-mode switching and reduce the latency of the data plane. This was explained by an interesting talk from Xie SongYang and Zhonghu Xu. Chun Li and Iris Ding from Intel also integrated eBPF with Istio, with their talk "Harnessing eBPF for Traffic Redirection in Istio ambient mode", leading to more interesting discussions. DaoCloud also had a presence at the event, with Kebe Liu sharing Merbridge’s innovation in eBPF and Xiaopeng Han presenting about MirageDebug for localized Istio development.

{{< image width="75%"
    link="./users-engaging.jpg"
    alt="interaction with audience"
    >}}

The talk from Tetrate’s Jimmy Song, about the perfect union of different GitOps and Observability tools, was also very well received. Chaomeng Zhang from Huawei presented on how cert-manager helps enhance the security and flexibility of Istio's certificate management system, and Xi Ning Wang and Zehuan Shi from Alibaba Cloud shared the idea of using VK (Virtual Kubelet) to implement serverless mesh.

While Shivanshu Raj Shrivastava gave a perfect introduction to WebAssembly through his talk "Extending and Customizing Istio with Wasm", Zufar Dhiyaulhaq from GoTo Financial, Indonesia shared the practice of using Coraza Proxy Wasm to extend Envoy and quickly implement custom Web Application Firewalls.
Huabing Zhao from Tetrate shared Aeraki Mesh's Dubbo service governance practices with Qin Shilin from Boss Direct. While multi-tenancy is always a hot topic with Istio, John Zheng from HP described in detail about multi-tenant management in HP OneCloud Platform.

The slides for all the sessions can be found in the [IstioCon China 2023 schedule](https://istioconchina2023.sched.com/) and all the presentations will be available in the CNCF YouTube Channel soon for the audience in other parts of the world.

## On the show floor

Istio had a full time kiosk in the project pavilion at KubeCon + CloudNativeCon + Open Source Summit China 2023 , with the majority of questions asked around ambient mesh. Many of our members and maintainers offered support at the booth, where a lot of interesting discussions happened.

{{< image width="75%"
    link="./istio-support-at-the-booth.jpg"
    caption="KubeCon + CloudNativeCon + Open Source Summit China 2023, Istio Kiosk"
    >}}

Another highlight was the Istio Steering Committee members and authors of the Istio books "Cloud Native Service Mesh Istio" and "Istio: the Definitive Guide", Zhonghu Xu and Chaomeng Zhang, spent time at the Istio booth interacting with our users and contributors.

{{< image width="75%"
    link="./meet-the-authors.jpg"
    caption="Meet the Authors"
    >}}

We would like to express our heartfelt gratitude to our diamond sponsors Google Cloud, for supporting IstioCon 2023!

{{< image width="40%"
    link="./diamond-sponsor.jpg"
    caption="IstioCon 2023, Our Diamond Sponsor"
    >}}

Last but not least, we would like to thank our IstioCon China Program Committee members for all their hard work and support!

{{< image width="75%"
    link="./istiocon-program-committee.jpg"
    caption="IstioCon China 2023, Program Committee Members (Not Pictured: Iris Ding)"
    >}}

[See you all in Chicago in November!](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/)
