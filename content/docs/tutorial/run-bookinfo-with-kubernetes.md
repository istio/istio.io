---
title: Run Bookinfo with Kubernetes
overview: Deploy the Bookinfo application that uses the ratings microservice in Kubernetes.

weight: 30

---

This module shows you an application composed of four microservices: _productpage_, _details_, _ratings_ and _reviews_.
The application is called [Bookinfo](/docs/examples/bookinfo). Consider the application there as the final version, in
which the _reviews_ microservice has three versions _v1_, _v2, _v3_. In this module we start with the application with
the first version of the _reviews_ microservice, _v1_. In the next modules, we will evolve the application.

## Deploy the application and a testing pod

1.  Skim [bookinfo.yaml](https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/platform/kube/bookinfo.yaml).
    This is the Kubernetes deployment spec of the app. Notice the services and the deployments.

1.  Deploy the application to Kubernetes:

    {{< text bash >}}
    $ kubectl apply -l version!=v2,version!=v3 -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/platform/kube/bookinfo.yaml
    service "details" created
    deployment "details-v1" created
    service "ratings" created
    deployment "ratings-v1" created
    service "reviews" created
    deployment "reviews-v1" created
    service "productpage" created
    deployment "productpage-v1" created
    {{< /text >}}

1.  Check the pods status:

    {{< text bash >}}
    $ kubectl get pods
    {{< /text >}}

1.  Scale the deployments: let each version of each microservice run in three pods.

    {{< text bash >}}
    $ kubectl scale deployments --all --replicas 3
    deployment "details-v1" scaled
    deployment "productpage-v1" scaled
    deployment "ratings-v1" scaled
    deployment "reviews-v1" scaled
    deployment "reviews-v2" scaled
    deployment "reviews-v3" scaled
    {{< /text >}}

1.  Check the pods status. Notice that each microservice has three pods:

    {{< text bash >}}
    $ kubectl get pods
    {{< /text >}}

1.  Deploy a testing pod, [sleep](https://github.com/istio/istio/tree/master/samples/sleep), to use it for sending
  requests to our microservices:

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/sleep/sleep.yaml
    {{< /text >}}

1.  To confirm that the Bookinfo application is running, send a request to it by a curl command from your testing pod:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Enable external access to the application

Once your application is running, enable external (by clients from outside of the cluster) access to it. Once you
configure the steps below successfully, you will be able to access the application by browser from your laptop.

1.  Set `MYHOST` variable to hold the URL of the application:

    {{< text bash >}}
    $ export MYHOST=$(kubectl config view -o jsonpath={.contexts..namespace}).bookinfo.com
    {{< /text >}}

1.  Create Kubernetes Ingress:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: bookinfo
    spec:
      rules:
      - host: $MYHOST
        http:
          paths:
          - path: /productpage
            backend:
              serviceName: productpage
              servicePort: 9080
          - path: /login
            backend:
              serviceName: productpage
              servicePort: 9080
          - path: /logout
            backend:
              serviceName: productpage
              servicePort: 9080
    EOF
    {{< /text >}}

1.  Append the output of the following command to `/etc/hosts`:

    {{< text bash >}}
    $ echo $(kubectl get ingress istio-system -n istio-system -o jsonpath='{..ip} {..host}') $(kubectl get ingress bookinfo -o jsonpath='{..host}')
    {{< /text >}}

1.  Access the application home page from the command line:

    {{< text bash >}}
    $ curl -s $MYHOST/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

1.  Paste the output of the following command in your browser address bar:

    {{< text bash >}}
    $ echo http://$MYHOST/productpage
    {{< /text >}}

1.  Observe how microservices call each other, for example, _reviews_ calls the _ratings_ microservice by the URL `http://ratings:9080/ratings`. See the [code of _reviews_](https://github.com/istio/istio/blob/master/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java):

    {{< text java >}}
    private final static String ratings_service = "http://ratings:9080/ratings";
    {{< /text >}}
