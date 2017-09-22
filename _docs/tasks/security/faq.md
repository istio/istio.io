---
title: FAQ
overview: Common issues, known limitations and work arounds, and other frequently asked questions on this topic.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

This page summarizes frequently asked questions and the team can be reached via slack (istio.slack.com
 #auth channel) or google groups (https://groups.google.com/forum/#!forum/istio-users).

### Can a service with Istio Auth enabled communicate a service without Istio?

Currently it is not well supported. But we do have plan to support this in the near future.

### Can I enable Istio Auth with some services while disable others in the same cluster?

No, you cannot for now. Currently we only support cluster-wise Auth enable/disable. It is
a high priority action item for us to support per-service auth.

### How can I use Kubernetes liveness and readiness to for service health check with Istio Auth enabled?

If Istio Auth is enabled, http and tcp health check from kubelet will not work since they do not have
Istio Auth issued certs. A workaround is to use command option for health check, e.g., one can install
curl in the service pod and curl itself within the pod. Moreover, this is a temporary workaround. The
Auth team is actively working on a real solution.

### How can I access Kubernetes ApiServer with Auth enabled?

It will not work from service container since the traffic will be intercepted by Istio proxy, and
ApiServer cannot recognize Istio Auth issued certs. You can either turn off Istio Auth or access
ApiServer in the proxy container.

To ssh into the proxy container:

```bash
$ kubectl exec -it myPod -c istio-proxy /bin/bash
```

Access ApiServer within the proxy container:

```bash
# curl https://kubernetes/api/v1/namespaces/default/secrets -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -k -v
```
