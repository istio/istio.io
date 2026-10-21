---
title: Anuncio de Istio 1.31.1
linktitle: 1.31.1
subtitle: Versión de Parche
description: Parche de Istio 1.31.1.
publishdate: 2026-09-21
release: 1.31.1
aliases:
    - /news/announcing-1.31.1
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.31.0 e Istio 1.31.1.

{{< relnote >}}

## Actualización de seguridad

### CVEs de Istio

- __[GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx)__ (puntuación CVSS 6.8, Moderada): `BackendTLSPolicy` falla en modo fail-open a texto plano en proxies sidecar cuando su referencia CA no está resuelta.

## Cambios

- **Mejorado** el rendimiento al obtener las `PeerAuthentications` de un workload determinado.

- **Actualizado** el addon de Kiali a la versión v2.31.0.

- **Corregido** un problema en modo ambient donde el backend de iptables (`legacy` vs `nft`) autodetectado por el agente de nodo CNI podía cambiar entre reinicios del agente, provocando que se escribieran reglas de redirección duplicadas en pods ya inscritos. ([Issue #61020](https://github.com/istio/istio/issues/61020))

- **Corregida** la capacidad de borrar la Lista de Revocación de Certificados (CRL), ya sea especificando una cadena vacía como `ca-crl.pem` o eliminándolo. ([Issue #61073](https://github.com/istio/istio/issues/61073))

- **Corregido** el resolvedor de JWKS que forzaba todas las obtenciones de claves públicas a HTTP/1.1. El `TLSClientConfig` y el `DialContext` personalizados, usados para el pinning de TLS y el bloqueo de CIDR, hacían que `net/http` de Go deshabilitara HTTP/2 automático, por lo que ALPN nunca negociaba h2. HTTP/2 ahora se vuelve a habilitar (igual que `http.DefaultTransport`), corrigiendo las obtenciones de JWKS que fallan sobre HTTP/1.1 a través de algunos proxies HTTP CONNECT. ([Issue #61250](https://github.com/istio/istio/issues/61250))

- **Corregido** un problema donde el uso de CPU de istiod aumentaba a medida que aumentaba el número de `AuthorizationPolicies`. ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **Corregido** el tráfico `ALLOW_ANY_DYNAMIC_DNS` que fallaba en clústeres solo IPv6 porque Envoy usaba la dirección de loopback IPv4 para llegar al proxy DNS. ([Issue #61330](https://github.com/istio/istio/issues/61330))

- **Corregido** un problema donde istiod serializaba repetidamente el mismo workload al enviar metadatos de workload a los proxies Envoy. ([Issue #61502](https://github.com/istio/istio/issues/61502))

- **Corregido** un problema donde los proxies Envoy suscritos al descubrimiento de metadatos de Workload (MDS) no recibían actualizaciones incrementales de workload para cambios solo de Address cuando `AMBIENT_SCOPED_ADDRESS_PUSHES` estaba habilitado (el valor por defecto).

- **Corregido** un problema donde un waypoint de agentgateway al que un servicio hacía referencia solo como su canary, mediante la etiqueta `istio.io/use-waypoint-canary`, no se programaba con las rutas y políticas asociadas a ese servicio. Las conexiones desplazadas al waypoint canary se rechazaban, porque el waypoint no tenía configuración para el servicio al que daba servicio. ([Issue #61036](https://github.com/istio/istio/issues/61036))

- **Corregida** una fuga de memoria que afectaba al modo ambient multiclúster de Istiod, donde rotar las credenciales de un clúster remoto filtraba todo el estado en caché de ese clúster. ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Corregido** `istioctl analyze`, que construía clientes de Kubernetes directamente a partir de los secrets multiclúster de `istio-system` sin sanear el kubeconfig, lo que podía permitir que un secret manipulado ejecutara un plugin de credenciales `exec` (o leyera archivos locales mediante otros campos de autenticación inseguros) en la máquina que ejecuta `istioctl`. El kubeconfig ahora se sanea de la misma manera en que istiod ya sanea estos secrets. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Adam Korczynski.

- **Corregido** el bypass del aislamiento NAMESPACE de `serviceEntryVisibility` mediante la etiqueta `istio.io/use-waypoint-canary`: un `ServiceEntry` con visibilidad NAMESPACE podía enrutar su porción canary de tráfico a través de un waypoint de otro namespace. El waypoint canary ahora está sujeto al mismo rechazo cross-namespace que el principal. **Crédito**: Este problema fue reportado por Raphael Zanarelli.

- **Corregido** el `ValidatingWebhookConfiguration` del chart `default`, que seguía codificando `failurePolicy: Ignore`, lo que causaba el mismo conflicto de field manager en `helm upgrade` con server-side apply que ya se había corregido para los charts `base` e `istiod`. ([Issue #61613](https://github.com/istio/istio/issues/61613))

- **Corregido** un problema donde istiod conservaba permanentemente una copia de cada nombre de recurso de workload por cada conexión de envoy MDS (WDS, usada para consultas de metadatos de telemetría) que enviaba `initial_resource_versions`.

- **Corregida** la anotación `sidecar.istio.io/statsFlushInterval`, que producía un bootstrap de Envoy inválido para valores de un minuto o más, y para valores inferiores a un segundo, lo que impedía que el proxy arrancara.

- **Corregida** la anotación `sidecar.istio.io/statsEvictionInterval`, que truncaba silenciosamente la precisión inferior a un segundo.

- **Corregido** un problema de la Gateway API donde un `certificateRef` o `caCertificateRef` TLS cross-namespace se resolvía antes de la verificación de autorización de `ReferenceGrant`, de modo que el estado `ResolvedRefs` de un listener podía revelar si el `Secret` o `ConfigMap` referenciado existía incluso cuando ningún grant permitía la referencia. La autorización ahora se ejecuta primero, devolviendo `RefNotPermitted` para cualquier referencia cross-namespace no permitida por un grant. **Crédito**: Este problema fue reportado por Darryl Jaskolski.

- **Corregida** una brecha de SSRF en la obtención de `jwksUri` de `RequestAuthentication` de istiod. istiod ahora bloquea las direcciones de enlace local y de metadatos de nube conocidas (como `169.254.169.254`) a nivel de dial de forma predeterminada y rechaza las respuestas obtenidas que no son un JWKS válido. Los rangos privados y de loopback siguen siendo accesibles y pueden bloquearse con `BLOCKED_CIDRS_IN_JWKS_URIS`.

- **Corregida** una fuga de memoria en el modo ambient multiclúster donde las colecciones se registraban en el depurador de krt pero nunca se eliminaban del registro cuando se quitaba un clúster remoto o cambiaba su configuración, haciendo que los registros del depurador se acumularan con el tiempo. ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Corregido** el seguimiento de conflictos de listeners, que trataba un `Gateway` y un `ListenerSet` con el mismo namespace y nombre como el mismo objeto, lo que hacía que un conflicto registrado para uno marcara el listener ganador del otro como `Conflicted` e impidiera que se programara.

- **Corregido** un problema donde los `ServiceEntries` con un selector de workload presente pero vacío coincidían incorrectamente con todos los workloads de su namespace.

- **Corregido** un problema donde un pod de un clúster remoto, seleccionado por un `ServiceEntry`, podía no recalcularse cuando se convertía en endpoint de ese servicio. El recálculo se dirigía al clúster donde se ejecuta istiod en lugar de al clúster al que pertenece el pod.

- **Corregido** un problema donde un `WorkloadEntry` seleccionado por un `Service` no tenía su proxy correspondiente recalculado cuando se convertía en endpoint de ese servicio.

- **Corregidas** varias anotaciones `sidecar.istio.io/*` (`proxyImage`, `bootstrapOverride`, `logLevel`, `componentLogLevel`, `agentLogLevel`) que se interpolaban en las plantillas de inyección de sidecar/gateway sin escapar la salida, lo que podía permitir que un valor de anotación diseñado maliciosamente inyectara campos adicionales en el spec del pod o despliegue generado. Estas anotaciones ahora se escapan de forma consistente en cada punto de inserción de la plantilla. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por `localhost-detect`.

- **Corregido** `observedGeneration`, que se quedaba atascado en un valor obsoleto cuando un recurso se modifica de nuevo mientras una escritura de estado anterior sigue en cola.
