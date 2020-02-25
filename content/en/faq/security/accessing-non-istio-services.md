---
title: How can services that use Istio access non-Istio services?
weight: 40
---

Istio will try to detect whether the destination workload have Envoy proxy or not, and drop mutual TLS if it doesn't. You can also set the destination rule explicitly to disable mutual TLS. For example:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: "api-server"
spec:
 host: "kubernetes.default.svc.cluster.local"
 trafficPolicy:
   tls:
     mode: DISABLE
EOF
{{< /text >}}
