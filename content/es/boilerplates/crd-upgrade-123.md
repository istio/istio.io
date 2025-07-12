---
---
{{< warning >}}
Si actualizas las CRD a través de Helm desde una versión de Istio 1.23 o anterior, puedes encontrar un error como el siguiente

`Error: rendered manifests contain a resource that already exists. Unable to continue with update: CustomResourceDefinition "wasmplugins.extensions.istio.io" in namespace "" exists and cannot be imported into the current release: invalid ownership metadata`

Puedes resolver esto con una migración única usando los siguientes comandos de `kubectl`:

{{< text syntax=bash snip_id=adopt_legacy_crds >}}
$ for crd in $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name)
$ do
$    kubectl label "$crd" "app.kubernetes.io/managed-by=Helm"
$    kubectl annotate "$crd" "meta.helm.sh/release-name=istio-base" # reemplaza con el nombre real de la versión de Helm, si es diferente del predeterminado de la documentación
$    kubectl annotate "$crd" "meta.helm.sh/release-namespace=istio-system" # reemplaza con el namespace real de istio
$ done
{{< /text >}}

{{< /warning >}}
