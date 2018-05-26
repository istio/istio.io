---
title: In-Depth Telemetry
description: This sample demonstrates how to obtain uniform metrics, logs, traces across different services using Istio Mixer and Istio sidecar.
weight: 30
---

This sample demonstrates how to obtain uniform metrics, logs, traces across different services using Istio Mixer and Istio sidecar.

## Overview

Deploying a microservice-based application in an Istio service mesh allows one
to externally control service monitoring and tracing, request (version) routing, resiliency testing,
security and policy enforcement, etc., in a consistent way across the services,
for the application as a whole.

In this guide, we will use the [Bookinfo sample application](/docs/guides/bookinfo/)
to show how operators can obtain uniform metrics and traces from running
applications involving diverse language frameworks without relying on
developers to manually instrument their applications.

## Before you begin

* Install the Istio control plane by following the instructions
  corresponding to your platform [installation guide](/docs/setup/).

* Run the Bookinfo sample application by following the applicable
  [application deployment instructions](/docs/guides/bookinfo/#deploying-the-application).

## Tasks

1. [Collecting metrics](/docs/tasks/telemetry/metrics-logs/)
   This task will configure Mixer to collect a uniform set of metrics
   across all services in the Bookinfo application.

1. [Querying metrics](/docs/tasks/telemetry/querying-metrics/)
   This task installs the Prometheus add-on for metrics collection and
   demonstrates querying a configured Prometheus server for Istio metrics.

1. [Distributed tracing](/docs/tasks/telemetry/distributed-tracing/)
   We will now use Istio to trace how requests are flowing across services
   in the application. Distributed tracing speeds up troubleshooting by
   allowing developers to quickly understand how different services
   contribute to the overall end-user perceived latency. In addition, it
   can be a valuable tool to diagnosis and troubleshooting in distributed
   applications.

1. [Using the Istio Dashboard](/docs/tasks/telemetry/using-istio-dashboard/)
   This task installs the Grafana add-on with a preconfigured dashboard
   for monitoring mesh traffic.

## Cleanup

When you're finished experimenting with the Bookinfo sample, you can
uninstall it by following the
[Bookinfo cleanup instructions](/docs/guides/bookinfo/#cleanup)
corresponding to your environment.
