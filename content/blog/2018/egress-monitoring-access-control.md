---
title: Telemetry and Access Control for Egress Traffic
description: Describes how to configure Istio to direct egress traffic through a dedicated service, for collecting telemetry for egress traffic and applying access control to egress traffic.
publishdate: 2018-06-20
subtitle:
attribution: Vadim Eisenberg and Ronen Schaffer
weight: 86
keywords: [egress, access-control, monitoring]
---

While the main focus of Istio is managing traffic between the microservices inside a service mesh, Istio can also  manage ingress (from outside to the mesh) and egress (from the mesh outside) traffic. Istio can uniformly enforce access policies and aggregate telemetry data for mesh-internal, ingress and egress traffic.

In this blog post we show how Istio monitoring and access policies are applied to egress traffic.

## Use case

Consider an organization that runs applications that process content of _cnn.com_. The applications are decomposed into microservices deployed in Istio service mesh. The applications access pages of various topics of _cnn.com_: [edition.cnn.com/politics](https://edition.cnn.com/politics), [edition.cnn.com/sport](https://edition.cnn.com/sport) and  [edition.cnn.com/health](https://edition.cnn.com/health). The organization [configures Istio to allow access to edition.cnn.com](docs/tasks/traffic-management/egress-tls-origination/) and everything works fine. However, at some point in time the organization decides to banish politics. Practically, it means blocking access to [edition.cnn.com/politics](https://edition.cnn.com/politics) and allowing access to [edition.cnn.com/sport](https://edition.cnn.com/sport) and  [edition.cnn.com/health](https://edition.cnn.com/health) only.

To achieve that goal, the organization's operations people will monitor the access to the external services and will analyze the Istio logs to verify that no request to [edition.cnn.com/politics](https://edition.cnn.com/politics) was sent. They will also configure Istio to prevent access to [edition.cnn.com/politics](https://edition.cnn.com/politics) automatically.

The organization is resolved to prevent any tampering with the new policy. It decided to put mechanisms in place that will prevent any possibility for a malicious application to access the forbidden topic.

## Related Istio tasks

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task demonstrates how external (outside the Kubernetes cluster) HTTP and HTTPS services can be accessed from applications inside the mesh. The [TLS Origination for Egress Traffic](docs/tasks/traffic-management/egress-tls-origination/) task demonstrates how to allow the applications to send HTTP requests to external servers that require HTTPS. The <TBD> Configure an Egress Gateway task describes how to configure Istio to direct egress traffic through a dedicated gateway service called _egress gateway_.

This task describes how to configure Istio to collect telemetry for egress traffic and to apply access control on egress traffic. Note that if we want to accomplish that in a _secure way_, we must direct egress traffic through _egress gateway_, as described in the <TBD> Configure an Egress Gateway task. The _secure way_ here means that we want to prevent malicious applications from bypassing Istio monitoring and policy enforcement.

## Before you begin
