---
title: How to figure out what happened to a request in Istio?
weight: 80
---

You can enable [tracing](/docs/tasks/telemetry/distributed-tracing/) to figure out the flow of a request in Istio.

Additionally, you can use following commands to know more about the state of the mesh:

* `istioctl proxy-config`: Retrieves proxy configuration for the specified pod from the endpoint proxy or Pilot when running in Kubernetes.

    {{< text plain >}}
    # Retrieve all config for productpage-v1-bb8d5cbc7-k7qbm pod from the endpoint proxy
    $ istioctl proxy-config endpoint productpage-v1-bb8d5cbc7-k7qbm

    # Try the following to know more proxy-config command:
    $ istioctl proxy-config --help
    {{< /text >}}

* `kubectl get`: Gets information about different resources in mesh and routing configuration.

    {{< text plain >}}
    # List all virtual services
    $ istioctl get virtualservices

    # Try following to know more proxy-config command:
    $ istioctl proxy-config --help
    {{< /text >}}

* Mixer AccessLogs: Mixer writes access logs that contain information about requests. You can get them as follows:

    {{< text plain >}}
    # Fill <istio namespace> with the namespace of your istio mesh. Ex: istio-system
    $ TELEMETRY_POD=`kubectl get po -n <istio namespace> | grep istio-telemetry | awk '{print $1;}'`
    $ kubectl logs $TELEMETRY_POD -c mixer  -n istio-system  | grep accesslog
    {{< /text >}}
