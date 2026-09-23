---
title: Configurar Istio Ingress Gateway
overview: Controlar el tráfico que comienza desde Ingress.
weight: 71

owner: istio/wg-docs-maintainers
test: no
---

Hasta ahora, has usado un Kubernetes Ingress para acceder a tu aplicación desde el
exterior. En este módulo, configuras el tráfico para que ingrese a través de un Istio
ingress gateway, para aplicar control de Istio en el tráfico hacia tus microservicios.

1.  Almacena el nombre de tu namespace en la variable de entorno `NAMESPACE`.
    La necesitarás para reconocer tus microservicios en los logs:

    {{< text bash >}}
    $ export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    $ echo $NAMESPACE
    tutorial
    {{< /text >}}

1.  Crea una variable de entorno para el hostname del Istio ingress gateway:

    {{< text bash >}}
    $ export MY_INGRESS_GATEWAY_HOST=istio.$NAMESPACE.bookinfo.com
    $ echo $MY_INGRESS_GATEWAY_HOST
    istio.tutorial.bookinfo.com
    {{< /text >}}

1.  Configura un Istio ingress gateway:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
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
    apiVersion: networking.istio.io/v1
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

1.  Establece `INGRESS_HOST` e `INGRESS_PORT` usando las instrucciones en la
    sección [Determinando la IP y puertos de Ingress](/es/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports).

1.  Agrega la salida de este comando a tu archivo `/etc/hosts`:

    {{< text bash >}}
    $ echo $INGRESS_HOST $MY_INGRESS_GATEWAY_HOST
    {{< /text >}}

1.  Accede a la página principal de la aplicación desde la línea de comandos:

    {{< text bash >}}
    $ curl -s $MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

1.  Pega la salida del siguiente comando en la barra de direcciones de tu navegador:

    {{< text bash >}}
    $ echo http://$MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage
    {{< /text >}}

1.  Simula tráfico de usuario del mundo real hacia tu aplicación estableciendo un
    bucle infinito en una nueva ventana de terminal:

    {{< text bash >}}
    $ while :; do curl -s <output of the previous command> | grep -o "<title>.*</title>"; sleep 1; done
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    ...
    {{< /text >}}

1.  Verifica el gráfico de tu namespace en la consola de Kiali
    `my-kiali.io/kiali/console`.
    (La URL `my-kiali.io` debería estar en tu archivo `/etc/hosts` que configuraste
    [anteriormente](/es/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)).

    Esta vez, puedes ver que el tráfico llega desde dos fuentes, `unknown` (el
    Kubernetes Ingress) y desde `istio-ingressgateway istio-system` (el Istio
    Ingress Gateway).

    {{< image width="80%"
        link="kiali-ingress-gateway.png"
        caption="Pestaña de Gráfico de Kiali con Istio Ingress Gateway"
        >}}

1.  En este punto puedes dejar de enviar solicitudes a través del Kubernetes Ingress
    y usar solo el Istio Ingress Gateway. Detén el bucle infinito (`Ctrl-C` en la
    ventana de terminal) que estableciste en los pasos anteriores.
    En un entorno de producción real, actualizarías la entrada DNS de tu
    aplicación para que contenga la IP del Istio ingress gateway o configurarías tu
    Load Balancer externo.

1.  Elimina el recurso Kubernetes Ingress:

    {{< text bash >}}
    $ kubectl delete ingress bookinfo
    ingress.extensions "bookinfo" deleted
    {{< /text >}}

1.  En una nueva ventana de terminal, reinicia la simulación de tráfico de usuario del mundo real como se describe en los pasos anteriores.

1.  Verifica tu gráfico en la consola de Kiali. Después de aproximadamente un minuto, verás
    el Istio Ingress Gateway como una sola fuente de tráfico para tu
    aplicación.

    {{< image width="80%"
        link="kiali-ingress-gateway-only.png"
        caption="Pestaña de Gráfico de Kiali con Istio Ingress Gateway como única fuente de tráfico"
        >}}

Estás listo para configurar [logging con Istio](/es/docs/examples/microservices-istio/logs-istio).
