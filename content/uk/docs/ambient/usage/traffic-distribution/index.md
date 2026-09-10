---
title: Розподіл трафіку
description: Керуйте тим, як трафік розподіляється до точок доступу в режимі ambient.
weight: 35
owner: istio/wg-networking-maintainers
test: no
---

Анотація `networking.istio.io/traffic-distribution` контролює те, як {{< gloss >}}ztunnel{{< /gloss >}} розподіляє трафік між доступними точками доступу. Це корисно для збереження трафіку локальним для зменшення затримки та витрат на перехресні зони.

## Підтримувані значення {#supported-values}

| Значення | Поведінка |
| --- | --- |
| `PreferSameZone` | Пріоритезуйте точки доступу за близькістю: мережа, регіон, зона, потім підзона. Трафік йде до найближчих справних точок доступу першими. |
| `PreferClose` | Застарілий псевдонім для `PreferSameZone`. Див. [Kubernetes enhancement proposal 3015](https://github.com/kubernetes/enhancements/tree/master/keps/sig-network/3015-prefer-same-node). |
| `PreferSameNode` | Перевага точкам доступу на тому самому вузлі, що й клієнт. |
| (не встановлено) | Без пріоритету локальності. Трафік розподіляється між усіма справними точками доступу. |

## Застосування анотації {#applying-the-annotation}

Анотацію можна застосувати до:

- **`Service`**: Впливає на трафік до цього конкретного сервісу
- **`Namespace`**: Встановлює стандартне значення для всіх сервісів у просторі імен
- **`ServiceEntry`**: Впливає на трафік до зовнішніх сервісів

### Пріоритет {#precedence}

Коли налаштовано кілька рівнів, виграє найспецифічніший:

1. Поле `spec.trafficDistribution` (тільки `Service`)
1. Анотація на `Service`/`ServiceEntry`
1. Анотація на `Namespace`
1. Стандартна поведінка (без пріоритету локальності)

## Приклади {#examples}

### Конфігурація на рівні сервісу {#per-service-configuration}

Застосуйте до окремого сервісу:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
spec:
  selector:
    app: my-app
  ports:
  - port: 80
{{< /text >}}

### Конфігурація на рівні простору імен {#namespace-wide-configuration}

Застосуйте до всіх сервісів у просторі імен:

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
{{< /text >}}

Сервіси в просторі імен наслідують це налаштування, якщо у них немає власної анотації.

### Перевизначення стандартних значень простору імен {#override-namespace-default}

Сервіс може перевизначити налаштування простору імен власною анотацією:

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
---
apiVersion: v1
kind: Service
metadata:
  name: different-service
  namespace: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameNode
spec:
  selector:
    app: different-app
  ports:
  - port: 80
{{< /text >}}

Сервіси без анотації наслідують налаштування простору імен.

## Поведінка {#behavior}

### `PreferSameZone`

З `PreferSameZone`, ztunnel категоризує точки доступу за локальністю та маршрутизує трафік до найближчих справних точок доступу:

1. Та сама мережа, регіон, зона та підзона
2. Та сама мережа, регіон та зона
3. Та сама мережа та регіон
4. Та сама мережа
5. Будь-яка доступна кінцева точка

Якщо всі точки доступу в ближчій локальності стають несправними, трафік автоматично переключається на наступний рівень.

Наприклад, сервіс з точками доступу в зонах `us-west`, `us-west` та `us-east`:

- Клієнт у `us-west` надсилає весь трафік до двох точок доступу `us-west`
- Якщо одна точка доступу `us-west` вийде з ладу, трафік йде до залишкової точки доступу `us-west`
- Якщо обидві точки доступу `us-west` вийдуть з ладу, трафік переключається на `us-east`

### `PreferSameNode`

З `PreferSameNode`, ztunnel переважає кінцеві точки, що запущені на тому самому Kubernetes вузлі, що й клієнт. Це мінімізує мережеві хопи та затримку для вузлово-локального звʼязку.

## Звʼязок з Kubernetes `trafficDistribution` {#relationship-to-kubernetes-trafficdistribution}

Kubernetes 1.31 ввів поле [`spec.trafficDistribution`](https://kubernetes.io/docs/concepts/services-networking/service/#traffic-distribution) на `Service`ах. Ця анотація Istio надає ту саму функціональність з додатковими перевагами:

| | `spec.trafficDistribution` | Анотація |
| --- | --- | --- |
| Версія Kubernetes | 1.31+ | Будь-яка |
| `Service` | Так | Так |
| `ServiceEntry` | Ні | Так |
| `Namespace` | Ні | Так |

Коли і поле spec, і анотація встановлені на `Service`, поле spec має пріоритет.

Waypoints автоматично конфігурують цю анотацію.

## Дивіться також {#see-also}

- [Балансування навантаження за локацією](/docs/tasks/traffic-management/locality-load-balancing/) для маршрутизації за локальністю на основі sidecar
- [Довідник анотацій](/docs/reference/config/annotations/#NetworkingTrafficDistribution)
