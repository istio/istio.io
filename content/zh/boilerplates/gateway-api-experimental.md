---
---
{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

{{< warning >}}
以下 Gateway API 指令包括 [Experimental（实验）](https://gateway-api.sigs.k8s.io/geps/overview/#status)以及
Istio 特定的功能。在使用 Gateway API 指令之前，请确保安装**实验版本**的 Gateway API CRD：

{{< text syntax=bash snip_id=install_experimental_crds >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
{{< /text >}}

{{< /warning >}}
