---
title: Design Goals
headline: Design Goals
sidenav: doc-side-concepts-nav.html
bodyclass: docs
layout: docs
type: markdown
---

{% capture overview %}
This page the core principles that guide Istio's design.
{% endcapture %}

{% capture body %}

## Design goals

Istio’s architecture is informed by a few key design goals that are essential to making the system capable of dealing with services at scale and with high 
performance.

- **Maximize Transparency**.
To adopt Istio an operator or developer should be required to do the minimum amount of work possible to get real value from the system. To this end Istio 
can automatically inject itself into all the network paths between services. Istio uses sidecar proxies to capture traffic and where possible automatically 
program the networking layer to route traffic through those proxies without any changes to the deployed application code. In Kubernetes the proxies are 
injected into pods and traffic is captured by programming iptables rules. Once the sidecar proxies are injected and traffic routing is programmed Istio is 
able to mediate all traffic. This principle also applies to performance. When applying Istio to a deployment operators should see a minimal increase in 
resource costs for the 
functionality being provided. Components and APIs must all be designed with performance and scale in mind.

- **Incrementality**.
As operators and developers become more dependent on the functionality that Istio provides, the system must grow with their needs. While we expect to 
continue adding new features ourselves, we expect the greatest need will be the ability to extend the policy system, to integrate with other sources of policy and control and to propagate signals about mesh behavior to other systems for analysis. The policy runtime supports a standard extension mechanism for plugging in other services. In addition it allows for the extension of its vocabulary to allow policies to be enforced based on new signals that the mesh produces. 

- **Portability**.
The ecosystem in which Istio will be used varies along many dimensions. Istio must run on any cloud or on-prem environment with minimal effort. The task of 
porting Istio-based services to new environments should be trivial, and it should be possible to operate a single service deployed into multiple 
environments (on multiple clouds for redundancy for example) using Istio.

- **Policy Uniformity**.
The application of policy to API calls between services provides a great deal of control over mesh behavior but it can be equally important to apply 
policies to resources which are not necessarily expressed at the API level. For example applying quota to the amount of CPU consumed by an ML training task 
is more useful than applying quota to the call which initiated the work. To this end the policy system is maintained as a distinct service with its own API 
rather than being baked into the proxy/sidecar, allowing services to directly integrate with it as needed.

{% endcapture %}

{% include templates/concept.md %}
