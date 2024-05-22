
## Uninstall {#uninstall}

1. The label to instruct Istio to automatically include applications in the `default` namespace to an ambient mesh is not removed by default. If no longer needed, use the following command to remove it:

    {{< text bash >}}
    $ kubectl label namespace default istio.io/dataplane-mode-
    $ kubectl label namespace default istio.io/use-waypoint-
    {{< /text >}}

1. To remove waypoint proxies, installed policies, and uninstall Istio:

    {{< text bash >}}
    $ istioctl x waypoint delete --all
    $ istioctl uninstall -y --purge
    $ kubectl delete namespace istio-system
    {{< /text >}}

1. To delete the Bookinfo sample application and its configuration, see [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup).

1. To remove the `sleep` and `notsleep` applications:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    $ kubectl delete -f @samples/sleep/notsleep.yaml@
    {{< /text >}}

1. If you installed the Gateway API CRDs, remove them:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}
