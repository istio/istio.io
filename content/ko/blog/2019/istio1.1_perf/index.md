---
title: Architecting Istio 1.1 for Performance
description: An overview of Istio 1.1 performance.
publishdate: 2019-03-19
subtitle: An overview of Istio 1.1 performance improvements
attribution: Surya V Duggirala (IBM), Mandar Jog (Google), Jose Nativio (IBM)
keywords: [performance,scalability,scale,benchmarks]
target_release: 1.1
---

Hyper-scale, microservice-based cloud environments have been exciting to build but challenging to manage. Along came Kubernetes (container orchestration) in 2014, followed by Istio (container service management) in 2017. Both open-source projects enable developers to scale container-based applications without spending too much time on administration tasks.

Now, new enhancements in Istio 1.1 deliver scale-up with improved application performance and service management efficiency.
Simulations using our sample commercial airline reservation application show the following improvements, compared to Istio 1.0.

We've seen substantial application performance gains:

* up to 30% reduction in application average latency
* up to 40% faster service startup times in a large mesh

As well as impressive improvements in service management efficiency:

* up to 90% reduction in Pilot CPU usage in a large mesh
* up to 50% reduction in Pilot memory usage in a large mesh

With Istio 1.1, organizations can be more confident in their ability to scale applications with consistency and control -- even in hyper-scale cloud environments.

Congratulations to the Istio experts around the world who contributed to this release. We could not be more pleased with these results.

## Istio 1.1 performance enhancements

As members of the Istio Performance and Scalability workgroup, we have done extensive performance evaluations. We introduced many performance design features for Istio 1.1, in collaboration with other Istio contributors.
Some of the most visible performance enhancements in 1.1 include:

* Significant reduction in default collection of Envoy-generated statistics
* Added load-shedding functionality to Mixer workloads
* Improved the protocol between Envoy and Mixer
* Namespace isolation, to reduce operational overhead
* Configurable concurrent worker threads, which can improve overall throughput
* Configurable filters that limit telemetry data
* Removal of synchronization bottlenecks

## Continuous code quality and performance verification

Regression Patrol drives continuous improvement in Istio performance and quality. Behind the scenes, the Regression Patrol helps Istio developers to identify and fix code issues. Daily builds are checked using a customer-centric benchmark, [BluePerf](https://github.com/blueperf/). The results are published to the [Istio community web portal](https://ibmcloud-perf.istio.io/regpatrol/). Various application configurations are evaluated to help provide insights on Istio component performance.

Another tool that is used to evaluate the performance of Istio’s builds is [Fortio](https://fortio.org/), which provides a synthetic end to end load testing benchmark.

## Summary

Istio 1.1 was designed for performance and scalability. The Istio Performance and Scalability workgroup measured significant performance improvements over 1.0.
Istio 1.1 introduces new features and optimizations to help harden the service mesh for enterprise microservice workloads. The Istio 1.1 Performance and Tuning Guide documents performance simulations, provides sizing and capacity planning guidance, and includes best practices for tuning custom use cases.

## Useful links

* [Istio Service Mesh Performance (34:30)](https://www.youtube.com/watch?time_continue=349&v=G4F5aRFEXnU), by Surya Duggirala, Laurent Demailly and Fawad Khaliq at KubeCon Europe 2018
* [Istio Performance and Scalability discussion forum](https://discuss.istio.io/c/performance-and-scalability)

## Disclaimer

The performance data contained herein was obtained in a controlled, isolated environment.  Actual results that may be obtained in other operating environments may vary significantly.  There is no guarantee that the same or similar results will be obtained elsewhere.
