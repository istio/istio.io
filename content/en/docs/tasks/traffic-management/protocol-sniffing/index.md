---
title: Protocol Sniffing
description: Shows you how to define the new service without specifying port protocol.
weight: 30
keywords: [traffic-management,protocol-sniffing]
---

This task shows you how to define the new service without specifying the port protocol. For example, you 
can define service port as `foo` instead of `http-foo` and the protocol will be detected at runtime by sniffing packets. Using protocol 
sniffing will simplify the configuration of services.


## Before you begin

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

* If you are using [manual sidecar injection](/docs/setup/additional-setup/sidecar-injection/#manual-sidecar-injection),
        use the following command

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/tcp-echo/tcp-echo-services.yaml@)
        {{< /text >}}

## Deploy services with unnamed ports



## Understanding what happened

In this task you migrated traffic from an old to new version of the `reviews` service using Istio's weighted routing feature. Note that this is very different than doing version migration using the deployment features of container orchestration platforms, which use instance scaling to manage the traffic.

With Istio, you can allow the two versions of the `reviews` service to scale up and down independently, without affecting the traffic distribution between them.

For more information about version routing with autoscaling, check out the blog
article [Canary Deployments using Istio](/blog/2017/0.1-canary/).

## Cleanup

1. Remove the application routing rules:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.