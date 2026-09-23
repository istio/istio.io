---
title: Анонс Istio 1.23.2
linktitle: 1.23.2
subtitle: Випуск патча
description: Випуск патча Istio 1.23.2.
publishdate: 2024-09-19
release: 1.23.2
---

У цьому випуску виправлено уразливості, описані в нашому пості від 19 вересня, [ISTIO-SECURITY-2024-006](/news/security/istio-security-2024-006). У цьому документі описується різниця між версіями Istio 1.23.1 та 1.23.2.

{{< relnote >}}

## Зміни {#changes}

- **Виправлено** функцію `PILOT_SIDECAR_USE_REMOTE_ADDRESS` в sidecars для підтримки встановлення внутрішніх адрес у mesh-мережі, а не локального хосту, щоб запобігти очищенню заголовків, якщо увімкнено `envoy.reloadable_features.explicit_internal_address_config`.
