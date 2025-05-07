---
title: Анонс Istio 1.23.3
linktitle: 1.23.3
subtitle: Випуск патча
description: Випуск патча Istio 1.23.3.
publishdate: 2024-10-24
release: 1.23.3
---

Цей випуск містить виправлення помилок для підвищення надійності. У цьому документі описується різниця між Istio 1.23.2 та Istio 1.23.3

{{< relnote >}}

## Зміни {#changes}

- **Додано** виключення хостів `clusterLocal` для мультикластерів.

- **Додано** порт метрик у специфікації контейнерів `DaemonSet` чарт `istio-cni`.

- **Додано** порт метрик у специфікації контейнерів `kube-gateway` чарт `istio-discovery`.

- **Виправлено** правила `kube-virt-interfaces`, які не видаляються інструментом `istio-clean-iptables`.
  ([Тікет #48368](https://github.com/istio/istio/issues/48368))
