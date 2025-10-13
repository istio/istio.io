---
title: Проксіювання DNS
description: Як налаштувати проксіювання DNS.
weight: 65
keywords: [traffic-management,dns,virtual-machine]
owner: istio/wg-networking-maintainers
test: yes
---

Окрім перехоплення трафіку застосунків, Istio також може перехоплювати DNS-запити для покращення продуктивності та зручності використання вашої mesh-мережі. При проксіюванні DNS усі DNS-запити з застосунку будуть перенаправлені на sidecar або проксі ztunnel, який зберігає локальне відображення доменних імен на IP-адреси. Якщо запит може бути оброблений проксі, він безпосередньо поверне відповідь застосунку, уникаючи запиту до upstream DNS-сервера. В іншому випадку запит пересилається на upstream відповідно до стандартної конфігурації DNS з `/etc/resolv.conf`.

Хоча Kubernetes забезпечує DNS-резолюцію для Kubernetes `Service`ів "із коробки", будь-які користувацькі `ServiceEntry` не будуть розпізнані. Завдяки цій функції адреси `ServiceEntry` можуть бути розвʼязані без необхідності налаштування DNS-сервера. Для Kubernetes `Service`ів відповідь DNS залишиться такою ж, але зменшиться навантаження на `kube-dns` і підвищиться продуктивність.

Ця функціональність також доступна для сервісів, що працюють за межами Kubernetes. Це означає, що всі внутрішні сервіси можуть бути розвʼязані без громіздких обхідних рішень для експонування DNS-записів Kubernetes поза межами кластера.

## Початок роботи {#getting-started}

Istio зазвичай маршрутизує трафік на основі HTTP-заголовків. Якщо маршрутизація на основі HTTP-заголовка неможлива, в ambient режимі або з TCP-трафіком у режимі sidecar, можна увімкнути проксіювання DNS.

В ambient режимі ztunnel бачить трафік лише на рівні 4 і не має доступу до HTTP-заголовків. Тому проксіювання DNS необхідне для розвʼязання адрес `ServiceEntry`, особливо у випадку [надсилання вихідного трафіку до waypoints](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient#scenario-ztunnel-is-not-sending-egress-traffic-to-waypoints).

### Ambient режим {#ambient-mode}

Проксіювання DNS увімкнено стандартно в ambient режимі починаючи з Istio 1.25.

Для версій до 1.25 ви можете увімкнути перехоплення DNS, встановивши `values.cni.ambient.dnsCapture=true` та `values.pilot.env.PILOT_ENABLE_IP_AUTOALLOCATE=true` під час інсталяції.

### Режим sidecar {#sidecar-mode}

Ця функція наразі не увімкнена стандартно. Щоб її ввімкнути, встановіть Istio з такими налаштуваннями:

{{< text bash >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        # Увімкнути базове проксіювання DNS
        ISTIO_META_DNS_CAPTURE: "true"
EOF
{{< /text >}}

Її також можна ввімкнути на рівні окремих pod за допомогою анотації [`proxy.istio.io/config`](/docs/reference/config/annotations/):

{{< text syntax=yaml snip_id=none >}}
kind: Deployment
metadata:
  name: curl
spec:
...
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |
          proxyMetadata:
            ISTIO_META_DNS_CAPTURE: "true"
...
{{< /text >}}

{{< tip >}}
При розгортанні на віртуальній машині за допомогою [`istioctl workload entry configure`](/docs/setup/install/virtual-machine/) базове проксіювання DNS буде стнадартно ввімкнене.
{{< /tip >}}

## Перехоплення DNS в дії {#dns-capture-in-action}

Щоб спробувати перехоплення DNS, спочатку налаштуйте `ServiceEntry` для деякого зовнішнього сервісу:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-address
spec:
  addresses:
  - 198.51.100.1
  hosts:
  - address.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
EOF
{{< /text >}}

Запустіть клієнтський застосунок для ініціації DNS-запиту:

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled --overwrite
$ kubectl apply -f @samples/curl/curl.yaml@
{{< /text >}}

Без перехоплення DNS запит до `address.internal`, ймовірно, не буде успішно розвʼязаний. Після ввімкнення цієї функції ви маєте отримати відповідь на основі налаштованої `address`:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -sS -v address.internal
*   Trying 198.51.100.1:80...
{{< /text >}}

## Автоматичний розподіл адрес {#address-auto-allocation}

У наведеному вище прикладі у вас була заздалегідь визначена IP-адреса для сервісу, на який було надіслано запит. Однак часто виникає необхідність доступу до зовнішніх сервісів, які не мають стабільних адрес і натомість використовують DNS. У цьому випадку DNS-проксі не матиме достатньо інформації для повернення відповіді та має переслати DNS-запит upstream.

Це особливо проблематично з TCP-трафіком. На відміну від HTTP-запитів, які маршрутизуються на основі заголовків `Host`, TCP містить значно менше інформації; ви можете маршрутизувати лише за IP-адресою призначення і номером порту. Оскільки ви не маєте стабільної IP-адреси для backend, маршрутизація на основі цієї адреси також неможлива, що залишає лише номер порту, що призводить до конфліктів, коли кілька `ServiceEntry` для TCP-сервісів використовують один і той самий порт. Зверніться до [наступного розділу](#external-tcp-services-without-vips) для отримання детальнішої інформації.

Щоб обійти ці проблеми, DNS-проксі додатково підтримує автоматичний розподіл адрес для `ServiceEntry`, які явно не визначають адресу. Відповідь DNS включатиме унікальну автоматично призначену адресу для кожного `ServiceEntry`. Проксі налаштовується для відповідності запитам до цієї IP-адреси та пересилає запит до відповідного `ServiceEntry`. При використанні `ISTIO_META_DNS_AUTO_ALLOCATE` Istio автоматично розподілятиме нерозвʼязувані VIP (з підмережі Class E) для таких сервісів, якщо вони не використовують узагальнений хост. Агент Istio на sidecar використовуватиме VIP як відповіді на запити DNS-запитів з застосунку. Envoy тепер може чітко розрізняти трафік, спрямований на кожен зовнішній TCP-сервіс, і пересилати його до правильного призначення.

{{< warning >}}
Оскільки ця функція змінює відповіді DNS, вона може бути несумісною з деякими застосунками.
{{< /warning >}}

Щоб спробувати це, налаштуйте інший `ServiceEntry`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-auto
spec:
  hosts:
  - auto.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

Тепер надішліть запит:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -sS -v auto.internal
*   Trying 240.240.0.1:80...
{{< /text >}}

Як бачите, запит було надіслано на автоматично призначену адресу, `240.240.0.1`. Ці адреси будуть вибиратися з зарезервованого діапазону IP-адрес `240.240.0.0/16`, щоб уникнути конфліктів із реальними сервісами.

Користувачі також можуть гнучко налаштувати більш детальну конфігурацію, додавши мітку `networking.istio.io/enable-autoallocate-ip="true/false"` для свого `ServiceEntry`. Ця мітка визначає, чи має `ServiceEntry`, для якого не вказано жодної `spec.addresses`, автоматично отримувати IP-адресу.

Щоб спробувати це, оновіть `ServiceEntry` міткою відмови:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-auto
  labels:
    networking.istio.io/enable-autoallocate-ip: "false"
spec:
  hosts:
  - auto.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

Тепер надішліть запит і переконайтеся, що автоматичне виділення ресурсів більше не відбувається:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -sS -v auto.internal
* Could not resolve host: auto.internal
* Store negative name resolve for auto.internal:80
* shutting down connection #0
{{< /text >}}

## Зовнішні TCP сервіси без VIP {#external-tcp-services-without-vips}

Стандартно в Istio існує обмеження під час маршрутизації зовнішнього TCP-трафіку, оскільки він не може розрізняти кілька TCP-сервісів на одному порту. Це обмеження особливо помітне при використанні сторонніх баз даних, таких як AWS Relational Database Service або будь-якого налаштування баз даних з географічною надмірністю. Подібні, але різні зовнішні TCP-сервіси не можуть бути стандартно оброблені окремо. Щоб sidecar міг розрізняти трафік між двома різними TCP-сервісами, які знаходяться поза мережею, сервіси повинні бути на різних портах або мати глобально унікальні VIP-адреси.

Наприклад, якщо у вас є два зовнішні сервіси баз даних, `mysql-instance1` і `mysql-instance2`, і ви створите записи сервісів для обох, sidecarʼи клієнтів все одно матимуть єдиного слухача на `0.0.0.0:{port}`, який шукатиме IP-адресу лише для `mysql-instance1` через публічні DNS-сервери та передаватиме трафік на нього. Він не може маршрутизувати трафік до `mysql-instance2`, оскільки не має способу розрізнити, чи трафік, що надходить на `0.0.0.0:{port}`, призначений для `mysql-instance1` чи `mysql-instance2`.

У наступному прикладі показано, як проксіювання DNS можна використати для розвʼязання цієї проблеми. Віртуальна IP-адреса буде призначена кожному запису сервісу, щоб sidecarʼи клієнтів могли чітко розрізняти трафік, що надходить для кожного зовнішнього TCP-сервісу.

1. Оновіть конфігурацію Istio, зазначену в розділі [Початок роботи](#getting-started), щоб також налаштувати `discoverySelectors`, які обмежують mesh просторами назв із ввімкненим `istio-injection`. Це дозволить використовувати будь-які інші простори назв у кластері для запуску TCP-сервісів поза мережею.

    {{< text bash >}}
    $ cat <<EOF | istioctl install -y -f -
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        defaultConfig:
          proxyMetadata:
            # Увімкніть базове проксіювання DNS
            ISTIO_META_DNS_CAPTURE: "true"
        # конфігурація discoverySelectors нижче використовується лише для симуляції сценарію зовнішнього сервісу TCP,
        # щоб нам не потрібно було використовувати зовнішній сайт для тестування.
        discoverySelectors:
        - matchLabels:
            istio-injection: enabled
    EOF
    {{< /text >}}

2. Розгорніть перший зовнішній демонстраційний TCP-застосунок:

    {{< text bash >}}
    $ kubectl create ns external-1
    $ kubectl -n external-1 apply -f samples/tcp-echo/tcp-echo.yaml
    {{< /text >}}

3. Розгорніть другий зовнішній демонстраційний TCP-застосунок:

    {{< text bash >}}
    $ kubectl create ns external-2
    $ kubectl -n external-2 apply -f samples/tcp-echo/tcp-echo.yaml
    {{< /text >}}

4. Налаштуйте `ServiceEntry` для доступу до зовнішніх сервісів:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: external-svc-1
    spec:
      hosts:
      - tcp-echo.external-1.svc.cluster.local
      ports:
      - name: external-svc-1
        number: 9000
        protocol: TCP
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: external-svc-2
    spec:
      hosts:
      - tcp-echo.external-2.svc.cluster.local
      ports:
      - name: external-svc-2
        number: 9000
        protocol: TCP
      resolution: DNS
    EOF
    {{< /text >}}

5. Перевірте, чи слухачі налаштовані окремо для кожного сервісу на стороні клієнта:

    {{< text bash >}}
    $ istioctl pc listener deploy/curl | grep tcp-echo | awk '{printf "ADDRESS=%s, DESTINATION=%s %s\n", $1, $4, $5}'
    ADDRESS=240.240.105.94, DESTINATION=Cluster: outbound|9000||tcp-echo.external-2.svc.cluster.local
    ADDRESS=240.240.69.138, DESTINATION=Cluster: outbound|9000||tcp-echo.external-1.svc.cluster.local
    {{< /text >}}

## Автоматичний розподіл DNS V2 {#dns-auto-allocation-v2}

Istio тепер пропонує розширену реалізацію автоматичного розподілу DNS. Щоб скористатися новою функцією, замініть прапорець `MeshConfig` `ISTIO_META_DNS_AUTO_ALLOCATE`, який було використано у попередньому прикладі, на змінну пілотного середовища `PILOT_ENABLE_IP_AUTOALLOCATE` під час встановлення Istio. Всі приклади, наведені до цього часу, працюватимуть як є.

{{< text bash >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      env:
        # Вмикання автоматичного присвоєння адреси, необовʼязково
        PILOT_ENABLE_IP_AUTOALLOCATE: "true"
  meshConfig:
    defaultConfig:
      proxyMetadata:
        # Активація базового проксі-сервера DNS
        ISTIO_META_DNS_CAPTURE: "true"
    # конфігурація discoverySelectors, наведена нижче, використовується лише для імітації сценарію зовнішнього сервісу TCP,
    # щоб нам не довелося використовувати зовнішній сайт для тестування.
    discoverySelectors:
    - matchLabels:
        istio-injection: enabled
EOF
{{< /text >}}

Користувачі також можуть гнучко налаштувати більш детальну конфігурацію, додавши мітку `networking.istio.io/enable-autoallocate-ip="true/false"` до свого `ServiceEntry`. Ця мітка визначає, чи має `ServiceEntry`, для якого не вказано жодної `spec.addresses`, автоматично отримувати IP-адресу.

Щоб спробувати це, оновіть наявний `ServiceEntry` міткою відмови:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-auto
  labels:
    networking.istio.io/enable-autoallocate-ip: "false"
spec:
  hosts:
  - auto.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

Тепер надішліть запит і переконайтеся, що автоматичний розподіл більше не відбувається:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -sS -v auto.internal
* Could not resolve host: auto.internal
* Store negative name resolve for auto.internal:80
* shutting down connection #0
{{< /text >}}

## Очищення {#cleanup}

{{< text bash >}}
$ kubectl -n external-1 delete -f @samples/tcp-echo/tcp-echo.yaml@
$ kubectl -n external-2 delete -f @samples/tcp-echo/tcp-echo.yaml@
$ kubectl delete -f @samples/curl/curl.yaml@
$ istioctl uninstall --purge -y
$ kubectl delete ns istio-system external-1 external-2
$ kubectl label namespace default istio-injection-
{{< /text >}}
