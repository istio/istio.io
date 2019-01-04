---
title: Repairing Citadel
description: What to do if Citadel is not behaving properly.
weight: 10
keywords: [security,citadel,ops]
---

If you suspect Citadel isn't working properly, verify the status of the `istio-citadel` pod:

{{< text bash >}}
$ kubectl get pod -l istio=citadel -n istio-system
NAME                                     READY     STATUS   RESTARTS   AGE
istio-citadel-ff5696f6f-ht4gq            1/1       Running  0          25d
{{< /text >}}

If the `istio-citadel` pod doesn't exist, try to re-deploy the pod.

If the `istio-citadel` pod is present but its status is not `Running`, run the commands below to get more
debugging information and check if there are any errors:

{{< text bash >}}
$ kubectl logs -l istio=citadel -n istio-system
$ kubectl describe pod -l istio=citadel -n istio-system
{{< /text >}}
