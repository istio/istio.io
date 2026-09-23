---
---
{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

{{< warning >}}
Este documento configura Istio usando características de la API de Gateway que son
[experimentales](https://gateway-api.sigs.k8s.io/geps/overview/#status)
Antes de usar las instrucciones de la API de Gateway, asegúrate de:

1) Instalar la **versión experimental** de las CRD de la API de Gateway:

    {{< text syntax=bash snip_id=install_experimental_crds >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
    {{< /text >}}

2) Configurar Istio para que lea los recursos alfa de la API de Gateway estableciendo la variable de entorno `PILOT_ENABLE_ALPHA_GATEWAY_API`
    en `true` al instalar Istio:

    {{< text syntax=bash snip_id=enable_alpha_crds >}}
    $ istioctl install --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true --set profile=minimal -y
    {{< /text >}}

{{< /warning >}}
