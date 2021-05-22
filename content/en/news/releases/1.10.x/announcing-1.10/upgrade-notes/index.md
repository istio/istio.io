---
title: Istio 1.10 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.10.0.
publishdate: 2021-05-18
linktitle: 1.10 Upgrade Notes
weight: 20
---

When you upgrade from Istio 1.9 to Istio 1.10, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.9.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.9.

## Inbound Forwarding Configuration

The behavior of inbound forwarding has been modified for Istio 1.10. This change is enabled
by default in Istio 1.10 and it can be disabled by configuring the `PILOT_ENABLE_INBOUND_PASSTHROUGH=false` environment
variable in Istiod.

Previously, requests would be forwarded to `localhost`. This leads to two important differences compared to running applications
without Istio:

* Applications that bind to `localhost` will be exposed to external pods.
* Applications that bind to `<POD_IP>` will not be exposed to external pods.

The latter is a common source of friction when adopting Istio, in particular with stateful services where this is common.

The new behavior instead forwards the request as is. This matches the behavior a user would see without Istio installed.
However, as a result, applications that have come to rely on `localhost` being exposed externally by Istio may stop working.

To help detect these situations, we have added a check to find pods that will be impacted. You can run the `istioctl
experimental precheck` command to get a report of any pods binding to `localhost` on a port exposed in a Service. This command is
available in Istio 1.10+. Without action, these ports will no longer be accessible upon upgrade.

{{< text bash >}}
$ istioctl experimental precheck
Error [IST0143] (Pod echo-local-849647c5bd-g9wxf.default) Port 443 is exposed in a Service but listens on localhost. It will not be exposed to other pods.
Error [IST0143] (Pod echo-local-849647c5bd-g9wxf.default) Port 7070 is exposed in a Service but listens on localhost. It will not be exposed to other pods.
Error: Issues found when checking the cluster. Istio may not be safe to install or upgrade.
See https://istio.io/latest/docs/reference/config/analysis for more information about causes and resolutions.
{{< /text >}}

Regardless of Istio version, the behavior can be explicitly controlled by the `Sidecar`.
For example, to configure the 9080 port to explicitly be sent to localhost:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: ratings
spec:
  workloadSelector:
    labels:
      app: ratings
  ingress:
  - port:
      number: 9080
      protocol: HTTP
      name: http
    defaultEndpoint: 127.0.0.1:9080
{{< /text >}}

## Sidecar Injector Changes

The logic to determine if a pod requires sidecar injection or not has been updated to make use of
new Kubernetes features. Previously, the webhook was triggered at a coarse grain level, selecting any
pods in a namespace with a matching `istio-injection=enabled` label.

This has two limitations:

* Opting out individual pods with the `sidecar.istio.io/inject` annotation would still trigger the webhook,
  only to be filtered out by Istio. This can have the unexpected impact of adding a dependency on Istio
  when one is not expected.

* There is no way to opt-in an individual pod, with `sidecar.istio.io/inject`, without enabling injection
  for the entire namespace.

These limitations have both been resolved. As a result, additional pods may be injected that were not in previous versions,
if they exist in a namespace without an `istio-injection` label set but have the `sidecar.istio.io/inject` annotation set to `true` on the pod.
This is expected to be an uncommon case, so for most users there will be no behavioral changes to existing pods.

If this behavior is not desired, it can be temporarily disabled with `--set values.sidecarInjectorWebhook.useLegacySelectors=true`.
This option will be removed in future releases.

See the updated [Automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/) documentation for more information.

## Multicluster `.global` stub domain

As part of the fixes for [ISTIO-SECURITY-2021-006](/news/security/istio-security-2021-006/), the [previously deprecated](/news/releases/1.8.x/announcing-1.8/upgrade-notes/#multicluster-global-stub-domain-deprecation) `.global` stub domain for multicluster will no longer work.

This change can be temporarily disabled if desired by setting the environment variable `PILOT_ENABLE_LEGACY_AUTO_PASSTHROUGH=true` in Istiod. However, this is strongly discouraged, as it negates the fix to [ISTIO-SECURITY-2021-006](/news/security/istio-security-2021-006/).

Please follow the [Multicluster Installation documentation](/docs/setup/install/multicluster/) for more information.
