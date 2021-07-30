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

The Istio CNI plugin log provides information about how CNI plugin configures application pod traffic redirection
based on pod spec.

The plugin runs in the container runtime process space, so you can collect CNI plugin log from the `kubelet` log.
To ease the log collection, the CNI plugin also sends its log to the `istio-cni-node` DaemonSet.
Due to this, You can get the plugin log simply by getting `istio-cni-node` DaemonSet pod log.
The default log level for CNI plugin is at `info` level, to get more detailed log from the CNI plugin,
you can tune plugin log level via install option `values.cni.logLevel` and restart CNI DaemonSet pod.

In addition to CNI plugin log, the Istio CNI DaemonSet pod log also provides information about CNI network plugin installation,
and [race condition repairing](/docs/setup/additional-setup/cni/#race-condition-mitigation).

## Monitoring

The CNI DaemonSet [generates metrics](/docs/reference/commands/install-cni/#metrics),
which can be used to monitor CNI installation, readiness, and race condition mitigation.
Prometheus scraping annotations (`prometheus.io/port`, `prometheus.io/path`) are added to `istio-cni-node` DaemonSet pod by default.
You can collect the generated metrics via standard Prometheus configuration.

## Istio CNI DaemonSet readiness

Readiness of Istio CNI DaemonSet indicates Istio CNI network plugin is properly installed and configured.
If Istio CNI DaemonSet is unready, it suggests something is wrong with CNI plugin installation.
Best way to check why installation fails is to look at `istio-cni-node` DaemonSet logs.
You can also track the CNI installation readiness via metric `istio_cni_install_ready`.

## Race condition repair

Istio CNI DaemonSet by default has [race condition mitigation](/docs/setup/additional-setup/cni/#race-condition-mitigation) enabled,
which will evict pod that is broken by the race condition.
To understand which pods get evicted, you can look for log lines like the follow in CNI DaemonSet:

{{< text plain >}}
2021-07-21T08:32:17.362512Z     info   Deleting broken pod: service-graph00/svc00-0v1-95b5885bf-zhbzm
{{< /text >}}

You can also track pods repaired via metric `istio_cni_repair_pods_repaired_total`.

## Diagnose pod start-up failure

A common issue with Istio CNI is that pod fails to start up due to container network set up failure.
Typically the failure reason is written to the pod events and is visible via pod description.

{{< text bash >}}
$ kubectl describe pod POD_NAME -n POD_NAMESPACE
{{< /text >}}

If pod keeps getting init error, check the init container `istio-validation` log and
see if it complains about connection refused like the follow.

{{< text bash >}}
$ kubectl logs POD_NAME -n POD_NAMESPACE -c istio-validation
...
2021-07-20T05:30:17.111930Z     error   Error connecting to 127.0.0.6:15002: dial tcp 127.0.0.1:0->127.0.0.6:15002: connect: connection refused
2021-07-20T05:30:18.112503Z     error   Error connecting to 127.0.0.6:15002: dial tcp 127.0.0.1:0->127.0.0.6:15002: connect: connection refused
...
2021-07-20T05:30:22.111676Z     error   validation timeout
{{< /text >}}

What `istio-validation` init container does is that it sets up a local dummy server which
listens on traffic redirection target inbound/outbound ports,
and checks whether test traffic can be redirected to the dummy server.
When pod traffic redirection is not set up correctly by Istio CNI,
the `istio-validation` init container blocks pod startup to prevent traffic bypass.
You can check `istio-cni-node` DaemonSet log and look for pod ID to see
if there are any errors or unexpected network setup behaviors.

The other symptom of malfunctioned Istio CNI is that the application pod keeps being evicted at start-up time.
This is typically because the CNI plugin is not properly installed, thus pod traffic redirection cannot be set up.
CNI [race repair logic](/docs/setup/additional-setup/cni/#race-condition-mitigation) considers the pod is broken due to race condition and evicts pod continuously.
When running into this issue, CNI DaemonSet log should have information on why CNI plugin cannot be installed properly.
