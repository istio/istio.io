---
title: Увімкнення Istio на productpage
overview: Розгорніть панель управління Istio та увімкніть Istio на одному мікросервісі.
weight: 60
owner: istio/wg-docs-maintainers
test: no
---

Як ви бачили в попередньому модулі, Istio вдосконалює Kubernetes, надаючи вам можливість більш ефективно керувати вашими мікросервісами.

У цьому модулі ви увімкнете Istio на одному мікросервісі, `productpage`. Інші частини застосунку продовжать працювати як і раніше. Зверніть увагу, що ви можете поступово увімкнути Istio, мікросервіс за мікросервісом. Istio увімкнуто прозоро для мікросервісів. Вам не потрібно змінювати код мікросервісів або переривати роботу вашого застосунку; він продовжить працювати та обслуговувати запити користувачів.

1.  Застосуйте стандартні правила призначення:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/destination-rule-all.yaml
    {{< /text >}}

1.  Перерозгорніть мікросервіс `productpage`, увімкнувши Istio:

    {{< tip >}}
    Цей крок демонструє ручну інʼєкцію sidecar для ілюстрації увімкнення Istio для навчальних цілей. [Автоматична інʼєкція sidecar](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) є рекомендованим методом для використання в промисловому середовищі.
    {{< /tip >}}

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | sed 's/replicas: 1/replicas: 3/g' | kubectl apply -l app=productpage,version=v1 -f -
    deployment.apps/productpage-v1 configured
    {{< /text >}}

1.  Відкрийте вебсторінку застосунку і перевірте, що застосунок продовжує працювати. Istio було додано без зміни коду оригінального застосунку.

1.  Перевірте podʼи `productpage` і переконайтеся, що тепер кожна репліка має два контейнери. Перший контейнер є самим мікросервісом, а другий — sidecar проксі, прикріплений до нього:

    {{< text bash >}}
    $ kubectl get pods
    details-v1-68868454f5-8nbjv       1/1       Running   0          7h
    details-v1-68868454f5-nmngq       1/1       Running   0          7h
    details-v1-68868454f5-zmj7j       1/1       Running   0          7h
    productpage-v1-6dcdf77948-6tcbf   2/2       Running   0          7h
    productpage-v1-6dcdf77948-t9t97   2/2       Running   0          7h
    productpage-v1-6dcdf77948-tjq5d   2/2       Running   0          7h
    ratings-v1-76f4c9765f-khlvv       1/1       Running   0          7h
    ratings-v1-76f4c9765f-ntvkx       1/1       Running   0          7h
    ratings-v1-76f4c9765f-zd5mp       1/1       Running   0          7h
    reviews-v2-56f6855586-cnrjp       1/1       Running   0          7h
    reviews-v2-56f6855586-lxc49       1/1       Running   0          7h
    reviews-v2-56f6855586-qh84k       1/1       Running   0          7h
    curl-88ddbcfdd-cc85s              1/1       Running   0          7h
    {{< /text >}}

1.  Kubernetes замінив оригінальні podʼи `productpage` на podʼи з увімкненим Istio прозоро і поступово, виконуючи [rolling update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update-intro/). Kubernetes завершив роботу старого podʼа лише після того, як новий pod почав працювати, і прозоро переключив трафік на нові podʼи, один за одним. Тобто, він не завершив роботу більше ніж одного podʼа, поки не запустив новий pod. Це було зроблено для того, щоб уникнути переривання вашого застосунку, щоб він продовжував працювати під час виконання інʼєкції Istio.

1.  Перевірте журнали Istio sidecar для `productpage`:

    {{< text bash >}}
    $ kubectl logs -l app=productpage -c istio-proxy | grep GET
    ...
    [2019-02-15T09:06:04.079Z] "GET /details/0 HTTP/1.1" 200 - 0 178 5 3 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "details:9080" "172.30.230.51:9080" outbound|9080||details.tutorial.svc.cluster.local - 172.21.109.216:9080 172.30.146.104:58698 -
    [2019-02-15T09:06:04.088Z] "GET /reviews/0 HTTP/1.1" 200 - 0 379 22 22 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "reviews:9080" "172.30.230.27:9080" outbound|9080||reviews.tutorial.svc.cluster.local - 172.21.185.48:9080 172.30.146.104:41442 -
    [2019-02-15T09:06:04.053Z] "GET /productpage HTTP/1.1" 200 - 0 5723 90 83 "10.127.220.66" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "tutorial.bookinfo.com" "127.0.0.1:9080" inbound|9080|http|productpage.tutorial.svc.cluster.local - 172.30.146.104:9080 10.127.220.66:0 -
    {{< /text >}}

1.  Виведіть назву вашого простору імен. Це буде потрібно для розпізнавання ваших мікросервісів на панелі управління Istio:

    {{< text bash >}}
    $ echo $(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    tutorial
    {{< /text >}}

1.  Перевірте панель управління Istio, використовуючи власне посилання, яке ви налаштували у вашому `/etc/hosts` файлі [раніше](/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file):

    {{< text plain >}}
    http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard
    {{< /text >}}

    У верхньому лівому меню виберіть _Istio Mesh Dashboard_.

    {{< image width="80%"
        link="dashboard-select-dashboard.png"
        caption="Виберіть Istio Mesh Dashboard у верхньому лівому меню"
        >}}

    Зверніть увагу на сервіс `productpage` з вашого простору імен, його імʼя повинно бути `productpage.<ваш простір імен>.svc.cluster.local`.

    {{< image width="80%"
        link="dashboard-mesh.png"
        caption="Istio Mesh Dashboard"
        >}}

1.  В _Istio Mesh Dashboard_, під стовпцем `Service`, натисніть на сервіс `productpage`.

    {{< image width="80%"
        link="dashboard-service-select-productpage.png"
        caption="Панель управління Istio Service, вибраний `productpage`"
        >}}

    Прокрутіть вниз до розділу _Service Workloads_. Переконайтеся, що графіки на панелі управління оновлені.

    {{< image width="80%"
        link="dashboard-service.png"
        caption="Панель управління Istio Service"
        >}}

Це негайна перевага застосування Istio на одному мікросервісі. Ви отримуєте журнали трафіку до і з мікросервісу, включаючи час, HTTP-метод, шлях і код відповіді. Ви можете моніторити ваш мікросервіс за допомогою панелі управління Istio.

У наступних модулях ви дізнаєтеся про функціональність, яку Istio може надати вашим застосункам. Оскільки деякі функції Istio є корисними, коли вони застосовуються до окремого мікросервісу, ви дізнаєтесь, як застосовувати Istio в цілому для реалізації повного потенціалу Istio.

Ви готові [увімкнути Istio на всіх мікросервісах](/docs/examples/microservices-istio/enable-istio-all-microservices).
