---
title: ¿Por qué no se rastrean mis solicitudes?
weight: 30
---

La tasa de muestreo para el seguimiento se establece en el 1% en el [perfil de configuración](/es/docs/setup/additional-setup/config-profiles/) `predeterminado`.
Esto significa que solo 1 de cada 100 instancias de seguimiento capturadas por Istio se informará al backend de seguimiento.
La tasa de muestreo en el perfil `demo` se establece en 100%. Consulte
[esta sección](/es/docs/tasks/observability/distributed-tracing/telemetry-api/#customizing-trace-sampling)
para obtener información sobre cómo establecer la tasa de muestreo.

Si aún no ve ningún dato de seguimiento, confirme que sus puertos cumplen con las [convenciones de nomenclatura de puertos](/es/about/faq/#naming-port-convention) de Istio y que el puerto de contenedor apropiado está expuesto (a través de la especificación del pod, por ejemplo) para permitir la captura de tráfico por el proxy sidecar (Envoy).

Si solo ve datos de seguimiento asociados con el proxy de salida, pero no con el proxy de entrada, aún puede estar relacionado con las [convenciones de nomenclatura de puertos](/es/about/faq/#naming-port-convention) de Istio.