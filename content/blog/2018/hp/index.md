---
title: Istio is a Game Changer for HP Platform
publishdate: 2018-07-31
attribution: Steven Ceuppens, Chief Software Architect @ HP FitStation, Open Source Advocate / Contributor
weight: 85
---

The FitStation team at HP strongly believes in the future of Kubernetes, BPF and service-mesh as the next standards in cloud infrastructure. We are also very happy to see Istio coming to its official Istio 1.0 release -- thanks to the joint collaboration that started at Google, IBM and Lyft beginning in May 2017.

Throughout the development of FitStation’s large scale and progressive cloud platform, Istio, Cilium and Kubernetes technologies have delivered a multitude of opportunities to make our systems more robust and scalable. Istio was a game changer in creating reliable and dynamic network communication.

[FitStation powered by HP](http://www.fitstation.com) is a technology platform that captures 3D biometric data to design personalized footwear to perfectly fit individual foot size and shape as well as gait profile. It uses 3D scanning, pressure sensing, 3D printing and variable density injection molding to create unique footwear. Footwear brands such as Brooks, Steitz Secura or Superfeet are connecting to FitStation to build their next generation of high performance sports, professional and medical shoes.

FitStation is built on the promise of ultimate security and privacy for users' biometric data. ISTIO is the cornerstone to make that possible for data-at-flight within our cloud. By managing these aspects at the infrastructure level, we focused on solving business problems instead of spending time on individual implementations of secure service communication. Using Istio allowed us to dramatically reduce the complexity of maintaining a multitude of libraries and services to provide secure service communication.

As a bonus benefit of Istio 1.0, we gained network visibility, metrics and tracing out of the box. This radically improved decision-making and response quality for our development
and devops teams. The team got in-depth insight in the network communication across the entire platform, both for new as well as legacy applications. The integration of Cilium
with Envoy delivered a remarkable performance benefit on Istio service mesh communication, combined with a fine-grained kernel driven L7 network security layer. This was due to the powers of BPF brought to Istio by Cilium. We believe this will drive the future of Linux kernel security.

It has been very exciting to follow Istio’s growth. We have been able to see clear improvements of performance and stability over the different development versions. The improvements between version 0.7 and 0.8 made our teams feel comfortable with version 1.0, we can state that Istio is now ready for real production usage.

We are looking forward to the promising roadmaps of Istio, Envoy, Cilium and CNCF.
