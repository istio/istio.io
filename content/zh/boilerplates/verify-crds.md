等待所有的 Istio CRDs 创建完成：

{{< text bash >}}
$ kubectl -n istio-system wait --for=condition=complete job --all
{{< /text >}}
