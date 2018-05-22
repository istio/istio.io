---
title: Synthetic End to End benchmarks
overview: Fortio is our simple synthetic http and grpc benchmarking tool.
weight: 30

layout: docs
type: markdown
---
{% include home.html %}

We use Fortio (Φορτίο) as Istio's synthetic end to end load testing tool. Fortio runs at a specified query per second (qps) and records an histogram of execution time and calculates percentiles (e.g. p99 ie the response time such as 99% of the requests take less than that number (in seconds, SI unit)). It can run for a set duration, for a fixed number of calls, or until interrupted (at a constant target QPS, or max speed/load per connection/thread).

Fortio is a fast, small, reusable, embeddable go library as well as a command line tool and server process, the server includes a simple web UI and graphical representation of the results (both a single latency graph and a multiple results comparative min, max, avg and percentiles graphs).

Here is an example of scenario run result graphing the latency distribution for istio-0.6.0 at 400qps between 2 services inside the mesh:

<iframe src="https://fortio.istio.io/browse?url=2018-03-07-164634_0_6_0_400qps_scenario1_with_cache.json" width="100%" height="1024" scrolling="no" frameborder="0"></iframe>


You can learn more about [Fortio](https://github.com/istio/fortio/blob/master/README.md#fortio) on GitHub and see results on [https://fortio.istio.io](https://fortio.istio.io).
