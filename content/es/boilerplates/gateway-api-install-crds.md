---
---
Ten en cuenta que las CRD de la API de Gateway de Kubernetes no vienen instaladas por defecto en la mayoría de los clusteres de Kubernetes, así que asegúrate de que estén
instaladas antes de usar la API de Gateway:

{{< text syntax=bash snip_id=install_crds >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/{{< k8s_gateway_api_version >}}/standard-install.yaml
{{< /text >}}
