---
title: The Istio service mesh
description: Service mesh.
subtitle: Istio addresses the challenges developers and operators face with a distributed or microservices architecture. Whether you're building from scratch or migrating existing applications to cloud native, Istio can help. 
weight: 34
skip_toc: true
skip_byline: true
skip_pagenav: true
aliases:
    - /service-mesh.html
    - /docs/concepts/what-is-istio/overview
    - /docs/concepts/what-is-istio/goals
    - /about/intro
    - /docs/concepts/what-is-istio/
    - /latest/docs/concepts/what-is-istio/    
doc_type: about
---

{{< centered_block >}}

A **service mesh** is an infrastructure layer that gives applications capabilities like zero-trust security, observability, and advanced traffic management, without code changes. A service mesh supports modern DevOps practices by allowing individual teams to control policy around application and service communication safely, while still giving admins strong governance controls.

Istio is the most popular, most powerful and most trusted service mesh. Founded by Google and IBM in 2016, Istio is a graduated project in the Cloud Native Computing Foundation alongside projects like Kubernetes and Prometheus.

Making distributed systems reliable and performant requires operators to manage tasks like discovery, load balancing, failure recovery, metrics and monitoring. A service mesh aids you by handling operations such as encryption, access control, A/B testing, canary deployments, rate limiting, and authentication.

 ....  Istio solves these problems by ...."

Additionally, service mesh efficiently routes service-to-service communications within and across application clusters, crucial for distributed application functionality as service numbers grow.

A service mesh is not confined to the boundaries of a single cluster, network or runtime. Modern enterprises have workloads running on diverse platforms that must be connected and secured. Istio can efficiently route traffic between on-prem, cloud, Kubernetes, VMs and more - all in a single mesh.

<div class="cta-container">
    <a class="btn" href="/docs/overview/service-mesh-history/">Learn the history of service mesh</a>
</div>

{{< /centered_block >}}

{{< centered_block >}}

## What is Istio?

Istio, an open source service mesh, integrates with existing distributed applications, providing a standardized method for securing, connecting, and monitoring services. It simplifies functionality like load balancing, service-to-service authentication, and observability, with minimal or no code changes. Its design emphasizes extensibility, accommodating diverse deployment needs.

The Istio control plane operates within Kubernetes, allowing users to add applications from the same cluster, extend the mesh to other clusters, or connect external endpoints like VMs. Supported by a [broad ecosystem](/about/ecosystem) of contributors and partners, Istio offers packaged integrations and distributions for various use cases. You can install Istio independently or opt for managed support from commercial vendors providing Istio-based solutions.

<div class="cta-container">
    <a class="btn" href="/docs/overview/what-is-istio/">Learn more about Istio</a>
</div>

{{< /centered_block >}}

<br/><br/>

# Features

{{< feature_block header="Secure by default" image="security.svg" >}}
Istio provides a security solution with identity, policy, TLS encryption, and authentication, authorization, and audit tools, based on a security-by-default model for deploying applications across distrusted networks with in-depth defense.

<a class="btn" href="/docs/concepts/security/">Learn more about security</a>
{{< /feature_block>}}

{{< feature_block header="Increase observability" image="observability.svg" >}}
Istio generates telemetry within the service mesh, offering observability of service behavior, enabling operators to troubleshoot, maintain, and optimize applications, with minimal application changes.

<a class="btn" href="/docs/concepts/observability/">Learn more about observability</a>
{{< /feature_block>}}

{{< feature_block header="Manage traffic" image="management.svg" >}}
Istio simplifies traffic routing and service-level configuration, allowing easy control over flow between services and setup of tasks like A/B testing, canary deployments, and staged rollouts with percentage-based traffic splits.

<a class="btn" href="/docs/concepts/traffic-management/">Learn more about traffic management</a>
{{< /feature_block>}}

<br/><br/>

# Why Istio?

{{< feature_block header="Multiple deployment modes" image="istio-logo-with-brand.svg" >}}
Istio offers two data planes for users to choose. Deploy with the new ambient mode for a simplified app operational lifecycle or with traditional sidecars for complex configurations. 

<a class="btn" href="/docs/overview/dataplane-modes/">Learn more about Istio's dataplane modes</a>
{{< /feature_block>}}

{{< feature_block header="Powered by Envoy" image="istio-logo-with-brand.svg" >}}
Built on the industry standard gateway proxy for cloud-native applications, Istio is highly performative and extensible by design offering deep observability insights and security. 

<a class="btn" href="/docs/overview/why-istio/#envoy">Learn more about Istio and Envoy</a>
{{< /feature_block>}}

{{< feature_block header="True Community Project" image="istio-logo-with-brand.svg" >}}
Istio has been designed for modern workloads and engineered by a vast community of innovators across the cloud native landscape. 

<a class="btn" href="/docs/overview/why-istio/#community">Learn more Istio's contributors</a>
{{< /feature_block>}}

{{< feature_block header="Stable binary releases" image="istio-logo-with-brand.svg" >}}
Confidently deploy Istio across production workloads. Each release is fully accessible at no cost.

<a class="btn" href="/docs/overview/why-istio/#packages">Learn about how Istio is packaged</a>
{{< /feature_block>}}