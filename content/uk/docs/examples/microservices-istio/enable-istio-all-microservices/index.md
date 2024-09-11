---
title: Увімкнення Istio на всіх мікросервісах
overview: Увімкніть Istio для встього вашого застосунку.
weight: 70
owner: istio/wg-docs-maintainers
test: no
---

Раніше ви увімкнули Istio на одному мікросервісі, `productpage`. Тепер ви можете продовжити увімкнення Istio на інших мікросервісах поетапно, щоб отримати функціональність Istio для більшої кількості мікросервісів. Для цього навчального посібника ви увімкнете Istio на всіх мікросервісах, що залишились, за один раз.

1.  Для цілей цього навчального посібника зменшить масштабування розгортання мікросервісів до 1:

    {{< text bash >}}
    $ kubectl scale deployments --all --replicas 1
    {{< /text >}}

1.  Перерозгорніть застосунок Bookinfo з увімкненим Istio. Сервіс `productpage` не буде перерозгорнуто, оскільки він вже має інʼєкцію Istio, і його podʼи не будуть змінені. Цього разу ви будете використовувати лише одну репліку мікросервісу.

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | kubectl apply -l app!=reviews -f -
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | kubectl apply -l app=reviews,version=v2 -f -
    service/details unchanged
    serviceaccount/bookinfo-details unchanged
    deployment.apps/details-v1 configured
    service/ratings unchanged
    serviceaccount/bookinfo-ratings unchanged
    deployment.apps/ratings-v1 configured
    serviceaccount/bookinfo-reviews unchanged
    service/productpage unchanged
    serviceaccount/bookinfo-productpage unchanged
    deployment.apps/productpage-v1 configured
    deployment.apps/reviews-v2 configured
    {{< /text >}}

1.  Зверніться до вебсторінки застосунку кілька разів. Зверніть увагу, що Istio було додано **прозоро**, оригінальний застосунок не змінився. Istio було додано на льоту без потреби в знятті та повторному розгортанні всього застосунку.

1.  Перевірте podʼи застосунку та переконайтеся, що тепер кожен pod має два контейнери. Один контейнер є самим мікросервісом, інший — sidecar проксі, прикріплений до нього:

    {{< text bash >}}
    $ kubectl get pods
    details-v1-58c68b9ff-kz9lf        2/2       Running   0          2m
    productpage-v1-59b4f9f8d5-d4prx   2/2       Running   0          2m
    ratings-v1-b7b7fbbc9-sggxf        2/2       Running   0          2m
    reviews-v2-dfbcf859c-27dvk        2/2       Running   0          2m
    sleep-88ddbcfdd-cc85s             1/1       Running   0          7h
    {{< /text >}}

1.  Зверніться до панелі управління Istio за допомогою власного URL, який ви налаштували у вашому `/etc/hosts` файлі [раніше](/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file):

    {{< text plain >}}
    http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard
    {{< /text >}}

1.  У верхньому лівому меню виберіть _Istio Mesh Dashboard_. Зверніть увагу, що тепер усі сервіси з вашого простору імен зʼявляються у списку сервісів.

    {{< image width="80%"
        link="dashboard-mesh-all.png"
        caption="Istio Mesh Dashboard"
        >}}

1.  Перевірте якийсь мікросервіс на _Istio Service Dashboard_, наприклад `ratings`:

    {{< image width="80%"
        link="dashboard-ratings.png"
        caption="Istio Service Dashboard"
        >}}

1.  Візуалізуйте топологію вашого застосунку, використовуючи консоль [Kiali](https://www.kiali.io), яка не є частиною Istio, але встановлена як частина конфігурації `demo`. Доступ до панелі управління можна отримати за допомогою власного URL, який ви налаштували у вашому `/etc/hosts` файлі [раніше](/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file):

    {{< text plain >}}
    http://my-kiali.io/kiali/console
    {{< /text >}}

    Якщо ви встановили Kiali як частину [інструкцій з початку роботи](/docs/setup/getting-started/), ваш логін користувачва в консолі Kiali буде `admin`, а пароль — `admin`.

1.  Натисніть на вкладку Graph і виберіть ваш простір імен у меню _Namespace_ в верхньому кутку. У меню _Display_ відзначте прапорець _Traffic Animation_, щоб побачити анімацію трафіку.

    {{< image width="80%"
        link="kiali-display-menu.png"
        caption="Вкладка Kiali Graph, меню display"
        >}}

1.  Спробуйте різні опції у меню _Edge Labels_. Наведіть курсор миші на вузли та ребра графу. Зверніть увагу на метрики трафіку справа.

    {{< image width="80%"
        link="kiali-edge-labels-menu.png"
        caption="Вкладка Kiali Graph, меню edge labels"
        >}}

    {{< image width="80%"
        link="kiali-initial.png"
        caption="Вкладка Kiali Graph"
        >}}

Ви готові [налаштувати Istio Ingress Gateway](/docs/examples/microservices-istio/istio-ingress-gateway).
