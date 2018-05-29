---
title: Micro Benchmarks
overview: Performance measurement through code level micro-benchmarks.
weight: 20
---

We use Go’s native tools to write targeted micro-benchmarks in performance sensitive areas. Our main goal with this approach is to provide easy-to-use micro-benchmarks that developers can use to perform quick before/after performance comparisons for their changes.

See the [sample micro-benchmark](https://github.com/istio/istio/blob/master/mixer/test/perf/singlecheck_test.go) for Mixer that measures the performance of attribute processing code.

The developers can also utilize a golden-files approach to capture the state of their benchmark results in the source tree for keeping track and  referencing purposes. GitHub has this [baseline file](https://github.com/istio/istio/blob/master/mixer/test/perf/bench.baseline).

Due to the nature of this testing type, there is a high-variance in latency numbers across machines. It is recommended that micro-benchmark numbers captured in this way are compared only against the previous runs on the same machine.

The [perfcheck.sh](https://github.com/istio/istio/blob/master/bin/perfcheck.sh) script can be used to quickly run benchmarks in a sub-folder and compare its results against the co-located baseline files.
