Verify that all `23` Istio CRDs were committed to the Kubernetes api-server using the following command:

{{< text bash >}}
$ kubectl get crds -n istio-system | grep 'istio.io' | wc -l
23
{{< /text >}}
