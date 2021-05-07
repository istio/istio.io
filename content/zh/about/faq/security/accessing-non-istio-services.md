---
title: 如何让 Istio 服务访问非 Istio 服务？
weight: 40
---

Istio 会检测目标工作负载是否具有 Envoy 代理，如果没有则丢弃双向 TLS。设置明确的目标规则可以禁用双向 TLS。例如：

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
