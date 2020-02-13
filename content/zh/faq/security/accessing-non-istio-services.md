---
title: 如何让 Istio 服务访问非 Istio 服务？
weight: 40
---

当启用了全局双向 TLS， *全局* 目标规则会匹配集群中的所有服务，无论这些服务是否具有 Istio sidecar。
包括 Kubernetes API 服务器，以及群集中所有的非 Istio 服务。
想要通过具有 Istio sidecar 的服务访问这些非 Istio 服务，你需要设置目标规则，以豁免该服务。例如：

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

{{< tip >}}
如果安装 Istio 时就启用了双向 TLS，那这个目标规则已经添加到 system 了。
{{< /tip >}}

类似的，你也可以为其它非 Istio 服务添加目标规则。了解更多实例，参见 [任务](/zh/docs/tasks/security/authentication/authn-policy/#request-from-Istio-services-to-non-Istio-services)。
