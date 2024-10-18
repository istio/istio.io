---
title: Візуалізація метрик за допомогою Grafana
description: Це завдання показує, як налаштувати та використовувати Istio Dashboard для моніторингу трафіку мережі.
weight: 40
keywords: [telemetry,visualization]
aliases:
    - /uk/docs/tasks/telemetry/using-istio-dashboard/
    - /uk/docs/tasks/telemetry/metrics/using-istio-dashboard/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Це завдання показує, як налаштувати та використовувати Панель управління Istio для моніторингу трафіку мережі. В рамках цього завдання ви будете використовувати надбудову Grafana Istio та вебінтерфейс для перегляду даних трафіку сервісної мережі.

Як приклад використовуватиметься застосунок [Bookinfo](/docs/examples/bookinfo/).

## Перед початком {#before-you-begin}

* [Встановіть Istio](/docs/setup) у вашому кластері.
* Встановіть [надбудову Grafana](/docs/ops/integrations/grafana/#option-1-quick-start).
* Встановіть [надбудову Prometheus](/docs/ops/integrations/prometheus/#option-1-quick-start).
* Розгорніть застосунок [Bookinfo](/docs/examples/bookinfo/).

## Перегляд Панелі управління Istio {#viewing-the-istio-dashboard}

1. Перевірте, що сервіс `prometheus` працює у вашому кластері.

    У середовищах Kubernetes виконайте наступну команду:

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    prometheus   ClusterIP   10.100.250.202   <none>        9090/TCP   103s
    {{< /text >}}

1. Перевірте, що сервіс Grafana працює у вашому кластері.

    У середовищах Kubernetes виконайте наступну команду:

    {{< text bash >}}
    $ kubectl -n istio-system get svc grafana
    NAME      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    grafana   ClusterIP   10.103.244.103   <none>        3000/TCP   2m25s
    {{< /text >}}

1. Відкрийте Панель управління Istio через UI Grafana.

    У середовищах Kubernetes виконайте наступну команду:

    {{< text bash >}}
    $ istioctl dashboard grafana
    {{< /text >}}

    Відвідайте [http://localhost:3000/d/G8wLrJIZk/istio-mesh-dashboard](http://localhost:3000/d/G8wLrJIZk/istio-mesh-dashboard) у вашому веб-браузері.

    Панель управління Istio виглядатиме приблизно так:

    {{< image link="./grafana-istio-dashboard.png" caption="Панель управління Istio" >}}

1. Надішліть трафік до мережі.

    Для Bookinfo відвідайте `http://$GATEWAY_URL/productpage` у вашому вебоглядачі або виконайте наступну команду:

    {{< boilerplate trace-generation >}}

    {{< tip >}}
    `$GATEWAY_URL` — це значення, встановлене в застосунку [Bookinfo](/docs/examples/bookinfo/).
    {{< /tip >}}

    Оновіть сторінку кілька разів (або виконайте команду кілька разів), щоб згенерувати невелику кількість трафіку.

    Перегляньте Панель управління Istio знову. Вона повинна показувати згенерований трафік. Виглядати це буде приблизно так:

    {{< image link="./dashboard-with-traffic.png" caption="Панель управління Istio з трафіком" >}}

    Вона надає глобальний огляд Mesh разом із сервісами та робочими навантаженнями в мережі. Ви можете отримати більше деталей про сервіси та робочі навантаження, перейшовши до їхніх специфічних панелей управління, як описано нижче.

1. Візуалізуйте Панелі управління Service.

    З меню навігації в лівому куті панелі управління Grafana ви можете перейти до Панелі управління Сервісами Istio або відвідати [http://localhost:3000/d/LJ_uJAvmk/istio-service-dashboard](http://localhost:3000/d/LJ_uJAvmk/istio-service-dashboard) у вашому вебоглядачі.

    {{< tip >}}
    Можливо, вам потрібно вибрати сервіс у меню Сервіс.
    {{< /tip >}}

    Панель управління Сервісами Istio виглядатиме приблизно так:

    {{< image link="./istio-service-dashboard.png" caption="Панель управління Сервісами Istio" >}}

    Вона надає деталі про метрики для сервісу та робочих навантажень клієнтів (робочі навантаження, які викликають цей сервіс) і робочих навантажень сервісу (робочі навантаження, які надають цей сервіс) для цього сервісу.

1. Візуалізуйте Панелі управління Робочими навантаженнями.

    З меню навігації в лівому куті панелі управління Grafana ви можете перейти до Панелі управління Робочими навантаженнями Istio або відвідати [http://localhost:3000/d/UbsSZTDik/istio-workload-dashboard](http://localhost:3000/d/UbsSZTDik/istio-workload-dashboard) у вашому вебоглядачі.

    Панель управління Робочими навантаженнями Istio виглядатиме приблизно так:

    {{< image link="./istio-workload-dashboard.png" caption="Панель управління Робочими навантаженнями Istio" >}}

    Вона надає деталі про метрики для кожного робочого навантаження та вхідні робочі навантаження (робочі навантаження, які надсилають запити до цього робочого навантаження) і вихідні сервіси (сервери, до яких це робоче навантаження надсилає запити) для цього робочого навантаження.

### Про панелі управління Grafana {#about-the-grafana-dashboards}

Панель управління Istio складається з трьох основних розділів:

1. Огляд Мережі. Цей розділ надає глобальний огляд Мережі та показує HTTP/gRPC та TCP робочі навантаження в Mesh.

1. Індивідуальні Сервіси. Цей розділ надає метрики про запити та відповіді для кожного окремого сервісу в мережі (HTTP/gRPC та TCP). Також надаються метрики про робочі навантаження клієнтів та сервісу для цього сервісу.

1. Індивідуальні Робочі навантаження. Цей розділ надає метрики про запити та відповіді для кожного окремого робочого навантаження в мережі (HTTP/gRPC та TCP). Також надаються метрики про вхідні робочі навантаження та вихідні сервіси для цього робочого навантаження.

Більше про те, як створювати, налаштовувати та редагувати панелі управління, читайте в [документації Grafana](https://docs.grafana.org/).

## Очищення {#cleanup}

* Видаліть будь-які процеси `kubectl port-forward`, які можуть бути запущені:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* Якщо ви не плануєте досліджувати подальші завдання, дотримуйтесь інструкцій з [очищення Bookinfo](/docs/examples/bookinfo/#cleanup) для завершення роботи застосунку.
