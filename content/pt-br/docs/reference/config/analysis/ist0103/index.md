---
title: PodMissingProxy
layout: analysis-message
---

This message occurs when the sidecar is not present or not working correctly.

This most commonly occurs when you enable auto-injection but do not restart your
pods afterwards, causing the sidecar to be missing.

To resolve this problem, restart your pods and try again.

For example, to restart the pods, use this command:

{{< text bash >}}
$ kubectl rollout restart deployment
{{< /text >}}
