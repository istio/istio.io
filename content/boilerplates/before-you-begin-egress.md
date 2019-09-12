---
---
## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Deploy the [sleep]({{< github_tree >}}/samples/sleep) sample app to use as a test source for sending requests.
    If you have
    [automatic sidecar injection](/docs/setup/kubernetes/additional-setup/sidecar-injection/#automatic-sidecar-injection)
    enabled, run the following command to deploy the sample app:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    Otherwise, manually inject the sidecar before deploying the `sleep` application with the following command:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    {{< tip >}}
    You can use any pod with `curl` installed as a test source.
    {{< /tip >}}

*   Set the `SOURCE_POD` environment variable to the name of your source pod:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}
