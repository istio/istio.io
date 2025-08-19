---
title: Workload Instance Principal
test: n/a
---

The verifiable authority under which a [workload instance](/docs/reference/glossary/#workload-instance) runs.
Istio's service-to-service authentication is used to produce the workload principal.
By default workload principals are compliant with the SPIFFE ID format.

Workload instance principals are available in policy and telemetry configuration
using the `source.principal` and `destination.principal` [attributes](/docs/reference/glossary/#attribute).
