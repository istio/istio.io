---
---
*   Start the [httpbin]({{< github_tree >}}/samples/httpbin) sample.

    If you have enabled [automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), deploy the `httpbin` service:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    Otherwise, you have to manually inject the sidecar before deploying the `httpbin` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    {{< /text >}}
