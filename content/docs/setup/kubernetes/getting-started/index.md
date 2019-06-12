---
title: Getting Started
description: Download and install Istio.
weight: 5
keywords: [kubernetes]
---

{{< tip >}}
These quick-start instructions are for new users that want to try out Istio on Kubernetes.
Istio can also be installed and customized in many other ways, depending on your platform and intended use.
Check out our [general installation instructions](/docs/setup/) for details.
{{< /tip >}}

If you’re new to Istio and just want to try it out, the quickest way to get started is
by downloading and installing Istio's built-in **demo** configuration by following these simple steps:

1. [Setup your platform](/docs/setup/kubernetes/platform-setup/)
1. [Download the Istio release](/docs/setup/kubernetes/#downloading-the-release)
1. [Follow the quick-start installation instructions](/docs/setup/kubernetes/install/kubernetes)

Once you've installed Istio, a good way to start evaluating Istio's features is using our
[Bookinfo sample application](/docs/examples/bookinfo/).
You can use this sample to experiment with Istio’s features for traffic routing,
fault injection, rate limitting, etc..

1. [Deploy the Bookinfo sample](/docs/examples/bookinfo/#if-you-are-running-on-kubernetes)
1. Explore various [Istio tasks](/docs/tasks/), depending on your interest.
    The following tasks are a good start for beginners:
    * [Request routing](/docs/tasks/traffic-management/request-routing/)
    * [Fault injection](/docs/tasks/traffic-management/fault-injection/)
    * [Traffic shifting](/docs/tasks/traffic-management/traffic-shifting/)
    * [Querying metrics](/docs/tasks/telemetry/metrics/querying-metrics/)
    * [Visualizing metrics](/docs/tasks/telemetry/metrics/using-istio-dashboard/)
    * [Collecting logs](/docs/tasks/telemetry/logs/collecting-logs/)
    * [Rate limiting](/docs/tasks/policy-enforcement/rate-limiting/)
    * [Ingress gateways](/docs/tasks/traffic-management/ingress/ingress-control/)
    * [Accessing external services](/docs/tasks/traffic-management/egress/egress-control/)
    * [Visualizing your mesh](/docs/tasks/telemetry/kiali/)

After that, you will have a pretty good understanding of Istio's basic functionality and can then
proceed to explore Istio's many other tasks or, even better, start to deploy your own applications.
If you do continue to use Istio, we look forward to hearing from you.
