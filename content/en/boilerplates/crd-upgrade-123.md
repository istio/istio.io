---
---
{{< warning >}}
If upgrading CRDs via Helm from an Istio release 1.23 or older, you may encounter an error such as the following

`Error: rendered manifests contain a resource that already exists. Unable to continue with update: CustomResourceDefinition "wasmplugins.extensions.istio.io" in namespace "" exists and cannot be imported into the current release: invalid ownership metadata`

You can resolve this with a one-time migration using the following `kubectl` commands:

    {{< text syntax=bash snip_id=adopt_legacy_crds >}}
    $ for crd in $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name)
    $ do
    $    kubectl label "$crd" "app.kubernetes.io/managed-by=Helm"
    $    kubectl annotate "$crd" "meta.helm.sh/release-name=istio-base" # replace with actual Helm release name, if different from the documentation default
    $    kubectl annotate "$crd" "meta.helm.sh/release-namespace=istio-system" # replace with actual istio namespace
    $ done
    {{< /text >}}

{{< /warning >}}
