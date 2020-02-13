---
title: Enable mutual TLS Authentication with Istio
overview: Enable Mutual TLS Authentication on the traffic between microservices
weight: 75

---

In your current configuration, microservices communicate using HTTP, which means the traffic
is not encrypted.

Istio helps solve this problem by encrypting the traffic between the
sidecars. This leaves only the traffic inside the application pods, and traffic
between microservices and sidecars unencrypted.

In this module, you enable Istio
[mutual TLS authentication](/docs/reference/glossary#mutual-tls-authentication)
for the traffic between microservices in your namespace.

1.  First, check that your microservices accept unencrypted traffic. Send an
    HTTP request to `ratings` from your testing pod, `sleep`:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl http://ratings:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

1.  Enable mutual TLS authentication in your namespace:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: authentication.istio.io/v1alpha1
    kind: Policy
    metadata:
      name: default
    spec:
      peers:
      - mtls: {}
    EOF
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml
    {{< /text >}}

    {{< warning >}}
    In case you did not enable the Istio Ingress Gateway, run the following command, in addition to the command above.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: authentication.istio.io/v1alpha1
    kind: Policy
    metadata:
      name: disable-mtls-productpage
    spec:
      targets:
      - name: productpage
      peers: []
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: productpage
    spec:
      host: productpage
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

1.  Access your application's web page to verify that everything continues to work as expected. Recall that you
    recently changed the URL of the application, e.g. `http://istio.tutorial.bookinfo.com/productpage`).

1.  Verify that your microservices do not accept unencrypted traffic anymore.
    Send an HTTP request to `ratings` from your testing pod, `sleep`:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl http://ratings:9080/ratings/7
    curl: (56) Recv failure: Connection reset by peer
    command terminated with exit code 56
    {{< /text >}}

    The last command failed as expected because your testing pod has no Istio
    sidecar and it sent an unencrypted HTTP request to your service that requires
    mutual TLS Authentication. Now communication is limited between services
    where Istio sidecars are injected and only if the traffic is encrypted by the sidecar.

1.  Access the Istio dashboard at
    [http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard](http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard). Check `ratings` in _Istio Service Dashboard_. Notice that now a lock icon with text `mTLS` appears in
    _Service Workload_.

    {{< image width="80%"
        link="dashboard-ratings-mtls.png"
        caption="Istio Service Dashboard"
        >}}

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    In the _Display_ drop-down menu mark the _Security_ check box to see locks
    that designate mutual TLS on the graph's edges.

    {{< tip >}}
    You might zoom in to the graph view to see the lock icons clearly.
    {{< /tip >}}

    {{< image width="80%"
        link="kiali-mtls.png"
        caption="Kiali Graph Tab with mutual TLS"
        >}}

Note that you made all the traffic between the pods in your cluster encrypted,
transparently to your microservice, while changing neither code nor
configuration of your microservices.
