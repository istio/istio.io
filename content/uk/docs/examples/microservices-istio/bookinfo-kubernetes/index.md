---
title: Запуск Bookinfo з Kubernetes
overview: Розгорніть застосунок Bookinfo, який використовує мікросервіс ratings, в Kubernetes.
weight: 30

owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

Цей модуль показує вам застосунок, що складається з чотирьох мікросервісів, написаних різними мовами програмування: `productpage`, `details`, `ratings` і `reviews`. Ми називаємо складений застосунок `Bookinfo`, і ви можете дізнатися більше про нього на [сторінці демонстраційного застосунку Bookinfo](/docs/examples/bookinfo).

[Bookinfo](/docs/examples/bookinfo) показує остаточний стан застосунку, в якому мікросервіс `reviews` має три версії: `v1`, `v2`, `v3`. У цьому модулі застосунок використовує лише версію `v1` мікросервісу `reviews`. Наступні модулі покращать застосунок, розгорнувши нові версії мікросервісу `reviews`.

## Розгорніть застосунок і pod для тестування {#deploy-the-application-and-a-testing-pod}

1. Встановіть змінну середовища `MYHOST`, щоб зберігати URL застосунку:

    {{< text bash >}}
    $ export MYHOST=$(kubectl config view -o jsonpath={.contexts..namespace}).bookinfo.com
    {{< /text >}}

2. Ознайомтесь з [`bookinfo.yaml`]({{< github_blob >}}/samples/bookinfo/platform/kube/bookinfo.yaml). Це специфікація розгортання Kubernetes для застосунку. Зверніть увагу на services та deployments.

3. Розгорніть застосунок у вашому кластері Kubernetes:

    {{< text bash >}}
    $ kubectl apply -l version!=v2,version!=v3 -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
    service/details created
    serviceaccount/bookinfo-details created
    deployment.apps/details-v1 created
    service/ratings created
    serviceaccount/bookinfo-ratings created
    deployment.apps/ratings-v1 created
    service/reviews created
    serviceaccount/bookinfo-reviews created
    deployment.apps/reviews-v1 created
    service/productpage created
    serviceaccount/bookinfo-productpage created
    deployment.apps/productpage-v1 created
    {{< /text >}}

4. Перевірте статус podʼів:

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-q8rrf     1/1     Running   0          10s
    productpage-v1-c9965499-tjdjx   1/1     Running   0          8s
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          9s
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          9s
    {{< /text >}}

5. Після того, як чотири podʼа досягнуть статусу `Running`, ви можете масштабувати розгортання. Щоб кожна версія кожного мікросервісу працювала в трьох podʼах, виконайте наступну команду:

    {{< text bash >}}
    $ kubectl scale deployments --all --replicas 3
    deployment.apps/details-v1 scaled
    deployment.apps/productpage-v1 scaled
    deployment.apps/ratings-v1 scaled
    deployment.apps/reviews-v1 scaled
    {{< /text >}}

6. Перевірте статус podʼів. Зверніть увагу, що у кожного мікросервісу є три podʼа:

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   0          50s
    details-v1-6d86fd9949-mksv7     1/1     Running   0          50s
    details-v1-6d86fd9949-q8rrf     1/1     Running   0          1m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          50s
    productpage-v1-c9965499-nccwq   1/1     Running   0          50s
    productpage-v1-c9965499-tjdjx   1/1     Running   0          1m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          50s
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          50s
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          1m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          49s
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          1m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          49s
    {{< /text >}}

7. Після того, як сервіси досягнуть статусу `Running`, розгорніть тестовий pod, [sleep]({{< github_tree >}}/samples/sleep), для надсилання запитів до ваших мікросервісів:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
    {{< /text >}}

8. Щоб підтвердити, що застосунок Bookinfo працює, надішліть запит до нього за допомогою команди curl з вашого тестового podʼа:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Увімкніть зовнішній доступ до застосунку {#enable-external-access-to-the-application}

Коли ваш застосунок працює, увімкніть доступ клієнтів ззовні кластера. Коли ви успішно налаштуєте наступні кроки, ви зможете отримати доступ до застосунку з оглядача вашого компʼютера.

{{< warning >}}

Якщо ваш кластер працює на GKE, змініть тип сервісу `productpage` на `LoadBalancer`:

{{< text bash >}}
$ kubectl patch svc productpage -p '{"spec": {"type": "LoadBalancer"}}'
service/productpage patched
{{< /text >}}

{{< /warning >}}

### Налаштуйте ресурс Ingress Kubernetes і отримайте доступ до вебсторінки вашого застосунку {#configure-the-kubernetes-ingress-resource-and-access-your-applications-webpage}

1. Створіть ресурс Ingress Kubernetes:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: bookinfo
      annotations:
        kubernetes.io/ingress.class: istio
    spec:
      rules:
      - host: $MYHOST
        http:
          paths:
          - path: /productpage
            pathType: Prefix
            backend:
              service:
                name: productpage
                port:
                  number: 9080
          - path: /login
            pathType: Prefix
            backend:
              service:
                name: productpage
                port:
                  number: 9080
          - path: /logout
            pathType: Prefix
            backend:
              service:
                name: productpage
                port:
                  number: 9080
          - path: /static
            pathType: Prefix
            backend:
              service:
                name: productpage
                port:
                  number: 9080
    EOF
    {{< /text >}}

### Оновіть ваш файл конфігурації `/etc/hosts` {#update-your-etchosts-configuration-file}

1. Отримайте IP-адресу для Kubernetes ingress з імʼям `bookinfo`:

    {{< text bash >}}
    $ kubectl get ingress bookinfo
    {{< /text >}}

2. У вашому файлі `/etc/hosts` додайте попередню IP-адресу до записів хостів, наданих наступною командою. Ви повинні мати [права суперкористувача](https://en.wikipedia.org/wiki/Superuser) і, ймовірно, використати [`sudo`](https://en.wikipedia.org/wiki/Sudo) для редагування `/etc/hosts`.

    {{< text bash >}}
    $ echo $(kubectl get ingress istio-system -n istio-system -o jsonpath='{..ip} {..host}') $(kubectl get ingress bookinfo -o jsonpath='{..host}')
    {{< /text >}}

### Отримайте доступ до вашого застосунку {#access-your-application}

1. Отримайте доступ до домашньої сторінки застосунку з командного рядка:

    {{< text bash >}}
    $ curl -s $MYHOST/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

2. Вставте результат наступної команди в адресний рядок оглядача:

    {{< text bash >}}
    $ echo http://$MYHOST/productpage
    {{< /text >}}

    Ви повинні побачити таку вебсторінку:

    {{< image width="80%"
        link="bookinfo.png"
        caption="Вебзастосунок Bookinfo"
        >}}

3. Спостерігайте, як мікросервіси викликають один одного. Наприклад, `reviews` викликає мікросервіс `ratings`, використовуючи URL `http://ratings:9080/ratings`. Дивіться [код `reviews`]({{< github_blob >}}/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java):

    {{< text java >}}
    private final static String ratings_service = "http://ratings:9080/ratings";
    {{< /text >}}

4. Встановіть нескінченний цикл в окремому вікні термінала, щоб надсилати трафік до вашого застосунку для імітації постійного трафіку від користувачів в реальному світі:

    {{< text bash >}}
    $ while :; do curl -s $MYHOST/productpage | grep -o "<title>.*</title>"; sleep 1; done
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    ...
    {{< /text >}}

Ви готові до [тестування застосунку](/docs/examples/microservices-istio/production-testing).
