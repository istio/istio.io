---
title: Вимоги до застосунку
description: Вимоги до застосунків, розгорнутих у кластері з підтримкою Istio.
weight: 40
keywords:
  - kubernetes
  - sidecar
  - sidecar-injection
  - deployment-models
  - pods
  - setup
aliases:
  - /uk/docs/setup/kubernetes/spec-requirements/
  - /uk/docs/setup/kubernetes/prepare/spec-requirements/
  - /uk/docs/setup/kubernetes/prepare/requirements/
  - /uk/docs/setup/kubernetes/additional-setup/requirements/
  - /uk/docs/setup/additional-setup/requirements
  - /uk/docs/ops/setup/required-pod-capabilities
  - /uk/help/ops/setup/required-pod-capabilities
  - /uk/docs/ops/prep/requirements
  - /uk/docs/ops/deployment/requirements
owner: istio/wg-environments-maintainers
test: n/a
---

Istio надає широкі функціональні можливості застосункам з мінімальним або взагалі без впливу на код самого застосунку. Багато застосунків у Kubernetes можуть бути розгорнуті в кластері з підтримкою Istio без жодних змін. Однак, є деякі особливості моделі sidecar в Istio, які можуть потребувати спеціальної уваги при розгортанні застосунку з підтримкою Istio. Цей документ описує ці особливості та специфічні вимоги до застосунків з підтримкою Istio.

## Вимоги до podʼів {#pod-requirements}

Щоб бути частиною mesh, podʼи в Kubernetes повинні відповідати таким вимогам:

- **UID застосунку**: Переконайтеся, що ваші podʼи **не** запускають застосунки від імені користувача з ідентифікатором користувача (UID) зі значенням `1337`, оскільки `1337` зарезервований для sidecar proxy.

- **Можливості `NET_ADMIN` та `NET_RAW`**: Якщо [політики безпеки podʼів](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) застосовані у вашому кластері та якщо ви не використовуєте [втулок Istio CNI](/docs/setup/additional-setup/cni/), ваші podʼи повинні мати дозволені можливості `NET_ADMIN` та `NET_RAW`. Контейнери ініціалізації proxy Envoy потребують цих можливостей.

    Щоб перевірити, чи дозволені можливості `NET_ADMIN` та `NET_RAW` для ваших podʼів, вам потрібно перевірити, чи може [обліковий запис сервісу](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) використовувати політику безпеки podʼів, яка дозволяє можливості `NET_ADMIN` та `NET_RAW`. Якщо ви не вказали обліковий запис сервісу в deployment podʼів, podʼи запускаються з використанням службового облікового запису `default` у просторі імен розгортання.

    Щоб вивести перелік можливостей службового облікового запису, замініть `<your namespace>` та `<your service account>` на ваші значення у наступній команді:

    {{< text bash >}}
    $ for psp in $(kubectl get psp -o jsonpath="{range .items[*]}{@.metadata.name}{'\n'}{end}"); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:<your namespace>:<your service account>) = yes ]; then kubectl get psp/$psp --no-headers -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
    {{< /text >}}

    Наприклад, щоб перевірити службовий обліковий запис `default` у просторі імен `default`, виконайте наступну команду:

    {{< text bash >}}
    $ for psp in $(kubectl get psp -o jsonpath="{range .items[*]}{@.metadata.name}{'\n'}{end}"); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:default:default) = yes ]; then kubectl get psp/$psp --no-headers -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
    {{< /text >}}

    Якщо ви бачите `NET_ADMIN` та `NET_RAW` або `*` у списку можливостей однієї з дозволених політик для вашого облікового запису сервісу, ваші podʼи мають дозвіл на запуск контейнерів ініціалізації Istio. В іншому випадку вам доведеться [надати цей дозвіл](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#authorizing-policies).

- **Мітки podʼів**: Рекомендуємо явно оголошувати podʼи з ідентифікатором застосунку та версією, використовуючи мітку podʼа. Ці мітки додають контекстну інформацію до метрик та телеметрії, які збирає Istio. Кожне з цих значень зчитується з кількох міток, впорядкованих від найвищого до найнижчого пріоритету:

  - Назва застосунку: `service.istio.io/canonical-name`, `app.kubernetes.io/name` або `app`.
  - Версія застосунку: `service.istio.io/canonical-revision`, `app.kubernetes.io/version` або `version`.

- **Іменовані порти сервісу**: Порти сервісу можуть бути опціонально названі для явного зазначення протоколу. Дивіться [Вибір протоколу](/docs/ops/configuration/traffic-management/protocol-selection/) для отримання додаткової інформації. Якщо pod належить до кількох [сервісів Kubernetes](https://kubernetes.io/docs/concepts/services-networking/service/), сервіси не можуть використовувати той самий номер порту для різних протоколів, наприклад HTTP і TCP.

## Порти, які використовує Istio {#ports-used-by-istio}

Наступні порти та протоколи використовуються проксі sidecar (Envoy) в Istio.

{{< warning >}}
Щоб уникнути конфліктів портів із sidecar, застосунки не повинні використовувати порти, які використовує Envoy.
{{< /warning >}}

| Порт | Протокол | Опис | Тільки для podʼа |
|----|----|----|----|
| 15000 | TCP | Адмін-порт Envoy (команди/діагностика) | Так |
| 15001 | TCP | Вихідний трафік Envoy | Ні |
| 15002 | TCP | Порт прослуховування для виявлення збоїв | Yes |
| 15004 | HTTP | Порт налагодження | Так |
| 15006 | TCP | Вхідний трафік Envoy | Ні |
| 15008 | HTTP2 | Порт тунелю {{< gloss >}}HBONE{{</ gloss >}} mTLS | Ні |
| 15020 | HTTP | Зібрана телеметрія Prometheus від Istio agent, Envoy та застосунку | Ні |
| 15021 | HTTP | Перевірки справності | Ні |
| 15053 | DNS  | Порт DNS, якщо захоплення включено | Так |
| 15090 | HTTP | Телеметрія Prometheus Envoy | Ні |

Наступні порти та протоколи використовуються панеллю управління Istio (istiod).

| Порт | Протокол | Опис | Лише локальний хост |
|----|----|----|----|
| 443 | HTTPS | Порт служби webhook | Ні |
| 8080 | HTTP | Інтерфейс налагодження (застарілий, лише порт контейнера) | Ні |
| 15010 | GRPC | Служби XDS та CA (Plaintext, лише для безпечних мереж) | Ні |
| 15012 | GRPC | Служби XDS та CA (TLS і mTLS, рекомендовано для промислового використання) | Ні |
| 15014 | HTTP | Моніторинг панелі управління | Ні |
| 15017 | HTTPS | Порт контейнера webhook, переспрямований з 443 | Ні |

## Протоколи "Server First" {#server-first-protocols}

Деякі протоколи є протоколами "Server First", що означає, що сервер надсилає перші байти. Це може вплинути на [`PERMISSIVE`](/docs/reference/config/security/peer_authentication/#PeerAuthentication-MutualTLS-Mode) mTLS та [Автоматичний вибір протоколу](/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection).

Обидві ці функції працюють шляхом перевірки початкових байтів зʼєднання для визначення протоколу, що є несумісним з протоколами "Server First".

Щоб підтримати ці випадки, дотримуйтесь кроків [Явного вибору протоколу](/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection), щоб оголосити протокол застосунку як `TCP`.

Нижче наведені порти, які зазвичай використовують протоколи "Server First", і автоматично вважаються `TCP`:

| Протокол | Порт |
|----------|------|
| SMTP     | 25   |
| DNS      | 53   |
| MySQL    | 3306 |
| MongoDB  | 27017|

Оскільки TLS-комунікація не є "Server First", TLS-зашифрований трафік "Server First" працюватиме з автоматичним визначенням протоколу, якщо ви переконаєтеся, що весь трафік, що підлягає TLS-скануванню, зашифрований:

1. Налаштуйте режим `mTLS` як `STRICT` для сервера. Це забезпечить TLS-шифрування для всіх запитів.
1. Налаштуйте режим `mTLS` як `DISABLE` для сервера. Це відключить TLS-сканування, дозволяючи використовувати протоколи "Server First".
1. Налаштуйте всі клієнти для надсилання трафіку `TLS`, зазвичай через [`DestinationRule`](/docs/reference/config/networking/destination-rule/#ClientTLSSettings) або покладаючись на авто mTLS.
1. Налаштуйте ваш застосунок для прямого надсилання трафіку TLS.

## Вихідний трафік {#outbound-traffic}

Щоб підтримувати можливості маршрутизації трафіку Istio, трафік, що виходить з контейнера, може маршрутизуватися інакше, ніж коли sidecar не розгорнуто.

Для трафіку на основі HTTP маршрутизація базується на заголовку `Host`. Це може призвести до непередбачуваної поведінки, якщо IP-адреса призначення та заголовок `Host` не узгоджені. Наприклад, запит типу `curl 1.2.3.4 -H "Host: httpbin.default"` буде маршрутизовано до сервісу `httpbin`, а не до `1.2.3.4`.

Для не HTTP-трафіку (включаючи HTTPS) Istio не має доступу до заголовка `Host`, тому рішення про маршрутизацію базуються на IP-адресі сервісу.

Одним з наслідків цього є те, що прямі виклики до контейнерів (наприклад, `curl <POD_IP>`), а не до сервісів, не будуть збігатись. Хоча трафік може бути [пропущений](/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services), він не отримає повну функціональність Istio, включаючи шифрування mTLS, маршрутизацію трафіку та телеметрію.

Дивіться сторінку [Маршрутизація трафіку](/docs/ops/configuration/traffic-management/traffic-routing) для отримання додаткової інформації.
