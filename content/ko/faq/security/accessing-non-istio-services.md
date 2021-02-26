---
title: How can services that use Istio access non-Istio services?
weight: 40
---

Istio detects if the destination workload has an Envoy proxy and drops mutual TLS if it doesn't. Set an explicit destination rule to disable mutual TLS. For example:

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
