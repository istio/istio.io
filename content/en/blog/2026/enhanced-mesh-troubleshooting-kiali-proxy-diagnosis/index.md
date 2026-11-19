---
title: "Enhanced Mesh Troubleshooting: How Kiali Helps You Diagnose Proxy Issues"
description: Kiali v2.34 surfaces Envoy memory pressure on workloads and waypoints, classifies likely causes, and ties diagnostics to historical health and AI-assisted investigation.
publishdate: 2026-11-19
attribution: "Josune Córdoba"
keywords: [istio, kiali, envoy, observability, troubleshooting, ambient, waypoint]
---

Keeping your service mesh healthy means catching problems before they show up as failed requests or restart loops. [Kiali](https://kiali.io/) has long helped you visualize traffic and configuration; with **Kiali v2.34**, troubleshooting goes further by highlighting **istio-proxy** memory pressure and pointing you toward the right next step while the proxy is still healthy.

High memory use in Envoy is easy to overlook in production. Until a pod hits its limit or the kubelet evicts it, you might not notice anything wrong unless you are watching the right dashboards. Kiali adds a **workload-level memory indicator** that warns when a proxy is approaching its limits:

{{< image width="90%" link="./envoy-indicator-workload-details.png" caption="Envoy indicator on the workload details page" >}}

From that indicator you can jump straight to the dedicated **Envoy Overview** page. There, Kiali summarizes configuration and performance signals, highlights potential memory bottlenecks, and connects related trends so you can decide whether to scope configuration, adjust limits, or address load—before memory becomes an outage.

{{< image width="50%" link="./envoy-tooltip-degraded-state.png" caption="Envoy tooltip showing a likely cause of a degraded memory state" >}}

## Inside the Envoy overview

The Envoy Overview tab is a focused dashboard: configuration summary, threshold-based status in a banner, and charts that answer a practical question—**why is this proxy using so much memory?** When memory is high, Kiali classifies the situation into one of these guidance categories:

- **Large configurations**: Heavy dynamic configuration (many clusters, listeners, or routes), which you can often reduce with Istio [configuration scoping](/docs/ops/configuration/mesh/configuration-scoping/).
- **Heavy active traffic**: The proxy is simply handling a high volume of live requests or connections.

{{< image width="90%" link="./envoy-overview-tab.png" caption="Envoy Overview tab with memory status and context" >}}

### How memory status is calculated

Kiali marks memory as **high** when peak istio-proxy memory in the selected time range exceeds a warning threshold for the most pressured pod in the workload. It prefers **container working set** metrics; if those are unavailable, it falls back to **Envoy allocated memory**. Limits are evaluated **per pod**, using sidecar annotations and/or `container_spec_memory_limit_bytes`.

When a proxy memory limit is set—for example on [waypoint proxies](/docs/ambient/overview/#waypoint-proxies)—the warning threshold is **70% of that limit**. If no limit is set, Kiali uses fixed defaults that differ for sidecars versus gateways and waypoints.

The warning only means memory is above threshold. Labels such as “configuration” versus “traffic” come from separate hints (cluster counts, request rates, connections, and byte rates); they do not change the underlying memory calculation.

### Large Envoy configuration

If memory is above threshold **and** active clusters exceed the large-config limit (**100** for sidecars, **150** for gateways and waypoints), that often correlates with higher proxy memory. When traffic is not busy, Kiali points toward **configuration** as the likely driver.

{{< image width="90%" link="./large-envoy-configuration-clusters.png" caption="A large number of active clusters can drive high proxy memory" >}}

### Active traffic

If memory is above threshold **and** at least one “busy” signal is present—roughly **≥ 100 HTTP req/s**, **≥ 10 active connections** (when Kiali can measure them), or **≥ 256 KiB/s TCP bytes** (typical for waypoints)—Kiali shifts the emphasis toward **load**. When the cluster footprint is already large, any busy signal tilts the label toward traffic; with a small footprint, busy traffic is the main reason to blame load instead of configuration.

{{< image width="90%" link="./high-traffic-proxy-memory.png" caption="High traffic rates can drive high proxy memory" >}}

### When the cause is unclear

Memory may be high while the configuration footprint is not large and no busy threshold is met, or memory metrics may be missing. In those cases the UI still shows elevated memory, but the classification stays neutral.

These labels are **guidance**, not a definitive root-cause verdict. Thresholds are not configurable in v2.34; if you need tunable limits for your environment, share feedback with the [Kiali community](https://github.com/kiali/kiali/issues).

### Memory vs. connections chart

The Envoy Overview chart plots istio-proxy **working set** and Envoy **allocated memory** over time. When a memory limit is set, the chart also shows the limit and a **70% warning** line. The right axis shows **active connections** over the same range so you can correlate memory growth with load.

## Ambient mesh and waypoint proxies

In **ambient** mode, workloads do not run a sidecar, so you will not see the Envoy memory indicator on application pods. Kiali still provides the same diagnostics for **waypoint** proxies, which can carry heavy L4 (and selected L7) load and need accurate sizing signals.

{{< image width="90%" link="./waypoint-envoy-overview.png" caption="Envoy Overview for a waypoint proxy" >}}

Waypoints rely more on **L4 metrics** and use different traffic thresholds because expected load is higher:

- **Sidecars and gateways**: Classification prioritizes HTTP req/s; if HTTP traffic is zero but TCP bytes are present, byte rates are used.
- **Waypoints**: Traffic is always classified using **TCP byte rates**, because the waypoint often operates at L4 and downstream HTTP stats may be absent; Istio TCP metrics (and HTTP metrics when available) fill the gap.

These memory diagnostics ship starting in **Kiali v2.34**.

## Deep-dive investigations

Beyond proxy memory visibility, v2.34 improves how you investigate mesh issues over time. When health metrics storage is enabled, Kiali can retain up to **seven days** of historical health for workloads, applications, services, and namespaces. From the diagnostic overview you can replay graph history or jump to related logs, traces, and metrics.

{{< image width="90%" link="./health-status-ribbon.png" caption="Health status ribbon with historical context" >}}

When the [Kiali assistant](https://kiali.io/docs/ai/kiali-chatbot/) is enabled, you can run prompt-based analyses for specific time windows—useful when you are correlating a memory spike with deployments or traffic shifts.

{{< image width="30%"
    link="./kiali-ai-investigation-prompt.png"
    caption="One-click prompt to start an AI-assisted investigation"
>}}

With these capabilities, Kiali helps you catch proxy performance problems early and gives you the context to resolve service mesh issues faster—whether you run classic sidecars, gateways, or ambient waypoints.

_A version of this article was first published on [the Kiali blog on Medium](https://medium.com/kialiproject/enhanced-mesh-troubleshooting-how-kiali-can-help-you-diagnose-proxy-issues-1f4e65104c40). Follow us there for more frequent updates._