---
title: Anuncio de Istio 1.28.7
linktitle: 1.28.7
subtitle: Versión de Parche
description: Parche de Istio 1.28.7.
publishdate: 2026-05-18
release: 1.28.7
aliases:
    - /news/announcing-1.28.7
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.28.6 e Istio 1.28.7.

{{< relnote >}}

## Cambios

- **Añadido** soporte para Gateway API v1.4.1.

- **Añadida** una advertencia de `istioctl analyze` (IST0175) cuando existen recursos `RequestAuthentication` pero `BLOCKED_CIDRS_IN_JWKS_URIS` no está configurado en istiod.
  ([Issue #59523](https://github.com/istio/istio/issues/59523))

- **Añadidos** los flags de características `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE` y `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`. Permiten configurar los tamaños iniciales de la ventana de flujo y conexión para las conexiones HBONE a clústeres ascendentes (generados para waypoints y gateways east-west). Pueden usarse para reducir el almacenamiento en búfer no deseado.
  ([Issue #59961](https://github.com/istio/istio/issues/59961))

- **Corregido** un problema donde los waypoints no podían añadir el filtro de escucha del inspector TLS cuando solo existían puertos TLS, lo que causaba que el enrutamiento basado en SNI fallara para recursos `ServiceEntry` comodín con `resolution: DYNAMIC_DNS`.
  ([Issue #59024](https://github.com/istio/istio/issues/59024))

- **Corregido** un problema donde Istiod podía emitir certificados de hoja con un tiempo `NotAfter` más allá del vencimiento del certificado de firma.
  ([Issue #59768](https://github.com/istio/istio/issues/59768))

- **Corregidos** los fallos de sondeo de salud de kubelet para los pods de mesh ambient en AWS EKS al usar Security Groups for Pods (branch ENI). istio-cni ahora detecta los pods branch ENI y añade reglas IP para enrutar el tráfico de sondeo a través del par veth en lugar del tejido VPC. Controlado por el flag de características `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` (activado por defecto).

- **Corregidos** los endpoints de depuración XDS (`istio.io/debug/syncz` e `istio.io/debug/config_dump`) servidos por `StatusGen` para aplicar autorización del mismo namespace a los llamantes que no son del sistema. Anteriormente, un workload autenticado de cualquier namespace podía enumerar proxies y recuperar volcados de configuración de workloads en otros namespaces.

**Crédito**: Esta vulnerabilidad fue descubierta y reportada por [1seal](https://github.com/1seal).

## Actualización de seguridad

- **Corregido** un bypass de autorización en `AuthorizationPolicy` donde los metacaracteres de expresiones regulares en ciertos campos de identidad se incrustaban en el `SafeRegex` generado de Envoy sin escapar. Como resultado, los nombres de Kubernetes válidos que contenían caracteres como `.` o `[` podían tratarse como comodines de expresión regular, admitiendo identidades más allá de la intención del autor de la política. Este problema afectaba a `source.principals` (específicamente las coincidencias de sufijo que comenzaban con `*`) y `source.namespaces`.
  ([Issue #59992](https://github.com/istio/istio/issues/59992))

**Crédito**: Esta vulnerabilidad fue descubierta y reportada por [Alex](https://github.com/Alex0Young).
