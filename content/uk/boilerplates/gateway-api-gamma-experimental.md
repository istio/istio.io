---
---
{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

{{< warning >}}
Цей документ конфігурує Istio, використовуючи функції Gateway API, які є [експериментальними](https://gateway-api.sigs.k8s.io/geps/overview/#status). Перед використанням інструкцій Gateway API переконайтеся, що:

1) Ви встановили **експериментальну версію** CRD Gateway API:

    {{< text syntax=bash snip_id=install_experimental_crds >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
    {{< /text >}}

2) Налаштуйте Istio для читання альфа-ресурсів Gateway API, встановивши змінну середовища `PILOT_ENABLE_ALPHA_GATEWAY_API` на `true` під час інсталяції Istio:

    {{< text syntax=bash snip_id=enable_alpha_crds >}}
    $ istioctl install --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true --set profile=minimal -y
    {{< /text >}}

{{< /warning >}}
