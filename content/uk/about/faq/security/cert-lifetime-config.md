---
title: Як налаштувати тривалість дії сертифікатів Istio?
weight: 70
---

Для робочих навантажень, що виконуються в Kubernetes, термін дії їх сертифікатів Istio стандартно становить 24 години.

Цю конфігурацію можна змінити, налаштувавши поле `proxyMetadata` у [конфігурації проксі](/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig). Наприклад:

{{< text yaml >}}
proxyMetadata:
  SECRET_TTL: 48h
{{< /text >}}

{{< tip >}}
Значення більше 90 днів не приймаються.
{{< /tip >}}
