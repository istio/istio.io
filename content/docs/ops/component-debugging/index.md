---
title: Component Debugging
description: How to do low-level debugging of Istio components.
weight: 25
---

You can gain insights into what individual components are doing by inspecting their [logs](/docs/ops/component-logging/)
or peering inside via [introspection](/docs/ops/controlz/). If that's insufficient, the steps below explain
how to get under the hood.

## With `istioctl`

### Get an overview of your mesh

You can get an overview of your mesh using the `proxy-status` command:

{{< text bash >}}
$ istioctl proxy-status
{{< /text >}}

If a proxy is missing from the output list it means that it is not currently connected to a Pilot instance and so it
will not receive any configuration. Additionally, if it is marked stale, it likely means there are networking issues or
Pilot needs to be scaled.

### Get proxy configuration

`istioctl` allows you to retrieve information about proxy configuration using the `proxy-config` or `pc` command.

For example, to retrieve information about cluster configuration for the Envoy instance in a specific pod:

{{< text bash >}}
$ istioctl proxy-config cluster <pod-name> [flags]
{{< /text >}}

To retrieve information about bootstrap configuration for the Envoy instance in a specific pod:

{{< text bash >}}
$ istioctl proxy-config bootstrap <pod-name> [flags]
{{< /text >}}

To retrieve information about listener configuration for the Envoy instance in a specific pod:

{{< text bash >}}
$ istioctl proxy-config listener <pod-name> [flags]
{{< /text >}}

To retrieve information about route configuration for the Envoy instance in a specific pod:

{{< text bash >}}
$ istioctl proxy-config route <pod-name> [flags]
{{< /text >}}

To retrieve information about endpoint configuration for the Envoy instance in a specific pod:

{{< text bash >}}
$ istioctl proxy-config endpoints <pod-name> [flags]
{{< /text >}}

See [Debugging Envoy and Pilot](/docs/ops/traffic-management/proxy-cmd/) for more advice on interpreting this information.

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
