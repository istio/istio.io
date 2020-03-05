---
title: Enable Istio on productpage
overview: Deploy the Istio control plane and enable Istio on a single microservice.

weight: 60

---

As you saw in the previous module, Istio enhances Kubernetes by giving you the
functionality to more effectively operate your microservices.

In this module you enable Istio on a single microservice, `productpage`. The
rest of the application will continue to operate as before. Note that you
can enable Istio gradually, microservice by microservice. Istio is enabled
transparently to the microservices. You do not change the microservices code or
disrupt your application, it continues to run and serve user requests.

1.  Disable mutual TLS authentication in your namespace, which will be explained later in the tutorial:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: Policy
    metadata:
      name: default
    spec:
      peers: []
    EOF
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/destination-rule-all.yaml
    {{< /text >}}

1.  Redeploy the `productpage` microservice, Istio-enabled:

    {{< tip >}}
    This tutorial step demonstrates manual sidecar injection to enable Istio for instructional purposes,
    however [Automatic sidecar injection](/docs/ops/configuration/mesh/injection-concepts/) is more convenient.
    {{< /tip >}}

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | sed 's/replicas: 1/replicas: 3/g' | kubectl apply -l app=productpage,version=v1 -f -
    deployment "productpage-v1" configured
    {{< /text >}}

1.  Access the application's webpage and verify that the application continues
    to work. Istio was added without changing the code of the
    original application.

1.  Check the the `productpage`'s pods and see that now each replica has two
    containers. The first container is the microservice itself and the second one
    is the sidecar proxy attached to it:

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
    reviews-v2-56f6855586-cnrjp       1/1       Running   0          7h
    reviews-v2-56f6855586-lxc49       1/1       Running   0          7h
    reviews-v2-56f6855586-qh84k       1/1       Running   0          7h
    sleep-88ddbcfdd-cc85s             1/1       Running   0          7h
    {{< /text >}}

1.  Kubernetes replaced the original pods of `productpage` with the
    Istio-enabled pods, transparently and incrementally, performing a
    [rolling update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update-intro/).
    Kubernetes terminated an old pod only when a new pod started to run, and it
    transparently switched the traffic to the new pods, one by one. That is, it did not
    terminate more than one pod before it stated a new pod. All this was done to prevent
    disruption of your application, so it continued to work during the injection of Istio.

1.  Check the logs of the Istio sidecar of `productpage`:

    {{< text bash >}}
    $ kubectl logs -l app=productpage -c istio-proxy | grep GET
    ...
    [2019-02-15T09:06:04.079Z] "GET /details/0 HTTP/1.1" 200 - 0 178 5 3 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "details:9080" "172.30.230.51:9080" outbound|9080||details.tutorial.svc.cluster.local - 172.21.109.216:9080 172.30.146.104:58698 -
    [2019-02-15T09:06:04.088Z] "GET /reviews/0 HTTP/1.1" 200 - 0 379 22 22 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "reviews:9080" "172.30.230.27:9080" outbound|9080||reviews.tutorial.svc.cluster.local - 172.21.185.48:9080 172.30.146.104:41442 -
    [2019-02-15T09:06:04.053Z] "GET /productpage HTTP/1.1" 200 - 0 5723 90 83 "10.127.220.66" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "tutorial.bookinfo.com" "127.0.0.1:9080" inbound|9080|http|productpage.tutorial.svc.cluster.local - 172.30.146.104:9080 10.127.220.66:0 -
    {{< /text >}}

1.  Output the name of your namespace. You will need it to recognize your
    microservices in the Istio dashboard:

    {{< text bash >}}
    $ echo $(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    tutorial
    {{< /text >}}

1.  Check the Istio dashboard, using the custom URL you set in your `/etc/hosts` file
    [previously](/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)):

    {{< text plain >}}
    http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard
    {{< /text >}}

    In the top left drop-down menu, select _Istio Mesh Dashboard_.

    {{< image width="80%"
        link="dashboard-select-dashboard.png"
        caption="Select Istio Mesh Dashboard from the top left drop-down menu"
        >}}

    Notice the `productpage` service from your namespace, it's name should be
    `productpage.<your namespace>.svc.cluster.local`.

    {{< image width="80%"
        link="dashboard-mesh.png"
        caption="Istio Mesh Dashboard"
        >}}

1.  In the _Istio Mesh Dashboard_, under the `Service` column, click the `productpage` service.

    {{< image width="80%"
        link="dashboard-service-select-productpage.png"
        caption="Istio Service Dashboard, `productpage` selected"
        >}}

    Scroll down to the _Service Workloads_ section. Observe that the
    dashboard graphs are updated.

    {{< image width="80%"
        link="dashboard-service.png"
        caption="Istio Service Dashboard"
        >}}

This is the immediate benefit of applying Istio on a single microservice. You
receive logs of traffic to and from the microservice, including time, HTTP
method, path, and response code. You can monitor your microservice using the
Istio dashboard.

In the next modules, you will learn about the functionality Istio can provide to
your applications. While some Istio functionality is beneficial when applied to
a single microservice, you will learn how to apply Istio on the whole
application to realize its full potential.

You are ready to
[enable Istio on all the microservices](/docs/examples/microservices-istio/enable-istio-all-microservices).
