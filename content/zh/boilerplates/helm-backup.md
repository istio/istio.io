---
---
在您的集群中升级 Istio 之前，我们建议您创建自定义配置的备份，
并在必要时从备份中恢复它：

{{< text bash >}}
$ kubectl get istio-io --all-namespaces -oyaml > "$HOME"/istio_resource_backup.yaml
{{< /text >}}

您可以像下面这样恢复您的自定义配置：

{{< text bash >}}
$ kubectl apply -f "$HOME"/istio_resource_backup.yaml
{{< /text >}}
