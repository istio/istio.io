---
title: "Defense in Depth Security for Microservices"
opening_paragraph: "Istio’s traffic management model relies on the Envoy proxies that are deployed along with your services. All traffic that your mesh services send and receive (data plane traffic) is proxied through Envoy, making it easy to direct and control traffic around your mesh without making any changes to your services."
image: "defense.svg"
skip_toc: true
doc_type: article
sidebar_force: sidebar_solution
type: solutions
---

Metrics and traceability standardized across services which provide an increase in reliability, not an increase in paging fatigue or heavy loads of unprocessed data.

SRE builds on observability of services. Successful SRE needs winnowed down, clearly actionable data:

- Key signals as alerts for short term availability 
- Historical analysis to design for long term availability

The same golden signals of latency, traffic, errors, and saturation need to be collected and viewed for all services and potentially all pods.

## Who is involved
<div class="multi-block-wrapper">
{{< multi_block header="SRE Team" icon="people" >}}
Structuring best practices for achieving service level objectives through short term remediation and long-term service improvement.
{{< /multi_block >}}
{{< multi_block header="Devops Team" icon="people" >}}
Developers tasked with the building, deployment, and operation of a subset of the services in the organization.
{{< /multi_block >}}
</div>

## Additional Stakeholders
<div class="multi-block-wrapper">
{{< multi_block header="Platform owner" icon="person" >}}
(if separate from the SRE team)
{{< /multi_block >}}
{{< multi_block header="Devops TeBusiness owner" icon="person" >}}
and related service level agreement
{{< /multi_block >}}
</div>

## Preconditions
- A microservices architecture, such as a Kubernetes deployment or a VM-based implementation. 
- DevOps practices in place.

## Workflow
Istio proxy and service level metrics instituted, collecting Envoy statistics and passing to Prometheus. Grafana standardized dashboards are made available to teams. Distributed tracing is also implemented.

Consider implementing Kiali

If metric cardinality is creating excess data and traffic, implement federated Prometheus servers to roll-up rules.

## Workflow
Proxy level, service level, and tracing metrics are available in a standardized way. Alerting and paging are actionable and not bogging down forward-looking work by engineers.

{{< figure src="/img/service-mesh.svg" alt="Service mesh" >}}