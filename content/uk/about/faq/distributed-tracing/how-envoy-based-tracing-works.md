---
title: Як працює трейсинг на основі Envoy?
weight: 11
---

Для інтеграцій трейсингу на основі Envoy, Envoy (sidecar проксі) надсилає інформацію про трейсинг безпосередньо до бекендів трейсингу від імені застосунків, що проходять через проксі.

Envoy:

- генерує ID запитів та заголовки трейсингу (наприклад, `X-B3-TraceId`) для запитів, коли вони проходять через проксі
- генерує трейс-відрізки (span) для кожного запиту на основі метаданих запиту та відповіді (наприклад, час відповіді)
- надсилає згенеровані трейс-відрізки (span) до бекендів трейсингу
- передає заголовки трейсингу до застосунку, який проходить через проксі

Istio підтримує [OpenTelemetry](/docs/tasks/observability/distributed-tracing/opentelemetry/) та сумісні бекенди включаючи [Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/). Серед інших платформ також підтримуються [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/) та [Apache SkyWalking](/docs/tasks/observability/distributed-tracing/skywalking/).
