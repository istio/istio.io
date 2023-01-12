---
---
{{< tip >}}

Istio 打算在[未来](/zh/blog/2022/gateway-api-beta/)将 Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/) 作为流量管理的默认 API。下面的说明允许您在网格中配置流量管理时选择使用 Gateway API 或 Istio 配置 API。根据您的偏好，按照 `Gateway API` 或 `Istio classic` 标签下的说明进行操作。

注意，在大多数 Kubernetes 集群上，Kubernetes Gateway API CRD 并不是默认安装的，所以在使用 Gateway API 之前，请确保它们已经安装：

{{< text syntax=bash snip_id=install_crds >}}
$ kubectl get crd gateways.gateway.networking.k8s.io || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
{{< /text >}}

{{< /tip >}}
