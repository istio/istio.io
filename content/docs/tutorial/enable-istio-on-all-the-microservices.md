---
title: Enable Istio on all the microservices
overview: Enable Istio on our whole application and on the Ingress.
weight: 70

---

Previously we deployed the Istio control plane and enabled Istio on a single microservice, _productpage_. We can proceed to enable Istio on the microservices incrementally, one by one, to get the functionality provided by Istio for more and more microservices. For the purpose of this tutorial, we will just enable Istio on the remaining microservices in one stroke. We will also enable Istio on our pod that we use for testing.

1.  Redeploy the Bookinfo application, Istio-enabled. _productpage_ will not be redeployed since it already has Istio injected, its pods will not be changed.

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/istio.io-tutorial/bookinfo.yaml)
    {{< /text >}}

1.  Redeploy _reviews v2_, Istio-enabled:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/kube/bookinfo-reviews-v2.yaml)
    {{< /text >}}

1.  Redeploy the _sleep_ pod, Istio-enabled, for testing:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
    {{< /text >}}

1.  Redeploy Istio-enabled ingress. Note that it is written slightly differently than the ingress we used for Kubernetes without Istio. Istio-enabled ingress has the annotation `kubernetes.io/ingress.class: "istio"`, and it has no host defined. Check [Determining Ingress IP and Port]({{home}}/docs/guides/bookinfo.html#determining-the-ingress-ip-and-port) for instructions for your cloud.

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/istio.io-tutorial/ingress-for-istio.yaml)
    {{< /text >}}

    For _IBM Cloud Container Service_, use the following:

    1.  Get the host IP of the `istio-ingress` pod.

        {{< text bash >}}
        $ kubectl get po -l istio=ingress -n istio-system -o 'jsonpath={.items[0].status.hostIP}'
        {{< /text >}}

    1.  Get the public IP of the node on which `istio-ingress` runs:

        {{< text bash >}}
        $ bx cs workers <your cluster name> | grep <the host IP of istio-ingress>
        {{< /text >}}

    1.  Get the port of the `istio-ingress` service:

        {{< text bash >}}
        $ kubectl get svc istio-ingress -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}'
        {{< /text >}}

    1.  Use the public IP from the step _ii_ and the port from the step _iii_ to access the application.

1.  Access the application after determining Ingress IP and port. Note that Istio was added **transparently**, the original application did not change. It was added on the fly, without the need to undeploy and redeploy the whole application, without hurting the application's availability.

1.  Check the application pods and verify that now each pod has two containers. One container is the microservice itself, the other is the sidecar proxy attached to it:

    {{< text bash >}}
    $ kubectl get pods
    {{< /text >}}
