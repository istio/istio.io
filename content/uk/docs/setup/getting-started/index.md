---
title: Як розпочати
description: Спробуйте функції Istio швидко та легко.
weight: 5
aliases:
    - /uk/docs/setup/additional-setup/getting-started/
    - /latest/uk/docs/setup/additional-setup/getting-started/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes, gateway-api]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
Хочете дізнатись більше про режим {{< gloss "ambient" >}}ambient{{< /gloss >}} в Istio? Відвідайте посібник [Початок роботи з режимом оточення](/docs/ambient/getting-started)!
{{< /tip >}}

Цей посібник дозволяє швидко оцінити Istio. Якщо ви вже знайомі з Istio або зацікавлені в установці інших конфігураційних профілів чи розширених [моделей розгортання](/docs/ops/deployment/deployment-models/), зверніться до нашої сторінки Частих питань [який метод встановлення Istio використовувати?](/about/faq/#install-method-selection).

Вам знадобиться кластер Kubernetes для продовження. Якщо у вас немає кластера, ви можете використовувати [kind](/docs/setup/platform-setup/kind) або будь-яку іншу [підтримувану платформу Kubernetes](/docs/setup/platform-setup).

Виконайте наступні кроки, щоб розпочати роботу з Istio:

1. [Завантажте та встановіть Istio](#download)
2. [Встановіть CRD для Kubernetes Gateway API](#gateway-api)
3. [Розгорніть демонстраційний застосунок](#bookinfo)
4. [Відкрийте застосунок для зовнішнього трафіку](#ip)
5. [Перегляньте дашборд](#dashboard)

## Завантаження Istio {#download}

1. Перейдіть на сторінку [релізів Istio]({{< istio_release_url >}}), щоб завантажити файл установки для вашої ОС, або [завантажте та розпакуйте останній реліз автоматично](/docs/setup/additional-setup/download-istio-release) (Linux або macOS):

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

2. Перейдіть до теки пакета Istio. Наприклад, якщо пакет називається `istio-{{< istio_full_version >}}`:

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    Тека установки містить:

    - Демонстраційні застосунки в `samples/`
    - Бінарний файл клієнта [`istioctl`](/docs/reference/commands/istioctl) у теці `bin/`.

3. Додайте клієнт `istioctl` до вашого шляху (Linux або macOS):

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## Встановлення Istio {#install}

Для цього посібника ми використовуємо [профіль конфігурації](/docs/setup/additional-setup/config-profiles/) `demo`. Він обраний для забезпечення хорошого набору стандартних налаштувань для тестування, але є й інші профілі для продуктивності, тестування або [OpenShift](/docs/setup/platform-setup/openshift/).

На відміну від [Istio Gateways](/docs/concepts/traffic-management/#gateways), створення [Kubernetes Gateways](https://gateway-api.sigs.k8s.io/api-types/gateway/) стандартно також [розгортає проксі-сервери шлюзів](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment). Оскільки вони не будуть використовуватися, ми відключимо розгортання стандартних служб gateway в Istio, які зазвичай встановлюються як частина профілю `demo`.

1. Встановіть Istio, використовуючи профіль `demo`, без будь-яких шлюзів:

    {{< text bash >}}
    $ istioctl install -f @samples/bookinfo/demo-profile-no-gateways.yaml@ -y
    ✔ Istio core встановлено
    ✔ Istiod встановлено
    ✔ Встановлення завершено
    Зроблено цю установку стандартною для інʼєкції та валідації.
    {{< /text >}}

2. Додайте мітку до простору імен, щоб інструктувати Istio автоматично вбудовувати проксі-сервери Envoy при розгортанні вашого застосунку пізніше:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    namespace/default labeled
    {{< /text >}}

## Встановлення CRD Kubernetes Gateway API {#gateway-api}

CRD Kubernetes Gateway API не встановлені стандартно у більшості кластерів Kubernetes, тому переконайтеся, що вони встановлені перед використанням Gateway API.

1. Встановіть CRD Gateway API, якщо вони ще не присутні:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
    { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

## Розгортання демонстраційного застосунку {#bookinfo}

Ви налаштували Istio для автоматичного додавання контейнерів sidecar в будь-який застосунок, який ви розгортаєте в своєму просторі імен `default`.

1. Розгорніть [демонстраційний застосунок `Bookinfo`](/docs/examples/bookinfo/):

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    service/details created
    serviceaccount/bookinfo-details created
    deployment.apps/details-v1 created
    service/ratings created
    serviceaccount/bookinfo-ratings created
    deployment.apps/ratings-v1 created
    service/reviews created
    serviceaccount/bookinfo-reviews created
    deployment.apps/reviews-v1 created
    deployment.apps/reviews-v2 created
    deployment.apps/reviews-v3 created
    service/productpage created
    serviceaccount/bookinfo-productpage created
    deployment.apps/productpage-v1 created
    {{< /text >}}

    Застосунок почне запускатися. Як тільки кожен pod стане готовим, разом з ним буде розгорнуто і sidecar від Istio.

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

    Зверніть увагу, що podʼи показують `READY 2/2`, що підтверджує наявність контейнера застосунку та контейнера sidecar від Istio.

2. Перевірте, чи застосунок працює в кластері, перевіривши заголовок сторінки у відповіді:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Відкриття застосунку для зовнішнього трафіку {#ip}

Застосунок Bookinfo розгорнуто, але не доступний ззовні. Щоб зробити його доступним, вам потрібно створити ingress gateway, який зіставляє шлях до маршруту на периметрі вашої мережі.

1. Створіть [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/) для застосунку Bookinfo:

    {{< text syntax=bash snip_id=deploy_bookinfo_gateway >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    gateway.gateway.networking.k8s.io/bookinfo-gateway created
    httproute.gateway.networking.k8s.io/bookinfo created
    {{< /text >}}

    Стандартно Istio створює сервіс типу `LoadBalancer` для gateway. Оскільки ми будемо отримувати доступ до цього gateway через тунель, нам не потрібен балансувальник навантаження. Якщо ви хочете дізнатися, як налаштовуються балансувальники навантаження для зовнішніх IP-адрес, прочитайте документацію про [ingress gateways](/docs/tasks/traffic-management/ingress/ingress-control/).

2. Змініть тип сервісу на `ClusterIP`, додавши анотацію до gateway:

    {{< text syntax=bash snip_id=annotate_bookinfo_gateway >}}
    $ kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
    {{< /text >}}

3. Щоб перевірити статус gateway, виконайте:

    {{< text bash >}}
    $ kubectl get gateway
    NAME               CLASS   ADDRESS                                            PROGRAMMED   AGE
    bookinfo-gateway   istio   bookinfo-gateway-istio.default.svc.cluster.local   True         42s
    {{< /text >}}

## Доступ до застосунку {#access-the-application}

Ви приєднаєтесь до сервісу `productpage` застосунку Bookinfo через gateway, який ви щойно створили. Щоб отримати доступ до gateway, скористайтеся командою `kubectl port-forward`:

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway-istio 8080:80
{{< /text >}}

Відкрийте вебоглядач та перейдіть за адресою `http://localhost:8080/productpage`, щоб переглянути застосунок Bookinfo.

{{< image width="80%" link="./bookinfo-browser.png" caption="Застосунок Bookinfo" >}}

Якщо ви оновите сторінку, ви побачите, як відгуки та рейтинги книг змінюються, оскільки запити розподіляються між різними версіями сервісу `reviews`.

## Перегляд дашборда {#dashboard}

Istio інтегрується з [різними застосунками для телеметрії](/docs/ops/integrations), які допомагають отримати уявлення про структуру вашої сервісної мережі, відобразити топологію та проаналізувати її справність.

Скористайтеся наведеними інструкціями, щоб встановити дашборд [Kiali](/docs/ops/integrations/kiali/), разом з [Prometheus](/docs/ops/integrations/prometheus/), [Grafana](/docs/ops/integrations/grafana) та [Jaeger](/docs/ops/integrations/jaeger/).

1. Встановіть [Kiali та інші надбудови]({{< github_tree >}}/samples/addons) та дочекайтесь їх розгортання.

    {{< text bash >}}
    $ kubectl apply -f @samples/addons@
    $ kubectl rollout status deployment/kiali -n istio-system
    Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
    deployment "kiali" successfully rolled out
    {{< /text >}}

2. Отримайте доступ до дашборда Kiali.

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

3. У лівому меню виберіть _Graph_, а в списку _Namespace_ виберіть _default_.

    {{< tip >}}
    {{< boilerplate trace-generation >}}
    {{< /tip >}}

    Дашборд Kiali відображає огляд вашої сервісної мережі зі звʼязками між сервісами у демонстраційному застосунку `Bookinfo`. Вона також надає фільтри для візуалізації трафіку.

    {{< image link="./kiali-example2.png" caption="Панель керування Kiali" >}}

## Наступні кроки {#next-steps}

Вітаємо з завершенням установки!

Ось кілька завдань, які допоможуть початківцям далі оцінити можливості Istio, використовуючи цю установку `demo`:

- [Маршрутизація запитів](/docs/tasks/traffic-management/request-routing/)
- [Інʼєкції збоїв](/docs/tasks/traffic-management/fault-injection/)
- [Перемикання трафіку](/docs/tasks/traffic-management/traffic-shifting/)
- [Запити до метрик](/docs/tasks/observability/metrics/querying-metrics/)
- [Візуалізація метрик](/docs/tasks/observability/metrics/using-istio-dashboard/)
- [Доступ до зовнішніх сервісів](/docs/tasks/traffic-management/egress/egress-control/)
- [Візуалізація вашого mesh](/docs/tasks/observability/kiali/)

Перед тим, як налаштувати Istio для використання в операційній діяльності, ознайомтесь з наступними ресурсами:

- [Моделі розгортання](/docs/ops/deployment/deployment-models/)
- [Рекомендації щодо розгортання](/docs/ops/best-practices/deployment/)
- [Вимоги до podʼів](/docs/ops/deployment/application-requirements/)
- [Загальні інструкції з установки](/docs/setup/)

## Долучайтеся до спільноти Istio {#join-the-istio-community}

Ми запрошуємо вас ставити питання та надати зворотний зв'язок, приєднавшись до [спільноти Istio](/get-involved/).

## Видалення {#uninstall}

Щоб видалити демонстраційний застосунок `Bookinfo` та його конфігурацію, дивіться розділ [очищення `Bookinfo`](/docs/examples/bookinfo/#cleanup).

Видалення Istio видаляє дозволи RBAC та всі ресурси, що знаходяться в просторі імен `istio-system`. Можна ігнорувати помилки для неіснуючих ресурсів, оскільки вони могли бути видалені ієрархічно.

{{< text bash >}}
$ kubectl delete -f @samples/addons@
$ istioctl uninstall -y --purge
{{< /text >}}

Простір імен `istio-system` стандартно не видаляється. Якщо він більше не потрібен, використовуйте наступну команду для його видалення:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

Мітка, що інструктує Istio автоматично вставляти проксі-контейнери Envoy, також стандартно не видаляється. Якщо вона більше не потрібна, використовуйте наступну команду для її видалення:

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}

Якщо ви встановили CRD для Kubernetes Gateway API, а тепер хочете їх видалити, запустіть одну з наступних команд:

- Якщо ви використовували **експериментальну версію** CRD:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}

- В іншому випадку:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}
