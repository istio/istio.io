---
title: Set up a Local Computer
overview: Set up your local computer for the tutorial.
weight: 3
owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

In this module you prepare your local computer for the tutorial.

1.  Install [`curl`](https://curl.haxx.se/download.html).

1.  Install [Node.js](https://nodejs.org/en/download/).

1.  Install [Docker](https://docs.docker.com/install/).

1.  Install [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

1.  Set the `KUBECONFIG` environment variable for the configuration file you received from the tutorial instructors, or
    created yourself in the previous module.

    {{< text bash >}}
    $ export KUBECONFIG=<the file you received or created in the previous module>
    {{< /text >}}

1.  Verify that the configuration took effect by printing the current namespace:

    {{< text bash >}}
    $ kubectl config view -o jsonpath="{.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}"
    tutorial
    {{< /text >}}

    You should see in the output the name of the namespace, allocated for you by the instructors or allocated by
    yourself in the previous module.

1.  Download one of the [Istio release archives](https://github.com/istio/istio/releases) and extract
    the `istioctl` command line tool from the `bin` directory, and verify that you
    can run `istioctl` with the following command:

    {{< text bash >}}
    $ istioctl version
    client version: 1.7.0
    control plane version: 1.7.0
    data plane version: 1.7.0 (4 proxies)
    {{< /text >}}

Congratulations, you configured your local computer!

You are ready to [run a single service locally](/docs/examples/microservices-istio/single/).
