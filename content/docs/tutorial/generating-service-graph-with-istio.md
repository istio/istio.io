---
title: A service graph with Istio
overview: Enable service graph generation.

weight: 160

---
In this module, we will add service graph generation on top of Prometheus.

1.  Deploy a service graph generation instance:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/addons/servicegraph.yaml
    {{< /text >}}

1.  Check the pods at `istio-system` namespace and wait for the Servicegraph's pod to start running:

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    {{< /text >}}

1.  Perform port forwarding from the service graph generation instance to the local machine:

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 &
    {{< /text >}}

3. Access the generated service graph on the local machine:  [http://localhost:8088/dotviz](http://localhost:8088/dotviz)
