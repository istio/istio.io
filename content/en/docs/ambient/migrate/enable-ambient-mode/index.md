---
title: Enable ambient mode
description: Label namespaces, activate waypoints, remove sidecar injection, and validate the migration.
weight: 4
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate/migrate-policies
---

Enable ambient mode one namespace at a time. This lets you validate each namespace before
moving on, and roll back a single namespace if something goes wrong.

## Ordering requirements

{{< warning >}}
The order of operations in this step is critical. Follow the sequence below exactly:

1. Activate waypoints **before** enabling ambient mode.
1. Enable ambient mode (label namespace).
1. Remove sidecar injection **after** ambient mode is confirmed working.
1. Restart pods **last**.
{{< /warning >}}

Failing to follow this sequence can result in traffic being processed by neither sidecar nor
ztunnel, causing disruption in your workloads.

## Step 1: Activate waypoints

{{< tip >}}
Skip this step if you are not using waypoints.
{{< /tip >}}

Activate waypoints deployed in the [previous step](/docs/ambient/migrate/install-ambient-components/)
by adding the `istio.io/use-waypoint` label.

To activate a waypoint for an entire namespace:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/use-waypoint=waypoint
{{< /text >}}

To activate a waypoint for a specific Service only:

{{< text syntax=bash snip_id=none >}}
$ kubectl label service <service-name> -n <namespace> istio.io/use-waypoint=waypoint
{{< /text >}}

Verify the waypoint is ready:

{{< text syntax=bash snip_id=none >}}
$ kubectl get gateway waypoint -n <namespace>
{{< /text >}}

The `READY` column should show `True`.

## Step 2: Enable ambient mode for the namespace

Add the `istio.io/dataplane-mode=ambient` label to the namespace. This tells the CNI
plugin that new and restarted pods in this namespace should use ztunnel instead of
(or alongside) a sidecar:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/dataplane-mode=ambient
{{< /text >}}

Verify that the namespace is now enrolled in the ambient mesh:

{{< text syntax=bash snip_id=none >}}
$ istioctl ztunnel-config workloads -n istio-system | grep <namespace>
{{< /text >}}

Workloads in the namespace will appear with `HBONE` as their protocol. The pods still
have their sidecars at this point , note that the sidecar takes precedence over ztunnel for pods
that have both.

## Step 3: Remove sidecar injection

Remove the sidecar injection label from the namespace:

If you use the default injection label:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio-injection-
{{< /text >}}

If you use a revision label:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/rev-
{{< /text >}}

{{< warning >}}
Removing the injection label alone does not remove existing sidecars. Pods must be
restarted for the change to take effect. Do not restart pods until you have confirmed
that ambient mode is active (Step 2 above).
{{< /warning >}}

## Step 4: Restart pods

Restart the workloads in the namespace. As pods restart, they will come up without sidecar
containers and will use ztunnel (and waypoint, if configured) instead:

{{< text syntax=bash snip_id=none >}}
$ kubectl rollout restart deployment -n <namespace>
$ kubectl rollout status deployment -n <namespace>
{{< /text >}}

## Step 5: Remove old sidecar policies

{{< warning >}}
Do this immediately after the pod restart, before running any validation. Any
`AuthorizationPolicy` using a workload `selector` with L7 rules that remains active
after sidecars are removed will be enforced by ztunnel as a `DENY` policy for all
traffic to that workload, regardless of the HTTP method or path.
{{< /warning >}}

Delete any `AuthorizationPolicy` resources that used a workload `selector` with L7 rules,
now that they have been replaced by `targetRefs`-based equivalents:

{{< text syntax=bash snip_id=none >}}
$ kubectl delete authorizationpolicy <sidecar-policy-name> -n <namespace>
{{< /text >}}

Also remove `VirtualService` and `DestinationRule` resources replaced by `HTTPRoute`:

{{< text syntax=bash snip_id=none >}}
$ kubectl delete virtualservice <name> -n <namespace>
$ kubectl delete destinationrule <name> -n <namespace>
{{< /text >}}

L4 `AuthorizationPolicy` resources using `selector` (with no L7 rules) are safe to keep,
ztunnel enforces them correctly.

## Step 6: Validate

Verify that pods are running without sidecar containers:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n <namespace>
{{< /text >}}

Confirm that ztunnel is managing the workloads:

{{< text syntax=bash snip_id=none >}}
$ istioctl ztunnel-config workloads -n istio-system | grep <namespace>
{{< /text >}}

If you deployed waypoints, verify that L7 policy and routing rules are being enforced by
testing the specific behaviors (header-based routing, HTTP method restrictions, etc.) that
your `HTTPRoute` and `AuthorizationPolicy` resources define.

## Repeat for each namespace

Repeat Steps 1–6 for each namespace you want to migrate. Namespaces not labeled with
`istio.io/dataplane-mode=ambient` continue to use their sidecars and are not affected.

## Rollback

Each step is independently reversible. Use the rollback procedure that matches how far you
have progressed:

| Step | Rollback action |
|---|---|
| After Step 1 (waypoints activated) | `kubectl label namespace <ns> istio.io/use-waypoint-` |
| After Step 2 (ambient enabled) | `kubectl label namespace <ns> istio.io/dataplane-mode-` |
| After Step 3 (injection removed) | Re-add injection label: `kubectl label namespace <ns> istio-injection=enabled` |
| After Step 4 (pods restarted) | Re-add injection label, then `kubectl rollout restart deployment -n <ns>` |
| After Step 5 (old policies deleted) | `kubectl apply -f istio-config-backup.yaml` to restore from backup |

After any rollback that involves pod restarts, verify that pods show 2/2 containers
(indicating the sidecar has been re-injected) and confirm traffic is flowing before
proceeding.

## Post-migration observability changes

After migrating to ambient mode, be aware of the following changes to telemetry:

**Metrics**: In sidecar mode, metrics are reported with `reporter="source"` and
`reporter="destination"`. In ambient mode, metrics from ztunnel use `reporter="source"`,
while metrics from waypoint proxies use `reporter="waypoint"`. Update any dashboards or
alerting rules that rely on the `reporter` label.

**Metrics merging**: In sidecar mode, the proxy agent supports
[metrics merging](/docs/ops/integrations/prometheus/#option-1-metrics-merging), which
combines Istio and application metrics into a single scrape target using the standard
`prometheus.io` annotations. This feature is not available in ambient mode. After
migration, you must configure Prometheus to scrape Istio components (ztunnel and waypoint
pods) and your application pods as separate targets. Update any `PodMonitor` or
`ServiceMonitor` resources that relied on a single merged endpoint.

**Tracing**: In sidecar mode, each hop generates two spans (one from the source sidecar,
one from the destination sidecar). In ambient mode with waypoints, one span is generated
per waypoint. Update trace-based SLOs accordingly.

**`istioctl proxy-status`**: This command does not show ztunnel workloads. Use
`istioctl ztunnel-config workloads` instead to inspect ambient proxy state.

For more information, see:

- [Troubleshooting ztunnel](/docs/ambient/usage/troubleshoot-ztunnel/)
- [Troubleshooting waypoints](/docs/ambient/usage/troubleshoot-waypoint/)
