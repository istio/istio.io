---
title: Застосунок Bookinfo
description: Розгортає демонстраційних застосунок, що складається з чотирьох окремих мікросервісів, які використовуються для демонстрації різних можливостей Istio.
weight: 10
aliases:
    - /uk/docs/samples/bookinfo.html
    - /uk/docs/guides/bookinfo/index.html
    - /uk/docs/guides/bookinfo.html
owner: istio/wg-docs-maintainers
test: yes
---

Цей приклад розгортає демонстраційний застосунок, що складається з чотирьох окремих мікросервісів, які використовуються для демонстрації різних можливостей Istio.

{{< tip >}}
Якщо ви встановили Istio за допомогою [посібника Як розпочати](/docs/setup/getting-started/), у вас вже має бути встановлено Bookinfo, і ви можете пропустити більшість цих кроків та перейти безпосередньо до [Визначення версій сервісів](/docs/examples/bookinfo/#define-the-service-versions).
{{< /tip >}}

Застосунок показує інформацію про книги, схожу на один каталожний запис інтернет-магазину книг. На сторінці показується опис книги, деталі книги (ISBN, кількість сторінок і т.д.) та кілька відгуків про книгу.

Застосунок Bookinfo розбито на чотири окремі мікросервіси:

* `productpage`. Мікросервіс `productpage` викликає мікросервіси `details` та `reviews`, щоб заповнити сторінку.
* `details`. Мікросервіс `details` містить інформацію про книги.
* `reviews`. Мікросервіс `reviews` містить огляди книг і також викликає мікросервіс `ratings`.
* `ratings`. Мікросервіс `ratings` містить інформацію про рейтинги книг, яка супроводжує огляди.

Існує 3 версії мікросервісу `reviews`:

* Версія v1 не викликає сервіс `ratings`.
* Версія v2 викликає сервіс `ratings` і показує кожну оцінку у вигляді від 1 до 5 чорних зірок.
* Версія v3 викликає сервіс `ratings` і показує кожну оцінку у вигляді від 1 до 5 червоних зірок.

Архітектуру цього застосунку показано нижче.

{{< image width="80%" link="./noistio.svg" caption="Застосунок Bookinfo без Istio" >}}

Цей застосунок є поліглотом, тобто мікросервіси написані різними мовами програмування. Варто зазначити, що ці сервіси не мають залежностей від Istio, але становлять цікавий приклад для сервісної мережі, зокрема завдяки різноманіттю сервісів, мов та версій сервісу `reviews`.

## Перед тим, як почати {#before-you-begin}

Якщо ви ще цього не зробили, налаштуйте Istio, дотримуючись інструкцій з [керівництва з встановлення](/docs/setup/).

{{< boilerplate gateway-api-support >}}

## Розгортання застосунку {#deploying-the-application}

Щоб запустити приклад з Istio, не потрібно вносити жодних змін до самого застосунку. Замість цього потрібно просто налаштувати та запустити служби в середовищі, де активовано Istio, з інʼєкцією sidecar Envoy для кожної служби. Результат розгортання виглядатиме так:

{{< image width="80%" link="./withistio.svg" caption="Застосунок Bookinfo" >}}

Усі мікросервіси будуть упаковані з sidecar Envoy, який перехоплює вхідні та вихідні виклики для служб, забезпечуючи необхідні засоби для зовнішнього контролю через панель управління Istio, маршрутизації, збору телеметрії та впровадження політик для застосунку в цілому.

### Запуск сервісів застосунку {#start-the-application-services}

{{< tip >}}
Якщо ви використовуєте GKE, переконайтеся, що у вашому кластері є принаймні 4 стандартні вузли GKE. Якщо ви використовуєте Minikube, переконайтеся, що у вас є принаймні 4 ГБ оперативної памʼяті.
{{< /tip >}}

1. Перейдіть до кореневої теки встановлення Istio.

1. Стандартно встановлення Istio використовує [автоматичну інʼєкцію sidecar](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection). Додайте мітку до простору імен, де буде розміщено застосунок, з `istio-injection=enabled`:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

1. Розгорніть ваш застосунок за допомогою команди `kubectl`:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    {{< /text >}}

    Ця команда запускає всі чотири сервіси, показані на схемі архітектури застосунку `bookinfo`. Усі 3 версії сервісу reviews, v1, v2 та v3 будуть запущені.

    {{< tip >}}
    У реалістичному розгортанні нові версії мікросервісу розгортаються в міру їх створення, а не одночасно.
    {{< /tip >}}

1. Переконайтеся, що всі сервіси та podʼи правильно визначені та працюють:

    {{< text bash >}}
    $ kubectl get services
    NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
    details       ClusterIP   10.0.0.31    <none>        9080/TCP   6m
    kubernetes    ClusterIP   10.0.0.1     <none>        443/TCP    7d
    productpage   ClusterIP   10.0.0.120   <none>        9080/TCP   6m
    ratings       ClusterIP   10.0.0.15    <none>        9080/TCP   6m
    reviews       ClusterIP   10.0.0.170   <none>        9080/TCP   6m
    {{< /text >}}

    та

    {{< text bash >}}
    $ kubectl get pods
    NAME                             READY     STATUS    RESTARTS   AGE
    details-v1-1520924117-48z17      2/2       Running   0          6m
    productpage-v1-560495357-jk1lz   2/2       Running   0          6m
    ratings-v1-734492171-rnr5l       2/2       Running   0          6m
    reviews-v1-874083890-f0qf0       2/2       Running   0          6m
    reviews-v2-1343845940-b34q5      2/2       Running   0          6m
    reviews-v3-1813607990-8ch52      2/2       Running   0          6m
    {{< /text >}}

1. Щоб переконатися, що застосунок Bookinfo працює, надішліть запит до нього за допомогою команди `curl` з якогось podʼа, наприклад з `ratings`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

### Визначення IP та порту для ingress {#determine-the-ingress-ip-and-port}

Тепер, коли сервіси Bookinfo запущені, вам потрібно зробити застосунок доступним ззовні вашого кластера Kubernetes, наприклад, в оглядачі. Для цього використовується шлюз.

1. Створіть шлюз для застосунку Bookinfo:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    Створіть [Istio Gateway](/docs/concepts/traffic-management/#gateways) за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    gateway.networking.istio.io/bookinfo-gateway created
    virtualservice.networking.istio.io/bookinfo created
    {{< /text >}}

    Переконайтеся, що шлюз створено:

    {{< text bash >}}
    $ kubectl get gateway
    NAME               AGE
    bookinfo-gateway   32s
    {{< /text >}}

    Дотримуйтесь [цих інструкцій](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) для налаштування змінних `INGRESS_HOST` та `INGRESS_PORT` для доступу до шлюзу. Поверніться сюди, коли вони будуть налаштовані.

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< boilerplate external-loadbalancer-support >}}

    Створіть [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/) за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    gateway.gateway.networking.k8s.io/bookinfo-gateway created
    httproute.gateway.networking.k8s.io/bookinfo created
    {{< /text >}}

    Оскільки створення ресурсу `Gateway` Kubernetes також [розгорне повʼязаний проксі-сервіс](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment), виконайте наступну команду, щоб дочекатися готовності шлюзу:

    {{< text bash >}}
    $ kubectl wait --for=condition=programmed gtw bookinfo-gateway
    {{< /text >}}

    Отримайте адресу та порт шлюзу з ресурсу bookinfo gateway:

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.status.addresses[0].value}')
    $ export INGRESS_PORT=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Встановіть `GATEWAY_URL`:

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

## Переконайтеся, що застосунок доступний ззовні кластера {#confirm-the-app-is-accessible-from-outside-the-cluster}

Щоб підтвердити, що застосунок Bookinfo доступний ззовні кластера, виконайте наступну команду `curl`:

{{< text bash >}}
$ curl -s "http://${GATEWAY_URL}/productpage" | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

Ви також можете відкрити оглядач і перейти за посиланням `http://$GATEWAY_URL/productpage`, щоб переглянути вебсторінку Bookinfo. Якщо кілька разів оновити сторінку, ви побачите різні версії відгуків, що показуються на сторінці `productpage`, подані у стилі обходу по кругу (червоні зірки, чорні зірки, без зірок), оскільки ми ще не використовували Istio для контролю маршрутизації версій.

## Визначення версій сервісів {#define-the-service-versions}

Перед тим як використовувати Istio для контролю маршрутизації версій Bookinfo, необхідно визначити доступні версії.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Istio використовує *підмножини* у [правилах призначення](/docs/concepts/traffic-management/#destination-rules), щоб визначати версії сервісу. Виконайте наступну команду для створення стандартних правил призначення для сервісів Bookinfo:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
{{< /text >}}

{{< tip >}}
Профілі конфігурації `default` та `demo` (/docs/setup/additional-setup/config-profiles/) стандартно мають увімкнений режим [автоматичного взаємного TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls). Щоб примусово ввімкнути взаємний TLS, використовуйте правила призначення у `samples/bookinfo/networking/destination-rule-all-mtls.yaml`.
{{< /tip >}}

Зачекайте кілька секунд, поки правила призначення поширяться.

Ви можете переглянути правила призначення за допомогою наступної команди:

{{< text bash >}}
$ kubectl get destinationrules -o yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

На відміну від API Istio, який використовує підмножини `DestinationRule` для визначення версій сервісу, API Gateway Kubernetes використовує визначення бекенд-сервісів для цієї мети.

Виконайте наступну команду, щоб створити визначення бекенд-сервісів для трьох версій сервісу `reviews`:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-versions.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Що далі {#whats-next}

Тепер ви можете використовувати цей приклад для експериментів з можливостями Istio, такими як маршрутизація трафіку, інʼєкція збоїв, обмеження швидкості тощо. Щоб продовжити, зверніться до одного або кількох [Завдань Istio](/docs/tasks), залежно від ваших інтересів. [Налаштування маршрутизації запитів](/docs/tasks/traffic-management/request-routing/) є хорошим місцем для початку для новачків.

## Очищення {#cleanup}

Коли закінчите експериментувати з прикладом Bookinfo, видаліть його та виконайте очищення, використовуючи наступну команду:

{{< text bash >}}
$ @samples/bookinfo/platform/kube/cleanup.sh@
{{< /text >}}
