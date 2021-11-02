---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.12.0.
weight: 20
---

{{< warning >}}
This is an automatically generated rough draft of the release notes and has not yet been reviewed.
{{< /warning >}}

When you upgrade from Istio x.y.(z-1) to Istio x.y.z, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio x.y.(z-1).
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio x.y.(z-1).

## TCP probes now working as expected
When using TCP probes with older versions of istio the check was always successful, even if the application didn't open the port.
This may cause problems when upgrading: If you had a missconfiguration in a TCP probe (e.g wrong port) you maybe haven't noticed.
After the upgrade a missconfigured TCP probe will fail and therefore might cause downtimes.

## Default revision must be switched when performing a revision-based upgrade.
When installing a new Istio control plane revision the previous resource validator will remain unchanged to prevent
unintended effects on the existing, stable revision. Once prepared to migrate over to the new control plane revision,
cluster operators should switch the default revision. This can be done thorugh `istioctl tag set default --revision <new revision>`,
or if using a Helm-based flow, `helm upgrade istio-base manifests/charts/base -n istio-system --set defaultRevision=<new revision>`.

