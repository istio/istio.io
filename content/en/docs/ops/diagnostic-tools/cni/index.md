---
title: Troubleshooting the Istio CNI plugin
description: Describes tools and techniques to diagnose issues using Istio with the CNI plugin.
weight: 90
keywords: [debug,cni]
owner: istio/wg-networking-maintainers
test: n/a
---

This page describes how to troubleshoot issues with the Istio CNI plugin.
Before reading this, you should read the [CNI installation and operation guide](/docs/setup/additional-setup/cni/).

## Log

The Istio CNI plugin log provides information about how the plugin configures application pod traffic redirection
based on `PodSpec`.

The plugin runs in the container runtime process space, so you can see CNI log entries in the `kubelet` log.
To make debugging easier, the CNI plugin also sends its log to the `istio-cni-node` DaemonSet.

The default log level for the CNI plugin is `info`. To get more detailed log output, you can change the level by editing the `values.cni.logLevel` installation option and restarting the CNI DaemonSet pod.

The Istio CNI DaemonSet pod log also provides information about CNI plugin installation,
and [race condition repairing](/docs/setup/additional-setup/cni/#race-condition-mitigation).

## Monitoring

The CNI DaemonSet [generates metrics](/docs/reference/commands/install-cni/#metrics),
which can be used to monitor CNI installation, readiness, and race condition mitigation.
Prometheus scraping annotations (`prometheus.io/port`, `prometheus.io/path`) are added to the `istio-cni-node` DaemonSet pod by default.
You can collect the generated metrics via standard Prometheus configuration.

## DaemonSet readiness

Readiness of the CNI DaemonSet indicates that the Istio CNI plugin is properly installed and configured.
If Istio CNI DaemonSet is unready, it suggests something is wrong. Look at the  `istio-cni-node` DaemonSet logs to diagnose.
You can also track CNI installation readiness via the `istio_cni_install_ready` metric.

## Race condition repair

By default, the Istio CNI DaemonSet has [race condition mitigation](/docs/setup/additional-setup/cni/#race-condition-mitigation) enabled,
which will evict a pod that was started before the CNI plugin was ready.
To understand which pods were evicted, look for log lines like the following:

{{< text plain >}}
2021-07-21T08:32:17.362512Z     info   Deleting broken pod: service-graph00/svc00-0v1-95b5885bf-zhbzm
{{< /text >}}

You can also track pods repaired via the `istio_cni_repair_pods_repaired_total` metric.

## Diagnose pod start-up failure

A common issue with the CNI plugin is that a pod fails to start due to container network set-up failure.
Typically the failure reason is written to the pod events, and is visible via pod description:

{{< text bash >}}
$ kubectl describe pod POD_NAME -n POD_NAMESPACE
{{< /text >}}

If a pod keeps getting init error, check the init container `istio-validation` log for
"connection refused" errors like the following:

{{< text bash >}}
$ kubectl logs POD_NAME -n POD_NAMESPACE -c istio-validation
...
2021-07-20T05:30:17.111930Z     error   Error connecting to 127.0.0.6:15002: dial tcp 127.0.0.1:0->127.0.0.6:15002: connect: connection refused
2021-07-20T05:30:18.112503Z     error   Error connecting to 127.0.0.6:15002: dial tcp 127.0.0.1:0->127.0.0.6:15002: connect: connection refused
...
2021-07-20T05:30:22.111676Z     error   validation timeout
{{< /text >}}

The  `istio-validation` init container sets up a local dummy server which
listens on traffic redirection target inbound/outbound ports,
and checks whether test traffic can be redirected to the dummy server.
When pod traffic redirection is not set up correctly by the CNI plugin,
the `istio-validation` init container blocks pod startup, to prevent traffic bypass.
To see if there were any errors or unexpected network setup behaviors,
search the `istio-cni-node` for the pod ID.

Another symptom of a malfunctioned CNI plugin is that the application pod is continuously evicted at start-up time.
This is typically because the plugin is not properly installed, thus pod traffic redirection cannot be set up.
CNI [race repair logic](/docs/setup/additional-setup/cni/#race-condition-mitigation) considers the pod is broken due to the race condition and evicts the pod continuously.
When running into this issue,  check the CNI DaemonSet log for information on why the plugin could not be properly installed.
