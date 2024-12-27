---
---
{{< warning >}}
Якщо ви оновлюєте CRD за допомогою Helm з версії Istio 1.23 або старішої, ви можете зіткнутися з такою помилкою

`Error: rendered manifests contain a resource that already exists. Unable to continue with update: CustomResourceDefinition "wasmplugins.extensions.istio.io" in namespace "" exists and cannot be imported into the current release: invalid ownership metadata`

Ви можете розвʼязати цю проблему за допомогою одноразової міграції за допомогою наступних команд `kubectl`:

{{< text syntax=bash snip_id=adopt_legacy_crds >}}
$ for crd in $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name)
$ do
$    kubectl label "$crd" "app.kubernetes.io/managed-by=Helm"
$    kubectl annotate "$crd" "meta.helm.sh/release-name=istio-base" # замініть на актуальну назву релізу Helm, якщо вона відрізняється від стандартної у документації.
$    kubectl annotate "$crd" "meta.helm.sh/release-namespace=istio-system" # замінити на актуальний простір імен istio
$ done
{{< /text >}}

{{< /warning >}}
