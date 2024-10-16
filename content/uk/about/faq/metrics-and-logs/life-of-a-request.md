---
title: Як дізнатися, що сталося з запитом в Istio?
weight: 80
---

Ви можете включити [трейсинг](/docs/tasks/observability/distributed-tracing/), щоб визначити маршрут запиту в Istio.

Додатково, ви можете використовувати такі команди, щоб дізнатися більше про стан мережі:

* [`istioctl proxy-config`](/docs/reference/commands/istioctl/#istioctl-proxy-config): Отримати інформацію про конфігурацію проксі, коли ви працюєте в Kubernetes:

    {{< text plain >}}
    # Отримати інформацію про конфігурацію bootstrap для екземпляра Envoy у вказаному podʼі.
    $ istioctl proxy-config bootstrap productpage-v1-bb8d5cbc7-k7qbm

    # Отримати інформацію про конфігурацію кластера для екземпляра Envoy у вказаному podʼі.
    $ istioctl proxy-config cluster productpage-v1-bb8d5cbc7-k7qbm

    # Отримати інформацію про конфігурацію прослуховувача для екземпляра Envoy у вказаному podʼі.
    $ istioctl proxy-config listener productpage-v1-bb8d5cbc7-k7qbm

    # Отримати інформацію про конфігурацію маршрутизації для екземпляра Envoy у вказаному podʼі.
    $ istioctl proxy-config route productpage-v1-bb8d5cbc7-k7qbm

    # Отримати інформацію про конфігурацію точок доступу для екземпляра Envoy у вказаному podʼі.
    $ istioctl proxy-config endpoints productpage-v1-bb8d5cbc7-k7qbm

    # Спробуйте наступне, щоб дізнатися більше про команди proxy-config
    $ istioctl proxy-config --help
    {{< /text >}}

* `kubectl get`: Отримує інформацію про різні ресурси в мережі разом з конфігурацією маршрутизації:

    {{< text plain >}}
    # Показати всі віртуальні сервіси
    $ kubectl get virtualservices
    {{< /text >}}
