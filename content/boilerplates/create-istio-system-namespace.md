Create a namespace for the Istio control plane components:

{{< text bash >}}

$ kubectl create namespace istio-system

{{< /text >}}

{{< warning >}}
If you receve the following error, it means that you already created the namespace,
_Error from server (AlreadyExists): namespaces "istio-system" already exists_.
**Ignore** the error and proceed to the next step.
{{< /warning >}}
