---
title: Traffic Shifting
description: Shows you how to migrate traffic from an old to new version of a service.
weight: 30
keywords: [traffic-management,traffic-shifting]
aliases:
    - /docs/tasks/traffic-management/version-migration.html
owner: istio/wg-networking-maintainers
test: yes
---

This task shows you how to gradually migrate traffic from one version of a
microservice to another. For example, you might migrate traffic from an older
version to a new version.

A common use case is to migrate traffic gradually from one version of a microservice
to another. In Istio, you accomplish this goal by configuring a sequence of rules
that route a percentage of traffic to one service or another. In this task, you will send
50% of traffic to `reviews:v1` and 50% to `reviews:v3`. Then, you will
complete the migration by sending 100% of traffic to `reviews:v3`.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

* Review the [Traffic Management](/docs/concepts/traffic-management) concepts doc.

## Apply weight-based routing

{{< warning >}}
If you haven't already applied destination rules, follow the instructions in [Apply Default Destination Rules](/docs/examples/bookinfo/#apply-default-destination-rules).
{{< /warning >}}

1.  To get started, run this command to route all traffic to the `v1` version of
each microservice.

    {{< text syntax=bash snip_id=config_all_v1 >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1.  Open the Bookinfo site in your browser. The URL is `http://$GATEWAY_URL/productpage`, where `$GATEWAY_URL` is the External IP address of the ingress, as explained in
the [Bookinfo](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port) doc.

    Notice that the reviews part of the page displays with no rating stars, no
    matter how many times you refresh. This is because you configured Istio to route
    all traffic for the reviews service to the version `reviews:v1` and this
    version of the service does not access the star ratings service.

1.  Transfer 50% of the traffic from `reviews:v1` to `reviews:v3` with the following command:

    {{< text syntax=bash snip_id=config_50_v3 >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml@
    {{< /text >}}

    Wait a few seconds for the new rules to propagate.

1. Confirm the rule was replaced:

    {{< text syntax=bash outputis=yaml snip_id=verify_config_50_v3 >}}
    $ kubectl get virtualservice reviews -o yaml
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
    ...
    spec:
      hosts:
      - reviews
      http:
      - route:
        - destination:
            host: reviews
            subset: v1
          weight: 50
        - destination:
            host: reviews
            subset: v3
          weight: 50
    {{< /text >}}

1.  Refresh the `/productpage` in your browser and you now see *red* colored star ratings approximately 50% of the time. This is because the `v3` version of `reviews` accesses
the star ratings service, but the `v1` version does not.

    {{< tip >}}
    With the current Envoy sidecar implementation, you may need to refresh the
    `/productpage` many times --perhaps 15 or more--to see the proper distribution.
    You can modify the rules to route 90% of the traffic to `v3` to see red stars
    more often.
    {{< /tip >}}

1.  Assuming you decide that the `reviews:v3` microservice is stable, you can
route 100% of the traffic to `reviews:v3` by applying this virtual service:

    {{< text syntax=bash snip_id=config_100_v3 >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
    {{< /text >}}

    Now when you refresh the `/productpage` you will always see book reviews
    with *red* colored star ratings for each review.

## Understanding what happened

In this task you migrated traffic from an old to new version of the `reviews` service using Istio's weighted routing feature. Note that this is very different than doing version migration using the deployment features of container orchestration platforms, which use instance scaling to manage the traffic.

With Istio, you can allow the two versions of the `reviews` service to scale up and down independently, without affecting the traffic distribution between them.

For more information about version routing with autoscaling, check out the blog
article [Canary Deployments using Istio](/blog/2017/0.1-canary/).

## Cleanup

1. Remove the application routing rules:

    {{< text syntax=bash snip_id=cleanup >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.
