---
title: Enable Istio on productpage
overview: Deploy the Istio control plane and enable Istio on a single microservice.

weight: 60

---

As you saw in the previous module, Kubernetes does not provide us all the functionality you need to effectively operate
your microservices. Istio comes to your help.

In this module you enable Istio on a single microservice, _productpage_.
The rest of the application will continue to operate as previously. Note that you can enable Istio gradually,
microservice by microservice. Also note that Istio is enabled transparently to the microservices, you do not change the
microservices code. And also note that you enable Istio without disrupting our application, it continues to run and
serve user requests.

1.  Disable mututal TLS in your namespace (will be explained later):

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: Policy
    metadata:
      name: default
    spec:
      peers:
    EOF
    {{< /text >}}

1.  Redeploy the _productpage_ microservice, Istio-enabled:

    {{< text bash >}}
    $ kubectl apply -l app=productpage,version=v1 -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/platform/kube/bookinfo.yaml --dry-run -o yaml | istioctl kube-inject -f - | kubectl apply -f -
    deployment "productpage-v1" configured
    {{< /text >}}

1.  Access the application's webpage and verify that the application continues to work. Note that Istio was added
    **transparently**, the code of the original application did not change.

1.  Check the the _productpage_'s pods and see that now each replica has two containers.
    The first container is the microservice itself, the second is the sidecar proxy attached to it:

    {{< text bash >}}
    $ kubectl get pods
    details-v1-68868454f5-8nbjv       1/1       Running   0          7h
    details-v1-68868454f5-nmngq       1/1       Running   0          7h
    details-v1-68868454f5-zmj7j       1/1       Running   0          7h
    productpage-v1-6dcdf77948-6tcbf   2/2       Running   0          7h
    productpage-v1-6dcdf77948-t9t97   2/2       Running   0          7h
    productpage-v1-6dcdf77948-tjq5d   2/2       Running   0          7h
    ratings-v1-76f4c9765f-khlvv       1/1       Running   0          7h
    ratings-v1-76f4c9765f-ntvkx       1/1       Running   0          7h
    ratings-v1-76f4c9765f-zd5mp       1/1       Running   0          7h
    reviews-v1-56f6855586-cnrjp       1/1       Running   0          7h
    reviews-v1-56f6855586-lxc49       1/1       Running   0          7h
    reviews-v1-56f6855586-qh84k       1/1       Running   0          7h
    sleep-88ddbcfdd-cc85s             1/1       Running   0          7h
    sleep-88ddbcfdd-flvp6             1/1       Running   0          7h
    sleep-88ddbcfdd-zpn8m             1/1       Running   0          11h
    {{< /text >}}

1.  Note that Kubernetes replaced the original pods of _productpage_ with the Istio-enabled pods, transparently and
    incrementally,  performing what is called a
    [rolling update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update-intro/).
    Kubernetes terminated an old pod only when a new pod started to run, and it transparently switched the traffic to
    the new pods, one by one. (To be more precise, it did not terminate more than one pod before a new pod was started.)
    All this was done to prevent disruption of our application, so it continued to work during the injection of Istio.

1.  Check the logs of the Istio sidecar of _productpage_:

    {{< text bash >}}
    $ kubectl logs -l app=productpage -c istio-proxy | grep GET
    ...
    [2019-02-15T09:06:04.079Z] "GET /details/0 HTTP/1.1" 200 - 0 178 5 3 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "details:9080" "172.30.230.51:9080" outbound|9080||details.tutorial.svc.cluster.local - 172.21.109.216:9080 172.30.146.104:58698 -
    [2019-02-15T09:06:04.088Z] "GET /reviews/0 HTTP/1.1" 200 - 0 379 22 22 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "reviews:9080" "172.30.230.27:9080" outbound|9080||reviews.tutorial.svc.cluster.local - 172.21.185.48:9080 172.30.146.104:41442 -
    [2019-02-15T09:06:04.053Z] "GET /productpage HTTP/1.1" 200 - 0 5723 90 83 "10.127.220.66" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "tutorial.bookinfo.com" "127.0.0.1:9080" inbound|9080|http|productpage.tutorial.svc.cluster.local - 172.30.146.104:9080 10.127.220.66:0 -
    {{< /text >}}

1.  Check the Istio dashboard, access `http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard`. In the top left
    drop-down menu, select _Istio Mesh Dashboard_. Notice the `productpage` service from your namespace, it's name
    should be `productpage.<your namespace>.svc.cluster.local`.

    {{< image width="80%"
        link="images/dashboard-mesh.png"
        caption="Istio Mesh Dashboard"
        >}}

    Select _Istio Service Dashboard_ from the top left drop-down menu, and then select your `productpage` service from
    the drop-down menu of services.
    Scroll down to the _Service Workloads_ section. Access the application's webpage several times and see that the
    dashboard graphs are updated.

    {{< image width="80%"
        link="images/dashboard-service.png"
        caption="Istio Service Dashboard"
        >}}

This is the immediate gain you get by applying Istio even on a single microservice. You can get logs of traffic to
and from the microservice, including time, HTTP method, path, response code. You can monitor your microservice using
the Istio dashboard.
In the next modules you will learn the functionality Istio can provide to your applications. While some of Istio
functionality is relevant when applied even to a single microservice, for expediency's sake you will apply Istio on
the whole application to exploit its full potential.
