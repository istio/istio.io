---
title: ¿Cómo migro la funcionalidad de Mixer existente?
weight: 30
---

Mixer fue [eliminado en la versión 1.8 de Istio](/news/releases/1.8.x/announcing-1.8/#deprecations).
La migración es necesaria si todavía depende de los adaptadores integrados de Mixer o de cualquier adaptador fuera de proceso para la extensión de la malla.

Para los adaptadores integrados, se proporcionan varias alternativas:

* Las integraciones de `Prometheus` y `Stackdriver` se implementan como [extensiones de proxy](/es/docs/reference/config/proxy_extensions/).
    La personalización de la telemetría generada por estas dos extensiones se puede lograr a través de la [clasificación de solicitudes](/es/docs/tasks/observability/metrics/classify-metrics/) y la [personalización de métricas de Prometheus](/es/docs/tasks/observability/metrics/customize-metrics/).
* La funcionalidad de limitación de velocidad global y local (adaptadores `memquota` y `redisquota`) se proporciona a través de la [solución de limitación de velocidad basada en Envoy](/es/docs/tasks/policy-enforcement/rate-limit/).
* El adaptador `OPA` se reemplaza por la [solución basada en ext-authz de Envoy](/es/docs/tasks/security/authorization/authz-custom/), que admite la [integración con el agente de políticas de OPA](https://www.openpolicyagent.org/docs/latest/envoy-introduction/).

Para los adaptadores personalizados fuera de proceso, se recomienda encarecidamente la migración a extensiones basadas en Wasm. Consulte las guías sobre el [desarrollo de módulos Wasm](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md) y la [distribución de extensiones](/es/docs/tasks/extensibility/wasm-module-distribution/). Como solución temporal, puede [habilitar el soporte de la API de registro de acceso gRPC y ext-authz de Envoy en Mixer](https://github.com/istio/istio/wiki/Enabling-Envoy-Authorization-Service-and-gRPC-Access-Log-Service-With-Mixer), lo que le permite actualizar Istio a versiones posteriores a la 1.7 sin dejar de usar Mixer 1.7 con adaptadores fuera de proceso. Esto le dará más tiempo para migrar a extensiones basadas en Wasm. Tenga en cuenta que esta solución temporal no ha sido probada en batalla y es poco probable que reciba correcciones de parches, ya que solo está disponible en la rama 1.7 de Istio, que está fuera de la ventana de soporte después de febrero de 2021.
