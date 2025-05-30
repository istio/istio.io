---
title: PodsIstioProxyImageMismatchInNamespace
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when the namespace is enabled for automatic sidecar injection, but some pods in the namespace are not having the correct sidecar injected.

If any of the pods in the namespace are not running the correct sidecar version, this message will be reported.
The names of the pods are listed in the message detail.

This often happens as a result of upgrading the Istio control plane; after upgrading
Istio (which includes the sidecar injector), all running workloads with an Istio
sidecar must be recreated to allow the new version of the sidecar to be
injected.

To resolve this problem, update the sidecar version by redeploying your applications
using your normal rollout strategy. For a Kubernetes deployment:

* If you're using Kubernetes 1.15 or higher, you can run
  `kubectl rollout restart <my-deployment>` to trigger a new rollout.
* Alternatively, you can modify the deployment's `template` field to force a new
  rollout. This is often done by adding a label like
  `force-redeploy=<current-timestamp>` to the pod definition in the template.
