---
title: Керування трафіком
description: Керуйте трафіком між сервісами в режимі оточення.
weight: 5
owner: istio/wg-networking-maintainers
test: yes
---

Тепер, коли у нас встановлено проксі waypoint, ми дізнаємось як розподіляти трафік між сервісами.

## Розподіл трафіку між сервісами {#split-traffic-between-services}

Застосунок Bookinfo має три версії сервісу `reviews`. Ви можете розподілити трафік між цими версіями, щоб перевірити нові функції або провести A/B тестування.

Налаштуємо маршрутизацію трафіку, щоб 90% запитів надсилалися до `reviews` v1, а 10% — до `reviews` v2:

{{< text syntax=bash snip_id=deploy_httproute >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
EOF
{{< /text >}}

Щоб підтвердити, що приблизно 10\% зі 100 запитів йдуть до `reviews-v2`, ви можете виконати наступну команду:

{{< text syntax=bash snip_id=test_traffic_split >}}
$ kubectl exec deploy/curl -- sh -c "for i in \$(seq 1 100); do curl -s http://productpage:9080/productpage | grep reviews-v.-; done"
{{< /text >}}

Ви помітите, що більшість запитів надходять до `reviews-v1`. Ви можете підтвердити те ж саме, відкривши застосунок Bookinfo у вашому оглядачі та кілька разів оновивши сторінку. Зверніть увагу, що запити від `reviews-v1` не мають зірок, тоді як запити від `reviews-v2` мають чорні зірки.

## Подальші кроки {#next-steps}

Ця секція завершує посібник по початку роботи з ambient mode в Istio. Ви можете перейти до розділу [Очищення](/docs/ambient/getting-started/cleanup), щоб видалити Istio, або продовжити дослідження [посібників користувача ambient mode](/docs/ambient/usage/), щоб дізнатися більше про функції та можливості Istio.
