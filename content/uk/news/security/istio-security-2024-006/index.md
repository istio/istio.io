---
title: ISTIO-SECURITY-2024-006
subtitle: Бюлетень безпеки
description: CVE, повідомлені Envoy.
cves: [CVE-2024-45807, CVE-2024-45808, CVE-2024-45806, CVE-2024-45809, CVE-2024-45810]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.22.0 до 1.22.4", "1.23.0 до 1.23.1"]
publishdate: 2024-09-19
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE від Envoy

- __[CVE-2024-45807](https://github.com/envoyproxy/envoy/security/advisories/GHSA-qc52-r4x5-9w37)__: (CVSS Score 7.5, висока): oghttp2 може аварійно завершити роботу при обробці `OnBeginHeadersForStream`.

- __[CVE-2024-45808](https://github.com/envoyproxy/envoy/security/advisories/GHSA-p222-xhp9-39rc)__: (CVSS Score 6.5, помірна): Відсутність валідації для поля `REQUESTED_SERVER_NAME` для логерів доступу дозволяє впроваджувати неочікуваний вміст у логи доступу.

- __[CVE-2024-45806](https://github.com/envoyproxy/envoy/security/advisories/GHSA-ffhv-fvxq-r6mf)__: (CVSS Score 6.5, помірна): Можливість маніпуляцій з заголовками `x-envoy` зовнішніми джерелами.

- __[CVE-2024-45809](https://github.com/envoyproxy/envoy/security/advisories/GHSA-wqr5-qmq7-3qw3)__: (CVSS Score 5.3, помірна): Аварійне завершення роботи фільтра JWT в кеші маршрутів для віддалених JWK.

- __[CVE-2024-45810](https://github.com/envoyproxy/envoy/security/advisories/GHSA-qm74-x36m-555q)__: (CVSS Score 6.5, помірна): Аварійне завершення роботи Envoy для `LocalReply` у асинхронному HTTP клієнті.

## Чи впливає це на мене?

Ви піддаєтесь впливу, якщо використовуєте Istio версії 1.22.0 до 1.22.4 або 1.23.0 до 1.23.1.

Якщо ви розгортаєте Istio Ingress Gateway, ви можете бути вразливими до маніпуляцій з заголовками `x-envoy` зовнішніми джерелами. Раніше Envoy вважав усі приватні IP-адреси стандартно внутрішніми, тому не очищав заголовки від зовнішніх джерел з приватними IP-адресами. Envoy додав підтримку прапорця `envoy.reloadable_features.explicit_internal_address_config` для явного ігнорування всіх IP-адрес. Envoy та Istio наразі стандартно вимикають цей прапорець для зворотної сумісності. У майбутніх релізах Envoy та Istio прапорець `envoy.reloadable_features.explicit_internal_address_config` буде стандартно увімкнений. Прапорець Envoy можна налаштувати для всієї мережі або для кожного проксі через [ProxyConfig](/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig) у параметрі `runtimeValues`.

Приклад конфігурації для всієї мережі:

{{< text yaml >}}
meshConfig:
  defaultConfig:
    runtimeValues:
      "envoy.reloadable_features.explicit_internal_address_config": "true"
{{< /text >}}

Приклад конфігурації для кожного проксі:

{{< text yaml >}}
annotations:
  proxy.istio.io/config: |
    runtimeValues:
      "envoy.reloadable_features.explicit_internal_address_config": "true"
{{< /text >}}

Зверніть увагу, що поля в ProxyConfig не налаштовуються динамічно; для застосування змін необхідно перезапустити робочі навантаження.
