---
title: ¿Cómo puedo gestionar las métricas de corta duración?
weight: 20
---

Las métricas de corta duración pueden afectar el rendimiento de Prometheus, ya que a menudo son una gran fuente de cardinalidad de labels. La cardinalidad es una medida del número de valores únicos para una label. Para gestionar el impacto de sus métricas de corta duración en Prometheus, primero debe identificar las métricas y labels de alta cardinalidad. Prometheus proporciona información de cardinalidad en su página `/status`. Se puede recuperar información adicional [a través de PromQL](https://www.robustperception.io/which-are-my-biggest-metrics).
Hay varias formas de reducir la cardinalidad de las métricas de Istio:

* Deshabilitar la reserva del encabezado del host.
  La label `destination_service` es una fuente potencial de alta cardinalidad.
  Los valores para `destination_service` se establecen de forma predeterminada en el encabezado del host si el proxy de Istio no puede determinar el servicio de destino a partir de otros metadatos de la solicitud.
  Si los clientes utilizan una variedad de encabezados de host, esto podría dar como resultado una gran cantidad de valores para `destination_service`.
  En este caso, siga la guía de [personalización de métricas](/es/docs/tasks/observability/metrics/customize-metrics/) para deshabilitar la reserva del encabezado del host en toda la malla.
  Para deshabilitar la reserva del encabezado del host para una workload o un namespace en particular, debe copiar la configuración de `EnvoyFilter` de estadísticas, actualizarla para que la reserva del encabezado del host esté deshabilitada y aplicarla con un selector más específico.
  [Este problema](https://github.com/istio/istio/issues/25963#issuecomment-666037411) tiene más detalles sobre cómo lograrlo.
* Eliminar labels innecesarias de la colección. Si no se necesita la label con alta cardinalidad, puede eliminarla de la colección de métricas a través de la [personalización de métricas](/es/docs/tasks/observability/metrics/customize-metrics/) usando `tags_to_remove`.
* Normalizar los valores de las labels, ya sea a través de la federación o la clasificación.
  Si se desea la información proporcionada por la label, puede usar la [federación de Prometheus](/es/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring) o la [clasificación de solicitudes](/es/docs/tasks/observability/metrics/classify-metrics/) para normalizar la label.
  