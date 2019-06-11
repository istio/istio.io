---
title: Repairing Citadel
description: What to do if Citadel is not behaving properly.
weight: 10
keywords: [security,citadel,ops]
---

{{< warning >}}
Citadel does not support multiple instances. Running multiple Citadel instances
may introduce race conditions and lead to system outages.
{{< /warning >}}

{{< warning >}}
Workloads with new Kubernetes service accounts can not be started when Citadel is
disabled for maintenance since they can't get their certificates generated.
{{< /warning >}}

Citadel is not a critical data plane component. The default workload certificate lifetime is 3
months. Certificates will be rotated by Citadel before they expire. If Citadel is disabled for
short maintenance periods, existing mutual TLS traffic will not be affected.

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

If you want to check a workload (with `default` service account and `default` namespace)
certificate's lifetime:

{{< text bash >}}
$ kubectl get secret -o json istio.default -n default | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -noout -text | grep "Not After" -C 1
  Not Before: Jun  1 18:23:30 2019 GMT
  Not After : Aug 30 18:23:30 2019 GMT
Subject:
{{< /text >}}

{{< tip >}}
Remember to replace `istio.default` and `-n default` with `istio.YourServiceAccount` and
`-n YourNamespace` for other workloads. If the certificate is expired, Citadel did not
update the secret properly. Check Citadel logs for more information.
{{< /tip >}}
