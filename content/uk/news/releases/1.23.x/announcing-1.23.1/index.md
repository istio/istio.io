---
title: Анонс Istio 1.23.1
linktitle: 1.23.1
subtitle: Випуск патча
description: Випуск патча Istio 1.23.1.
publishdate: 2024-09-10
release: 1.23.1
---

У цьому повідомленні про випуск описано відмінності між версіями Istio 1.23.0 та 1.23.1.

{{< relnote >}}

## Зміни {#changes}

- **Виправлено** проблему, через яку IP-адреси, призначені контролером, не дотримувалися захоплення DNS на проксі, так само як і автоматично виділені тимчасові IP-адреси.
  ([Тікет #52609](https://github.com/istio/istio/issues/52609))

- **Виправлено** проблему, через яку для waypoint-проксі була потрібна активація DNS-проксі для використання автоматично виділених IP-адрес.
  ([Тікет #52746](https://github.com/istio/istio/issues/52746))

- **Виправлено** проблему, через яку ланцюг `ISTIO_OUTPUT` `iptables` не видалявся за допомогою команди `pilot-agent istio-clean-iptables`.
  ([Тікет #52835](https://github.com/istio/istio/issues/52835))

- **Виправлено** проблему, що призводила до ігнорування будь-яких `portLevelSettings` у `DestinationRule` для waypoint-проксі.
  ([Тікет #52532](https://github.com/istio/istio/issues/52532))

- **Вилучено** запис `kubeconfig` в теці мережевих налаштувань CNI.
  ([Тікет #52315](https://github.com/istio/istio/issues/52315))

- **Вилучено** параметр `CNI_NET_DIR` з `ConfigMap` `istio-cni`, оскільки тепер він не має жодного впливу.
  ([Тікет #52315](https://github.com/istio/istio/issues/52315))

- **Вилучено** зміну в Istio 1.23.0, яка викликала регресії для `ServiceEntries` з кількома адресами.
  Примітка: повернена зміна виправила проблему відсутніх адрес (#51747), але спричинила нові проблеми. Початкову проблему можна обійти, створивши ресурс sidecar.
  ([Тікет #52944](https://github.com/istio/istio/issues/52944)), ([Тікет #52847](https://github.com/istio/istio/issues/52847))
