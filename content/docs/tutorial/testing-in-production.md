---
title: Testing in production
overview: Testing a new version of a microservice in production.

weight: 40

---

Perform some testing of our microservice, in production!

## Testing individual microservices

1.  Issue an HTTP request from the testing pod to one of your services:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl http://ratings:9080/ratings/7
    {{< /text >}}

Exercise: test other microservices. For that, check in the
[source code](https://github.com/istio/istio/tree/master/samples/bookinfo/src) of the Bookinfo application how other microservices are called.

## Chaos testing

Let's do some [chaos testing](http://www.boyter.org/2016/07/chaos-testing-engineering/) in production and see how our application reacts. After each chaos operation, access the application home page and see if anything was
changed. Also check the pods' status with `kubectl get pods`.

1.  Terminate the _details_ service in one pod.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pods -l app=details -o jsonpath='{.items[0].metadata.name}') -- pkill ruby
    {{< /text >}}

1.  Terminate the _details_ service in all its pods:

    {{< text bash >}}
    $ for pod in $(kubectl get pods -l app=details -o jsonpath='{.items[*].metadata.name}'); do echo terminating $pod; kubectl exec -it $pod -- pkill ruby; done
    {{< /text >}}

Note that in both cases the application did not crash. The crash in the _details_ microservice did not cause other microservices to fail. It means we did not have a _cascading failure_ in this situation. On the contrary, we had _gradual service degradation_: despite one microservice being crashed, the application still provided useful functionality: displayed the reviews and the basic info about the book.

Exercise: terminate some other microservice. For that, get a shell into a container of a microservice and kill the
process of the microservice. Access the application home page and see how it is affected by microservice termination.
