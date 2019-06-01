---
title: Testing in production
overview: Testing a new version of a microservice in production.

weight: 40

---

Perform testing of your microservice, in production!

## Testing individual microservices

1.  Issue an HTTP request from the testing pod to one of your services:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl http://ratings:9080/ratings/7
    {{< /text >}}

**Exercise:** test other microservices. For that, check in the
[source code]({{< github_tree >}}/samples/bookinfo/src) of the Bookinfo application how other microservices are called.

## Chaos testing

Perform some [chaos testing](http://www.boyter.org/2016/07/chaos-testing-engineering/) in production and see how
your application reacts. After each chaos operation, access the application's webpage and see if anything was
changed. Also check the pods' status with `kubectl get pods`.

1.  Terminate the `details` service in one pod.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pods -l app=details -o jsonpath='{.items[0].metadata.name}') -- pkill ruby
    {{< /text >}}

1.  Check the pods status:

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   1          47m
    details-v1-6d86fd9949-mksv7     1/1     Running   0          47m
    details-v1-6d86fd9949-q8rrf     1/1     Running   0          48m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          47m
    productpage-v1-c9965499-nccwq   1/1     Running   0          47m
    productpage-v1-c9965499-tjdjx   1/1     Running   0          48m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          47m
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          47m
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          47m
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          47m
    sleep-88ddbcfdd-l9zq4           1/1     Running   0          47m
    {{< /text >}}

    Note that the first pod was restarted once.

1.  Terminate the `details` service in all its pods:

    {{< text bash >}}
    $ for pod in $(kubectl get pods -l app=details -o jsonpath='{.items[*].metadata.name}'); do echo terminating $pod; kubectl exec -it $pod -- pkill ruby; done
    {{< /text >}}

1.  Check the webpage of the application:

    {{< image width="80%"
        link="images/bookinfo-details-unavailable.png"
        caption="Bookinfo Web Application, details unavailable"
        >}}

    Note that the details section contains error messages instead of book details.

1.  Check the pods status:

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   2          48m
    details-v1-6d86fd9949-mksv7     1/1     Running   1          48m
    details-v1-6d86fd9949-q8rrf     1/1     Running   1          49m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          48m
    productpage-v1-c9965499-nccwq   1/1     Running   0          48m
    productpage-v1-c9965499-tjdjx   1/1     Running   0          48m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          48m
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          48m
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          49m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          49m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          48m
    sleep-88ddbcfdd-l9zq4           1/1     Running   0          48m
    {{< /text >}}

    Note that the first pod was restarted twice and two other `details` pods were restarted once. You may experience
    the `Error` and the `CrashLoopBackOff` statuses until the pods will start having `Running` status.

Note that in both cases the application did not crash. The crash in the `details` microservice did not cause other
microservices to fail. It means you did not have a _cascading failure_ in this situation. On the contrary,
you had _gradual service degradation_: despite one microservice being crashed, the application still provided useful
functionality: displayed the reviews and the basic info about the book.

**Exercise**: terminate some other microservice. For that, get a shell into a container of a microservice and kill the
process of the microservice. Access the application home page and see how it is affected by microservice termination.
