---
title: Тестування у промисловому середовищі
overview: Тестування нової версії мікросервісу у промисловому середовищі.

weight: 40

owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

Протестуйте ваш мікросервіс у промисловому середовищі!

## Тестування окремих мікросервісів {#testing-individual-microservices}

1. Виконайте HTTP-запит з тестового podʼа до одного з ваших сервісів:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=curl -o jsonpath='{.items[0].metadata.name}') -- curl -sS http://ratings:9080/ratings/7
    {{< /text >}}

## Хаос-тестування {#chaos-testing}

Здійсніть [хаос-тестування](http://www.boyter.org/2016/07/chaos-testing-engineering/) у промисловому середовищі і перевірте, як ваш застосунок реагує. Після кожної хаос-операції перевірте вебсторінку застосунку і перевірте, чи щось змінилося. Перевірте статус podʼів за допомогою `kubectl get pods`.

1. Завершіть роботу сервісу `details` в одному з podʼів.

    {{< text bash >}}
    $ kubectl exec $(kubectl get pods -l app=details -o jsonpath='{.items[0].metadata.name}') -- pkill ruby
    {{< /text >}}

2. Перевірте статус podʼів:

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   1          47m
    details-v1-6d86fd9949-mksv7     1/1     Running   0          47m
    details-v1-6d86fd9949-q8rrf     1/1     Running   0          48m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          47m
    productpage-v1-c9965499-nccwq   1/1     Running   0          47m
    productpage-v1-c9965499-tjdjx   1/1     Running   0          48m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          47m
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          47m
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          47m
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          47m
    curl-88ddbcfdd-l9zq4            1/1     Running   0          47m
    {{< /text >}}

    Зверніть увагу, що перший pod перезапустився один раз.

3. Завершіть роботу сервісу `details` у всіх його podʼах:

    {{< text bash >}}
    $ for pod in $(kubectl get pods -l app=details -o jsonpath='{.items[*].metadata.name}'); do echo terminating "$pod"; kubectl exec "$pod" -- pkill ruby; done
    {{< /text >}}

4. Перевірте вебсторінку застосунку:

    {{< image width="80%"
        link="bookinfo-details-unavailable.png"
        caption="Вебзастосунок Bookinfo, деталі недоступні"
        >}}

    Зверніть увагу, що розділ з докладною інформацією містить повідомлення про помилки замість інформації про книги.

5. Перевірте статус подів:

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   2          48m
    details-v1-6d86fd9949-mksv7     1/1     Running   1          48m
    details-v1-6d86fd9949-q8rrf     1/1     Running   1          49m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          48m
    productpage-v1-c9965499-nccwq   1/1     Running   0          48m
    productpage-v1-c9965499-tjdjx   1/1     Running   0          48m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          48m
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          48m
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          49m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          49m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          48m
    curl-88ddbcfdd-l9zq4            1/1     Running   0          48m
    {{< /text >}}

    Перший pod перезапустився двічі, а два інших podʼа `details` перезапустилися один раз. Можливо, ви помітите статуси `Error` і `CrashLoopBackOff`, поки podʼи не досягнуть статусу `Running`.

6. Використовуйте Ctrl-C у терміналі, щоб зупинити нескінченний цикл, який симулює трафік.

У обох випадках застосунок не зламався. Збої у мікросервісі `details` не призвели до збоїв інших мікросервісів. Це означає, що у цьому випадку не було **каскадного збою**, а був **поступова деградація сервісу**: не зважаючи на збій одного мікросервісу, застосунок все ще міг надавати корисний функціонал. Він показував відгуки та основну інформацію про книгу.

Ви готові до [додавання нової версії застосунку reviews](/docs/examples/microservices-istio/add-new-microservice-version).
