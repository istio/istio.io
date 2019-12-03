---
title: Configure Istio Ingress Gateway
overview: Control traffic starting from Ingress.
weight: 71

---

Until now you used a Kubernetes Ingress to access your application from the outside.
In this module you configure the traffic to enter through an Istio Ingress Gateway, in order to apply Istio
control already at the ingress point, even before the traffic reaches your microservices.

1.  Store the name of your namespace in the `NAMESPACE` environment variable.
    You will need it to recognize your microservices in the logs:

    {{< text bash >}}
    $ export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    $ echo $NAMESPACE
    tutorial
    {{< /text >}}

1.  Create an environment variable for the hostname of the Istio ingress gateway:

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
            prefix: /static
        route:
        - destination:
            host: productpage
            port:
              number: 9080
    EOF
    {{< /text >}}

1.  Follow the instructions in the
    [Istio Ingress Configuration task, Determining the Ingress IP and ports section](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
    to set `INGRESS_HOST` and `INGRESS_PORT`.

1.  Echo the line you will add to your `/etc/hosts` file:

    {{< text bash >}}
    $ echo $INGRESS_HOST $MY_INGRESS_GATEWAY_HOST
    {{< /text >}}

1.  Add the output of the previous command to your `/etc/hosts` file.

1.  Access the application's home page from the command line:

    {{< text bash >}}
    $ curl -s $MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

1.  Paste the output of the following command in your browser address bar:

    {{< text bash >}}
    $ echo http://$MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage
    {{< /text >}}

1.  Set an infinite loop in a separate terminal window to send traffic to your application. It will simulate the
    constant user traffic in the real world:

    {{< text bash >}}
    $ while :; do curl -s <output of the previous command> | grep -o "<title>.*</title>"; sleep 1; done
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

    This time you can see that the traffic arrives from two sources, `unknown` (the Kubernetes Ingress) and from
    `istio-ingressgateway istio-system` (the Istio Ingress Gateway).

    {{< image width="80%"
        link="kiali-ingress-gateway.png"
        caption="Kiali Graph Tab with Istio Ingress Gateway"
        >}}

1.  At this point you can stop sending requests through the Kubernetes Ingress and use Istio Ingress Gateway only.
    Stop the infinite loop (`Ctrl-C` in the terminal window) you set
    [previously](/docs/tutorial/run-bookinfo-with-kubernetes/#access-your-application).
    In the real life, that would mean updating the DNS entry of your application to contain the IP of Istio Ingress
    Gateway or configuring your external Load Balancer.

1.  Delete the Kubernetes Ingress resource:

    {{< text bash >}}
    $ kubectl delete ingress bookinfo
    ingress.extensions "bookinfo" deleted
    {{< /text >}}

1.  Check your graph at the Kiali console. After several seconds you will see the Istio Ingress Gateway as a single source
    of traffic for your application.

    {{< image width="80%"
        link="kiali-ingress-gateway-only.png"
        caption="Kiali Graph Tab with Istio Ingress Gateway as a single source of traffic"
        >}}
