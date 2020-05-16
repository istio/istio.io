---
title: Configure Istio Ingress Gateway
overview: Control traffic starting from Ingress.
weight: 71

---

Until now, you used a Kubernetes Ingress to access your application from the
outside. In this module, you configure the traffic to enter through an Istio
ingress gateway, in order to apply Istio control on traffic to your microservices.

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

1.  Configure an Istio ingress gateway:

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

1.  Set `INGRESS_HOST` and `INGRESS_PORT` using the instructions in the
    [Determining the Ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) section.

1.  Add the output of this command to your `/etc/hosts` file:

    {{< text bash >}}
    $ echo $INGRESS_HOST $MY_INGRESS_GATEWAY_HOST
    {{< /text >}}

1.  Access the application's home page from the command line:

    {{< text bash >}}
    $ curl -s $MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

1.  Paste the output of the following command in your browser address bar:

    {{< text bash >}}
    $ echo http://$MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage
    {{< /text >}}

1.  Simulate real-world user traffic to your application by setting an infinite
    loop in a new terminal window:

    {{< text bash >}}
    $ while :; do curl -s <output of the previous command> | grep -o "<title>.*</title>"; sleep 1; done
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    ...
    {{< /text >}}

1.  Check the graph of your namespace in the Kiali console
    `my-kiali.io/kiali/console`.
    (The `my-kiali.io` URL should be in your `/etc/hosts` file that you set
    [previously](/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)).

    This time, you can see that traffic arrives from two sources, `unknown` (the
    Kubernetes Ingress) and from `istio-ingressgateway istio-system` (the Istio
    Ingress Gateway).

    {{< image width="80%"
        link="kiali-ingress-gateway.png"
        caption="Kiali Graph Tab with Istio Ingress Gateway"
        >}}

1.  At this point you can stop sending requests through the Kubernetes Ingress
    and use Istio Ingress Gateway only. Stop the infinite loop (`Ctrl-C` in the
    terminal window) you set in the previous steps.
    In a real production environment, you would update the DNS entry of your
    application to contain the IP of Istio ingress gateway or configure your
    external Load Balancer.

1.  Delete the Kubernetes Ingress resource:

    {{< text bash >}}
    $ kubectl delete ingress bookinfo
    ingress.extensions "bookinfo" deleted
    {{< /text >}}

1.  In a new terminal window, restart the real-world user traffic simulation as described in the previous steps.

1.  Check your graph in the Kiali console. After about a minute, you will see
    the Istio Ingress Gateway as a single source of traffic for your
    application.

    {{< image width="80%"
        link="kiali-ingress-gateway-only.png"
        caption="Kiali Graph Tab with Istio Ingress Gateway as a single source of traffic"
        >}}

You are ready to configure [logging with Istio](/docs/examples/microservices-istio/logs-istio).
