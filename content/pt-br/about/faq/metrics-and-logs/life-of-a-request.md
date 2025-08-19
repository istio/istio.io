---
title: How to figure out what happened to a request in Istio?
weight: 80
---

You can enable [tracing](/docs/tasks/observability/distributed-tracing/) to determine the flow of a request in Istio.

Additionally, you can use the following commands to know more about the state of the mesh:

* [`istioctl proxy-config`](/docs/reference/commands/istioctl/#istioctl-proxy-config): Retrieve information about proxy configuration when running in Kubernetes:

    {{< text plain >}}
    # Retrieve information about bootstrap configuration for the Envoy instance in the specified pod.
    $ istioctl proxy-config bootstrap productpage-v1-bb8d5cbc7-k7qbm

    # Retrieve information about cluster configuration for the Envoy instance in the specified pod.
    $ istioctl proxy-config cluster productpage-v1-bb8d5cbc7-k7qbm

    # Retrieve information about listener configuration for the Envoy instance in the specified pod.
    $ istioctl proxy-config listener productpage-v1-bb8d5cbc7-k7qbm

    # Retrieve information about route configuration for the Envoy instance in the specified pod.
    $ istioctl proxy-config route productpage-v1-bb8d5cbc7-k7qbm

    # Retrieve information about endpoint configuration for the Envoy instance in the specified pod.
    $ istioctl proxy-config endpoints productpage-v1-bb8d5cbc7-k7qbm

    # Try the following to discover more proxy-config commands
    $ istioctl proxy-config --help
    {{< /text >}}

* `kubectl get`: Gets information about different resources in the mesh along with routing configuration:

    {{< text plain >}}
    # List all virtual services
    $ kubectl get virtualservices
    {{< /text >}}
