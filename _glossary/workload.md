---
title: Workload
type: markdown
---
A process/binary deployed by operators in Istio, typically represented by entities such as containers, pods, or VMs.
  * A workload can expose zero or more [service endpoints](#service-endpoint).
  * A workload can consume zero or more [services](#service).
  * Each workload has a single canonical [service name](#service-name) associated with it, but
    may also represent additional service names.
