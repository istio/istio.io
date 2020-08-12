---
title: What are the differences in telemetry reported between in-proxy telemetry (aka v2) and Mixer-based telemetry (aka v1)?
weight: 40
---

In-proxy telemetry (aka v2) reduces resource cost and improves proxy
performance as compared to the Mixer-based telemetry (aka v1) approach.
There are few differences in reported telemetry and configurability
between v1 and v2 which are listed below:

* **Missing labels for out-of-mesh traffic**
  Telemetry v2 relies on metadata exchange between Envoy proxies to gather
  information like peer workload name, namespace and labels. In telemetry v1
  this functionality was performed by Mixer as part of combining request attributes
  with the platform data. This metadata exchange in telemetry v2 is performed by the
  Envoy proxies by adding specific HTTP header for HTTP protocol or augmenting
  ALPN protocol for TCP protocol as described [here](/docs/tasks/observability/metrics/tcp-metrics/#understanding-tcp-telemetry-collection).
  This requires Envoy proxies to be injected at both client & server workloads,
  implying that the telemetry reported when one peer is not in the mesh will be
  missing peer attributes like workload name, namespace and labels.
  However, if both peers have proxies injected all the labels mentioned [here](/docs/reference/config/metrics/)
  are available in the generated metrics.

* **TCP metadata exchange requires mTLS**
  TCP metadata exchange relies on [Istio ALPN protocol](/docs/tasks/observability/metrics/tcp-metrics/#understanding-tcp-telemetry-collection)
  which requires mutual TLS (mTLS) to be enabled for Envoy proxies to exchange
  metadata successfully. This implies that if mTLS is not enabled in your
  cluster, telemetry for TCP protocol will not include peer information like
  workload name, namespace and labels.

* **No mechanism for configuring custom bucketization for histogram metrics**
  Telemetry v1 supported customizing buckets for histogram type metrics like
  request duration and TCP byte sizes. In telemetry v2, there's no such
  mechanism available. Additionally, the buckets available for latency metrics
  in telemetry v2 are in milliseconds as compared to seconds in telemetry v1.
  However, more buckets are available by default in telemetry v2 for latency
  metrics at the lower latency levels.

* **No metric expiration for short-lived metrics**
  Telemetry v1 supported metric expiration whereby metrics not seen for a
  configurable amount of time were de-registered for collection. This is
  useful in scenarios where short-lived jobs surfaced telemetry only for a
  short amount of time, and de-registering the metrics prevented reporting of
  metrics which would no longer change in future reducing network traffic and
  storage for Prometheus.
