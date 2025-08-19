---
---
Before upgrading Istio in your cluster, we recommend creating a backup of your
custom configurations, and restoring it from backup if necessary:

{{< text bash >}}
$ kubectl get istio-io --all-namespaces -oyaml > "$HOME"/istio_resource_backup.yaml
{{< /text >}}

You can restore your custom configuration like this:

{{< text bash >}}
$ kubectl apply -f "$HOME"/istio_resource_backup.yaml
{{< /text >}}
