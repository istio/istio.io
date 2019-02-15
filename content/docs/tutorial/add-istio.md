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

1.  Disable mututal TLS for _productpage_ microservice:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: Policy
    metadata:
      name: disable-mtls
    spec:
      peers:
    EOF
    {{< /text >}}

1.  Redeploy the _productpage_ microservice, Istio-enabled:

    {{< text bash >}}
    $ kubectl apply -l app=productpage,version=v1 -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/platform/kube/bookinfo.yaml --dry-run -o yaml | istioctl kube-inject -f - | kubectl apply -f -
    deployment "productpage-v1" configured
    {{< /text >}}

1.  Access the application and verify that the application continues to work. Note that Istio was added
    **transparently**, the code of the original application did not change.

1.  Check the the _productpage_'s pods and see that now each replica has two containers.
    The first container is the microservice itself, the second is the sidecar proxy attached to it:

    {{< text bash >}}
    $ kubectl get pods
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

    This is the immediate gain you get by applying Istio even on a single microservice. You can get logs of traffic to
    and from the microservice, including time, HTTP method, path, response code. In the next modules you will learn the
    functionality Istio can provide to your applications. While some of Istio functionality is relevant when applied
    even to a single microservice, for expediency's sake you will apply Istio on the whole application to exploit its full
    potential.
