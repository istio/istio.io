---
title: 如何使用 Istio 的服务访问非 Istio 服务？
weight: 40
---

当全局启用双向 TLS 时，全局目标规则 (*global* destination rule) 匹配群集中的所有服务，无论这些服务是否具有 Istio sidecar。 这包括 Kubernetes API 服务器，以及集群中的任何非 Istio 服务。 要让这些非 Istio 服务与有 Istio sidecar 的服务进行通信，你需要设置目标规则以免除服务。 例如：

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
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

> 这个目标规则已作为 [Istio 安装的一部分添加到系统中，并具有默认的双向 TLS](/docs/setup/kubernetes/quick-start/#option-2-install-istio-with-default-mutual-tls-authentication)

同样，您可以为其他非 Istio 服务添加目标规则。 有关更多示例，请参阅[任务](/docs/tasks/security/authn-policy/#request-from-istio-services-to-non-istio-services)。
