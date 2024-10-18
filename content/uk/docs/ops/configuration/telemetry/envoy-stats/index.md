---
title: Статистика Envoy
description: Тонке управління статистикою Envoy.
weight: 10
aliases:
  - /uk/help/ops/telemetry/envoy-stats
  - /uk/docs/ops/telemetry/envoy-stats
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Proxy Envoy зберігає детальну статистику про мережевий трафік.

Статистика Envoy охоплює лише трафік для конкретного екземпляра Envoy. Див. [Спостережуваність](/docs/tasks/observability/) для постійної телеметрії Istio на рівні сервісу. Статистика, яку записують проксі Envoy, може надати більше інформації про конкретні екземпляри podʼів.

Щоб переглянути статистику для podʼа:

{{< text syntax=bash snip_id=get_stats >}}
$ kubectl exec "$POD" -c istio-proxy -- pilot-agent request GET stats
{{< /text >}}

Envoy генерує статистику про свою поведінку, визначаючи статистику за функцією проксі. Приклади включають:

- [Upstream connection](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)
- [Listener](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/stats)
- [HTTP Connection Manager](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/stats)
- [TCP proxy](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/tcp_proxy_filter#statistics)
- [Router](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter.html?highlight=vhost#statistics)

Стандартно, Istio конфігурує Envoy для запису мінімального набору статистики, щоб зменшити загальне навантаження на ЦП і памʼять встановлених проксі. Стандартні ключі для збору:

- `cluster_manager`
- `listener_manager`
- `server`
- `cluster.xds-grpc`

Щоб переглянути налаштування Envoy для збору статистичних даних, використовуйте [`istioctl proxy-config bootstrap`](/docs/reference/commands/istioctl/#istioctl-proxy-config-bootstrap) і дотримуйтесь [детального огляду конфігурації Envoy](/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration). Envoy збирає статистичні дані лише за елементами, що відповідають `inclusion_list` в JSON-елементі `stats_matcher`.

{{< tip >}}
Зверніть увагу: Імена статистики Envoy можуть змінюватися залежно від складу конфігурації Envoy. Як результат, імена статистики для Envoy, які керуються Istio, залежать від поведінки конфігурації Istio. Якщо ви будуєте або підтримуєте панелі управління або оповіщення на основі статистики Envoy, **рекомендується** перевірити статистику в canary-середовищі **перед оновленням Istio**.
{{< /tip >}}

Щоб налаштувати проксі Istio для запису додаткової статистики, ви можете додати [`ProxyConfig.ProxyStatsMatcher`](/docs/reference/config/istio.mesh.v1alpha1/#ProxyStatsMatcher) до конфігурації вашої mesh. Наприклад, щоб увімкнути статистику для запобіжників, повторних запитів, upstream-зʼєднань і тайм-аутів запитів глобально, ви можете вказати matcher статистики наступним чином:

{{< tip >}}
Проксі потрібно перезапустити, щоб застосувати конфігурацію matcher статистики.
{{< /tip >}}

{{< text syntax=yaml snip_id=proxyStatsMatcher >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyStatsMatcher:
        inclusionRegexps:
          - ".*outlier_detection.*"
          - ".*upstream_rq_retry.*"
          - ".*upstream_cx_.*"
        inclusionSuffixes:
          - "upstream_rq_timeout"
{{< /text >}}

Ви також можете перевизначити глобальну конфігурацію збігу статистики для кожного проксі, використовуючи анотацію `proxy.istio.io/config`. Наприклад, щоб налаштувати таку ж генерацію статистики, як вище, ви можете додати анотацію до проксі шлюзу або робочого навантаження наступним чином:

{{< text syntax=yaml snip_id=proxyIstioConfig >}}
metadata:
  annotations:
    proxy.istio.io/config: |-
      proxyStatsMatcher:
        inclusionRegexps:
        - ".*outlier_detection.*"
        - ".*upstream_rq_retry.*"
        - ".*upstream_cx_.*"
        inclusionSuffixes:
        - "upstream_rq_timeout"
{{< /text >}}

{{< tip >}}
Зверніть увагу: Якщо ви використовуєте `sidecar.istio.io/statsInclusionPrefixes`, `sidecar.istio.io/statsInclusionRegexps` і `sidecar.istio.io/statsInclusionSuffixes`, розгляньте можливість переходу до конфігурації на основі `ProxyConfig`, оскільки вона забезпечує глобальні стандартні налаштування і єдину можливість перевизначити конфігурацію на шлюзі та sidecar проксі.
{{< /tip >}}
