---
title: Istio 1.12 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.12.0.
publishdate: 2021-11-18
weight: 20
---

When you upgrade from Istio 1.10.0 or 1.11.0 to Istio 1.12.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.10.0 and 1.11.0.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.12.0.

## TCP probes now working as expected

When using TCP probes with older versions of Istio, the check was always successful. TCP probes simply check the port will accept a connection, and because all traffic is first redirected to the Istio sidecar, the sidecar will always accept the connection.
In Istio 1.12, this issue is resolved by using the [same mechanism used for HTTP probes](/docs/ops/configuration/mesh/app-health-check/).
As a result, TCP probes in 1.12+ will start to properly check the health of the configured port. If your probes previously would have failed, they may now start failing unexpectedly.
This change can be disabled temporarily by setting the `REWRITE_TCP_PROBES=false` environment variable in the Istiod deployment. The entire probe rewrite feature (HTTP and TCP) can also [be disabled](/docs/ops/configuration/mesh/app-health-check/#liveness-and-readiness-probes-using-the-http-request-approach).

## Default revision must be switched when performing a revision-based upgrade

When installing a new Istio control plane revision the previous resource validator will remain unchanged to prevent
unintended effects on the existing, stable revision. Once prepared to migrate over to the new control plane revision,
cluster operators should switch the default revision. This can be done through `istioctl tag set default --revision <new revision>`,
or if using a Helm-based flow, `helm upgrade istio-base manifests/charts/base -n istio-system --set defaultRevision=<new revision>`.
