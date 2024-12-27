---
title: Розгортання демонстраційного застосунку
description: Розротання демонстраційного застосунку Bookinfo.
weight: 2
owner: istio/wg-networking-maintainers
test: yes
---

Щоб дослідити Istio, ви встановите демонстраційний [застосунок Bookinfo](/docs/examples/bookinfo/), що складається з чотирьох окремих мікросервісів, які використовуються для демонстрації різних функцій Istio.

{{< image width="50%" link="./bookinfo.svg" caption="Демонстраційний застосунок Bookinfo в Istio написаний різними мовами" >}}

У рамках цього посібника ви розгорнете застосунок Bookinfo та відкриєте сервіс `productpage` за допомогою ingress gateway.

## Розгортання застосунку Bookinfo {#deploy-the-bookinfo-application}

Розпочніть з розгортання застосунку:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo-versions.yaml
{{< /text >}}

Щоб перевірити, що застосунок працює, перевірте статус podʼів:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
details-v1-cf74bb974-nw94k       1/1     Running   0          42s
productpage-v1-87d54dd59-wl7qf   1/1     Running   0          42s
ratings-v1-7c4bbf97db-rwkw5      1/1     Running   0          42s
reviews-v1-5fd6d4f8f8-66j45      1/1     Running   0          42s
reviews-v2-6f9b55c5db-6ts96      1/1     Running   0          42s
reviews-v3-7d99fd7978-dm6mx      1/1     Running   0          42s
{{< /text >}}

Щоб отримати доступ до сервісу `productpage` ззовні кластера, потрібно налаштувати ingress gateway.

## Розгортання та налаштування ingress gateway {#deploy-and-configure-the-ingress-gateway}

Ви будете використовувати Kubernetes Gateway API для розгортання шлюзу з назвою `bookinfo-gateway`:

{{< text syntax=bash snip_id=deploy_bookinfo_gateway >}}
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
{{< /text >}}

Стандартно Istio створює сервіс `LoadBalancer` для шлюзу. Оскільки ми будемо отримувати доступ до цього шлюзу через тунель, нам не потрібен балансувальник навантаження. Змініть тип сервісу на `ClusterIP`, додавши анотацію до шлюзу:

{{< text syntax=bash snip_id=annotate_bookinfo_gateway >}}
$ kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
{{< /text >}}

Щоб перевірити статус шлюзу, виконайте:

{{< text bash >}}
$ kubectl get gateway
NAME               CLASS   ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio   bookinfo-gateway-istio.default.svc.cluster.local   True         42s
{{< /text >}}

Зачекайте, поки шлюз не зʼявиться, як запрограмовано, перш ніж продовжити.

## Доступ до застосунку {#access-the-application}

Ви зможете зʼєднатись з сервісом Bookinfo `productpage` через шлюз, який ви щойно налаштували. Щоб отримати доступ до шлюзу, використовуйте команду `kubectl port-forward`:

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway-istio 8080:80
{{< /text >}}

Відкрийте ваш оглядач та перейдіть за адресою `http://localhost:8080/productpage`, щоб переглянути застосунок Bookinfo.

{{< image width="80%" link="./bookinfo-browser.png" caption="Застосунок Bookinfo" >}}

Якщо ви оновите сторінку, ви повинні побачити, як рейтинги книг змінюються, оскільки запити розподіляються між різними версіями сервісу `reviews`.

## Подальші кроки {#next-steps}

[Перейдіть до наступного розділу](../secure-and-visualize/), щоб додати застосунок до сервісної мережі та дізнатися, як забезпечити безпеку та візуалізувати комунікацію між застосунками.
