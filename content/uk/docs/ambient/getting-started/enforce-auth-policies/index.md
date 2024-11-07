---
title: Забезпечення політики авторизації
description: Застосовуйте політики авторизації рівнів 4 і 7 у сервісній мережі з режимом оточення.
weight: 4
owner: istio/wg-networking-maintainers
test: yes
---

Після того, як ви додали застосунок до ambient mesh, ви можете забезпечити доступ до нього, використовуючи політики авторизації Layer 4.

Ця функція дозволяє контролювати доступ до сервісу та з сервісу на основі ідентичностей клієнтських робочих навантажень, які автоматично призначаються всім робочим навантаженням в сервісній мережі.

## Забезпечення політики авторизації Layer 4 {#enforce-layer-4-authorization-policy}

Створимо [політику авторизації](/docs/reference/config/security/authorization-policy/), яка обмежує, які сервіси можуть спілкуватися з сервісом `productpage`. Політика застосовується до podʼів з міткою `app: productpage` та дозволяє виклики тільки зі службового облікового запису `cluster.local/ns/default/sa/bookinfo-gateway-istio`. (Це службовий обліковий запис, який використовується шлюзом Bookinfo, який ви розгорнули на попередньому кроці.)

{{< text syntax=bash snip_id=deploy_l4_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-viewer
  namespace: default
spec:
  selector:
    matchLabels:
      app: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/bookinfo-gateway-istio
EOF
{{< /text >}}

Якщо ви відкриєте застосунок Bookinfo в оглядачі (`http://localhost:8080/productpage`), ви побачите сторінку продукту, як і раніше. Однак, якщо ви спробуєте отримати доступ до сервісу `productpage` з іншого службового облікового запису, ви повинні побачити помилку.

Спробуйте отримати доступ до застосунку Bookinfo з podʼа `curl`:

{{< text syntax=bash snip_id=deploy_curl >}}
$ kubectl apply -f samples/curl/curl.yaml
{{< /text >}}

Оскільки pod `curl` використовує інший службовий обліковий запис, він не матиме доступу до сервісу `productpage`:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -s "http://productpage:9080/productpage"
command terminated with exit code 56
{{< /text >}}

## Забезпечення політики авторизації Layer 7 {#enforce-layer-7-authorization-policy}

Щоб забезпечити політики Layer 7, спочатку потрібно мати {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} для простору імен. Цей проксі буде обробляти весь трафік Layer 7, що входить у простір імен.

{{< text syntax=bash snip_id=deploy_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Ви можете перевірити проксі waypoint і переконатися, що він має статус `Programmed=True`:

{{< text bash >}}
$ kubectl get gtw waypoint
NAME       CLASS            ADDRESS       PROGRAMMED   AGE
waypoint   istio-waypoint   10.96.58.95   True         42s
{{< /text >}}

Додавання [політики авторизації L7](/docs/ambient/usage/l7-features/) явно дозволить сервісу `curl` надсилати `GET` запити до сервісу `productpage`, але не виконувати інші операції:

{{< text syntax=bash snip_id=deploy_l7_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-viewer
  namespace: default
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/curl
    to:
    - operation:
        methods: ["GET"]
EOF
{{< /text >}}

Зверніть увагу, що поле `targetRefs` використовується для вказання цільового сервісу для політики авторизації проксі waypoint. Розділ `rules` подібний до попереднього, але тепер ми додали розділ `to`, щоб вказати дозволену операцію.

{{< tip >}}
Щоб дізнатися більше про те, як увімкнути інші функції Istio, прочитайте [посібник з використання функцій Layer 7](/docs/ambient/usage/l7-features/).
{{< /tip >}}

Перевірте, чи новий проксі waypoint застосовує оновлену політику авторизації:

{{< text bash >}}
$ # Це призведе до помилки RBAC, оскільки ми не використовуємо операцію GET
$ kubectl exec deploy/curl -- curl -s "http://productpage:9080/productpage" -X DELETE
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # Це призведе до помилки RBAC, оскільки ідентичність сервісу reviews-v1 не дозволена
$ kubectl exec deploy/reviews-v1 -- curl -s http://productpage:9080/productpage
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # Це працює, оскільки ми явно дозволили GET запити від podʼа curl
$ kubectl exec deploy/curl -- curl -s http://productpage:9080/productpage | grep -o "<title>.*</title>"
{{< /text >}}

## Подальші кроки {#next-steps}

З проксі waypoint тепер ви можете забезпечити політики Layer 7 у просторі імен. Окрім політик авторизації, [ми можемо використовувати проксі waypoint для розподілу трафіку між сервісами](../manage-traffic/). Це корисно для проведення canary deployments або A/B тестування.
