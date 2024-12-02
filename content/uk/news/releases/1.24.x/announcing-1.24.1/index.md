---
title: Анос Istio 1.24.1
linktitle: 1.24.1
subtitle: Випуск патча
description: Випуск патча Istio 1.24.1.
publishdate: 2024-11-25
release: 1.24.1
---

У цьому документі описується різниця між версіями Istio 1.24.0 та 1.24.1.

{{< relnote >}}

## Зміни {#changes}

- **Додано** невизначену анотацію AppArmor до `istio-cni-node` `DaemonSet`, щоб уникнути конфліктів з профілями AppArmor, які блокують певні можливості привілейованих pod. Раніше AppArmor (коли його увімкнено) оминався для `istio-cni-node` `DaemonSet`, оскільки privileged було встановлено у значення true у `SecurityContext`. Ця зміна гарантує, що профіль AppArmor для `istio-cni-node` `DaemonSet` буде встановлено у значення unconfined.

- **Додано** `dnsPolicy` `ClusterFirstWithHostNet` до `istio-cni`, коли він працює з `hostNetwork=true` (тобто у режимі ambient).

- **Виправлено** проблему, коли `istioctl install` не працював належним чином у Windows.

- **Виправлено** проблему, коли обʼєднання `Duration` з `EnvoyFilter` могло призвести до несподіваної модифікації всіх атрибутів, повʼязаних зі слухачами, оскільки всі слухачі мали спільний вказівник з типом `listener_filters_timeout`.

- **Виправлено** проблему, коли `istioctl install` призводив до глухого кута, якщо у файлі IstioOperator вказано декілька вхідних шлюзів.
  ([Тікет #53875](https://github.com/istio/istio/issues/53875))

- **Виправлено** помилку, яка виникала під час очищення правил iptables, що залежать від конфігурації iptables.

- **Виправлено** проблему під час оновлення waypoint проксі з Istio 1.23.x до Istio 1.24.x.
  ([Тікет #53883](https://github.com/istio/istio/issues/53883))
