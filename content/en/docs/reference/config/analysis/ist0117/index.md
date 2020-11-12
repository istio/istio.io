---
title: DeploymentRequiresServiceAssociated
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when pods are not associated with any services.

A pod must belong to at least one Kubernetes service even if the pod does NOT expose any port.

See the [Istio Requirements](../../../../ops/deployment/requirements).
