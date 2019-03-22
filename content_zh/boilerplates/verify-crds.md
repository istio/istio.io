使用以下命令验证所有的 `53` 个 Istio CRD 都已被成功提交到 Kubernetes api-server：

{{< warning >}}
如果启用了 cert-manager，则 CRD 的数量应改为 `58`。
{{< /warning >}}

{{< text bash >}}
$ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
53
{{< /text >}}
