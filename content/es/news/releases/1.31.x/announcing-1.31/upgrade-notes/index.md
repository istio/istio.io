---
title: Notas de Actualización de Istio 1.31
description: Cambios importantes a considerar al actualizar a Istio 1.31.0.
weight: 20
publishdate: 2026-08-31
---

Al actualizar de Istio 1.30.x a Istio 1.31.x, debes tener en cuenta los cambios de esta página.
Estas notas detallan los cambios que rompen intencionalmente la compatibilidad con versiones anteriores de Istio 1.30.x.
Las notas también mencionan cambios que preservan la compatibilidad con versiones anteriores e introducen nuevo comportamiento.
Solo se incluyen los cambios cuyo nuevo comportamiento resultaría inesperado para un usuario de Istio 1.30.x.

## Obsolescencia de la infraestructura y el alojamiento en GCP

A partir de Istio 1.31, ya no publicaremos artefactos en `gcr.io/istio-release`, `registry.istio.io` ni `istio-release.storage.googleapis.com`.

- Las imágenes Docker seguirán disponibles en Docker Hub.
- Los charts de Helm estarán disponibles en `blob.istio.io/istio-release/charts`.
- Otros artefactos estarán disponibles en `blob.istio.io/istio-release`.
- Los charts OCI de Helm estarán disponibles en `ghcr.io/istio/release/charts`.

Realizaremos pruebas de eliminación en las que deshabilitaremos todos los artefactos alojados en GCP durante períodos breves.

La primera prueba será el 15 de septiembre de 2026, de 15:00 a 16:00 UTC.
La segunda prueba será el 13 de octubre de 2026, de 15:00 a 18:00 UTC.
La tercera prueba será el 17 de noviembre de 2026, de 15:00 a 21:00 UTC.
La cuarta y última prueba será del 8 de diciembre de 2026 a las 15:00 UTC al 9 de diciembre de 2026 a las 15:00 UTC.

Para más detalles, consulta [esta entrada de blog](/blog/2026/retirement-of-gcp/).

## Comportamiento predeterminado para el envío de endpoints no saludables

Por defecto, Istio ahora envía endpoints no saludables a menos que `OutlierDetection.minHealthPercent` esté configurado en un `Service`.
Se puede deshabilitar estableciendo `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` en `false`, o usando perfiles de compatibilidad.

## Los recursos `WorkloadEntry` auto-registrados existentes necesitan re-registro o una etiqueta manual para HBONE

La etiqueta del túnel HBONE solo se aplica cuando se crea automáticamente un `WorkloadEntry`, por lo que los workloads
auto-registrados antes de la actualización siguen siendo alcanzables mediante texto plano hasta que se vuelvan a registrar
(reconecten una instancia nueva) o se añada la etiqueta (`networking.istio.io/tunnel=http`) a su `WorkloadEntry` existente.

## Feature flag `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` eliminado

La variable de entorno `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` ha sido eliminada. El comportamiento que controlaba
(generar un span de trazado independiente para cada solicitud upstream del gateway cuando se usa la API de Telemetría)
ahora siempre está habilitado. Los usuarios que establecían esta variable en `false` para desactivar este comportamiento
deben saber que ya no está disponible la opción de desactivación.

## Las solicitudes de reconexión WDS son más grandes en ambient meshes grandes

Al reconectarse, ztunnel reporta el nombre y la versión de cada recurso workload (WDS) que tiene. Esta solicitud puede
superar el límite de recepción gRPC predeterminado de 4 MiB de istiod, dejando a ztunnel en un bucle de reconexión con
errores `ResourceExhausted: grpc: received message larger than max`. Las meshes ya podían alcanzar el límite con
aproximadamente 55.000 workloads, ya que los nombres de recursos se reportaban antes de este cambio; las versiones
añadidas hacen crecer la solicitud en aproximadamente un tercio, reduciendo el punto de activación a aproximadamente
40.000 workloads (antes con nombres de recursos largos o muchos servicios). Si tu mesh está cerca de esta escala,
aumenta `ISTIO_GPRC_MAXRECVMSGSIZE` en istiod —calcula aproximadamente 1 MiB por cada 10.000 workloads y servicios;
por ejemplo, `--set pilot.env.ISTIO_GPRC_MAXRECVMSGSIZE=33554432` (32 MiB) cubre meshes bien por encima de 300.000
recursos— y vigila los logs de istiod para el error anterior tras la actualización.

## El generador XDS `api` ahora requiere una identidad de control plane

Los consumidores MCP personalizados que se conecten al generador `api` de istiod desde namespaces que no son del sistema
ahora son rechazados. El tráfico estándar de sidecar, gateway y ztunnel no se ve afectado.
Para restaurar el comportamiento anterior, establece `ENABLE_XDS_API_GENERATOR_AUTH=false`.
