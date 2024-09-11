---
title: Виправлення проблем за допомогою waypoints
description: Як дослідити проблеми маршрутизації через waypoint-проксі.
weight: 70
owner: istio/wg-networking-maintainers
test: no
---

Цей посібник описує, що робити, якщо ви зареєстрували простір імен, сервіс або робоче навантаження в проксі waypoint, але не бачите очікуваної поведінки.

## Проблеми з маршрутизацією трафіку або політикою безпеки {#problems-with-traffic-routing-or-security-policy}

Щоб надіслати деякі запити до сервісу `reviews` через сервіс `productpage` з podʼа `sleep`:

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/productpage
{{< /text >}}

Щоб надіслати деякі запити до podʼа `reviews` `v2` з podʼа `sleep`:

{{< text bash >}}
$ export REVIEWS_V2_POD_IP=$(kubectl get pod -l version=v2,app=reviews -o jsonpath='{.items[0].status.podIP}')
$ kubectl exec deploy/sleep -- curl -s http://$REVIEWS_V2_POD_IP:9080/reviews/1
{{< /text >}}

Запити до сервісу `reviews` повинні бути оброблені через `reviews-svc-waypoint` для будь-яких політик L7. Запити до podʼа `reviews` `v2` повинні бути оброблені через `reviews-v2-pod-waypoint` для будь-яких політик L7.

1. Якщо ваша конфігурація L7 не застосовується, спочатку запустіть команду `istioctl analyze`, щоб перевірити, чи немає проблем з валідацією вашої конфігурації.

    {{< text bash >}}
    $ istioctl analyze
    ✔ No validation issues found when analyzing namespace: default.
    {{< /text >}}

2. Визначте, який waypoint реалізує конфігурацію L7 для вашого сервісу або podʼа.

    Якщо ваше джерело викликає призначення за допомогою імені хосту або IP-адреси сервісу, використовуйте команду `istioctl experimental ztunnel-config service`, щоб підтвердити, що ваш waypoint використовується призначеним сервісом. За прикладом вище, сервіс `reviews` повинен використовувати `reviews-svc-waypoint`, тоді як усі інші сервіси в просторі імен `default` повинні використовувати waypoint простору імен.

    {{< text bash >}}
    $ istioctl experimental ztunnel-config service
    NAMESPACE    SERVICE NAME            SERVICE VIP   WAYPOINT
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      details                 10.43.160.119 waypoint
    default      kubernetes              10.43.0.1     waypoint
    default      notsleep                10.43.156.147 waypoint
    default      productpage             10.43.172.254 waypoint
    default      ratings                 10.43.71.236  waypoint
    default      reviews                 10.43.162.105 reviews-svc-waypoint
    ...
    {{< /text >}}

    Якщо вашу джерело викликає призначення за допомогою IP-адреси podʼа, використовуйте команду `istioctl experimental ztunnel-config workload`, щоб підтвердити, що ваш waypoint використовується призначеним podʼом. За прикладом вище, pod `reviews` `v2` повинен використовувати `reviews-v2-pod-waypoint`, тоді як усі інші podʼи в просторі імен `default` не повинні мати жодних waypoint, оскільки стандартно [waypoint обробляє лише трафік, адресований сервісам](/docs/ambient/usage/waypoint/#waypoint-traffic-types).

    {{< text bash >}}
    $ istioctl experimental ztunnel-config workload
    NAMESPACE    POD NAME                                    IP         NODE                     WAYPOINT                PROTOCOL
    default      bookinfo-gateway-istio-7c57fc4647-wjqvm     10.42.2.8  k3d-k3s-default-server-0 None                    TCP
    default      details-v1-698d88b-wwsnv                    10.42.2.4  k3d-k3s-default-server-0 None                    HBONE
    default      notsleep-685df55c6c-nwhs6                   10.42.0.9  k3d-k3s-default-agent-0  None                    HBONE
    default      productpage-v1-675fc69cf-fp65z              10.42.2.6  k3d-k3s-default-server-0 None                    HBONE
    default      ratings-v1-6484c4d9bb-crjtt                 10.42.0.4  k3d-k3s-default-agent-0  None                    HBONE
    default      reviews-svc-waypoint-c49f9f569-b492t        10.42.2.10 k3d-k3s-default-server-0 None                    TCP
    default      reviews-v1-5b5d6494f4-nrvfx                 10.42.2.5  k3d-k3s-default-server-0 None                    HBONE
    default      reviews-v2-5b667bcbf8-gj7nz                 10.42.0.5  k3d-k3s-default-agent-0  reviews-v2-pod-waypoint HBONE
    ...
    {{< /text >}}

    Якщо значення стовпця waypoint для podʼа неправильне, перевірте, чи ваш pod має мітку `istio.io/use-waypoint` і чи значення цієї мітки відповідає імені waypoint, що може обробляти трафік робочого навантаження. Наприклад, якщо ваш pod `reviews` `v2` використовує waypoint, який може обробляти лише трафік сервісу, ви не побачите жодного waypoint, що використовується цим podʼом. Якщо мітка `istio.io/use-waypoint` на вашому podʼі виглядає правильною, перевірте, чи ресурс Gateway для вашого waypoint має відповідне значення для мітки `istio.io/waypoint-for`. У випадку з podʼом слушними значеннями були б `all` або `workload`.

3. Перевірте статус проксі waypoint за допомогою команди `istioctl proxy-status`.

    {{< text bash >}}
    $ istioctl proxy-status
    NAME                                                CLUSTER        CDS         LDS         EDS          RDS          ECDS         ISTIOD                      VERSION
    bookinfo-gateway-istio-7c57fc4647-wjqvm.default     Kubernetes     SYNCED      SYNCED      SYNCED       SYNCED       NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    reviews-svc-waypoint-c49f9f569-b492t.default        Kubernetes     SYNCED      SYNCED      SYNCED       NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    reviews-v2-pod-waypoint-7f5dbd597-7zzw7.default     Kubernetes     SYNCED      SYNCED      NOT SENT     NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    waypoint-6f7b665c89-6hppr.default                   Kubernetes     SYNCED      SYNCED      SYNCED       NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    ...
    {{< /text >}}

4. Увімкніть [журнал доступу](/docs/tasks/observability/logs/access-log/) Envoy та перевірте логи проксі waypoint після відправлення кількох запитів:

    {{< text bash >}}
    $ kubectl logs deploy/waypoint
    {{< /text >}}

    Якщо інформації недостатньо, ви можете увімкнути debug логи для проксі waypoint:

    {{< text bash >}}
    $ istioctl pc log deploy/waypoint --level debug
    {{< /text >}}

5. Перевірте конфігурацію envoy для waypoint за допомогою команди `istioctl proxy-config`, яка показує всю інформацію, повʼязану з waypoint, таку як кластери, точки доступу, слухачі, маршрути та секрети:

    {{< text bash >}}
    $ istioctl proxy-config all deploy/waypoint
    {{< /text >}}

Зверніться до розділу [глибокого аналізу конфігурації Envoy](/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration) для отримання додаткової інформації про те, як налагоджувати Envoy, оскільки проксі waypoint засновані на Envoy.
