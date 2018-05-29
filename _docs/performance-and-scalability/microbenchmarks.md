---
title: Micro Benchmarks
overview: Performance measurement through code level micro-benchmarks.
weight: 20

layout: docs
type: markdown
---
{% include home.html %}

We use Go’s native tools to write targeted micro-benchmarks in performance sensitive areas. Our main goal with this approach is to provide easy-to-use micro-benchmarks that developers can use to perform quick before/after performance comparisons for their changes.

[Here](https://github.com/istio/istio/blob/master/mixer/test/perf/singlecheck_test.go) is a sample micro-benchmark for Mixer that measures the performance of attribute processing code.

The developers can also utilize a golden-files approach to capture the state of their benchmark results in the source tree for keeping track and  referencing purposes. [Here](https://github.com/istio/istio/blob/master/mixer/test/perf/bench.baseline) is a baseline file.

Due to the nature of this testing type, there is a high-variance in latency numbers across machines. It is recommended that micro-benchmark numbers captured in this way are compared only against the previous runs on the same machine.

The [perfcheck.sh](https://github.com/istio/istio/blob/master/bin/perfcheck.sh) script can be used to quickly run benchmarks in a sub-folder and compare its results against the co-located baseline files.
