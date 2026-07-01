---
title: Anuncio de Istio 1.28.6
linktitle: 1.28.6
subtitle: Versión de Parche
description: Parche de Istio 1.28.6.
publishdate: 2026-04-13
release: 1.28.6
aliases:
    - /news/announcing-1.28.6
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.28.5 e Istio 1.28.6.

{{< relnote >}}

## Cambios

- **Añadido** soporte de Helm v4 (apply del lado del servidor). Corregido un conflicto de propiedad del campo `failurePolicy` del webhook que causaba que `helm upgrade` con SSA fallara.
  ([Issue #58302](https://github.com/istio/istio/issues/58302)) ([Issue #59367](https://github.com/istio/istio/issues/59367))

- **Añadida** la posibilidad de especificar namespaces autorizados para los endpoints de depuración cuando `ENABLE_DEBUG_ENDPOINT_AUTH=true`. Se habilita configurando `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` con una lista separada por comas de namespaces autorizados. El namespace del sistema (normalmente `istio-system`) siempre está autorizado.

- **Añadido** soporte para bloquear CIDRs en URIs de JWKS al obtener claves públicas para la validación JWT. Si alguna IP resuelta de una URI de JWKS coincide con un CIDR bloqueado, Istio omitirá la obtención de la clave pública y usará un JWKS falso en su lugar para rechazar solicitudes con tokens JWT.

- **Corregido** un conflicto del gestor de campos en `ValidatingWebhookConfiguration` durante `helm upgrade` con apply del lado del servidor en herramientas que respetan `.Release.IsUpgrade` (Helm 4, Flux). El campo `failurePolicy` ahora se omite de la plantilla del webhook al actualizar, preservando el valor establecido en tiempo de ejecución por el controlador del webhook. Para herramientas que usan `helm template` con SSA, establece `base.validationFailurePolicy: Fail` para evitar el conflicto.

- **Corregido** el bloqueo de CIDR en URI de JWKS mediante el uso de una función de control personalizada en un `DialContext` personalizado. La función de control filtra las conexiones después de la resolución DNS pero antes de marcar, permitiendo que el bloqueo siga las redirecciones y la ruta de descubrimiento del emisor. Esto también preserva las características del `DialContext` predeterminado como happy eyeballs y `dialSerial` (intentando cada IP resuelta en orden).

- **Corregida** la expresión regular del comparador `serviceAccount` en `AuthorizationPolicy` para citar correctamente el nombre de la cuenta de servicio, permitiendo la coincidencia correcta de cuentas de servicio con caracteres especiales en sus nombres.
  ([Issue #59700](https://github.com/istio/istio/issues/59700))

- **Corregido** un problema donde el comando `iptables` no esperaba a adquirir un bloqueo en `/run/xtables.lock`, causando algunos errores confusos en los registros.
  ([Issue #58507](https://github.com/istio/istio/issues/58507))

- **Corregido** el análisis del origen CORS de la Gateway API cuando se usa un comodín para también ignorar solicitudes preflight no coincidentes.

- **Corregido** el análisis del encabezado `Origin` de la Gateway API para ser más estricto.

- **Corregido** que istiod fallara cuando `PILOT_ENABLE_AMBIENT=true`, pero `AMBIENT_ENABLE_MULTI_NETWORK` no está configurado y existe un recurso `WorkloadEntry` con una red diferente a la del clúster local.

- **Corregidos** los errores de istiod al iniciar cuando se instala en un clúster una versión de CRD mayor que la versión máxima compatible. Las versiones de `TLSRoute` v1.4 y anteriores son compatibles; v1.5 y superiores se ignorarán.
  ([Issue #59443](https://github.com/istio/istio/issues/59443))

- **Corregida** la aplicación de múltiples recursos `VirtualService` para el mismo nombre de host a los waypoints.
  ([Issue #59483](https://github.com/istio/istio/issues/59483))

- **Corregido** un problema donde todos los `Gateways` se reiniciaban después de que istiod se reiniciara.
  ([Issue #59709](https://github.com/istio/istio/issues/59709))

- **Corregido** un problema donde establecer los límites o solicitudes de recursos a `null` causaba errores de validación (`cpu request must be less than or equal to cpu limit of 0`). Esto afectaba la inyección de proxy, la generación de gateway y los despliegues de charts de Helm.
  ([Issue #58805](https://github.com/istio/istio/issues/58805))

- **Corregidos** los nombres de host de `TLSRoute` para que se restrinjan correctamente a la intersección con el nombre de host del listener del `Gateway`. Anteriormente, una `TLSRoute` con un nombre de host amplio (por ejemplo, `*.com`) adjunto a un listener con un nombre de host más restringido (por ejemplo, `*.example.com`) coincidía incorrectamente con el nombre de host completo de la ruta en lugar de solo con la intersección (`*.example.com`), según lo requerido por la especificación de la Gateway API.
  ([Issue #59229](https://github.com/istio/istio/issues/59229))

- **Corregido** un error donde el `percent` predeterminado para `retryBudget` en `DestinationRule` se establecía incorrectamente en 0.2% en lugar del 20% previsto.
  ([Issue #59504](https://github.com/istio/istio/issues/59504))

- **Corregido** un límite de tamaño faltante en binarios WASM descomprimidos con `gzip` obtenidos a través de HTTP, de forma consistente con los límites ya aplicados a otras rutas de obtención.

- **Corregidos** los `ReadHeaderTimeout` e `IdleTimeout` faltantes en el servidor HTTPS del webhook de istiod (puerto 15017), alineándolos con los tiempos de espera existentes en el servidor HTTP (puerto 8080).

- **Corregida** una condición de carrera que causaba registros de error intermitentes `"proxy::h2 ping error: broken pipe"`.
  ([Issue #59192](https://github.com/istio/istio/issues/59192)) ([Issue #1346](https://github.com/istio/ztunnel/issues/1346))
