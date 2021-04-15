---
title: "Upcoming networking changes in Istio 1.10"
description: Understanding the upcoming changes to Istio networking, how they may impact your cluster, and what action to take.
publishdate: 2021-04-15
attribution: "John Howard (Google)"
---

## Background

While Kubernetes networking is customizable, a typical pod's network will look like this:

{{< image width="75%" link="./pod.svg" caption="A pod's network" >}}

An application may choose to bind to either the loopback interface `lo` (typically binding to `127.0.0.1`), or the pods network interface `eth0` (typically to the pod's IP), or both (typically binding to `0.0.0.0`).

Binding to `lo` allows calls such as `curl localhost` to work from within the pod.
Binding to `eth0` allows calls to the pod from other pods.

Typically, an application will bind to both.
However, applications which have internal logic, such as an admin interface may choose to bind to only `lo` to avoid access from other pods.
Additionally, some applications, typically stateful applications, choose to bind only to `eth0`.

## Current behavior

In Istio prior to release 1.10, the Envoy proxy, running in the same pod as the application, binds to the `eth0` interface and redirects all inbound traffic to the `lo` interface.

{{< image width="75%" link="./current.svg" caption="A pod's network with Istio today" >}}

This has two important side effects that cause the behavior to differ from standard Kubernetes:

* Applications binding only to `lo` will receive traffic from other pods, when otherwise this is not allowed.
* Applications binding only to `eth0` will not receive traffic.

Applications that bind to both interfaces (which is typical) will not be impacted.

## Future behavior

Starting with Istio 1.10, the networking behavior is changed to align with the standard behavior present in Kubernetes.

{{< image width="75%" link="./planned.svg" caption="A pod's network with Istio in the future" >}}

Here we can see that the proxy no longer redirects the traffic to the `lo` interface, but instead forwards it to the application on `eth0`.
As a result, the standard behavior of Kubernetes is retained, but we still get all the benefits of Istio.
This change allows Istio to get closer to its goal of being a drop-in transparent proxy that works with existing workloads with [zero configuration](/blog/2021/zero-config-istio/).
Additionally, it avoids unintended exposure of applications binding only to `lo`.

## Am I impacted?

For new users, this change should only be an improvement.
However, if you are an existing user, you may have come to depend on the old behavior, intentionally or accidentally.

To help detect these situations, we have added a check to find pods that will be impacted.
You can run the `istioctl experimental precheck` command to get a report of any pods binding to `lo` on a port exposed in a `Service`.
This command is available in Istio 1.10+.
**Without action, these ports will no longer be accessible upon upgrade.**

{{< text bash >}}
$ istioctl experimental precheck
Error [IST0143] (Pod echo-local-849647c5bd-g9wxf.default) Port 443 is exposed in a Service but listens on localhost. It will not be exposed to other pods.
Error [IST0143] (Pod echo-local-849647c5bd-g9wxf.default) Port 7070 is exposed in a Service but listens on localhost. It will not be exposed to other pods.
Error: Issues found when checking the cluster. Istio may not be safe to install or upgrade.
See https://istio.io/latest/docs/reference/config/analysis for more information about causes and resolutions.
{{< /text >}}

### Migration

If you are currently binding to `lo`, you have a few options:

* Switch your application to bind to all interfaces (`0.0.0.0` or `::`).
* Explicitly configure the port using the [`Sidecar` ingress configuration](/docs/reference/config/networking/sidecar/#IstioIngressListener) to send to `lo`, preserving the old behavior.

    For example, to configure request to be sent to `localhost` for the `ratings` application:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1beta1
    kind: Sidecar
    metadata:
      name: ratings
    spec:
      workloadSelector:
        labels:
          app: ratings
      ingress:
      - port:
          number: 8080
          protocol: HTTP
          name: http
        defaultEndpoint: 127.0.0.1:8080
    {{< /text >}}

* Disable the change entirely with the `PILOT_ENABLE_INBOUND_PASSTHROUGH=false` environment variable in Istiod, to enable the same behavior as prior to Istio 1.10. This option will be removed in the future.
