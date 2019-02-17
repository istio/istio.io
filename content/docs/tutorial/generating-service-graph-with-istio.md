---
title: A service graph with Istio
overview: Enable service graph generation.

weight: 160

---
Istio arrives out-of-the-box with another tool for visualizing traffic, _ServiceGraph_.

1.  Access your application's webpage several times.

1.  Access ServiceGraph at [http://my-istio-servicegraph.io/dotviz](http://my-istio-servicegraph.io/dotviz).
    (The `my-istio-logs-servicegraph.io` URL should be in your /etc/hosts file, you set it
    [previously](/docs/tutorial/run-bookinfo-with-kubernetes/#update-your-etc-hosts-file)).

    {{< image width="80%"
        link="images/servicegraph.png"
        caption="ServiceGraph"
        >}}

    You can see the graph of your microservices together with the Istio components, `istio-pilot`, `istio-telemetry`,
    `istio-policy`. On the arcs appear the rates of requests sent between microservices, and between microservices and
    Istio components.

There are other tools for visualizing Istio service mesh, for example [Kiali](https://www.kiali.io).
