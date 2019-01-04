---
title: Enable Istio on productpage
overview: Deploy the Istio control plane and enable Istio on a single microservice.

order: 06

layout: docs
type: markdown
---

As we saw in the previous module, Kubernetes does not provide us all the functionality we need to effectively operate our microservices. Istio comes to our help.

First we deploy the _Istio control plane_. Then we enable Istio on a single microservice, _productpage_. The rest of the application will continue to operate as previously. Note that we can enable Istio gradually, microservice by microservice. Also note that Istio is enabled transparently to the microservices, we do not change the microservices code. And also note that we enable Istio without disrupting our application, it continues to run and serve user requests.

We use the `istiocl kube-inject` command to inject Istio _sidecar proxies_ into the microservice pods.

1. Install Istio
   ```bash
   kubectl apply -f install/kubernetes/istio.yaml
   ```
1. Verify that Istio started correctly, all the pods in `istio-system` namespace are running.
   ```bash
   kubectl get pods -n istio-system
   ```
1. Redeploy the _productpage_ microservice, Istio-enabled
   ```bash
   kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/istio.io-tutorial/bookinfo-productpage.yaml)
   ```

1. Access the application and verify that the application continues to work. Note that Istio was added **transparently**, the code of the original application did not change.

2. Check the the _productpage_'s pods and see that now each replica has two containers. The first container is the microservice itself, the second is the sidecar proxy attached to it:
  ```bash
  kubectl get pods
  ```

3. Note that Kubernetes replaced the original pods of _productpage_ with the Istio-enabled pods, transparently and incrementally, performing what is called a [rolling update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update-intro/). Kubernetes terminated an old pod only when a new pod started to run, and it transparently switched the traffic to the new pods, one by one. (To be more precise, it did not terminate more than one pod before a new pod was started.) All this was done to prevent disruption of our application, so it continued to work during the injection of Istio.

