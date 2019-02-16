---
title: Enable Mutual TLS Authentication
overview: Enable Mutual TLS Authentication on the traffic between microservices
weight: 75

---

In your current setting, microservices communicate one with another by HTTP. The traffic is not encrypted and if your
cluster is compromised, the attackers can eavesdrop on the traffic. You may want to prevent this. In addition, in some
environments, there are regulations that require that all the traffic inside the cluster must be encrypted.

Here Istio comes to your rescue, by encrypting the traffic between the sidecars. The traffic is unencrypted only inside
the application pods, between the microservices and the sidecars, but leaves the pods encrypted.

In this module you enable [mutual TLS authentication](/help/glossary#mutual-tls-authentication) of Istio on the traffic between
microservices in your namespace.

1.  First, check that your microservices accept unencrypted traffic. Send an HTTP request to `ratings` from your testing
    pod, `sleep`:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl http://ratings:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

1.  Enable mutual TLS authentication in your namespace. Note, however, that you cannot enable mutual TLS authentication
    on the incoming traffic into _productpage_, since the incoming traffic arrives from Kubernetes Ingress which is
    unaware of the mutual TLS authentication of Istio.
    If you want to enable mutual TLS and other Istio features on the incoming traffic into your frontend microservices,
    you should [configure Istio Ingress Gateway](/docs/tasks/traffic-management/ingress/) (out of scope of this
    tutorial).

    So, you disable mutual TLS authentication on the traffic to your frontend microservice,
    _productpage_, and enable it on the rest of your microservices in your namespace:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: authentication.istio.io/v1alpha1
    kind: Policy
    metadata:
      name: disable-mtls-for-productpage
    spec:
      targets:
      - name: productpage
      peers:
    ---
    apiVersion: authentication.istio.io/v1alpha1
    kind: Policy
    metadata:
      name: default
    spec:
      peers:
      - mtls: {}
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: default
    spec:
      host: "*.local"
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}

1.  Access your application's web page and verify that everything continued to work as expected.

1.  Verify that your microservices do not accept unencrypted traffic anymore. Send an HTTP request to `ratings` from
    your testing pod, `sleep`:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl http://ratings:9080/ratings/7
    curl: (56) Recv failure: Connection reset by peer
    command terminated with exit code 56
    {{< /text >}}

    The last command failed as expected because your testing pod has no Istio sidecar and it sent unencrypted HTTP
    request to your service that requires mutual TLS Authentication. Now you can communicate with
    your microservices, except from the frontend microservice, only from pods with Istio sidecars injected and only if
    the traffic is encrypted by the sidecar.

1.  Inject an Istio sidecar into your testing pod:

    {{< text bash >}}
    $ curl -s https://raw.githubusercontent.com/istio/istio/master/samples/sleep/sleep.yaml | istioctl kube-inject -f - | kubectl apply -f -
    serviceaccount "sleep" unchanged
    service "sleep" unchanged
    deployment "sleep" configured
    {{< /text >}}

1.  Check the sleep pod and see that now it has two containers. Wait for the old pods to terminate:

    {{< text bash >}}
    $ kubectl get pods -l app=sleep
    NAME                    READY     STATUS    RESTARTS   AGE
    sleep-ccb8594c9-8pmz5   2/2       Running   0          2m
    {{< /text >}}

1.  Resend the request to _ratings_ from your testing pod:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl http://ratings:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

    This time the request succeeds, since your testing pod now has an Istio sidecar that encrypts outgoing traffic for it.

Note that you made all the traffic between the pods in your cluster encrypted, transparently to your microservice, that
is you changed neither code nor configuration of your microservices.
