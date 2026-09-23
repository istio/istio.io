---
---
{{< warning >}}
如果通过 Helm 从 Istio 1.23 或更早版本升级 CRD，可能会遇到如下错误

`Error: rendered manifests contain a resource that already exists. Unable to continue with update: CustomResourceDefinition "wasmplugins.extensions.istio.io" in namespace "" exists and cannot be imported into the current release: invalid ownership metadata`

您可以使用以下 `kubectl` 命令通过一次性迁移解决此问题：

{{< text syntax=bash snip_id=adopt_legacy_crds >}}
$ for crd in $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name)
$ do
$    kubectl label "$crd" "app.kubernetes.io/managed-by=Helm"
$    kubectl annotate "$crd" "meta.helm.sh/release-name=istio-base" # 如果与文档默认值不同，请用实际的 Helm 版本名称替换
$    kubectl annotate "$crd" "meta.helm.sh/release-namespace=istio-system" # 用实际的 istio 命名空间替换
$ done
{{< /text >}}

{{< /warning >}}
