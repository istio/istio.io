---
title: Enable Istio on all the microservices
overview: Enable Istio on our whole application and on the Ingress.
weight: 70

---

Previously we deployed the Istio control plane and enabled Istio on a single microservice, _productpage_. We can proceed to enable Istio on the microservices incrementally, one by one, to get the functionality provided by Istio for more and more microservices. For the purpose of this tutorial, we will just enable Istio on the remaining microservices in one stroke. We will also enable Istio on our pod that we use for testing.

1.  Redeploy the Bookinfo application, Istio-enabled. _productpage_ will not be redeployed since it already has Istio injected, its pods will not be changed.

    {{< text bash >}}
    $ curl -s https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | kubectl apply -l version!=v3 -f -
    service "details" unchanged
    deployment "details-v1" configured
    service "ratings" unchanged
    deployment "ratings-v1" configured
    service "reviews" unchanged
    deployment "reviews-v1" configured
    deployment "reviews-v2" configured
    service "productpage" unchanged
    deployment "productpage-v1" configured
    {{< /text >}}

1.  Access the application's webpage several times. Note that Istio was added **transparently**, the original
    application did not change.
    It was added on the fly, without the need to undeploy and redeploy the whole application, without hurting the
    application's availability.

1.  Check the application pods and verify that now each pod has two containers.
    One container is the microservice itself, the other is the sidecar proxy attached to it:

    {{< text bash >}}
    $ kubectl get pods
    details-v1-58c68b9ff-kz9lf        2/2       Running   0          2m
    productpage-v1-59b4f9f8d5-d4prx   2/2       Running   0          2m
    ratings-v1-b7b7fbbc9-sggxf        2/2       Running   0          2m
    reviews-v1-6f954d668-d7w4l        2/2       Running   0          2m
    reviews-v2-dfbcf859c-27dvk        2/2       Running   0          2m
    sleep-88ddbcfdd-cc85s             1/1       Running   0          7h
    sleep-88ddbcfdd-flvp6             1/1       Running   0          7h
    sleep-88ddbcfdd-zpn8m             1/1       Running   0          11h
    {{< /text >}}
