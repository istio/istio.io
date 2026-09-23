---
title: Встановлення компонентів ambient
description: Додайте ztunnel та оновіть CNI для підтримки режиму ambient поряд з наявними sidecars.
weight: 2
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate/before-you-begin
next: /docs/ambient/migrate/migrate-policies
---

Цей крок оновлює ваше встановлення Istio для включення компонентів даних ambient (ztunnel та оновлений CNI), залишаючи всі наявні робочі навантаження sidecar без змін. Ваші sidecars продовжуватимуть обробляти трафік нормально протягом цього кроку.

{{< warning >}}
Не видаляйте інʼєкцію sidecar і не додавайте мітку `istio.io/dataplane-mode=ambient` до жодного простору імен до кроку [Увімкнення режиму ambient](/docs/ambient/migrate/enable-ambient-mode/).
{{< /warning >}}

## Оновлення до профілю ambient {#upgrade-to-the-ambient-profile}

### Використання istioctl {#using-istioctl}

Оновіть ваше поточне встановлення Istio для використання профілю `ambient`. Це додає DaemonSet ztunnel та оновлює втулок CNI для підтримки режиму ambient:

{{< text syntax=bash snip_id=none >}}
$ istioctl upgrade --set profile=ambient
{{< /text >}}

{{< tip >}}
Якщо ви встановлювали Istio з власним `IstioOperator` або прапорцями `--set`, ви можете поєднати їх з профілем ambient. Наприклад: `istioctl upgrade --set profile=ambient --set values.pilot.resources.requests.cpu=500m`
{{< /tip >}}

### Використання Helm {#using-helm}

Якщо ви встановлювали Istio з Helm, оновіть кожен компонент для додавання підтримки ambient:

{{< text syntax=bash snip_id=none >}}
$ helm upgrade istio-base istio/base -n istio-system $ helm upgrade istiod istio/istiod -n istio-system --set profile=ambient $ helm upgrade istio-cni istio/cni -n istio-system --set profile=ambient $ helm install ztunnel istio/ztunnel -n istio-system  # новий компонент, раніше не встановлювався
{{< /text >}}

## Перевірка компонентів ambient {#verify-the-ambient-components}

Після завершення оновлення перевірте, що ztunnel та оновлений CNI запущені:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n istio-system
{{< /text >}}

Ви повинні бачити podʼи DaemonSet `ztunnel`, що запущені на кожному вузлі, крім ваших наявних podʼів Istiod та CNI:

{{< text syntax=plain snip_id=none >}}
NAME                                   READY   STATUS    RESTARTS   AGE
istio-cni-node-...                     1/1     Running   0          2m
istiod-...                             1/1     Running   0          2m
ztunnel-...                            1/1     Running   0          2m
{{< /text >}}

Підтвердьте, що ztunnel запущений як DaemonSet на всіх вузлах:

{{< text syntax=bash snip_id=none >}}
$ kubectl get daemonset ztunnel -n istio-system
{{< /text >}}

## Увімкнення підтримки HBONE в наявних sidecars {#enable-hbone-support-in-existing-sidecars}

Sidecar проксі мають бути перезапущені, щоб підхопити нову конфігурацію `ISTIO_META_ENABLE_HBONE=true`, яку профіль ambient встановлює в `MeshConfig`. Це дозволяє sidecars спілкуватися з робочими навантаженнями режиму ambient за допомогою протоколу HBONE.

Перезапустіть кожен простір імен, що має увімкнену інʼєкцію sidecar, або перезапустіть ваші окремі робочі навантаження на основі вашої стратегії розгортання. Наприклад, для перезапуску простору імен:

{{< text syntax=bash snip_id=none >}}
$ kubectl rollout restart deployment -n <namespace>
$ kubectl rollout status deployment -n <namespace>
{{< /text >}}

Повторіть для кожного простору імен, що містить робочі навантаження, інʼєкція яких була виконана за допомогою sidecar.

Для перевірки, що підтримка HBONE активна на перезапущеному podʼі:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pod <pod-name> -n <namespace> -o json | \
    jq '.spec.initContainers[] | select(.name=="istio-proxy") | .env[] | select(.name=="ISTIO_META_ENABLE_HBONE")'
{{< /text >}}

Вивід має показати:

{{< text syntax=json snip_id=none >}}
{
  "name": "ISTIO_META_ENABLE_HBONE",
  "value": "true"
}
{{< /text >}}

{{< tip >}}
Перезапуск podʼів на цьому етапі не має видимого впливу на трафік. HBONE активується лише коли призначення є робочим навантаженням режиму ambient, а жоден простір імен ще не зараховано.
{{< /tip >}}

## Співпраця sidecar та ambient під час міграції {#sidecar-and-ambient-interoperability-during-migration}

Коли pod з інʼєкцією sidecar спілкується з робочим навантаженням, яке вже переміщене в режим ambient, sidecar використовує протокол HBONE для тунелювання трафіку безпосередньо до ztunnel podʼа призначення.

Практичним наслідком є те, що L7 політики на waypoint (такі як правила `HTTPRoute` або `AuthorizationPolicy` з `targetRefs`) **не застосовуються** для трафіку, що надходить від робочих навантажень режиму sidecar під час періоду міграції. Sidecar застосовує власну L7 логіку перед надсиланням, але waypoint ніколи не маршрутизує цей трафік. Це означає, що L7 політики не будуть застосовані двічі, оскільки sidecar обробляє власні рішення щодо маршрутизації, а HBONE тунель доставляє трафік безпосередньо до призначення без повторної обробки на waypoint.

{{< warning >}}
Якщо ви використовуєте політику запобігання обходу waypoint (політику DENY, що відхиляє трафік, що не походить від waypoint), ця політика також відхилить трафік від робочих навантажень режиму sidecar, оскільки вони обходять waypoint. Див. [Запобігання обходу waypoint](/docs/ambient/migrate/migrate-policies/#prevent-waypoint-bypass) для порад щодо обробки цього під час інкрементальної міграції.
{{< /warning >}}

## Розгортання waypoint проксі (опціонально) {#deploy-waypoint-proxies-optional}

{{< tip >}}
Пропустіть цю секцію, якщо вам потрібні лише mTLS L4 та політики авторизації. Waypoints потрібні лише для функцій L7. Див. [Міграція політик](/docs/ambient/migrate/migrate-policies/) щоб визначити, чи потрібні вони вам.
{{< /tip >}}

Для просторів імен, що вимагають функцій L7, розгорніть waypoint проксі зараз. Waypoint буде налаштований, але **ще не активований**, трафік продовжуватиме йти через sidecars.

Розгорніть waypoint на рівні простору імен за допомогою `istioctl`:

{{< text syntax=bash snip_id=none >}}
$ istioctl waypoint apply -n <namespace>
{{< /text >}}

Перевірте, що pod waypoint запущений:

{{< text syntax=bash snip_id=none >}}
$ kubectl get gateway waypoint -n <namespace>
$ kubectl get pods -n <namespace> -l gateway.istio.io/managed=istio.io-mesh-controller
{{< /text >}}

{{< warning >}}
**Не** додавайте мітку `istio.io/use-waypoint` до жодного простору імен чи сервісу ще. Активація waypoints до видалення sidecars може спричинити подвійну обробку трафіку. Зачекайте до кроку [Увімкнення режиму ambient](/docs/ambient/migrate/enable-ambient-mode/).
{{< /warning >}}

Для отримання додаткових деталей щодо опцій конфігурації waypoint (на рівні сервісу, робочого навантаження або cross-namespace waypoints), див. [Використання waypoint проксі](/docs/ambient/usage/waypoint/).

## Наступні кроки {#next-steps}

Перейдіть до [Міграція політик](/docs/ambient/migrate/migrate-policies/) для оновлення ваших політик трафіку та авторизації для режиму ambient.

Якщо у вас немає ресурсів `VirtualService` або `DestinationRule`, а ваші ресурси `AuthorizationPolicy` використовують лише правила L4 (без відповідності HTTP метод/шлях/заголовок), пропустіть ту сторінку і перейдіть безпосередньо до [Увімкнення режиму ambient](/docs/ambient/migrate/enable-ambient-mode/).
