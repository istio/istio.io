---
title: How can I control the data being reported by the sidecar?
weight: 20
---

It's sometimes useful to exclude access to specific URLs from being reported. For example, you might wish to exclude some health-checking
URLs. You can skip telemetry reports specific to certain URLs by excluding them using a `match` clause of the telemetry configuration
such as:

{{< text yaml >}}
match: source.name != "health"
{{< /text >}}
