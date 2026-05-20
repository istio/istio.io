---
title: Anuncio de Istio 1.29.2
linktitle: 1.29.2
subtitle: Versión de Parche
description: Parche de Istio 1.29.2.
publishdate: 2026-04-13
release: 1.29.2
aliases:
    - /news/announcing-1.29.2
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.29.1 e Istio 1.29.2.

{{< relnote >}}

## Cambios

- **Añadido** soporte de Helm v4 (apply del lado del servidor). Corregido un conflicto de propiedad del campo `failurePolicy` del webhook que causaba que `helm upgrade` con SSA fallara.
  ([Issue #58302](https://github.com/istio/istio/issues/58302)) ([Issue #59367](https://github.com/istio/istio/issues/59367))

- **Corregido** un conflicto del gestor de campos en `ValidatingWebhookConfiguration` durante `helm upgrade` con apply del lado del servidor en herramientas que respetan `.Release.IsUpgrade` (Helm 4, Flux). El campo `failurePolicy` ahora se omite de la plantilla del webhook al actualizar, preservando el valor establecido en tiempo de ejecución por el controlador del webhook. Para herramientas que usan `helm template` con SSA, establece `base.validationFailurePolicy: Fail` para evitar el conflicto.

- **Corregida** la expresión regular del comparador `serviceAccount` en `AuthorizationPolicy` para citar correctamente el nombre de la cuenta de servicio, permitiendo la coincidencia correcta de cuentas de servicio con caracteres especiales en sus nombres.
  ([Issue #59700](https://github.com/istio/istio/issues/59700))

- **Corregido** el bloqueo de CIDR en URI de JWKS mediante el uso de una función de control personalizada en un `DialContext` personalizado. La función de control filtra las conexiones después de la resolución DNS pero antes de marcar, permitiendo que el bloqueo siga las redirecciones y la ruta de descubrimiento del emisor. Esto también preserva las características del `DialContext` predeterminado como happy eyeballs y `dialSerial` (intentando cada IP resuelta en orden).

- **Corregidos** los errores de istiod al iniciar cuando se instala en un clúster una versión de CRD mayor que la versión máxima compatible. Las versiones de `TLSRoute` v1.4 y anteriores son compatibles; v1.5 y superiores se ignorarán.
  ([Issue #59443](https://github.com/istio/istio/issues/59443))

- **Corregidas** las instalaciones multi-clúster que intentaban validar el dominio de confianza incorrecto cuando el plano de control no tiene un `ClusterRole` `istio-reader` actualizado, fallando al leer el dominio de confianza del `ConfigMap` remoto. Ahora, istiod usará como alternativa el dominio de confianza especificado en la configuración de mesh local hasta que pueda leer el remoto.
  ([Issue #59474](https://github.com/istio/istio/issues/59474))

- **Corregida** la aplicación de múltiples recursos `VirtualService` para el mismo nombre de host a los waypoints.
  ([Issue #59483](https://github.com/istio/istio/issues/59483))

- **Corregido** un problema donde `istioctl` reportaba incorrectamente un error en `EnvoyFilter` con operación `REPLACE` en `VIRTUAL_HOST`.
  ([Issue #59495](https://github.com/istio/istio/issues/59495))

- **Corregido** un error donde el gateway E/W ocasionalmente enrutaba conexiones HBONE a un servicio incorrecto debido a un pool de conexiones incorrecto en Envoy.
  ([Issue #58630](https://github.com/istio/istio/issues/58630))

- **Corregido** un problema donde todos los `Gateways` se reiniciaban después de que istiod se reiniciara.
  ([Issue #59709](https://github.com/istio/istio/issues/59709))

- **Corregidos** los nombres de host de `TLSRoute` para que se restrinjan correctamente a la intersección con el nombre de host del listener del `Gateway`. Anteriormente, una `TLSRoute` con un nombre de host amplio (por ejemplo, `*.com`) adjunto a un listener con un nombre de host más restringido (por ejemplo, `*.example.com`) coincidía incorrectamente con el nombre de host completo de la ruta en lugar de solo con la intersección (`*.example.com`), según lo requerido por la especificación de la Gateway API.
  ([Issue #59229](https://github.com/istio/istio/issues/59229))

- **Corregido** un error donde el `percent` predeterminado para `retryBudget` en `DestinationRule` se establecía incorrectamente en 0.2% en lugar del 20% previsto.
  ([Issue #59504](https://github.com/istio/istio/issues/59504))

- **Corregido** un error donde el `retryBudget` configurado en la `trafficPolicy` de nivel superior de una `DestinationRule` se descartaba silenciosamente cuando el destino también tenía un subconjunto con su propia `trafficPolicy`. Además, el `retryBudget` definido a nivel de subconjunto también era ignorado.
  ([Issue #59667](https://github.com/istio/istio/issues/59667))

- **Corregido** un límite de tamaño faltante en binarios WASM descomprimidos con `gzip` obtenidos a través de HTTP, de forma consistente con los límites ya aplicados a otras rutas de obtención.

- **Corregidos** los `ReadHeaderTimeout` e `IdleTimeout` faltantes en el servidor HTTPS del webhook de istiod (puerto 15017), alineándolos con los tiempos de espera existentes en el servidor HTTP (puerto 8080).

- **Corregida** una condición de carrera que causaba registros de error intermitentes `"proxy::h2 ping error: broken pipe"`.
  ([Issue #59192](https://github.com/istio/istio/issues/59192)) ([Issue #1346](https://github.com/istio/ztunnel/issues/1346))
