---
title: In-Depth Telemetry
overview: This sample demonstrates how to obtain uniform metrics, logs, traces across different services using Istio Mixer and Istio sidecar.

order: 30
layout: docs
type: markdown
---
{% include home.html %}

This sample demonstrates how to obtain uniform metrics, logs, traces across different services using Istio Mixer and Istio sidecar.

## Overview

Deploying a microservice-based application in an Istio service mesh allows one
to externally control service monitoring and tracing, request (version) routing, resiliency testing,
security and policy enforcement, etc., in a consistent way across the services,
for the application as a whole.

In this guide, we will use the [Bookinfo sample application]({{home}}/docs/guides/bookinfo.html)
to show how operators can obtain uniform metrics and traces from running
applications involving diverse language frameworks without relying on
developers to manually instrument their applications.

## Before you begin

* Install the Istio control plane by following the instructions
  corresponding to your platform [installation guide]({{home}}/docs/setup/).

* Run the Bookinfo sample application by following the applicable
  [application deployment instructions]({{home}}/docs/guides/bookinfo.html#deploying-the-application).

## Tasks

1. [Collecting metrics]({{home}}/docs/tasks/telemetry/metrics-logs.html)
   This task will configure Mixer to collect a uniform set of metrics
   across all services in the Bookinfo application. It will configure Istio
   Mixer to propagate the metrics to a Prometheus backend. Interested users can
   setup Grafana to visualize the metrics by following the
   [Istio Add-ons]({{home}}/docs/tasks/telemetry/istio-addons.html).

1. [Request tracing]({{home}}/docs/tasks/telemetry/distributed-tracing.html) We will now use Istio to
   trace how requests are flowing across services in the
   application. Distributed tracing speeds up troubleshooting by allowing
   developers to quickly understand how different services contribute to
   the overall end-user perceived latency. In addition, it can be a
   valuable tool to diagnosis and troubleshooting in distributed applications.

## Cleanup

When you're finished experimenting with the BookInfo sample, you can
uninstall it by following the
[Bookinfo cleanup instructions]({{home}}/docs/guides/bookinfo.html#cleanup)
corresponding to your environment.
