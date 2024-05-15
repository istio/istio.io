---
title: The Istio service mesh
description: Service mesh.
subtitle: Istio addresses the challenges developers and operators face with a distributed or microservices architecture. Whether you're building from scratch, migrating existing applications to cloud native, or securing your existing estate, Istio can help. 
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

A **service mesh** is an infrastructure layer that gives applications capabilities like zero-trust security, observability, and advanced traffic management, without code changes. **Istio** is the most popular, powerful, and trusted service mesh. Founded by Google and IBM in 2016, Istio is a graduated project in the Cloud Native Computing Foundation alongside projects like Kubernetes and Prometheus.

Istio ensures that cloud native and distributed systems are resilient, helping modern enterprises maintain their workloads across diverse platforms while staying connected and protected. It [enables security and governance controls](/docs/concepts/observability/) including mTLS encryption, policy management and access control, [powers network features](/docs/concepts/traffic-management/) like canary deployments, A/B testing, load balancing, failure recovery, and [adds observability](/docs/concepts/observability/) of traffic across your estate.

Istio is not confined to the boundaries of a single cluster, network or runtime — services running on Kubernetes or VMs, multi-cloud, hybrid, or on-premises, can be included within a single mesh.

Extensible by design and supported by a [broad ecosystem](/about/ecosystem) of contributors and partners, Istio offers packaged integrations and distributions for various use cases. You can install Istio independently or opt for managed support from commercial vendors providing Istio-based solutions.

<div class="cta-container">
    <a class="btn" href="/docs/overview/">Learn more about Istio</a>
</div>

{{< /centered_block >}}

<br/><br/>

# Features

{{< feature_block header="Secure by default" image="security.svg" >}}
Istio provides a market-leading zero-trust solution based on workload identity, TLS, and strong policy controls. Istio delivers the value of [BeyondProd](https://cloud.google.com/security/beyondprod/) in open source, while avoiding vendor lock-in or SPOFs.

<a class="btn" href="/docs/concepts/security/">Learn more about security</a>
{{< /feature_block>}}

{{< feature_block header="Increase observability" image="observability.svg" >}}
Istio generates telemetry within the service mesh, enabling observability on service behavior. It integrates with APM systems including Grafana and Prometheus to deliver insightful metrics for operators to troubleshoot, maintain, and optimize applications.

<a class="btn" href="/docs/concepts/observability/">Learn more about observability</a>
{{< /feature_block>}}

{{< feature_block header="Manage traffic" image="management.svg" >}}
Istio simplifies traffic routing and service-level configuration, allowing easy control over flow between services and setup of tasks like A/B testing, canary deployments, and staged rollouts with percentage-based traffic splits.

<a class="btn" href="/docs/concepts/traffic-management/">Learn more about traffic management</a>
{{< /feature_block>}}

<br/><br/>

# Why Istio?

{{< feature_block header="Multiple deployment modes" image="istio-logo-with-brand.svg" >}}
Istio offers two data plane modes for users to choose. Deploy with the new ambient mode for a simplified app operational lifecycle or with traditional sidecars for complex configurations.

<a class="btn" href="/docs/overview/dataplane-modes/">Learn more about Istio's dataplane modes</a>
{{< /feature_block>}}

{{< feature_block header="Powered by Envoy" image="istio-logo-with-brand.svg" >}}
Built on the industry standard gateway proxy for cloud native applications, Istio is highly performative and extensible by design. Add functionality with WebAssembly, or integrate third-party policy systems.

<a class="btn" href="/docs/overview/why-choose-istio/#envoy">Learn more about Istio and Envoy</a>
{{< /feature_block>}}

{{< feature_block header="True Community Project" image="istio-logo-with-brand.svg" >}}
Istio has been designed for modern workloads and engineered by a vast community of innovators across the cloud native landscape.

<a class="btn" href="/docs/overview/why-choose-istio/#community">Learn more Istio's contributors</a>
{{< /feature_block>}}

{{< feature_block header="Stable binary releases" image="istio-logo-with-brand.svg" >}}
Confidently deploy Istio across production workloads. All releases are fully accessible at no cost.

<a class="btn" href="/docs/overview/why-choose-istio/#packages">Learn about how Istio is packaged</a>
{{< /feature_block>}}
