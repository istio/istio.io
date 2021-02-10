---
title: "Defense in Depth Security for Microservices"
opening_paragraph: "Istio’s traffic management model relies on the Envoy proxies that are deployed along with your services. All traffic that your mesh services send and receive (data plane traffic) is proxied through Envoy, making it easy to direct and control traffic around your mesh without making any changes to your services."
author:
    name: ""
    image: ""
image: "defense.svg"
skip_feedback: true
skip_toc: true
skip_byline: true
skip_pagenav: true
layout: solution
doc_type: article
sidebar_force: sidebar_solution
---

Metrics and traceability standardized across services which provide an increase in reliability, not an increase in paging fatigue or heavy loads of unprocessed data.

SRE builds on observability of services. Successful SRE needs winnowed down, clearly actionable data:

- Key signals as alerts for short term availability 
- Historical analysis to design for long term availability

The same golden signals of latency, traffic, errors, and saturation need to be collected and viewed for all services and potentially all pods.

## Who is involved

## Additional Stakeholders

## Preconditions
- A microservices architecture, such as a Kubernetes deployment or a VM-based implementation. 
- DevOps practices in place.

## Workflow
Istio proxy and service level metrics instituted, collecting Envoy statistics and passing to Prometheus. Grafana standardized dashboards are made available to teams. Distributed tracing is also implemented.

Consider implementing Kiali

If metric cardinality is creating excess data and traffic, implement federated Prometheus servers to roll-up rules.

## Workflow
Proxy level, service level, and tracing metrics are available in a standardized way. Alerting and paging are actionable and not bogging down forward-looking work by engineers.

{{< inline_image "service-mesh.svg" true >}}