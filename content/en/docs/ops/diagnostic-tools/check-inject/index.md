---
title: Verifying Istio Sidecar Injection with Istioctl Check-Inject
description: Learn how to use istioctl check-inject to confirm if Istio sidecar injection is properly enabled for your deployments.
weight: 45
keywords: [istioctl, injection, kubernetes]
owner: istio/wg-user-experience-maintainers
test: no
---

`istioctl experimental check-inject` is a diagnostic tool that helps you verify if specific webhooks will perform Istio sidecar injection in your pods. Use this tool to check if the sidecar injection configuration is correctly applied to a live cluster.

## Quick Start

To check why Istio sidecar injection did/didn't (or will/won't) occur for a specific pod, run:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> <pod-name>
{{< /text >}}

For a deployment, run:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> deploy/<deployment-name>
{{< /text >}}

Or, for label pairs:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> -l <label-key>=<label-value>
{{< /text >}}

For example, if you have a deployment named `httpbin` in the `hello` namespace and a pod named `httpbin-1234` with the label `app=httpbin`, the following commands are equivalent:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n hello httpbin-1234
$ istioctl experimental check-inject -n hello deploy/httpbin
$ istioctl experimental check-inject -n hello -l app=httpbin
{{< /text >}}

Example results:

{{< text plain >}}
WEBHOOK                      REVISION  INJECTED      REASON
istio-revision-tag-default   default   ✔             Namespace label istio-injection=enabled matches
istio-sidecar-injector-1-18  1-18      ✘             No matching namespace labels (istio.io/rev=1-18) or pod labels (istio.io/rev=1-18)
{{< /text >}}

If the `INJECTED` field is marked as `✔`, the webhook in that row will perform the injection, with the reason why the webhook will do the sidecar injection.

If the `INJECTED` field is marked as `✘`, the webhook in that row will not perform the injection, and the reason is also shown.

Possible reasons the webhook won't perform injection or the injection will have errors:

1. **No matching namespace labels or pod labels**: Ensure proper labels are set on the namespace or pod.

1. **No matching namespace labels or pod labels for a specific revision**: Set correct labels to match the desired Istio revision.

1. **Pod label preventing injection**: Remove the label or set it to the appropriate value.

1. **Namespace label preventing injection**: Change the label to the appropriate value.

1. **Multiple webhooks injecting sidecars**: Ensure only one webhook is enabled for injection, or set appropriate labels on the namespace or pod to target a specific webhook.
