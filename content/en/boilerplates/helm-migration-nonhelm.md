---
---
### Migrating from non-Helm installations

If you're migrating from a version of Istio installed using `istioctl` or
Operator to Helm, you need to delete your current Istio control plane resources
and and re-install Istio using Helm as described above. When deleting your
current Istio installation, you must not remove the Istio Custom Resource
Definitions (CRDs) as that can lead to loss of your custom Istio resources.

{{< warning >}}
It is highly recommended to take a backup of your Istio resources using steps
described above before deleting current Istio installation in your cluster.
{{< /warning >}}

You can follow steps mentioned in the
[Istioctl uninstall guide](/docs/setup/install/istioctl#uninstall-istio) or
[Operator uninstall guide](/docs/setup/install/operator/#uninstall)
depending upon your installation method.