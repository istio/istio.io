等待 Istio 所有的 CRDs 创建完成：

{{< text bash >}}
$ kubectl -n istio-system wait --for=condition=complete job --all
{{< /text >}}
