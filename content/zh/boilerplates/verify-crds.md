使用以下命令验证所有 `23` 个 Istio CRD 是否已提交到 Kubernetes api-server：

{{< text bash >}}
$ kubectl get crds | grep 'istio.io' | wc -l
23
{{< /text >}}