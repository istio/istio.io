Verify that all `23` Istio CRDs were committed to the Kubernetes api-server using the following command:

{{< warning >}}
If cert-manager is enabled, then the CRD count will be `28` instead.
{{< /warning >}}

{{< text bash >}}
$ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
23
{{< /text >}}
