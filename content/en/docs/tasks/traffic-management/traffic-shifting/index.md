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

This task shows you how to shift traffic from one version of a microservice to another.

A common use case is to migrate traffic gradually from an older version of a microservice to a new one.
In Istio, you accomplish this goal by configuring a sequence of routing rules that redirect a percentage of traffic
from one destination to another.

In this task, you will use send 50% of traffic to `reviews:v1` and 50% to `reviews:v3`. Then, you will
complete the migration by sending 100% of traffic to `reviews:v3`.

{{< boilerplate gateway-api-gamma-support >}}

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

* Review the [Traffic Management](/docs/concepts/traffic-management) concepts doc.

## Apply weight-based routing

{{< warning >}}
If you haven't already, follow the instructions in [define the service versions](/docs/examples/bookinfo/#define-the-service-versions).
{{< /warning >}}

1.  To get started, run this command to route all traffic to the `v1` version:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_all_v1 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_all_v1 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Open the Bookinfo site in your browser. The URL is `http://$GATEWAY_URL/productpage`, where `$GATEWAY_URL` is the External IP address of the ingress, as explained in
the [Bookinfo](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port) doc.

    Notice that the reviews part of the page displays with no rating stars, no
    matter how many times you refresh. This is because you configured Istio to route
    all traffic for the reviews service to the version `reviews:v1` and this
    version of the service does not access the star ratings service.

3)  Transfer 50% of the traffic from `reviews:v1` to `reviews:v3` with the following command:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_50_v3 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_50_v3 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-50-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4) Wait a few seconds for the new rules to propagate and then
confirm the rule was replaced:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

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

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash outputis=yaml snip_id=gtw_verify_config_50_v3 >}}
$ kubectl get httproute reviews -o yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
...
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: reviews-v1
      port: 9080
      weight: 50
    - group: ""
      kind: Service
      name: reviews-v3
      port: 9080
      weight: 50
    matches:
    - path:
        type: PathPrefix
        value: /
status:
  parents:
  - conditions:
    - lastTransitionTime: "2022-11-10T18:13:43Z"
      message: Route was valid
      observedGeneration: 14
      reason: Accepted
      status: "True"
      type: Accepted
...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  Refresh the `/productpage` in your browser and you now see *red* colored star ratings approximately 50% of the time. This is because the `v3` version of `reviews` accesses
the star ratings service, but the `v1` version does not.

    {{< tip >}}
    With the current Envoy sidecar implementation, you may need to refresh the
    `/productpage` many times --perhaps 15 or more--to see the proper distribution.
    You can modify the rules to route 90% of the traffic to `v3` to see red stars
    more often.
    {{< /tip >}}

6)  Assuming you decide that the `reviews:v3` microservice is stable, you can
route 100% of the traffic to `reviews:v3` by applying this virtual service:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_100_v3 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_100_v3 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7) Refresh the `/productpage` several times. Now you will always see book reviews
    with *red* colored star ratings for each review.

## Understanding what happened

In this task you migrated traffic from an old to new version of the `reviews` service using Istio's weighted routing feature. Note that this is very different than doing version migration using the deployment features of container orchestration platforms, which use instance scaling to manage the traffic.

With Istio, you can allow the two versions of the `reviews` service to scale up and down independently, without affecting the traffic distribution between them.

For more information about version routing with autoscaling, check out the blog
article [Canary Deployments using Istio](/blog/2017/0.1-canary/).

## Cleanup

1. Remove the application routing rules:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=cleanup >}}
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_cleanup >}}
$ kubectl delete httproute reviews
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.
