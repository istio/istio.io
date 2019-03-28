使用以下命令验证所有 `53` Istio CRD 是否已提交到 Kubernetes api-server：

{{< warning >}}
如果启用了 cert-manager，则 CRD 计数将为 `58`。
{{< /warning >}}

{{< text bash >}}
$ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
53
{{< /text >}}
