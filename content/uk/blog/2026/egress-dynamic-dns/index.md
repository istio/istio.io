---
title: "Спрощення маршрутизації egress до універсальних призначень"
description: "Istio тепер підтримує універсальні ServiceEntry з DYNAMIC_DNS resolution, що дозволяє sidecars напряму маршрутизувати трафік до універсальних HTTPS-призначень, спрощуючи конфігурацію egress."
publishdate: 2026-04-09
attribution: "Rudrakh Panigrahi (Salesforce)"
keywords: [traffic-management,gateway,mesh,egress,wildcard,service-entry,ambient,waypoint]
---

## Огляд {#overview}

Контроль трафіку egress є поширеною вимогою в розгортаннях service mesh. Багато організацій налаштовують свою mesh так, щоб дозволяти лише явно зареєстровані зовнішні сервіси, встановлюючи:

{{< text plain >}}
meshConfig.outboundTrafficPolicy.mode = REGISTRY_ONLY
{{< /text >}}

З такою конфігурацією будь-яке зовнішнє призначення має бути зареєстроване в mesh за допомогою ресурсів, таких як `ServiceEntry` з повністю кваліфікованими доменними іменами та типом визначення DNS.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-wikipedia-https
  namespace: istio-system
spec:
  hosts:

- "www.wikipedia.org"
  ports:
- name: tls
    number: 443
    protocol: TLS
  location: MESH_EXTERNAL
  resolution: DNS
  exportTo:
- "*"
{{< /text >}}

Однак деякі зовнішні сервіси мають багато динамічних піддоменів, до яких застосунки можуть потребувати доступу, наприклад:

{{< text plain >}}
<https://en.wikipedia.org>
<https://de.wikipedia.org>
<https://upload.wikipedia.org>
{{< /text >}}

У міру зростання списку імен хостів реєстрація кожного окремо швидко стає непрактичною для керування та масштабування. Щоб вирішити цю проблему, Istio потребує підтримки реєстрації універсальних імен хостів.

## Чому універсальний HTTPS-egress є складним {#why-wildcard-https-egress-is-difficult}

Коли робоче навантаження ініціює HTTPS-зʼєднання, імʼя хосту призначення передається в TLS-handshake через поле **Server Name Indication (SNI)**.

Наприклад, клієнт, що викликає `https://en.wikipedia.org`, надсилає імʼя хосту `en.wikipedia.org` у полі ClientHello SNI під час TLS-handshake. Sidecars Istio перехоплюють вихідні зʼєднання та визначають, чи зареєстроване призначення і як його слід маршрутизувати.

Однак модель маршрутизації Istio зазвичай вимагає, щоб upstream-призначення було відоме заздалегідь. Навіть якщо у правилах маршрутизації використовується універсальне співпадіння, кінцевий upstream-кластер все одно має відповідати статично налаштованому сервісу. Оскільки різні піддомени можуть припадати на різні точки доступу, маршрутизація безпосередньо до універсальних хостів історично була непростою.

## Маршрутизація SNI через Egress Gateway {#sni-routing-via-egress-gateway}

Цю проблему раніше було розглянуто в блозі Istio [Маршрутизація egress-трафіку до універсальних призначень](/blog/2023/egress-sni/). Архітектура включала налаштування спеціального egress gateway, який працював як SNI forward proxy.

{{< image width="90%" link="./egress-sni-flow.svg" alt="Маршрутизація SNI через універсальні імена хостів" title="Маршрутизація SNI через універсальні імена хостів" caption="Застосунок → sidecar → egress gateway → перевірка SNI → зовнішнє призначення" >}}

Діаграма вище була вперше опублікована в блозі Istio [Маршрутизація egress-трафіку до універсальних призначень](/blog/2023/egress-sni/).

Як показано вище:

1. Застосунок ініціює HTTPS-зʼєднання.
1. Sidecar-проксі перехоплює це зʼєднання та ініціює внутрішнє mTLS-зʼєднання до egress gateway.
1. Gateway термінує це внутрішнє mTLS-зʼєднання.
1. Внутрішній слухач перевіряє значення SNI з оригінального TLS-handshake.
1. Трафік динамічно пересилається до імені хосту, отриманого з SNI.

Реалізація цього вимагала кількох спеціальних ресурсів:

- `ServiceEntry` та `VirtualService` для пересилання трафіку універсальних доменів до egress gateway.
- `DestinationRule` для mTLS між sidecar-проксі та gateway.
- Конфігурація `EnvoyFilter`, яка дозволяє egress gateway виконувати динамічну пересилку SNI, безумовно, найскладніша частина цього рішення. Фільтр розширює gateway, використовуючи низькорівневі можливості Envoy, вводячи три елементи: **патч до TCP-проксі gateway**, який маршрутизує трафік до внутрішнього слухача, **інспектор SNI у слухачі** для витягування SNI з TLS ClientHello та **динамічний кластер форвард-проксі** для виконання динамічного DNS-розвʼязання SNI.

Хоча цей підхід працює, він вводить додатковий мережевий перехід і додатковий рівень внутрішнього mTLS для цього переходу. Він також додає операційну складність через велику кількість необхідної спеціальної конфігурації, якою може бути важко керувати та яка схильна до помилок. Але останні покращення дозволяють досягти того самого результату з набагато простішою конфігурацією.

## `ServiceEntry` із символами-замінниками та розпізнаванням `DYNAMIC_DNS`{#wildcard-serviceentry-with-dynamic_dns-resolution}

Istio тепер підтримує універсальні імена хостів із розпізнаванням `DYNAMIC_DNS` у `ServiceEntry`, що дозволяє sidecar-проксі напряму маршрутизувати універсальний вихідний TLS-трафік без необхідності в egress gateway.

Наприклад, наступна конфігурація дозволяє доступ до всіх точок доступу `*.wikipedia.org`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-wildcard-https
  namespace: istio-system
spec:
  hosts:

- "*.wikipedia.org"
  ports:
- name: tls
    number: 443
    protocol: TLS
  location: MESH_EXTERNAL
  resolution: DYNAMIC_DNS
  exportTo:
- "*"
{{< /text >}}

Після застосування цього ресурсу, робочі навантаження в мережі можуть підключатися до будь-якого відповідного піддомену через цей `ServiceEntry`.

{{< text bash >}}
$ kubectl exec $POD_NAME -n default -c ratings -- curl -sS -o /dev/null -w "HTTP %{http_code}\n" <https://de.wikipedia.org> && echo "Checking stats after request..." && kubectl exec $POD_NAME -c istio-proxy -- curl -s localhost:15000/clusters | grep "outbound|443||\*\.wikipedia\.org" | grep -E "rq|cx"

HTTP 200
Checking stats after request...
outbound|443||*.wikipedia.org::142.251.223.228:443::cx_active::0
outbound|443||*.wikipedia.org::142.251.223.228:443::cx_connect_fail::0
outbound|443||*.wikipedia.org::142.251.223.228:443::cx_total::3
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_active::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_error::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_success::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_timeout::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_total::3
{{< /text >}}

### Як працює конфігурація {#how-the-configuration-works}

{{< image width="90%" link="./egress-dynamic-dns.svg" alt="ServiceEntry із символами-замінниками та розпізнаванням DYNAMIC_DNS" title="ServiceEntry із символами-замінниками та розпізнаванням DYNAMIC_DNS" caption="Застосунок → sidecar → зовнішня точка доступу" >}}

`ServiceEntry` із символами-замінниками та `resolution: DYNAMIC_DNS` призводить до того, що Istio створює [динамічний кластер форвард-проксі (DFP)](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/clusters/dynamic_forward_proxy/v3/cluster.proto#envoy-v3-api-msg-extensions-clusters-dynamic-forward-proxy-v3-clusterconfig), який пересилає TLS-зʼєднання на основі імені хосту в полі SNI. Спочатку універсальний хост (наприклад, `*.wikipedia.org`) реєструється в реєстрі сервісів mesh, що дозволяє sidecar маршрутизувати вихідні запити з іменами хостів, що відповідають шаблону. Коли робоче навантаження ініціює TLS-зʼєднання, інспектор SNI у слухачі налаштований на зчитування значення SNI з рукостискання. Потім кластер DFP використовує його як імʼя хоста upstream для пересилання зʼєднання. Це ефективно дозволяє універсальний HTTPS-egress, дозволяючи проксі динамічно розвʼязувати та пересилати зʼєднання до відповідних піддоменів без необхідності статичної конфігурації точок доступу. При цьому зберігається TLS-сесія, ініційована клієнтом, пересилаючи зашифрований трафік без змін.

## Інші випадки використання {#other-use-cases}

Цей підхід підходить для випадків використання, коли застосунки потребують підключення до універсальних доменів, одночасно отримуючи можливості спостереження та стійкості mesh.

### Трафік egress в режимі Ambient {#egress-traffic-in-ambient-mode}

У [ambient mesh](/docs/ambient/overview/) вузловий ztunnel обробляє трафік L4, а необовʼязковий [waypoint proxy](/docs/ambient/usage/waypoint/) може застосовувати політику L7 та телеметрію, коли він явно приєднаний. Щоб обробляти egress через waypoint, наприклад, щоб зберегти послідовний шлях політики для викликів до багатьох точок доступу сервісів AWS, `ServiceEntry` можна позначити `istio.io/use-waypoint`, щоб панель управління направляла відповідний трафік через зазначений waypoint `Gateway`.

Приклад нижче реєструє `*.amazonaws.com` як зовнішній TLS (`443`) ServiceEntry та привʼязує його до waypoint gateway з імʼям `waypoint`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: amazonaws-wildcard
  namespace: istio-system
  labels:
    istio.io/use-waypoint: waypoint # attached to a waypoint gateway
spec:
  exportTo:

- .
  hosts:
- '*.amazonaws.com'
  location: MESH_EXTERNAL
  ports:
- name: tls
    number: 443
    protocol: TLS
  resolution: DYNAMIC_DNS
{{< /text >}}

### Трафік до невідомих внутрішніх призначень {#traffic-to-unknown-internal-destinations}

Клієнт може мати в конфігурації лише обмежену кількість сервісів, але все одно потребувати mTLS-зʼєднання з іншими внутрішніми сервісами. Налаштування таке:

- Ресурс `Sidecar`, який обмежує egress-хости сервісу ratings до простору імен `istio-system`, тобто він не може викликати сервіс details безпосередньо:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata:
  name: restrict-default
  namespace: default
spec:
  workloadSelector:
    labels:
      app: ratings
  egress:

- hosts:
  - "istio-system/*"
{{< /text >}}

- `ServiceEntry`, який визначає універсальний сервіс для інших внутрішніх сервісів:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: internal-wildcard-http
  namespace: istio-system
spec:
  hosts:

- "*.svc.cluster.local"
  ports:
- name: http
    number: 9080
    protocol: HTTP
  location: MESH_INTERNAL
  resolution: DYNAMIC_DNS
  exportTo:
- "*"
{{< /text >}}

- `DestinationRule`, який визначає mTLS-конфігурацію для цього `ServiceEntry`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: internal-wildcard-dr
  namespace: istio-system
spec:
  host: "*.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: MUTUAL_TLS # needs DNS SAN in cert
  exportTo:

- "*"
{{< /text >}}

Сервіс ratings тепер може викликати інші сервіси в mesh, навіть якщо він не має їх у своїй конфігурації, динамічно визначаючи імʼя хосту за допомогою DNS:

{{< text bash >}}
$ kubectl exec $POD_NAME -n default -c ratings -- curl -sS -o /dev/null -w "HTTP %{http_code}\n" details.default.svc.cluster.local:9080/details/0 && echo "Checking stats after request..." && kubectl exec $POD_NAME -c istio-proxy -- curl -s localhost:15000/clusters | grep "outbound|9080||\*\.svc\.cluster\.local" | grep -E "rq_total|rq_success"

Making test request...
HTTP 200
Checking stats after request...
outbound|9080||*.svc.cluster.local::10.96.35.238:9080::rq_success::1
outbound|9080||*.svc.cluster.local::10.96.35.238:9080::rq_total::1
{{< /text >}}

Примітка: mTLS у цьому випадку потребує, щоб сертифікати мали DNS SAN, оскільки динамічний форвард-проксі Envoy використовує імʼя хосту для автоматичної перевірки SAN.

## Висновок {#conclusion}

Проксі sidecar Istio тепер можуть безпосередньо обробляти HTTP- та TLS-трафік egress до універсальних доменів завдяки підтримці універсальних `ServiceEntry` та розвʼязуванню `DYNAMIC_DNS`. Це спрощує конфігурацію та забезпечує більш прямий шлях запиту, зменшуючи затримку за рахунок усунення проміжного переходу через egress gateway, при цьому зберігаючи наявні механізми безпеки та контролю політик.

## Джерела {#references}

- [Routing egress traffic to wildcard destinations](/blog/2023/egress-sni/)
- [SNI dynamic forward proxy - Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/sni_dynamic_forward_proxy_filter)
- [HTTP dynamic forward proxy - Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_proxy#arch-overview-http-dynamic-forward-proxy)
