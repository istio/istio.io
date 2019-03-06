Create a namespace for the Istio control plane components:

{{< text bash >}}
$ kubectl create namespace istio-system
{{< /text >}}

{{< warning >}}
If you receive the following error, it means that you already created the namespace,
`Error from server (AlreadyExists): namespaces "istio-system" already exists`.
**Ignore** the error and proceed to the next step.
{{< /warning >}}
