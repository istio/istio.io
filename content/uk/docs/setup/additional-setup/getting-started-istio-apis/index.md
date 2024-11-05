---
title: Початок роботи без API Gateway
description: Спробуйте можливості Istio за допомогою застарілих API Istio.
weight: 80
keywords: [getting-started, install, bookinfo, quick-start, kubernetes]
owner: istio/wg-environments-maintainers
test: yes
---

Цей посібник дозволить вам швидко оцінити Istio, використовуючи лише його застарілі API. Якщо ви хочете використовувати Kubernetes Gateway API, [будь ласка, перегляньте цей приклад](/docs/setup/getting-started/). Якщо ви вже знайомі з Istio або зацікавлені в установці інших профілів конфігурації чи розширених [моделей розгортання](/docs/ops/deployment/deployment-models/), зверніться до нашої сторінки ЧАстих питань — [який метод установки Istio мені слід використовувати?](/about/faq/#install-method-selection).

Ці кроки вимагають, щоб у вас був {{< gloss "кластер" >}}кластер{{< /gloss >}}, який запускає [підтримувану версію](/docs/releases/supported-releases#support-status-of-istio-releases) Kubernetes ({{< supported_kubernetes_versions >}}). Ви можете використовувати будь-яку підтримувану платформу, наприклад [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) або інші, зазначені в [інструкціях з налаштування платформи](/docs/setup/platform-setup/).

Виконайте ці кроки, щоб розпочати роботу з Istio:

1. [Завантажте та встановіть Istio](#download)
2. [Розгорніть приклад застосунку](#bookinfo)
3. [Надайте доступ до застосунку ззовні](#ip)
4. [Перегляньте інфопанель (дашборд)](#dashboard)

## Завантаження Istio {#download}

1. Перейдіть на сторінку [релізу Istio]({{< istio_release_url >}}), щоб завантажити файл встановлення для вашої ОС, або завантажте та розпакуйте останній реліз автоматично (Linux або macOS):

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

    {{< tip >}}
    Наведена вище команда завантажує останній (у числовому порядку) реліз Istio. Ви можете передати змінні через командний рядок, щоб завантажити конкретну версію або змінити архітектуру процесора. Наприклад, щоб завантажити Istio {{< istio_full_version >}} для архітектури x86_64,
    виконайте:

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_full_version >}} TARGET_ARCH=x86_64 sh -
    {{< /text >}}

    {{< /tip >}}

1. Перейдіть до теки з пакетом Istio. Наприклад, якщо пакет називається `istio-{{< istio_full_version >}}`:

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    Тека встановлення містить:

    - Прикладні застосунки у `samples/`
    - Клієнтський бінарний файл [`istioctl`](/docs/reference/commands/istioctl) у теці `bin/`.

2. Додайте файл `istioctl` до вашого шляху (Linux або macOS):

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## Встановлення Istio {#install}

1. Для цього встановлення ми використовуємо [профіль конфігурації](/docs/setup/additional-setup/config-profiles/) `demo`. Його обрано через наявність хорошого набору стандартних параметрів для тестування, але є інші профілі для операційного використання або тестування продуктивності.

    {{< warning >}}
    Якщо ваша платформа має специфічний для постачальника профіль конфігурації, наприклад Openshift, використовуйте його в наступній команді замість профілю `demo`. Зверніться до [інструкцій для вашої платформи](/docs/setup/platform-setup/) для деталей.
    {{< /warning >}}

    {{< text bash >}}
    $ istioctl install --set profile=demo -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Egress gateways installed
    ✔ Ingress gateways installed
    ✔ Installation complete
    {{< /text >}}

2. Додайте мітку до простору імен, щоб вказати Istio автоматично вставляти проксі Envoy при подальшому розгортанні вашого застосунку:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    namespace/default позначено
    {{< /text >}}

## Розгортання застосунку прикладу {#bookinfo}

1. Розгорніть [застосунок приклад `Bookinfo`](/docs/examples/bookinfo/):

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    service/details створено
    serviceaccount/bookinfo-details створено
    deployment.apps/details-v1 створено
    service/ratings створено
    serviceaccount/bookinfo-ratings створено
    deployment.apps/ratings-v1 створено
    service/reviews створено
    serviceaccount/bookinfo-reviews створено
    deployment.apps/reviews-v1 створено
    deployment.apps/reviews-v2 створено
    deployment.apps/reviews-v3 створено
    service/productpage створено
    serviceaccount/bookinfo-productpage створено
    deployment.apps/productpage-v1 створено
    {{< /text >}}

2. Застосунок буде запущено. Як тільки кожен pod стане готовим, разом з ним буде розгорнуто Istio sidecar.

    {{< text bash >}}
    $ kubectl get services
    NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    details       ClusterIP   10.0.0.212      <none>        9080/TCP   29s
    kubernetes    ClusterIP   10.0.0.1        <none>        443/TCP    25m
    productpage   ClusterIP   10.0.0.57       <none>        9080/TCP   28s
    ratings       ClusterIP   10.0.0.33       <none>        9080/TCP   29s
    reviews       ClusterIP   10.0.0.28       <none>        9080/TCP   29s
    {{< /text >}}

    та

    {{< text bash >}}
    $ kubectl get pods
    NAME                              READY   STATUS    RESTARTS   AGE
    details-v1-558b8b4b76-2llld       2/2     Running   0          2m41s
    productpage-v1-6987489c74-lpkgl   2/2     Running   0          2m40s
    ratings-v1-7dc98c7588-vzftc       2/2     Running   0          2m41s
    reviews-v1-7f99cc4496-gdxfn       2/2     Running   0          2m41s
    reviews-v2-7d79d5bd5d-8zzqd       2/2     Running   0          2m41s
    reviews-v3-7dbcdcbc56-m8dph       2/2     Running   0          2m41s
    {{< /text >}}

    {{< tip >}}
    Повторно виконайте попередню команду та дочекайтеся, поки всі podʼи не будуть у статусі READY `2/2`, а STATUS `Running`, перш ніж переходити до наступного кроку. Це може зайняти кілька хвилин залежно від вашої платформи.
    {{< /tip >}}

3. Переконайтеся, що все працює правильно на даному етапі. Виконайте цю команду, щоб перевірити, чи працює застосунок всередині кластера та чи він обслуговує HTML-сторінки, перевіривши заголовок сторінки у відповіді:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Відкриття доступу до застосунку ззовні {#ip}

Застосунок Bookinfo розгорнуто, але він недоступний ззовні. Щоб зробити його доступним, вам потрібно створити [Istio Ingress Gateway](/docs/concepts/traffic-management/#gateways), який зіставляє шлях з маршрутом на межі вашої мережі mesh.

1. Звʼяжіть цей застосунок з Istio gateway:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    gateway.networking.istio.io/bookinfo-gateway створено
    virtualservice.networking.istio.io/bookinfo створено
    {{< /text >}}

2. Переконайтеся, що конфігурація не має проблем:

    {{< text bash >}}
    $ istioctl analyze
    ✔ No validation issues found when analyzing namespace: default.
    {{< /text >}}

### Визначення IP-адреси та портів для Ingress {#determine-the-ingress-ip-and-ports}

Дотримуйтесь цих інструкцій, щоб встановити змінні `INGRESS_HOST` та `INGRESS_PORT` для доступу до шлюзу. Використовуйте вкладки для вибору інструкцій для вашої платформи:

{{< tabset category-name="gateway-ip" >}}

{{< tab name="Minikube" category-value="external-lb" >}}

Виконайте цю команду в новому вікні термінала, щоб запустити тунель Minikube, який спрямовує трафік до вашого Istio Ingress Gateway. Це забезпечить зовнішній балансувальник навантаження, `EXTERNAL-IP`, для `service/istio-ingressgateway`.

{{< text bash >}}
$ minikube tunnel
{{< /text >}}

Встановіть хост і порти для ingress:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

Переконайтеся, що IP-адреса і порти були успішно призначені кожній змінній середовища:

{{< text bash >}}
$ echo "$INGRESS_HOST"
127.0.0.1
{{< /text >}}

{{< text bash >}}
$ echo "$INGRESS_PORT"
80
{{< /text >}}

{{< text bash >}}
$ echo "$SECURE_INGRESS_PORT"
443
{{< /text >}}

{{< /tab >}}

{{< tab name="Інші платформи" category-value="node-port" >}}

Виконайте наступну команду, щоб визначити, чи ваш кластер Kubernetes працює в середовищі, яке підтримує зовнішні балансувальники навантаження:

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121  80:31380/TCP,443:31390/TCP,31400:31400/TCP   17h
{{< /text >}}

Якщо значення `EXTERNAL-IP` встановлено, ваше середовище має зовнішній балансувальник навантаження, який можна використовувати для шлюзу ingress. Якщо значення `EXTERNAL-IP` є `<none>` (або постійно `<pending>`), ваше середовище не надає зовнішній балансувальник навантаження для шлюзу ingress. У цьому випадку ви можете отримати доступ до шлюзу, використовуючи [node port](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) сервісу.

Виберіть інструкції, які відповідають вашому середовищу:

**Дотримуйтесь цих інструкцій, якщо ви визначили, що ваше середовище має зовнішній балансувальник навантаження.**

Встановіть IP-адресу та порти для ingress:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

{{< warning >}}
У певних середовищах балансувальник навантаження може бути відкритий за допомогою імені хосту, а не IP-адреси. У цьому випадку значення `EXTERNAL-IP` шлюзу ingress буде не IP-адресою, а імʼям хосту, і попередня команда не зможе встановити змінну середовища `INGRESS_HOST`. Використовуйте наступну команду, щоб виправити значення `INGRESS_HOST`:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

**Дотримуйтесь цих інструкцій, якщо ваше середовище не має зовнішнього балансувальника навантаження і виберіть node port.**

Встановіть порти для ingress:

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
{{< /text >}}

_GKE:_

{{< text bash >}}
$ export INGRESS_HOST=worker-node-address
{{< /text >}}

Вам потрібно створити правила фаєрволу, щоб дозволити TCP-трафік на порти сервісу `ingressgateway`. Виконайте наступні команди, щоб дозволити трафік для HTTP-порту, захищеного порту (HTTPS) або обох:

{{< text bash >}}
$ gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
$ gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"
{{< /text >}}

_IBM Cloud Kubernetes Service:_

{{< text bash >}}
$ ibmcloud ks workers --cluster cluster-name-or-id
$ export INGRESS_HOST=public-IP-of-one-of-the-worker-nodes
{{< /text >}}

_Docker For Desktop:_

{{< text bash >}}
$ export INGRESS_HOST=127.0.0.1
{{< /text >}}

_Інші середовища:_

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1. Встановіть `GATEWAY_URL`:

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

2. Переконайтеся, що IP-адреса і порт були успішно призначені змінній середовища:

    {{< text bash >}}
    $ echo "$GATEWAY_URL"
    127.0.0.1:80
    {{< /text >}}

### Перевірте зовнішній доступ {#confirm}

Підтвердьте, що застосунок Bookinfo доступний зовні, переглянувши сторінку продукту Bookinfo за допомогою браузера.

1. Виконайте наступну команду, щоб отримати зовнішню адресу застосунку Bookinfo.

    {{< text bash >}}
    $ echo "http://$GATEWAY_URL/productpage"
    {{< /text >}}

1. Вставте результат попередньої команди у свій вебоглядач та підтвердіть, що сторінка продукту Bookinfo відображається.

## Перегляд панелі керування (дашборд) {#dashboard}

Istio інтегрується з [декількома](/docs/ops/integrations) різними телеметричними застосунками. Вони допоможуть вам зрозуміти структуру вашої сервісної мережі, відобразити топологію мережі та проаналізувати її стан.

Використайте наступні інструкції для розгортання дашборду [Kiali](/docs/ops/integrations/kiali/) разом з [Prometheus](/docs/ops/integrations/prometheus/), [Grafana](/docs/ops/integrations/grafana) та [Jaeger](/docs/ops/integrations/jaeger/).

1. Встановіть [Kiali та інші надбудови]({{< github_tree >}}/samples/addons) та дочекайтеся їх розгортання.

    {{< text bash >}}
    $ kubectl apply -f samples/addons
    $ kubectl rollout status deployment/kiali -n istio-system
    Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
    deployment "kiali" successfully rolled out
    {{< /text >}}

    {{< tip >}}
    Якщо виникають помилки під час встановлення надбудов, спробуйте повторно виконати команду. Можливо, є деякі проблеми з часом, які вирішаться при повторному запуску команди.
    {{< /tip >}}

2. Доступ до дашборду Kiali.

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

3. У меню навігації ліворуч оберіть _Graph_ і в списку _Namespace_ оберіть _default_.

    {{< tip >}}
    {{< boilerplate trace-generation >}}
    {{< /tip >}}

    Kiali показує огляд вашої мережі зі звʼязками між сервісами у демонстраційному застосунку `Bookinfo`. Вона також надає фільтри для візуалізації потоку трафіку.

    {{< image link="./kiali-example2.png" caption="Дашборд Kiali" >}}

## Наступні кроки {#next-steps}

Вітаємо з завершенням цього демонстраційного встановлення!

Ці завдання є чудовим початком для новачків, щоб продовжити оцінку можливостей Istio, використовуючи цю інсталяцію `demo`:

- [Маршрутизація запитів](/docs/tasks/traffic-management/request-routing/)
- [Ін’єкція збоїв](/docs/tasks/traffic-management/fault-injection/)
- [Зміна трафіку](/docs/tasks/traffic-management/traffic-shifting/)
- [Запити метрик](/docs/tasks/observability/metrics/querying-metrics/)
- [Візуалізація метрик](/docs/tasks/observability/metrics/using-istio-dashboard/)
- [Доступ до зовнішніх сервісів](/docs/tasks/traffic-management/egress/egress-control/)
- [Візуалізація вашої мережі](/docs/tasks/observability/kiali/)

Перед тим як налаштувати Istio для використання в операційній діяльності, ознайомтеся з наступними ресурсами:

- [Моделі розгортання](/docs/ops/deployment/deployment-models/)
- [Найкращі практики розгортання](/docs/ops/best-practices/deployment/)
- [Вимоги до Pod](/docs/ops/deployment/application-requirements/)
- [Загальні інструкції з встановлення](/docs/setup/)

## Приєднуйтесь до спільноти Istio {#join-the-isito-community}

Ми запрошуємо вас ставити питання та залишати відгуки, приєднавшись до [спільноти Istio](/get-involved/).

## Видалення {#uninstall}

Щоб видалити демонстраційний застосунок `Bookinfo` та його конфігурацію, перегляньте [очищення `Bookinfo`](/docs/examples/bookinfo/#cleanup).

Видалення Istio знищує дозволи RBAC і всі ресурси в просторі імен `istio-system`. Безпечно ігнорувати помилки для відсутніх ресурсів, оскільки вони могли бути видалені ієрархічно.

{{< text bash >}}
$ kubectl delete -f @samples/addons@
$ istioctl uninstall -y --purge
{{< /text >}}

Простір імен `istio-system` стандартно не видаляється. Якщо він більше не потрібен, використайте наступну команду, щоб видалити його:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

Мітка, яка вказує Istio автоматично виконувати інʼєкцію sidecar проксі Envoy, стандартно не видаляється. Якщо вона більше не потрібна, використайте наступну команду, щоб видалити її:

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}
