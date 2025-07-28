---
title: "Presentamos las API v1 de Istio"
description: Reflejando la estabilidad de las características de Istio, nuestras API de red, seguridad y telemetría se promueven a v1 en 1.22.
publishdate: 2024-05-13
attribution: Whitney Griffith - Microsoft
keywords: [istio, traffic, security, telemetry, API]
target_release: 1.22
---

Istio proporciona API de [red](/es/docs/reference/config/networking/), [seguridad](/es/docs/reference/config/security/) y [telemetría](/es/docs/reference/config/telemetry/) que son cruciales para garantizar la seguridad robusta, la conectividad perfecta y la observabilidad efectiva de los servicios dentro de la service mesh. Estas API se utilizan en miles de clusteres en todo el mundo, asegurando y mejorando la infraestructura crítica.

La mayoría de las características impulsadas por estas API se han [considerado estables](/es/docs/releases/feature-stages/) durante algún tiempo, pero la versión de la API se ha mantenido en `v1beta1`. Como reflejo de la estabilidad, adopción y valor de estos recursos, la comunidad de Istio ha decidido promover estas API a `v1` en Istio 1.22.

En Istio 1.22 nos complace anunciar que se ha realizado un esfuerzo concertado para graduar las siguientes API a `v1`:
* [Destination Rule](/es/docs/reference/config/networking/destination-rule/)
* [Gateway](/es/docs/reference/config/networking/gateway/)
* [Service Entry](/es/docs/reference/config/networking/service-entry/)
* [Sidecar](/es/docs/reference/config/networking/sidecar/)
* [Virtual Service](/es/docs/reference/config/networking/virtual-service/)
* [Workload Entry](/es/docs/reference/config/networking/workload-entry/)
* [Workload Group](/es/docs/reference/config/networking/workload-group/)
* [API de Telemetría](/es/docs/reference/config/telemetry/)*
* [Peer Authentication](/es/docs/reference/config/security/peer_authentication/)

## Estabilidad de características y versiones de API

Las API declarativas, como las utilizadas por Kubernetes e Istio, desacoplan la _descripción_ de un recurso de la _implementación_ que actúa sobre él.

Las [definiciones de fase de características de Istio](/es/docs/releases/feature-stages/) describen cómo una característica estable, una que se considera lista para su uso en producción a cualquier escala y que viene con una política de desaprobación formal, debe coincidir con una API `v1`. Ahora estamos cumpliendo esa promesa, con nuestras versiones de API que coinciden con la estabilidad de nuestras características tanto para las características que han sido estables durante algún tiempo, como para aquellas que se designan como estables en esta versión.

Aunque actualmente no hay planes para descontinuar el soporte para las versiones anteriores de la API `v1beta1` y `v1alpha1`, se alienta a los usuarios a realizar la transición manual al uso de las API `v1` actualizando sus archivos YAML existentes.

## API de Telemetría

La API de Telemetría `v1` es la única API que se promovió que tuvo cambios con respecto a su versión de API anterior. Las siguientes características de `v1alpha1` no se promovieron a `v1`:
* `metrics.reportingInterval`
    * El intervalo de informes permite la configuración del tiempo entre llamadas para los informes de métricas. Actualmente, esto solo admite métricas de TCP, pero podemos usarlo para flujos HTTP de larga duración en el futuro.

      _En este momento, Istio carece de datos de uso para respaldar la necesidad de esta característica._
* `accessLogging.filter`
    * Si se especifica, este filtro se utilizará para seleccionar solicitudes/conexiones específicas para el registro.

      _Esta característica se basa en una característica relativamente nueva en Envoy, e Istio necesita desarrollar aún más el caso de uso y la implementación antes de graduarla a `v1`._
* `tracing.useRequestIdForTraceSampling`
    * Este valor es verdadero por defecto. El formato de este ID de solicitud es específico de Envoy, y si el ID de solicitud generado por el proxy que recibe el tráfico del usuario primero no es específico de Envoy, Envoy romperá el seguimiento porque no puede interpretar el ID de solicitud. Al establecer este valor en falso, podemos evitar que [Envoy realice un muestreo basado en el ID de solicitud](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing#trace-context-propagation).

      _No existe un caso de uso sólido para hacer que esto sea configurable a través de la API de Telemetría._

Por favor, comparte cualquier comentario sobre estos campos [creando incidencias en GitHub](https://github.com/istio/istio/issues).

## Descripción general de las CRD de Istio

Esta es la lista completa de las versiones de API compatibles:

| Categoría | API | Versiones |
| ---------|-----|----------|
| Redes | [Destination Rule](/es/docs/reference/config/networking/destination-rule/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Gateway](/es/docs/reference/config/networking/gateway/) de Istio |  `v1`, `v1beta1`, `v1alpha3` |
| | [Service Entry](/es/docs/reference/config/networking/service-entry/) |  `v1`, `v1beta1`, `v1alpha3` |
| | Ámbito de [Sidecar](/es/docs/reference/config/networking/sidecar/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Virtual Service](/es/docs/reference/config/networking/virtual-service/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Workload Entry](/es/docs/reference/config/networking/workload-entry/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Workload Group](/es/docs/reference/config/networking/workload-group/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Proxy Config](/es/docs/reference/config/networking/proxy-config/) |  `v1beta1` |
| | [Envoy Filter](/es/docs/reference/config/networking/envoy-filter/) |  `v1alpha3` |
| Seguridad  | [Authorization Policy](/es/docs/reference/config/security/authorization-policy/) |  `v1`, `v1beta1` |
| | [Peer Authentication](/es/docs/reference/config/security/peer_authentication/) |  `v1`, `v1beta1` |
| | [Request Authentication](/es/docs/reference/config/security/request_authentication/) |  `v1`, `v1beta1` |
| Telemetría | [Telemetría](/es/docs/reference/config/telemetry/) |  `v1`, `v1alpha1` |
| Extensión | [Wasm Plugin](/es/docs/reference/config/proxy_extensions/wasm-plugin/) |  `v1alpha1` |

Istio también se puede configurar [usando la API de Gateway de Kubernetes](/es/docs/setup/getting-started/).

## Uso de las API `v1` de Istio

Hay algunas API en Istio que todavía están en desarrollo activo y están sujetas a posibles cambios entre versiones. Por ejemplo, las API de Envoy Filter, Proxy Config y Wasm Plugin.

Además, Istio mantiene un esquema estrictamente idéntico en todas las versiones de una API debido a las limitaciones en el [versionado de CRD](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/). Por lo tanto, aunque existe una API de Telemetría `v1`, los tres campos `v1alpha1` mencionados [anteriormente](#telemetry-api) todavía se pueden utilizar al declarar un recurso de API de Telemetría `v1`.

Para entornos reacios al riesgo, hemos agregado una **política de validación estable**, una [política de admisión de validación](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/) que puede garantizar que solo se utilicen API y campos `v1` con las API de Istio.

En entornos nuevos, la selección de la política de validación estable al instalar Istio garantizará que todos los Recursos Personalizados futuros creados o actualizados sean `v1` y contengan solo características `v1`.

Si la política se implementa en una instalación de Istio existente que tiene Recursos Personalizados que no la cumplen, la única acción permitida es eliminar el recurso o eliminar el uso de los campos infractores.

Para instalar Istio con la política de validación estable:

{{< text bash >}}
$ helm install istio-base -n istio-system --set experimental.stableValidationPolicy=true
{{< /text >}}

Para establecer una revisión específica al instalar Istio con la política:

{{< text bash >}}
$ helm install istio-base -n istio-system --set experimental.stableValidationPolicy=true -set revision=x
{{< /text >}}

Esta característica es compatible con [Kubernetes 1.30](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/) y superior. Las validaciones se crean utilizando expresiones [CEL](https://github.com/google/cel-spec), y los usuarios pueden modificar las validaciones para sus necesidades específicas.

## Resumen

El proyecto Istio se compromete a ofrecer API y características estables esenciales para el funcionamiento exitoso de tu service mesh. Nos encantaría recibir tus comentarios para que nos ayuden a tomar las decisiones correctas a medida que continuamos refinando los casos de uso relevantes y los bloqueadores de estabilidad para nuestras características. Por favor, comparte tus comentarios creando [incidencias](https://github.com/istio/istio/issues), publicando en el [canal de Slack de Istio](https://slack.istio.io/) relevante, o uniéndote a nosotros en nuestra [reunión semanal del grupo de trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings).
