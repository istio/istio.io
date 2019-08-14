使用以下命令验证所有 `23` 个 Istio CRD 是否已提交到 Kubernetes api-server：

{{< warning >}}
如果启用了 cert-manager，则 CRD 个数将为 `28` 个。
{{< /warning >}}

{{< text bash >}}
$ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
23
{{< /text >}}
