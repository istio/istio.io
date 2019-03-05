## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   To have test source for sending requests, start the [sleep]({{< github_tree >}}/samples/sleep) sample.

    If you have enabled
    [automatic sidecar injection](/docs/setup/kubernetes/additional-setup/sidecar-injection/#automatic-sidecar-injection), do

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    You can use any pod with `curl` installed as a test source.

*   To send requests, create the `SOURCE_POD` environment variable to store the name of the source
    pod:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}
