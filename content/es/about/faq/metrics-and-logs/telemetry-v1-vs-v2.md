---
title: ¿Cuáles son las diferencias en la telemetría informada por la telemetría en el proxy (también conocida como v2) y la telemetría basada en Mixer (también conocida como v1)?
weight: 10
---

La telemetría en el proxy (también conocida como v2) reduce el costo de los recursos y mejora el rendimiento del proxy
en comparación con el enfoque de telemetría basada en Mixer (también conocida como v1),
y es el mecanismo preferido para mostrar la telemetría en Istio.
Sin embargo, existen algunas diferencias en la telemetría informada entre v1 y
v2 que se enumeran a continuación:

* **Faltan labels para el tráfico fuera de la malla**
  La telemetría en el proxy se basa en el intercambio de metadatos entre los proxies de Envoy para recopilar
  información como el nombre de el workload del par, el namespace y las labels. En la telemetría basada en Mixer
  , esta funcionalidad la realizaba Mixer como parte de la combinación de los atributos de la solicitud
  con los datos de la plataforma. Este intercambio de metadatos lo realizan los proxies de Envoy
  agregando un encabezado HTTP específico para el protocolo HTTP o aumentando
  el protocolo ALPN para el protocolo TCP como se describe
  [aquí](/es/docs/tasks/observability/metrics/tcp-metrics/#understanding-tcp-telemetry-collection).
  Esto requiere que los proxies de Envoy se inyecten tanto en los workloads del cliente como del servidor,
  lo que implica que a la telemetría informada cuando un par no está en la malla le faltarán
  atributos del par como el nombre de el workload, el namespace y las labels.
  Sin embargo, si ambos pares tienen proxies inyectados, todas las labels mencionadas
  [aquí](/es/docs/reference/config/metrics/) están disponibles en las métricas generadas.
  Cuando el workload del servidor está fuera de la malla, los metadatos de el workload del servidor todavía
  se distribuyen al sidecar del cliente, lo que hace que las métricas del lado del cliente tengan los metadatos de el workload del servidor
  labels completadas.

* **El intercambio de metadatos TCP requiere mTLS**
  El intercambio de metadatos TCP se basa en el [protocolo ALPN de Istio](/es/docs/tasks/observability/metrics/tcp-metrics/#understanding-tcp-telemetry-collection)
  que requiere que el TLS mutuo (mTLS) esté habilitado para que los proxies de Envoy
  intercambien metadatos con éxito. Esto implica que si mTLS no está
  habilitado en su cluster, la telemetría para el protocolo TCP no incluirá
  información del par como el nombre de el workload, el namespace y las labels.

* **No hay mecanismo para configurar depósitos personalizados para métricas de histograma**
  La telemetría basada en Mixer admitía la personalización de depósitos para métricas de tipo histograma
  como la duración de la solicitud y los tamaños de bytes de TCP. La telemetría en el proxy no tiene tal
  mecanismo disponible. Además, los depósitos disponibles para las métricas de latencia
  en la telemetría en el proxy están en milisegundos en comparación con los segundos
  en la telemetría basada en Mixer. Sin embargo, hay más depósitos disponibles de forma predeterminada
  en la telemetría en el proxy para las métricas de latencia en los niveles de latencia más bajos.

* **No hay vencimiento de métricas para métricas de corta duración**
  La telemetría basada en Mixer admitía el vencimiento de métricas por el cual las métricas que no se
  generaban durante un período de tiempo configurable se daban de baja para
  la recopilación por parte de Prometheus. Esto es útil en escenarios, como trabajos únicos, que generan métricas de corta duración. Dar de baja
  las métricas evita la notificación de métricas que ya no cambiarían en el
  futuro, lo que reduce el tráfico de red y el almacenamiento en Prometheus.
  Este mecanismo de vencimiento no está disponible en la telemetría en el proxy.
  La solución alternativa para esto se puede encontrar [aquí](/es/about/faq/#metric-expiry).