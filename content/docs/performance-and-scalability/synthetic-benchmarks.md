---
title: Synthetic End to End benchmarks
overview: Fortio is our simple synthetic http and grpc benchmarking tool.
weight: 30

layout: docs
type: markdown
---
{% include home.html %}

We use Fortio (Φορτίο) as Istio's synthetic end to end load testing tool. Fortio runs at a specified query per second (qps) and records an histogram of execution time and calculates percentiles (e.g. p99 i.e. the response time such as 99% of the requests take less than that number (in seconds, SI unit)). It can run for a set duration, for a fixed number of calls, or until interrupted (at a constant target QPS, or max speed/load per connection/thread).

Fortio is a fast, small, reusable, embeddable go library as well as a command line tool and server process, the server includes a simple web UI and graphical representation of the results (both a single latency graph and a multiple results comparative min, max, average and percentiles graphs).

Fortio is also 100% open-source and with no external dependencies beside go and gRPC so you can reproduce all our results easily and add your own variants or scenarios you are interested in exploring.

Here is an example of scenario (one out of the 8 scenarios we run for every build) result graphing the latency distribution for istio-0.7.1 at 400 Query-Per-Second (qps) between 2 services inside the mesh (with mTLS, Mixer Checks and Telemetry):

<iframe src="https://fortio.istio.io/browse?url=qps_400-s1_to_s2-0.7.1-2018-04-05-22-06.json&xMax=105&yLog=true" width="100%" height="1024" scrolling="no" frameborder="0"></iframe>

Comparing 0.6.0 and 0.7.1 histograms/response time distribution for the same scenario, clearly showing 0.7 improvements:

<iframe src="https://fortio.istio.io/?xMin=2&xMax=110&xLog=true&sel=qps_400-s1_to_s2-0.7.1-2018-04-05-22-06&sel=qps_400-s1_to_s2-0.6.0-2018-04-05-22-33" width="100%" height="1024" scrolling="no" frameborder="0"></iframe>

And tracking the progress across all the tested releases for that scenario:

<iframe src="https://fortio.istio.io/?s=qps_400-s1_to_s2" width="100%" height="1024" scrolling="no" frameborder="0"></iframe>

You can learn more about [Fortio](https://github.com/istio/fortio/blob/master/README.md#fortio) on GitHub and see results on [https://fortio.istio.io](https://fortio.istio.io).
