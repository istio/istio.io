---
title: Переконайтеся, що mTLS увімкнено
description: Дізнайтеся, як перевірити, чи ввімкнено mTLS в робочих навантаженях в ambient mesh.
weight: 15
owner: istio/wg-networking-maintainers
test: no
---

Щойно ви додали застосунки до ambient mesh, ви можете легко перевірити, чи ввімкнено mTLS серед ваших навантажень, використовуючи один або кілька методів, наведених нижче:

## Перевірка mTLS за допомогою конфігурацій ztunnel робочого навантаження {#validate-mtls-using-workloads-ztunnel-configurations}

За допомогою зручної команди `istioctl ztunnel-config workloads` ви можете перевірити, чи налаштоване ваше робоче навантаження на надсилання та приймання трафіку HBONE за значенням у стовпці `PROTOCOL`. Наприклад:

{{< text syntax=bash >}}
$ istioctl ztunnel-config workloads
NAMESPACE    POD NAME                                IP         NODE                     WAYPOINT PROTOCOL
default      details-v1-857849f66-ft8wx              10.42.0.5  k3d-k3s-default-agent-0  None     HBONE
default      kubernetes                              172.20.0.3                          None     TCP
default      productpage-v1-c5b7f7dbc-hlhpd          10.42.0.8  k3d-k3s-default-agent-0  None     HBONE
default      ratings-v1-68d5f5486b-b5sbj             10.42.0.6  k3d-k3s-default-agent-0  None     HBONE
default      reviews-v1-7dc5fc4b46-ndrq9             10.42.1.5  k3d-k3s-default-agent-1  None     HBONE
default      reviews-v2-6cf45d556b-4k4md             10.42.0.7  k3d-k3s-default-agent-0  None     HBONE
default      reviews-v3-86cb7d97f8-zxzl4             10.42.1.6  k3d-k3s-default-agent-1  None     HBONE
{{< /text >}}

Наявність сконфігурованого HBONE на вашому навантаженні не означає, що ваше навантаження відкидатиме будь-який трафік у вигляді простого тексту. Якщо ви хочете, щоб ваше навантаження відкидало текстовий трафік, створіть політику `PeerAuthentication` з режимом mTLS, встановленим на `STRICT` для вашого навантаження.

## Перевірка mTLS за допомогою метрик {#validate-mtls-from-metrics}

Якщо ви [встановили Prometheus](/docs/ops/integrations/prometheus/#installation), ви можете налаштувати пересилання портів і відкрити інтерфейс Prometheus за допомогою наступної команди:

{{< text syntax=bash >}}
$ istioctl dashboard prometheus
{{< /text >}}

У Prometheus ви можете переглянути значення метрик TCP. Спочатку виберіть Graph і введіть метрику, наприклад: `istio_tcp_connections_opened_total`, `istio_tcp_connections_closed_total`, `istio_tcp_received_bytes_total` або `istio_tcp_sent_bytes_total`. Нарешті, натисніть Execute. Дані міститимуть такі записи, як:

{{< text syntax=plain >}}
istio_tcp_connections_opened_total{
  app="ztunnel",
  connection_security_policy="mutual_tls",
  destination_principal="spiffe://cluster.local/ns/default/sa/bookinfo-details",
  destination_service="details.default.svc.cluster.local",
  reporter="source",
  request_protocol="tcp",
  response_flags="-",
  source_app="curl",
  source_principal="spiffe://cluster.local/ns/default/sa/curl",source_workload_namespace="default",
  ...}
{{< /text >}}

Переконайтеся, що значення `connection_security_policy` встановлене на `mutual_tls` разом з очікуваною інформацією про ідентичність джерела та призначення.

## Перевірка mTLS за допомогою логів {#validate-mtls-from-logs}

Ви також можете переглянути лог ztunnel на стороні джерела або призначення, щоб підтвердити, що mTLS увімкнено, а також перевірити ідентичність учасників. Нижче наведено приклад логу ztunnel на стороні джерела для запиту від сервісу `curl` до сервісу `details`:

{{< text syntax=plain >}}
2024-08-21T15:32:05.754291Z info access connection complete src.addr=10.42.0.9:33772 src.workload="curl-7656cf8794-6lsm4" src.namespace="default"
src.identity="spiffe://cluster.local/ns/default/sa/curl" dst.addr=10.42.0.5:15008 dst.hbone_addr=10.42.0.5:9080 dst.service="details.default.svc.cluster.local"
dst.workload="details-v1-857849f66-ft8wx" dst.namespace="default" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-details"
direction="outbound" bytes_sent=84 bytes_recv=358 duration="15ms"
{{< /text >}}

Перевірте, чи значення `src.identity` і `dst.identity` правильні. Вони є ідентичностями, які використовуються для mTLS-комунікації між джерелом і призначенням. Дивіться розділ [верифікація трафіку ztunnel через логи](/docs/ambient/usage/troubleshoot-ztunnel/#verifying-ztunnel-traffic-through-logs) для отримання додаткової інформації.

## Перевірка за допомогою панелі Kiali {#validate-with-kiali-dashboard}

Якщо ви встановили Kiali та Prometheus, ви можете візуалізувати комунікацію вашого навантаження в ambient mesh за допомогою панелі Kiali. Ви можете побачити, чи має зʼєднання між будь-якими навантаженнями значок замка, щоб перевірити, чи ввімкнено mTLS, а також перевірити інформацію про ідентичність учасників:

{{< image link="./kiali-mtls.png" caption="Панель Kiali" >}}

Зверніться до документа [Візуалізація застосунку і метрик](/docs/ambient/getting-started/secure-and-visualize/#visualize-the-application-and-metrics) для отримання додаткової інформації.

## Перевірка за допомогою `tcpdump` {#validate-with-tcpdump}

Якщо ви маєте доступ до робочих вузлів Kubernetes, ви можете запустити команду `tcpdump`, щоб перехопити весь трафік на мережевому інтерфейсі, з можливістю фокусування на портах застосунку та портах HBONE. У цьому прикладі, порт `9080` є портом сервісу `details`, а порт `15008` — портом HBONE:

{{< text syntax=bash >}}
$ tcpdump -nAi eth0 port 9080 or port 15008
{{< /text >}}

Ви повинні побачити зашифрований трафік у виводі команди `tcpdump`.

Якщо у вас немає доступу до робочих вузлів, ви можете скористатися [образом контейнера netshoot](https://hub.docker.com/r/nicolaka/netshoot) для зручного запуску команди:

{{< text syntax=bash >}}
$ POD=$(kubectl get pods -l app=details -o jsonpath="{.items[0].metadata.name}")
$ kubectl debug $POD -i --image=nicolaka/netshoot -- tcpdump -nAi eth0 port 9080 or port 15008
{{< /text >}}
