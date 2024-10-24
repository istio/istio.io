---
title: Виправлення проблем зі зʼєднанням за допомогою ztunnel
description: Як перевірити, що проксі вузла мають правильну конфігурацію.
weight: 60
owner: istio/wg-networking-maintainers
test: no
---

Цей посібник описує деякі варіанти моніторингу конфігурації та шляхів передачі даних проксі-сервера ztunnel. Ця інформація також може допомогти з базовим усуненням несправностей та у визначенні корисної інформації, яку варто зібрати та надати у звіті про помилку, якщо виникають будь-які проблеми.

## Перегляд стану проксі-сервера ztunnel {#viewing-ztunnel-proxy-state}

Проксі-сервер ztunnel отримує конфігурацію та інформацію про виявлення з {{< gloss "панель управління" >}}панелі управління{{< /gloss >}} istiod за допомогою API xDS.

Команда `istioctl ztunnel-config` дозволяє переглядати знайдені робочі навантаження, як їх бачить проксі-сервер ztunnel.

У першому прикладі ви бачите всі робочі навантаження та компоненти панелі управління, які наразі відстежує ztunnel, включаючи інформацію про IP-адресу та протокол, який слід використовувати при підключенні до цього компонента, а також чи є проксі waypoint, асоційований з цим робочим навантаженням.

{{< text bash >}}
$ istioctl ztunnel-config workloads
NAMESPACE          POD NAME                                IP          NODE                  WAYPOINT PROTOCOL
default            bookinfo-gateway-istio-59dd7c96db-q9k6v 10.244.1.11 ambient-worker        None     TCP
default            details-v1-cf74bb974-5sqkp              10.244.1.5  ambient-worker        None     HBONE
default            notsleep-5c785bc478-zpg7j               10.244.2.7  ambient-worker2       None     HBONE
default            productpage-v1-87d54dd59-fn6vw          10.244.1.10 ambient-worker        None     HBONE
default            ratings-v1-7c4bbf97db-zvkdw             10.244.1.6  ambient-worker        None     HBONE
default            reviews-v1-5fd6d4f8f8-knbht             10.244.1.16 ambient-worker        None     HBONE
default            reviews-v2-6f9b55c5db-c94m2             10.244.1.17 ambient-worker        None     HBONE
default            reviews-v3-7d99fd7978-7rgtd             10.244.1.18 ambient-worker        None     HBONE
default            sleep-7656cf8794-r7zb9                  10.244.1.12 ambient-worker        None     HBONE
istio-system       istiod-7ff4959459-qcpvp                 10.244.2.5  ambient-worker2       None     TCP
istio-system       ztunnel-6hvcw                           10.244.1.4  ambient-worker        None     TCP
istio-system       ztunnel-mf476                           10.244.2.6  ambient-worker2       None     TCP
istio-system       ztunnel-vqzf9                           10.244.0.6  ambient-control-plane None     TCP
kube-system        coredns-76f75df574-2sms2                10.244.0.3  ambient-control-plane None     TCP
kube-system        coredns-76f75df574-5bf9c                10.244.0.2  ambient-control-plane None     TCP
local-path-storage local-path-provisioner-7577fdbbfb-pslg6 10.244.0.4  ambient-control-plane None     TCP

{{< /text >}}

Команда `ztunnel-config` може бути використана для перегляду секретів, що містять сертифікати TLS, які проксі-сервер ztunnel отримав з панелі управління istiod для використання для mTLS.

{{< text bash >}}
$ istioctl ztunnel-config certificates "$ZTUNNEL".istio-system
CERTIFICATE NAME                                              TYPE     STATUS        VALID CERT     SERIAL NUMBER                        NOT AFTER                NOT BEFORE
spiffe://cluster.local/ns/default/sa/bookinfo-details         Leaf     Available     true           c198d859ee51556d0eae13b331b0c259     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-details         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-productpage     Leaf     Available     true           64c3828993c7df6f85a601a1615532cc     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-productpage     Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-ratings         Leaf     Available     true           720479815bf6d81a05df8a64f384ebb0     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-ratings         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-reviews         Leaf     Available     true           285697fb2cf806852d3293298e300c86     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-reviews         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/sleep                    Leaf     Available     true           fa33bbb783553a1704866842586e4c0b     2024-05-05T09:25:49Z     2024-05-04T09:23:49Z
spiffe://cluster.local/ns/default/sa/sleep                    Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
{{< /text >}}

Використовуючи ці команди, ви можете перевірити, що проксі-сервери ztunnel налаштовані з усіма очікуваними робочими навантаженнями та TLS сертифікатом. Крім того, відсутню інформацію можна використовувати для усунення будь-яких помилок мережі.

Ви можете використати опцію `all`, щоб переглянути всі частини конфігурації ztunnel за допомогою однієї команди CLI:

{{< text bash >}}
$ istioctl ztunnel-config all -o json
{{< /text >}}

Також ви можете переглянути необроблений дамп конфігурації проксі-сервера ztunnel через `curl` до точки доступу всередині його podʼа:

{{< text bash >}}
$ kubectl debug -it $ZTUNNEL -n istio-system --image=curlimages/curl -- curl localhost:15000/config_dump
{{< /text >}}

## Перегляд стану Istiod для ресурсів ztunnel xDS {#viewing-istiod-state-for-ztunnel-xds-resources}

Іноді може виникнути необхідність переглянути стан конфігураційних ресурсів проксі ztunnel, які зберігаються в панелі управління istiod, у форматі ресурсів API xDS, спеціально визначених для проксі ztunnel. Це можна зробити, виконавши команду exec у pod istiod і отримавши цю інформацію з порту 15014 для конкретного проксі ztunnel, як показано в прикладі нижче. Отриманий результат можна зберегти та переглянути за допомогою утиліти форматування JSON для зручнішого перегляду (не показано в прикладі).

{{< text bash >}}
$ export ISTIOD=$(kubectl get pods -n istio-system -l app=istiod -o=jsonpath='{.items[0].metadata.name}')
$ kubectl debug -it $ISTIOD -n istio-system --image=curlimages/curl -- curl localhost:15014/debug/config_dump?proxyID="$ZTUNNEL".istio-system
{{< /text >}}

## Перевірка трафіку через ztunnel за допомогою логів {#verifying-ztunnel-traffic-through-logs}

Логи трафіку ztunnel можна переглядати за допомогою стандартних засобів роботи з логами в Kubernetes.

{{< text bash >}}
$ kubectl -n default exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://productpage:9080/; done'
HTTP/1.1 200 OK
Server: Werkzeug/3.0.1 Python/3.12.1
--snip--
{{< /text >}}

Показаний у відповідь результат підтверджує, що pod клієнта отримує відповіді від сервісу. Тепер ви можете перевірити логи podʼів ztunnel, щоб підтвердити, що трафік був переданий через тунель HBONE.

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "inbound|outbound"
2024-05-04T09:59:05.028709Z info    access  connection complete src.addr=10.244.1.12:60059 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.10:9080 dst.hbone_addr="10.244.1.10:9080" dst.service="productpage.default.svc.cluster.local" dst.workload="productpage-v1-87d54dd59-fn6vw" dst.namespace="productpage" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-productpage" direction="inbound" bytes_sent=175 bytes_recv=80 duration="1ms"
2024-05-04T09:59:05.028771Z info    access  connection complete src.addr=10.244.1.12:58508 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.10:15008 dst.hbone_addr="10.244.1.10:9080" dst.service="productpage.default.svc.cluster.local" dst.workload="productpage-v1-87d54dd59-fn6vw" dst.namespace="productpage" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-productpage" direction="outbound" bytes_sent=80 bytes_recv=175 duration="1ms"
--snip--
{{< /text >}}

Ці повідомлення в логах підтверджують, що трафік був переданий через проксі ztunnel. Додатковий детальний моніторинг можна виконати, перевіряючи логи на конкретних екземплярах проксі ztunnel, які знаходяться на тих же вузлах, що й вихідні та кінцеві podʼи трафіку. Якщо ці логи не відображаються, можливо, [перенаправлення трафіку](/docs/ambient/architecture/traffic-redirection) працює некоректно.

{{< tip >}}
Трафік завжди проходить через pod ztunnel, навіть якщо джерело і місце призначення трафіку знаходяться на одному обчислювальному вузлі.
{{< /tip >}}

### Перевірка балансування навантаження в ztunnel {#verifying-ztunnel-load-balancing}

Проксі ztunnel автоматично виконує балансування навантаження на стороні клієнта, якщо місце призначення є сервісом з декількома точками доступу. Додаткова конфігурація не потрібна. Алгоритм балансування навантаження фіксований і використовує внутрішній алгоритм Round Robin на рівні L4, який розподіляє трафік на основі стану підключення L4 і не підлягає налаштуванню користувачем.

{{< tip >}}
Якщо місце призначення є сервісом з декількома екземплярами або podʼами і з ним не пов’язаний жоден проксі waypoint, то вихідний проксі ztunnel виконує балансування навантаження на рівні L4 безпосередньо між цими екземплярами або бекендами сервісу і потім передає трафік через віддалені проксі ztunnel, асоційовані з цими бекендами. Якщо сервіс призначення налаштовано на використання одного або декількох проксі waypoint, то вихідний проксі ztunnel виконує балансування навантаження шляхом розподілу трафіку між цими проксі waypoint і передає трафік через віддалені проксі ztunnel на вузлі, який розміщує екземпляри проксі waypoint.
{{< /tip >}}

Викликаючи сервіс з декількома бекендами, ми можемо перевірити, що трафік клієнтів збалансований між репліками сервісу.

{{< text bash >}}
$ kubectl -n default exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://reviews:9080/; done'
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "outbound"
--snip--
2024-05-04T10:11:04.964851Z info    access  connection complete src.addr=10.244.1.12:35520 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.9:15008 dst.hbone_addr="10.244.1.9:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v3-7d99fd7978-zznnq" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.969578Z info    access  connection complete src.addr=10.244.1.12:35526 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.9:15008 dst.hbone_addr="10.244.1.9:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v3-7d99fd7978-zznnq" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.974720Z info    access  connection complete src.addr=10.244.1.12:35536 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.7:15008 dst.hbone_addr="10.244.1.7:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v1-5fd6d4f8f8-26j92" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.979462Z info    access  connection complete src.addr=10.244.1.12:35552 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.8:15008 dst.hbone_addr="10.244.1.8:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v2-6f9b55c5db-c2dtw" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
{{< /text >}}

Це алгоритм балансування навантаження за схемою Round Robin, який відокремлений і незалежний від будь-якого алгоритму балансування навантаження, що може бути налаштований у полі `TrafficPolicy` ресурсу `VirtualService`. Як вже було згадано, усі аспекти обʼєктів API `VirtualService` реалізуються на проксі waypoint, а не на проксі ztunnel.

### Спостережуваність трафіку в режимі ambient {#observability-of-ambient-mode-traffic}

На додачу до перевірки логів ztunnel та інших зазначених вище варіантів моніторингу, ви також можете використовувати стандартні функції моніторингу та телеметрії Istio для моніторингу трафіку застосунків у режимі ambient панелі даних.

* [Встановлення Prometheus](/docs/ops/integrations/prometheus/#installation)
* [Встановлення Kiali](/docs/ops/integrations/kiali/#installation)
* [Метрики Istio](/docs/reference/config/metrics/)
* [Запити метрик з Prometheus](/docs/tasks/observability/metrics/querying-metrics/)

Якщо сервіс використовує тільки secure overlay, наданий ztunnel, Istio буде повідомляти лише метрики L4 TCP (зокрема, `istio_tcp_sent_bytes_total`, `istio_tcp_received_bytes_total`, `istio_tcp_connections_opened_total`, `istio_tcp_connections_closed_total`). Повний набір метрик Istio та Envoy буде наданий у разі використання проксі waypoint.
