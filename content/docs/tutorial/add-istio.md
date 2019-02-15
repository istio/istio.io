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

1.  Redeploy the _productpage_ microservice, Istio-enabled
    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/platform/kube/bookinfo.yaml)
    {{< /text >}}

1.  Access the application and verify that the application continues to work. Note that Istio was added
    **transparently**, the code of the original application did not change.

1.  Check the the _productpage_'s pods and see that now each replica has two containers.
    The first container is the microservice itself, the second is the sidecar proxy attached to it:

    {{< text bash >}}
    $ kubectl get pods
    {{< /text >}}

3. Note that Kubernetes replaced the original pods of _productpage_ with the Istio-enabled pods, transparently and incrementally, performing what is called a [rolling update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update-intro/). Kubernetes terminated an old pod only when a new pod started to run, and it transparently switched the traffic to the new pods, one by one. (To be more precise, it did not terminate more than one pod before a new pod was started.) All this was done to prevent disruption of our application, so it continued to work during the injection of Istio.
