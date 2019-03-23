---
title: Enable Istio on all the microservices
overview: Enable Istio on your whole application.
weight: 70

---

Previously you deployed the Istio control plane and enabled Istio on a single microservice, _`productpage`_.
You can proceed to enable Istio on the microservices incrementally, one by one, to get the functionality provided by
Istio for more and more microservices. For the purpose of this tutorial, you will just enable Istio on the remaining
microservices in one stroke.

1.  Redeploy the Bookinfo application, Istio-enabled. _`productpage`_ will not be redeployed since it already has Istio injected, its pods will not be changed.

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | kubectl apply -l app!=reviews -f -
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | kubectl apply -l app=reviews,version=v2 -f -
    service "details" unchanged
    deployment "details-v1" configured
    service "ratings" unchanged
    deployment "ratings-v1" configured
    service "productpage" unchanged
    deployment "productpage-v1" configured
    deployment "reviews-v2" configured
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
    reviews-v2-dfbcf859c-27dvk        2/2       Running   0          2m
    sleep-88ddbcfdd-cc85s             1/1       Running   0          7h
    sleep-88ddbcfdd-flvp6             1/1       Running   0          7h
    sleep-88ddbcfdd-zpn8m             1/1       Running   0          11h
    {{< /text >}}

1.  Access the Istio dashboard at
    [http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard](http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard).
    In the top left drop-down menu, select _Istio Mesh Dashboard_. Note that now all the services from your namespace
    appear in the list of services.

    {{< image width="80%"
        link="images/dashboard-mesh-all.png"
        caption="Istio Mesh Dashboard"
        >}}

1.  Check some other microservice in _Istio Service Dashboard_, e.g. _ratings_ :

    {{< image width="80%"
        link="images/dashboard-ratings.png"
        caption="Istio Service Dashboard"
        >}}

1.  Visualize your application's topology by using the [Kiali](https://www.kiali.io) console. Access
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console).
    (The `my-kiali.io` URL should be in your /etc/hosts file, you set it
    [previously](/docs/tutorial/run-bookinfo-with-kubernetes/#update-your-etc-hosts-file)).

    Click on the Graph tab and select your namespace in the _Namespace_ drop-down menu in the top level corner.
    In the _Display_ drop-down menu mark the _Traffic Animation_ checkbox to see some cool traffic animation.

    Access your application's homepage several times for several seconds and see the graph of your application
    displayed.

    Try different options in the _Edge Labels_ drop-down menu. Hover with the mouse over the nodes and edges of the
    graph. Notice the traffic metrics on the right.

    {{< image width="80%"
        link="images/kiali-initial.png"
        caption="Kiali Graph Tab"
        >}}

Now, once you enabled Istio on your whole application, you can explore the Istio functionality in its full potential.
You will do it in the following modules.
