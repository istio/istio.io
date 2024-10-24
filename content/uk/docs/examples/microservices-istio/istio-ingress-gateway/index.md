---
title: Налаштування Istio Ingress Gateway
overview: Контролюйте трафік, починаючи з Ingress.
weight: 71
owner: istio/wg-docs-maintainers
test: no
---

До цього часу ви використовували Kubernetes Ingress для доступу до вашого застосунку ззовні. У цьому модулі ви налаштуєте трафік для входу через Istio ingress gateway, щоб застосувати контроль Istio до трафіку до ваших мікросервісів.

1.  Збережіть назву вашого простору імен у змінній середовища `NAMESPACE`. Вам знадобиться це для розпізнавання ваших мікросервісів в журналах:

    {{< text bash >}}
    $ export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    $ echo $NAMESPACE
    tutorial
    {{< /text >}}

1.  Створіть змінну середовища для назви хосту Istio ingress gateway:

    {{< text bash >}}
    $ export MY_INGRESS_GATEWAY_HOST=istio.$NAMESPACE.bookinfo.com
    $ echo $MY_INGRESS_GATEWAY_HOST
    istio.tutorial.bookinfo.com
    {{< /text >}}

1.  Налаштуйте Istio ingress gateway:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: Gateway
    metadata:
      name: bookinfo-gateway
    spec:
      selector:
        istio: ingressgateway # використовуйте стандартну реалізацію шлюзу Istio
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

1.  Встановіть `INGRESS_HOST` і `INGRESS_PORT`, використовуючи інструкції з розділу [Визначення IP та портів Ingress](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports).

1.  Додайте результат цієї команди у ваш файл `/etc/hosts`:

    {{< text bash >}}
    $ echo $INGRESS_HOST $MY_INGRESS_GATEWAY_HOST
    {{< /text >}}

1.  Отримайте доступ до домашньої сторінки застосунку з командного рядка:

    {{< text bash >}}
    $ curl -s $MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

1.  Вставте результат наступної команди в адресний рядок вашого оглядача:

    {{< text bash >}}
    $ echo http://$MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage
    {{< /text >}}

1.  Імітуйте реальний трафік користувачів до вашого застосунку, встановивши нескінченний
    цикл у новому вікні термінала:

    {{< text bash >}}
    $ while :; do curl -s <output of the previous command> | grep -o "<title>.*</title>"; sleep 1; done
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    ...
    {{< /text >}}

1.  Перевірте графік вашого простору імен у консолі Kiali `my-kiali.io/kiali/console`. (URL `my-kiali.io` має бути у вашому файлі `/etc/hosts`, який ви налаштували [раніше](/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)).

    Тепер ви можете бачити, що трафік надходить з двох джерел, `unknown` (Kubernetes Ingress) і `istio-ingressgateway istio-system` (Istio Ingress Gateway).

    {{< image width="80%"
        link="kiali-ingress-gateway.png"
        caption="Вкладка Kiali Graph з Istio Ingress Gateway"
        >}}

1.  На цьому етапі ви можете припинити надсилати запити через Kubernetes Ingress і використовувати тільки Istio Ingress Gateway. Припиніть нескінченний цикл (`Ctrl-C` у вікні термінала), який ви встановили на попередніх кроках. У реальному виробничому середовищі вам потрібно оновити DNS-запис вашого застосунку, щоб він містив IP Istio ingress gateway, або налаштувати ваш зовнішній балансувальник навантаження.

1.  Видаліть ресурс Kubernetes Ingress:

    {{< text bash >}}
    $ kubectl delete ingress bookinfo
    ingress.extensions "bookinfo" deleted
    {{< /text >}}

1.  У новому вікні термінала перезапустіть імітацію реального трафіку користувачів, як описано в попередніх кроках.

1.  Перевірте ваш графік у консолі Kiali. Через хвилину ви побачите Istio Ingress Gateway як єдине джерело трафіку для вашого застосунку.

    {{< image width="80%"
        link="kiali-ingress-gateway-only.png"
        caption="Вкладка Kiali Graph з Istio Ingress Gateway як єдине джерело трафіку"
        >}}

Ви готові до [налаштування логування з Istio](/docs/examples/microservices-istio/logs-istio).
