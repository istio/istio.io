---
---
## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

    {{< warning >}}
    Add the following [installation options](/docs/reference/config/installation-options/)
    to your install command if they are not already configured in your selected [configuration profile](/docs/setup/kubernetes/additional-setup/config-profiles/):

    {{< text plain >}}
    --set global.outboundTrafficPolicy.mode=ALLOW_ANY --set pilot.env.PILOT_ENABLE_FALLTHROUGH_ROUTE=1
    {{< /text >}}

    {{< /warning >}}

*   To use as a test source for sending requests, start the [sleep]({{< github_tree >}}/samples/sleep) sample.

    If you have
    [automatic sidecar injection](/docs/setup/kubernetes/additional-setup/sidecar-injection/#automatic-sidecar-injection)
    enabled, run the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    Otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

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
