---
title: Configuring Request Routing
description: This task shows you how to configure dynamic request routing based on weights and HTTP headers.
weight: 10
aliases:
    - /docs/tasks/request-routing.html
keywords: [traffic-management,routing]
---

> This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.7/docs/tasks/traffic-management/).

This task shows you how to configure dynamic request routing based on weights and HTTP headers.

## Before you begin

* Setup Istio by following the instructions in the
[Installation guide](/docs/setup/).

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

## Content-based routing

1.  The Bookinfo sample deploys multiple versions of each microservice, so you will start by creating destination rules
that define the service subsets corresponding to each version, and the load balancing policy for each subset.

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/destination-rule-all.yaml@
    {{< /text >}}

    If you enabled mutual TLS, please run the following instead

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

    You can display the destination rules with the following command:

    {{< text bash >}}
    $ istioctl get destinationrules -o yaml
    {{< /text >}}

    Since the subset references in virtual services rely on the destination rules,
    wait a few seconds for destination rules to propagate before adding virtual services that refer to these subsets.

1.  Because the Bookinfo sample deploys 3 versions of the reviews microservice, you need to set a default route.
Otherwise if you access the application several times, you'll notice that sometimes the output contains
star ratings. This is because without an explicit default version set, Istio will route requests to all available
versions of a service in a random fashion.

    > This task assumes you don't have any existing virtual services. If you've already created conflicting virtual services for the sample,
you'll need to use `replace` rather than `create` in the following command.

    Set the default version for all microservices to v1.

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

    > In a Kubernetes deployment of Istio, you can replace `istioctl`
    with `kubectl` in the above, and for all other CLI commands.
    Note, however, that `kubectl` currently does not provide input validation.

    You can display the routes that are defined with the following command:

    {{< text bash yaml >}}
    $ istioctl get virtualservices -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: details
      ...
    spec:
      hosts:
      - details
      http:
      - route:
        - destination:
            host: details
            subset: v1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: productpage
      ...
    spec:
      gateways:
      - bookinfo-gateway
      - mesh
      hosts:
      - productpage
      http:
      - route:
        - destination:
            host: productpage
            subset: v1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
      ...
    spec:
      hosts:
      - ratings
      http:
      - route:
        - destination:
            host: ratings
            subset: v1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
      ...
    spec:
      hosts:
      - reviews
      http:
      - route:
        - destination:
            host: reviews
            subset: v1
    ---
    {{< /text >}}

    > The corresponding `subset` definitions can be displayed using `istioctl get destinationrules -o yaml`.

    Since config propagation is eventually consistent, wait a few seconds for the virtual services to take effect.

1.  Open the Bookinfo URL (`http://$GATEWAY_URL/productpage`) in your browser. Recall that `GATEWAY_URL`
    should have been set using [these instructions](/docs/examples/bookinfo/#determining-the-ingress-ip-and-port)
    when the Bookinfo sample was deployed.

    You should see the Bookinfo application productpage displayed.
    Notice that the `productpage` is displayed with no rating stars since `reviews:v1` does not access the ratings service.

1.  Route a specific user to `reviews:v2`

    Lets enable the ratings service for test user "jason" by routing productpage traffic to
    `reviews:v2` instances.

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
    {{< /text >}}

    Confirm the rule is created:

    {{< text bash yaml >}}
    $ istioctl get virtualservice reviews -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
      ...
    spec:
      hosts:
      - reviews
      http:
      - match:
        - headers:
            cookie:
              regex: ^(.*?;)?(user=jason)(;.*)?$
        route:
        - destination:
            host: reviews
            subset: v2
      - route:
        - destination:
            host: reviews
            subset: v1
    {{< /text >}}

1.  Log in as user "jason" at the `productpage` web page.

    You should now see ratings (1-5 stars) next to each review. Notice that if you log in as
    any other user, you will continue to see `reviews:v1`.

## Understanding what happened

In this task, you used Istio to send 100% of the traffic to the v1 version of each of the Bookinfo
services. You then set a rule to selectively send traffic to version v2 of the reviews service based
on a header (i.e., a user cookie) in a request.

Note that Kubernetes services, like the Bookinfo ones used in this task, must adhere to certain
restrictions in order to take advantage of Istio's L7 routing features. Refer to the
[sidecar injection documentation](/docs/setup/kubernetes/sidecar-injection/#pod-spec-requirements)
for details.

Once the v2 version has been tested to our satisfaction, you could use Istio to send traffic from
all users to v2, optionally in a gradual fashion. You'll explore this in a separate task.

## Cleanup

1.   Remove the application virtual services.

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1.   Remove the application destination rules.

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/destination-rule-all.yaml@
    {{< /text >}}

    If you enabled mutual TLS, please run the following instead

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

1. If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.
