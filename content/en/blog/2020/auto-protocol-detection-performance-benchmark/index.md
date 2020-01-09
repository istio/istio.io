---
title: "Auto Protocol Detection Proformance Benchmark"
description: "Performance benchmark for auto protocol detection."
publishdate: 2020-01-07
last_update: 2020-01-07
subtitle:
attribution: Yan Xue (Google)
keywords: [performance,benchmarks,protocol]
---

Auto protocol detection introduces protocol inspection in ingress and egress path, which could potentially 
cost more CPU cycles and increase latency. To make an informed decision on whether auto protocol detection
is right for your use case, it’s important to evaluate how your application performs when auto protocol detection
is enabled.


## Environment Setup

Many performance benchmark blogs have been published earlier, e.g., [best practices and Istio 1.2 performance](/blog/2019/performance-best-practices/),
[Istio 1.1 performance](/blog/2019/istio1.1_perf). The environment setup in this blog will follow settings
in [this blog]((/blog/2019/performance-best-practices/)). 

We benchmarked the performance with different application protocols, such as HTTP/1.1 and gRPC. In order to
benchmark the auto protocol detection with [mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication),
we setup environments with and without mutual TLS authentication. 

Since auto protocol detection only affects pods with sidecar, we benchmarked `both` and `serveronly` of [three different modes](https://github.com/istio/tools/tree/3ac7ab40db8a0d595b71f47b8ba246763ecd6213/perf/benchmark#run-performance-tests).

Mixer is also disabled because it doesn't affect the performance of auto protocol detection regardless of its enablement.


## Auto Protocol Detection Performance

We found that when mTLS is enabled, the performance gap is trivial between system enabling auto protocol detection and disabling auto protocol detection.

{{< image  width="75%" ratio="60%"
    link="./mtls_latency_p50.png"
    alt="Istio sidecar proxy, 50th percentile latency, HTTP"
    title="Istio sidecar proxy, 50th percentile latency, HTTP"
    caption=""
    >}}

{{< image  width="75%" ratio="60%"
    link="./mtls_latency_p90.png"
    alt="Istio sidecar proxy, 90th percentile latency, HTTP"
    title="Istio sidecar proxy, 90th percentile latency, HTTP"
    caption=""
    >}}

{{< image  width="75%" ratio="60%"
    link="./mtls_latency_p99.png"
    alt="Istio sidecar proxy, 99th percentile latency, HTTP"
    title="Istio sidecar proxy, 99th percentile latency, HTTP"
    caption=""
    >}}    

The reason is that sniffing happens on client side using [alpn filter](https://github.com/airbnb/istio-api/blob/master/envoy/config/filter/http/alpn/v2alpha1/config.proto) when mTLS is enabled and the cost is trivial.

For plaintext, we found that with 64 concurrent connections and 1000 RPS, Istio adds **1ms** when a request travels through both a client and server proxy. 

{{< image  width="75%" ratio="60%"
    link="./pt_latency_p50.png"
    alt="Istio sidecar proxy, 50th percentile latency, HTTP"
    title="Istio sidecar proxy, 50th percentile latency, HTTP"
    caption=""
    >}}

{{< image  width="75%" ratio="60%"
    link="./pt_latency_p90.png"
    alt="Istio sidecar proxy, 90th percentile latency, HTTP"
    title="Istio sidecar proxy, 90th percentile latency, HTTP"
    caption=""
    >}}

{{< image  width="75%" ratio="60%"
    link="./pt_latency_p99.png"
    alt="Istio sidecar proxy, 99th percentile latency, HTTP"
    title="Istio sidecar proxy, 99th percentile latency, HTTP"
    caption=""
    >}}    

In the 90th percentile and 99th percentile, with all connections, Istio adds less than **1ms** overhead.

## Conclusion

In the process of benchmarking Istio's performance, we learned several key lessons:

- The performance degradation of applying auto protocol detection can be ignored when mutual TLS authentication is applied.
- The latency overhead for using auto protocol detection in system using plaintext is around **1ms**.