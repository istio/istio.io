---
title: Run Bookinfo with Kubernetes
overview: Deploy the Bookinfo application that uses the ratings microservice in Kubernetes.

weight: 30

---

This module shows you an application composed of four microservices: `productpage`, `details`, `ratings` and `reviews`.
The application is called `Bookinfo`, it is described in the [Bookinfo example](/docs/examples/bookinfo).
Read [the description of the application](/docs/examples/bookinfo),
consider the described application there as the final version, in which the `reviews` microservice has three versions
_v1_, _v2_, _v3_.

In this module you start with the application which has the first version of the `reviews` microservice, _v1_.
In the next modules, you will evolve the application.

## Deploy the application and a testing pod

1.  Skim [`bookinfo.yaml`]({{< github_blob >}}/samples/bookinfo/platform/kube/bookinfo.yaml).
    This is the Kubernetes deployment spec of the app. Notice the services and the deployments.

1.  Deploy the application to Kubernetes:

    {{< text bash >}}
    $ kubectl apply -l version!=v2,version!=v3 -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
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
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-q8rrf     1/1     Running   0          10s
    productpage-v1-c9965499-tjdjx   1/1     Running   0          8s
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          9s
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          9s
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
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   0          50s
    details-v1-6d86fd9949-mksv7     1/1     Running   0          50s
    details-v1-6d86fd9949-q8rrf     1/1     Running   0          1m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          50s
    productpage-v1-c9965499-nccwq   1/1     Running   0          50s
    productpage-v1-c9965499-tjdjx   1/1     Running   0          1m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          50s
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          50s
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          1m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          49s
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          1m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          49s
    {{< /text >}}

1.  Deploy a testing pod, [sleep]({{< github_tree >}}/samples/sleep), to use it for sending
    requests to your microservices:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
    {{< /text >}}

1.  To confirm that the Bookinfo application is running, send a request to it by a curl command from your testing pod:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Enable external access to the application

Once your application is running, enable external (by clients from outside of the cluster) access to it. Once you
configure the steps below successfully, you will be able to access the application by browser from your laptop.

### Configure Ingress and access your application's webpage

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

### Update your /etc/hosts file

1.  Append the output of the following command to `/etc/hosts`. You should have a
    [Superuser](https://en.wikipedia.org/wiki/Superuser) privilege and probably use the
    [`sudo`](https://en.wikipedia.org/wiki/Sudo) command for it.

    {{< text bash >}}
    $ echo $(kubectl get ingress istio-system -n istio-system -o jsonpath='{..ip} {..host}') $(kubectl get ingress bookinfo -o jsonpath='{..host}')
    {{< /text >}}

### Access your application

1.  Access the application's home page from the command line:

    {{< text bash >}}
    $ curl -s $MYHOST/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

1.  Paste the output of the following command in your browser address bar:

    {{< text bash >}}
    $ echo http://$MYHOST/productpage
    {{< /text >}}

    You should see the following webpage:

    {{< image width="80%"
        link="images/bookinfo.png"
        caption="Bookinfo Web Application"
        >}}

1.  Observe how microservices call each other, for example, `reviews` calls the `ratings` microservice by the
    `http://ratings:9080/ratings` URL.
    See the [code of `reviews`]({{< github_blob >}}/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java):

    {{< text java >}}
    private final static String ratings_service = "http://ratings:9080/ratings";
    {{< /text >}}

1.  Set an infinite loop in a separate terminal window to send traffic to your application. It will simulate the
    constant user traffic in the real world:

    {{< text bash >}}
    $ while :; do curl -s $MYHOST/productpage | grep -o "<title>.*</title>"; sleep 1; done
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    ...
    {{< /text >}}
