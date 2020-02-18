---
title: IstioProxyImageMismatch
layout: analysis-message
---

This message occurs regarding a pod when:

* Automatic sidecar injection is enabled (default enabled unless explicitly
  disabled during installation.)
* The pod is running in a namespace where sidecar injection is enabled (the
  namespace has the label `istio-injection=enabled`)
* The proxy version running on the sidecar does not match the version used by
  the auto-injector

This often results after upgrading the Istio control plane; after upgrading
Istio (which includes the sidecar injector), all running workloads with an Istio
sidecar must be recreated to allow the new version of the sidecar to be
injected.

To resolve this problem, update the sidecar version by redeploying your application
using your normal rollout strategy. For a Kubernetes deployment:

* If you're using Kubernetes 1.15 or higher, you can run
  `kubectl rollout restart <my-deployment>` to trigger a new rollout.
* Alternatively, you can modify the deployment's `template` field to force a new
  rollout. This is often done by adding a label like
  `force-redeploy=<current-timestamp>` to the pod definition in the template.
