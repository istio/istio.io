---
title: Summary
overview: Tutorial summary and next steps.

order: 98

layout: docs
type: markdown
---
{% include home.html %}

As we saw in the tutorial modules, Istio provides the following features:
* Control the traffic between the microservices. With Istio you can implement canary deployments, traffic shadowing, phased rollouts and A/B testing.
* Reporting and Monitoring. With Istio you can collect the logs about the traffic between all the microservices, collect metrics, implement a dashboard and calculate the service graph.
* Enforce security policies.
* Implement fault injection.

# Next steps to learn Istio
We learned explicit injection of Istio sidecar proxies into our microservices, incrementally. We can perform [automatic injection of the sidecar proxies]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection) and use the regular `kubectl` command to deploy our Istio-enabled microservices.

In addition, Istio can [encrypt the traffic between microservices]({{home}}/docs/tasks/security/mutual-tls.html). Also, Istio supports various microservices patterns, for example [timeouts]({{home}}/docs/tasks/traffic-management/request-timeouts.html), retries, [circuit breakers]({{home}}/docs/tasks/traffic-management/circuit-breaking.html).

Also note that [Istio can run on VMs]({{home}}/docs/guides/integrating-vms.html). Istio can be integrated with [service registries]({{home}}/docs/setup/) other than Kubernetes. Istio can [control the traffic from the outside into the service mesh]({{home}}/docs/tasks/traffic-management/ingress.html) and [the traffic to external services]({{home}}/docs/tasks/traffic-management/egress.html).

See more guides, tasks and blog posts at [istio.io]({{home}}).

{% include what-is-next-footer.md %}
