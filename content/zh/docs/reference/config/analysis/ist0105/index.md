---
title: IstioProxyVersionMismatch
layout: analysis-message
---

This message is emitted regarding a pod when:

* Automatic sidecar injection is enabled (default enabled unless explicitly
  disabled via the helm template variable `sidecarInjectorWebhook.enabled`)
* The pod is running in a namespace where sidecar injection is enabled (the
  namespace has the label `istio-injection=enabled`)
* The proxy version running on the sidecar does not match the version used by
  the auto-injector

This often results after upgrading the Istio control plane; after upgrading
Istio (which includes the sidecar injector), all running workloads with an Istio
sidecar must be recreated to allow the new version of the sidecar to be
injected.

The easiest way to update the sidecar version is to redeploy your application
using your normal rollout strategy. For a Kubernetes deployment:

* If you're using Kubernetes version 1.15 or above, you can run `kubectl rollout
  restart <my-deployment>` to trigger a new rollout.
* Alternatively, you can modify the deployment's `template` field to force a new
  rollout. This is often done by adding a label like `force-redeploy=<current
  timestamp>` to the pod definition in the template.
