---
title: "Upcoming changes to Istio networking"
description: Understanding the upcoming changes to Istio networking, how they may impact your cluster, and what action to take.
publishdate: 2021-03-10
attribution: "John Howard (Google)"
---

## Background

While Kubernetes networking is complex and customizable, it is very common for a pod's network to look like this:

{{< image width="75%" link="./pod.svg" caption="A pod's network" >}}

A pod may choose to bind to either the loopback interface `lo` (typically binding to `127.0.0.1`), or the pods network interface `eth0` (typically to the pod's IP), or both (typically binding to `0.0.0.0`).

Binding to `lo` allows calls such as `curl localhost` to work from within the pod.
Binding to `eth0` allows calls to the pod from other pods.

Typically, an application will bind to both.
However, applications which have internal logic, such as an admin interface may choose to bind to only `lo` to avoid access from other pods.
Additionally, some applications, typically stateful applications, choose to bind only to `eth0`.

## Current behavior

In Istio today, the Envoy proxy will bind to the `eth0` interface. However, it will always forward traffic to the `lo` interface.

{{< image width="75%" link="./current.svg" caption="A pod's network with Istio today" >}}

This has two important side effects that cause the behavior to differ from standard Kubernetes:

* Applications binding only to `lo` will now receive traffic from other pods, when previously this was not allowed.
* Applications binding only to `eth0` will not receive traffic.

Applications that bind to both interfaces (which is typical) will not be impacted.

## Future behavior

In Istio 1.xx (TODO) we plan to introduce a change to the networking behavior to align with the standard behavior present in Kubernetes.

{{< image width="75%" link="./planned.svg" caption="A pod's network with Istio in the future" >}}

Here we can see the standard behavior of Kubernetes is retained, but we [automatically](/blog/2021/zero-config-istio/) get all the benefits of Istio.
This change allows Istio to get closer to its goal of being a drop-in transparent proxy that works with existing workloads with zero configuration.
Additionally, it avoids unintended exposure of applications binding only to `lo`.
## Detection

TODO: script

## Timeline

TODO

