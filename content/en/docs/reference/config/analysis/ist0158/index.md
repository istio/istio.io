---
title: PodsIstioProxyImageMismatchInNamespace
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message is similar to [IST0105](/docs/reference/config/analysis/ist0105/), which is a warning message for a single pod.

This message occurs when the namespace is enabled for automatic sidecar injection, but some pods in the namespace are not having the correct sidecar injected. 

There are several possible causes for the pod:

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

If any of the pods in the namespace are not running the correct sidecar version, this message will be reported.
The names of the pods are listed in the message.

To resolve this problem, update the sidecar version by redeploying your applications
using your normal rollout strategy. For a Kubernetes deployment:

* If you're using Kubernetes 1.15 or higher, you can run
  `kubectl rollout restart <my-deployment>` to trigger a new rollout.
* Alternatively, you can modify the deployment's `template` field to force a new
  rollout. This is often done by adding a label like
  `force-redeploy=<current-timestamp>` to the pod definition in the template.
