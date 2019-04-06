---
title: Configure Istio Ingress Gateway
overview: Control traffic starting from Ingress.
weight: 71

---

Until now you operated the Kubernetes Ingress. Istio started to operate at your front-end microservice, `productpage`.
In this module you configure the traffic to enter through Istio Ingress Gateway, so you will be able to apply Istio
control already at the ingress point, even before the traffic arrives to your microservices.

1.  Store the name of your namespace in the `NAMESPACE` environment variable.
    You will need it to recognize your microservices in the logs:

    {{< text bash >}}
    $ export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    $ echo $NAMESPACE
    tutorial
    {{< /text >}}

1.  Create an environment variable for

    {{< text bash >}}
    $ export MY_INGRESS_GATEWAY_HOST=istio.$NAMESPACE.bookinfo.com
    $ echo $MY_INGRESS_GATEWAY_HOST
    istio.tutorial.bookinfo.com
    {{< /text >}}

1.  Configure an Istio Ingress Gateway:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: bookinfo-gateway
    spec:
      selector:
        istio: ingressgateway # use Istio default gateway implementation
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - $MY_INGRESS_GATEWAY_HOST
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: bookinfo
    spec:
      hosts:
      - $MY_INGRESS_GATEWAY_HOST
      gateways:
      - bookinfo-gateway.$NAMESPACE.svc.cluster.local
      http:
      - match:
        - uri:
            exact: /productpage
        - uri:
            exact: /login
        - uri:
            exact: /logout
        - uri:
            prefix: /api/v1/products
        route:
        - destination:
            host: productpage
            port:
              number: 9080
    EOF
    {{< /text >}}

1.  Follow the instructions in the
    [Istio Ingress Configuration task, Determining the Ingress IP and ports section](/docs/tasks/traffic-management/ingress/#determining-the-ingress-ip-and-ports) to set `INGRESS_HOST` and `INGRESS_PORT`.

1.  Echo the line you will add to your `/etc/hosts` file:

    {{< text bash >}}
    $ echo $INGRESS_HOST istio.$MYHOST
    {{< /text >}}

1.  Add the output of the previous command to your `/etc/hosts` file.

1.  Access the application's home page from the command line:

    {{< text bash >}}
    $ curl -s istio.$MYHOST:$INGRESS_PORT/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

1.  Paste the output of the following command in your browser address bar:

    {{< text bash >}}
    $ echo http://istio.$MYHOST:$INGRESS_PORT/productpage
    {{< /text >}}

1.  Set an infinite loop in a separate terminal window to send traffic to your application. It will simulate the
    constant user traffic in the real world:

    {{< text bash >}}
    $ while :; do curl -s istio.$MYHOST:$INGRESS_PORT/productpage | grep -o "<title>.*</title>"; sleep 1; done
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    ...
    {{< /text >}}

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.
    (The `my-kiali.io` URL should be in your /etc/hosts file, you set it
    [previously](/docs/tutorial/run-bookinfo-with-kubernetes/#update-your-etc-hosts-file)).

    This time you see that the traffic arrives from two sources, `unknown` (the Kubernetes Ingress) and from
    `istio-ingressgateway istio-system` (the Istio Ingress Gateway).

    {{< image width="80%"
        link="images/kiali-ingress-gateway.png"
        caption="Kiali Graph Tab with Istio Ingress Gateway"
        >}}

1.  At this point you can stop sending requests through the Kubernetes Ingress and use Istio Ingress Gateway only.
    In the real life, that would mean updating the DNS entry of your application to contain the IP of Istio Ingress
    Gateway or configuring your external Load Balancer.

1.  Delete the Kubernetes Ingress resource:

    {{< text bash >}}
    $ kubectl delete ingress bookinfo
    {{< /text >}}

1.  Check your graph at the Kiali console. After several seconds you will see the Istio Ingress Gateway as a single source
    of traffic for your application.

    {{< image width="80%"
        link="images/kiali-ingress-gateway-only.png"
        caption="Kiali Graph Tab with Istio Ingress Gateway as a single source of traffic"
        >}}
