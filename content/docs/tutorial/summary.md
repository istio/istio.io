---
title: Summary
overview: Tutorial summary and next steps.

weight: 980

---

As you saw in the tutorial modules, Istio provides the following features:

* Management of the traffic between the microservices. With Istio you can perform canary deployments,
traffic shadowing, phased rollouts and A/B testing.
* Reporting and Monitoring. With Istio you can collect logs and metrics related to the traffic between your
microservices, monitor traffic by a dashboard, examine distributed tracing and service graph.
* Fault injection.
* Traffic encryption.
* Security policies enforcement.

# Next steps to learn Istio

Istio provides many more features, not covered in this tutorial.
For example, Istio supports various microservices patterns, like
[timeouts](/docs/tasks/traffic-management/request-timeouts),
[retries](/docs/reference/config/istio.networking.v1alpha3/#HTTPRetry),
[rate limitings](/docs/tasks/policy-enforcement/rate-limiting/),
[circuit breakers](/docs/tasks/traffic-management/circuit-breaking).

Also note that [Istio can run on VMs](/docs/guides/integrating-vms).
Istio can be integrated with [service registries](/docs/setup/consul) other than Kubernetes.
Istio can [control the traffic from the outside into the service mesh](/docs/tasks/traffic-management/ingress)
and [the traffic to external services](/docs/tasks/traffic-management/egress).

And, last but not least, Istio can be used to
[connect applications in multiple clusters](/docs/setup/kubernetes/multicluster-install/).

See more tasks, examples and blog posts at [istio.io](/).
