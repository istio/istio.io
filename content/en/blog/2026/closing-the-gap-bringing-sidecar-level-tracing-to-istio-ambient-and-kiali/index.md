---
title: "Closing the Gap: Bringing Sidecar-Level Tracing to Istio Ambient and Kiali"
description: Tracing parity between ambient and sidecar modes arrives with Istio 1.29 and Kiali 2.25, closing the workload visibility gap.
publishdate: 2026-05-21
attribution: "Josune Córdoba"
keywords: [istio, ambient, tracing, kiali, telemetry, observability]
target_release: "1.30"
---

Istio ambient mode has been steadily evolving across recent releases. This evolution hasn’t always been linear; behaviors have shifted, and certain features only recently reached stability. Although ambient mode became **GA in version 1.24**, we can now confidently state that **tracing parity** between ambient mode and sidecar mode is a reality, specifically starting with **Istio 1.29 and Kiali 2.25 in regards to tracing.**

### The Role of Waypoint Proxies

First, it is important to clarify that L7 telemetry - both metrics and traces - in ambient mode is provided by **Waypoint proxies**. Unlike sidecar mode, where the proxy resides within the same pod as the application, a Waypoint is a shared, decoupled resource that can be scoped to a namespace, a service, or even specific workloads. It acts as the “gatekeeper” for the traffic it handles, processing all Layer 7 logic.

{{< image width="90%" link="./waypoint-traffic-graph.png" caption="The waypoint handling the traffic - view from Kiali's traffic graph" >}}

### The Shift in Identity: From Service to Waypoint

Because Waypoint proxies are external to the workload, identifying the “owner” of a trace has been an architectural challenge. In Istio 1.27, it was the waypoint proxy that created the trace using the waypoint name as the service.

{{< image width="90%" link="./service-traces-istio-127.png" caption="Service traces with Istio 1.27" >}}

In **Istio 1.28**, a change was introduced to attribute the trace directly to the destination service instead of the Waypoint. This behavior remained in **Istio 1.29**.

> Note that this shift was exclusive to the OpenTelemetry (OTel) provider; traditional formats like Zipkin continued to use the waypoint identity.

{{< image width="90%" link="./service-traces-istio-129.png" caption="Service traces with Istio 1.29" >}}

However, **Istio 1.30** refined this by treating the Waypoint as a **“first-class citizen.”** The Waypoint now preserves the architectural reality of the hop without obfuscating the destination. The operation name of the span correctly reflects the redirected service traffic, while the infrastructure metadata points to the Waypoint.

{{< image width="90%" link="./service-traces-istio-130.png" caption="Service traces with Istio 1.30" >}}

### The Missing Link: Workload Visibility

While service-to-service tracing was functional, there was a significant gap: **Workload-level granularity.** In sidecar mode, we rely on the _node_id_ attribute to identify specific pods. In ambient mode, this was the missing piece. If a service routed traffic to multiple versions of a workload (e.g., v1, v2, and v3), we could see the service hop, but we lost the ability to pinpoint which specific workload was processing the request - losing important information for debugging.

{{< image width="90%" link="./workload-visibility-gap.png" caption="Incomplete traceability without the workloads information" >}}

This gap was closed in **Istio 1.29**. By introducing explicit attributes such as _istio.source_workload_ and _istio.destination_workload_, and leveraging the Waypoint’s privileged “middleman” position, we now have a complete view of both the origin and the final destination.

{{< image width="90%" link="./span-attributes-trace.png" caption="Span attributes from a trace" >}}

### Kiali: The Unified Observability Plane

How does this look in **Kiali**? Thanks to these new attributes, Kiali’s **Trace Overlay** feature is now more powerful than ever with Istio Ambient Mesh. When selecting a trace, Kiali highlights the entire request path, including both services and the specific workloads involved, completing the view for a trace in the versioned app graph.

Kiali builds the traffic graph from metrics data, which provides the topology and a visual representation of how requests flow through the mesh. The **Trace Overlay** feature then uses the selected trace to highlight the nodes and edges that belong to that specific request path. In other words, metrics provide the structure of the graph, and tracing identifies the exact route taken by the request within that structure.

This works hop by hop. The selected trace provides a sequence of spans, and each span now includes attributes that identify both the service and the workload involved in that hop. With that information, Kiali can match each span to the corresponding elements in the versioned app graph and reconstruct the full path of the request, including the exact workload versions that actually processed the traffic.

{{< image width="90%" link="./kiali-trace-overlay.png" caption="Kiali trace overlay" >}}

One of the Kiali’s missions is to facilitate troubleshooting. In the **Workload Details** view, it correlates data automatically so you don’t have to manually hunt for traces hidden under a Waypoint’s name. Kiali identifies the associated Waypoint for a workload, queries the tracing provider, and filters the results for you.

{{< image width="90%" link="./kiali-service-details-traces.png" caption="Service traces in Kiali's Service details page" >}}

While Kiali by default looks for traces using the service name, you can fine-tune this behavior. If your environment requires it, based on the Istio version and Ambient mesh, you can configure how Kiali maps these identities, using the Kiali configuration _external_services.tracing.use_waypoint_name=true_, which is set to false by default.

Beyond visualization, this telemetry enrichment opens the door to even more advanced capabilities. With consistent tracing and metrics across the mesh, Kiali’s AI-driven features (like the [chatbot](https://kiali.io/docs/ai/kiali-chatbot/)) can now more accurately assist in root cause analysis. By having all the pieces of the puzzle in place, the assistant can proactively identify bottlenecks or misconfiguration in your Ambient mesh, turning raw observability into automated intelligence.

{{< image width="90%" link="./kiali-chatbot-trace-overview.png" caption="Kiali chatbot providing a trace overview based on the current context" >}}

> As Istio continues to mature, Kiali ensures that moving to Ambient doesn’t mean losing control. It completes the puzzle, allowing you to focus on your services while Kiali handles the intricate mapping of the mesh.

_This article was also published on [Medium](https://medium.com/p/817b1f9bc61d)._