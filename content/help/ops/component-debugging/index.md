---
title: Component Debugging
description: How to do low-level debugging of Istio components.
weight: 25
---

You can gain insights into what individual components are doing by inspecting their [logs](/help/ops/component-logging/)
or peering inside via [introspection](/help/ops/controlz/). If that's insufficient, the steps below explain
how to get under the hood.

## With `istioctl`

`istioctl` allows you to inspect the current xDS of a given Envoy from its admin interface (locally) or from Pilot using the `proxy-config` or `pc` command.

For example, to retrieve the configured clusters in an Envoy via the admin interface run the following command:

{{< text bash >}}
$ istioctl proxy-config endpoint <pod-name> clusters
{{< /text >}}

To retrieve endpoints for a given pod in the application namespace from Pilot, run the following command:

{{< text bash >}}
$ istioctl proxy-config pilot -n application <pod-name> eds
{{< /text >}}

The `proxy-config` command also allows you to retrieve the state of the entire mesh from Pilot using the following command:

{{< text bash >}}
$ istioctl proxy-config pilot mesh ads
{{< /text >}}

## With GDB

To debug Istio with `gdb`, you will need to run the debug images of Envoy / Mixer / Pilot. A recent `gdb` and the golang extensions (for Mixer/Pilot or other golang components) is required.

1. `kubectl exec -it PODNAME -c [proxy | mixer | pilot]`

1. Find process ID: ps ax

1. gdb -p PID binary

1. For go: info goroutines, goroutine x bt

## With Tcpdump

Tcpdump doesn't work in the sidecar pod - the container doesn't run as root. However any other container in the same pod will see all the packets, since the
network namespace is shared. `iptables` will also see the pod-wide configuration.

Communication between Envoy and the app happens on 127.0.0.1, and is not encrypted.
