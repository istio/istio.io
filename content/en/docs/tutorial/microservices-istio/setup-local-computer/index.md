---
title: Setup a Local Computer
overview: Set up your local computer for the tutorial.
weight: 3
---

{{< boilerplate work-in-progress >}}

In this module you prepare your local computer for the tutorial.

1.  On your local computer, locate the `${NAMESPACE}-user-config.yaml` file you
    created earlier in the tutorial, where `${NAMESPACE}` is the name of your
    namespace. For example `tutorial-user-config.yaml`.

1.  Install [curl](https://curl.haxx.se/download.html).

1.  Install [Node.js](https://nodejs.org/en/download/).

1.  Install [Docker](https://docs.docker.com/install/).

1.  Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

1.  Set the `KUBECONFIG` environment variable for the `${NAMESPACE}-user-config.yaml`
    configuration file:

    {{< text bash >}}
    $ export KUBECONFIG=./${NAMESPACE}-user-config.yaml
    {{< /text >}}

1.  Verify that the configuration took effect by printing the current namespace:

    {{< text bash >}}
    $ kubectl config view -o jsonpath="{.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}"
    tutorial
    {{< /text >}}

    You should see the name of your namespace in the output.

1.  Download one of the [Istio release archives](https://github.com/istio/istio/releases) and extract
    the `istioctl` command line tool from the `bin` directory, and verify that you
    can run `istioctl` with the following command:

    {{< text bash >}}
    $ istioctl version
    version.BuildInfo{Version:"release-1.1-20190214-09-16", GitRevision:"6113e155ac85e2485e30dfea2b80fd97afd3130a", User:"root", Host:"4496ae63-3039-11e9-86e9-0a580a2c0304", GolangVersion:"go1.10.4", DockerHub:"gcr.io/istio-release", BuildStatus:"Clean", GitTag:"1.1.0-snapshot.6-6-g6113e15"}
    {{< /text >}}

Congratulations, you configured your local computer!

You are ready to [run a single service locally](/docs/tutorial/microservices-istio/single/).
