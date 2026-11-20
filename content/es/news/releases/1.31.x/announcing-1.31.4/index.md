---
title: Anuncio de Istio 1.31.4
linktitle: 1.31.4
subtitle: Versión de Parche
description: Parche de Istio 1.31.4.
publishdate: 2026-11-06
release: 1.31.4
aliases:
    - /news/announcing-1.31.4
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.31.3 e Istio 1.31.4.

{{< relnote >}}

## Actualización de seguridad

Para más información, consulta [ISTIO-SECURITY-2026-009](/es/news/security/istio-security-2026-009).

### CVE de Istio

- __[GHSA-rr2c-p22p-6r9r](https://github.com/istio/istio/security/advisories/GHSA-rr2c-p22p-6r9r)__ (puntuación CVSS 8.2, Alta): En modo ambient, un error de precedencia de operadores permitía omitir una `PeerAuthentication` `STRICT` a nivel de puerto cuando el modo del workload era `PERMISSIVE` o `DISABLE` bajo una política `STRICT` a nivel de toda la mesh, lo que permitía que tráfico en texto plano llegara a un puerto que requería mTLS. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Ravikanth Reddy.
- __[GHSA-7m6f-j3gp-2r53](https://github.com/istio/istio/security/advisories/GHSA-7m6f-j3gp-2r53)__ (puntuación CVSS 6.5, Moderada): Una condición `when` de `AuthorizationPolicy` sobre `request.headers[:authority]` o `request.headers[host]` se evaluaba distinguiendo mayúsculas de minúsculas, por lo que una solicitud con un host escrito con distinta capitalización podía eludirla. Ahora estas condiciones se evalúan sin distinguir mayúsculas de minúsculas, igual que `hosts`. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [@akoul](https://github.com/akoul).
- __[GHSA-cxwg-46mx-q8hf](https://github.com/istio/istio/security/advisories/GHSA-cxwg-46mx-q8hf)__ (puntuación CVSS 7.4, Alta): Una nueva conexión entrante que reutilizaba la 4-tupla de una conexión ya cerrada podía eludir el proxy sidecar al coincidir con una entrada `ESTABLISHED` obsoleta de conntrack. Ahora se evalúa una regla solo para SYN antes de la regla de desvío `ESTABLISHED`, tanto en modo iptables como en nftables. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [@ramaraochavali](https://github.com/ramaraochavali), [@akshayreddyb](https://github.com/akshayreddyb), [@Pawan-Bishnoi](https://github.com/Pawan-Bishnoi) y [@deveshkandpal1224](https://github.com/deveshkandpal1224).
- __[GHSA-635j-qv98-9275](https://github.com/istio/istio/security/advisories/GHSA-635j-qv98-9275)__ (puntuación CVSS 7.7, Alta): Cualquier workload con una identidad de la mesh podía hacer fallar istiod enviando una solicitud xDS `istio.io/debug` cuyo nombre de recurso no superaba el análisis de URL, dejando el control plane en un bucle de fallos para toda la mesh. Ahora la solicitud se rechaza con `InvalidArgument`. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Alon Lerner de Checkmarx Research.
- __[GHSA-8jw7-82jp-wr2c](https://github.com/istio/istio/security/advisories/GHSA-8jw7-82jp-wr2c)__ (puntuación CVSS 6.3, Moderada): En modo ambient, una `AuthorizationPolicy` con una entrada `to` o `from` vacía que el webhook de validación no rechazaba hacía que istiod fallara y entrara en un bucle de fallos hasta que se eliminaba la política, deteniendo la distribución de la configuración para toda la mesh. Ahora estas entradas se tratan como una `operation` o `source` vacía, igual que en el comportamiento de sidecar. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [@r0binak](https://github.com/r0binak).
- __[GHSA-gf6w-6mxv-5fj4](https://github.com/istio/istio/security/advisories/GHSA-gf6w-6mxv-5fj4)__ (puntuación CVSS 6.3, Moderada): En instalaciones multiclúster, un proxy podía reclamar el `CLUSTER_ID` de otro clúster y recibir por SDS los secretos `kubernetes://` de ese clúster. istiod ya no acepta un `CLUSTER_ID` en los metadatos del nodo que difiera del clúster contra el que se validó el token del proxy. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Yonghwa Lee (Xint by Theori).
- __[GHSA-77vw-rg85-wx5x](https://github.com/istio/istio/security/advisories/GHSA-77vw-rg85-wx5x)__ (puntuación CVSS 6.5, Moderada): ztunnel entraba en pánico al analizar un encabezado `traceparent` de 55 bytes que no contenía cuatro campos separados por guiones, terminando la tarea de la conexión HBONE entrante y descartando todos los streams multiplexados en esa conexión. Los encabezados con la longitud correcta pero con una disposición de campos no válida también se aceptaban en lugar de rechazarse. Ahora los encabezados `traceparent` no válidos se ignoran y se genera un nuevo ID de traza. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [@RaphaelFakhri](https://github.com/RaphaelFakhri).
- __[GHSA-9gqj-583v-mpqp](https://github.com/istio/istio/security/advisories/GHSA-9gqj-583v-mpqp)__ (puntuación CVSS 5.6, Moderada): `ipBlocks`, `notIpBlocks` y la condición `source.ip` de `AuthorizationPolicy` en waypoints de ambient, y en sidecars que reciben tráfico HBONE, se evaluaban contra la dirección del listener interno de Envoy en lugar de la IP del cliente, por lo que las reglas `DENY` sobre estos campos podían fallar de forma permisiva.

### Otras correcciones de seguridad de Istio

- **Corregido** que la actualización periódica en segundo plano del resolutor de JWKS almacenara en caché una respuesta obtenida sin validar que tuviera aspecto de JWKS. La ruta de obtención síncrona ya rechazaba una respuesta que no tuviera la forma de un JWKS (`{"keys": [...]}`), evitando que la respuesta de un `jwksUri` de `RequestAuthentication` que apuntara a un endpoint interno no previsto se almacenara en caché y se sirviera como si fuera un JWKS. Ahora la ruta de actualización en segundo plano aplica la misma comprobación. **Crédito**: Este problema fue reportado por Anthropic y Ada Logics.

## Cambios

- **Añadido** soporte para listeners `AUTO_PASSTHROUGH` en los gateways east-west de ambient (`GatewayClass` `istio-east-west`). Un listener TLS passthrough en el puerto 15443 (o en cualquier puerto que use la opción `gateway.istio.io/listener-protocol: auto-passthrough`) ahora sirve tráfico multi-network de sidecars junto con el listener HBONE, de modo que una mesh mixta de ambient y sidecars ya no necesita dos gateways east-west por clúster. Esto requiere que `AMBIENT_ENABLE_MULTI_NETWORK` esté habilitado. ([Issue #60887](https://github.com/istio/istio/issues/60887))

- **Corregido** un pánico de istiod cuando se aplicaba `outlierDetection` a un clúster comodín de dynamic forward proxy (DFP). ([Issue #61450](https://github.com/istio/istio/issues/61450))

- **Corregido** un problema por el que el chart de Helm de `istio-cni` no respetaba el valor definido en `istioOwnedCNIConfigFileName`.

- **Corregido** un problema por el que las actualizaciones de la configuración de `istio-cni` mediante el chart de Helm no reiniciaban `istio-cni` para que tomara los nuevos valores.

- **Corregido** un problema por el que, al desinstalar el chart de Helm de `istio-cni`, no se eliminaba la configuración propia de `istio-cni` o no se quitaba el plugin `istio-cni` de la configuración CNI principal.

- **Corregido** un problema por el que, al habilitar la configuración propia de `istio-cni`, no se limpiaba la configuración CNI principal.

- **Corregido** un problema por el que, al cambiar el nombre de archivo de la configuración propia de `istio-cni`, no se eliminaba el nombre anterior. ([Issue #61890](https://github.com/istio/istio/issues/61890))

- **Corregido** que las etiquetas de métrica `source_app` y `destination_app` usen la etiqueta de pod `app` cuando un pod también tiene `app.kubernetes.io/name`. Desde 1.29.1 usaban `app.kubernetes.io/name`, lo cual es una regresión respecto al comportamiento previsto. ([Issue #62280](https://github.com/istio/istio/issues/62280))

- **Corregida** una situación en la que la obtención del JWKS podía bloquear la generación de xDS. ([Pull Request #62486](https://github.com/istio/istio/pull/62486))

- **Corregida** la coincidencia de `ipBlocks` y `notIpBlocks` de `AuthorizationPolicy` en los listeners internos HBONE de waypoints y sidecars para que use la dirección IP remota directa del cliente downstream en lugar de la dirección interna de Envoy. ([Issue #62522](https://github.com/istio/istio/issues/62522))

- **Corregido** un problema por el que `istio-cni` omitía la limpieza de un pod ambient eliminado junto con su namespace, dejando atrás su proxy ztunnel y la entrada ipset de la sonda del host.

- **Corregido** un problema introducido en Istio 1.31 por el que un cambio en un `ConfigMap` que contiene certificados de CA, como el `ConfigMap` `kube-root-ca.crt` que Kubernetes crea en cada namespace, desencadenaba pushes de CDS, LDS, RDS y NDS a todos los proxies. Los clústeres se reconstruían por completo en lugar de forma incremental. Igual que las actualizaciones de `Secret`, ahora estos cambios solo desencadenan pushes de SDS. Ahora también se omite EDS en estas actualizaciones. ([Issue #62523](https://github.com/istio/istio/issues/62523))

- **Corregido** un problema por el que una actualización de solo metadatos de un `EndpointSlice`, como una herramienta de GitOps que escribe una anotación, desencadenaba un push de EDS y, en el caso de `Services` headless con puertos no HTTP, un push a todos los proxies, aunque los endpoints no hubieran cambiado.

- **Corregido** que `istiod` solo toleraba el taint `cni.istio.io/not-ready` por defecto. Cuando `taint.name` se define con un taint personalizado, el deployment de `istiod` ahora tolera ese taint, de modo que `istiod` puede programarse en nodos que aún lo tengan. ([Issue #52073](https://github.com/istio/istio/issues/52073))

- **Corregido** un problema por el que una actualización de solo metadatos de un recurso de configuración de Istio, como una herramienta de GitOps que escribe una anotación, desencadenaba un push siempre que el recurso tuviera cualquier etiqueta o anotación `istio.io`, por ejemplo `istio.io/rev`. Ahora el push solo se desencadena cuando cambia el spec o el valor de una etiqueta o anotación `istio.io`.

- **Corregida** una regresión por la que un recurso `Telemetry` en el propio namespace de un waypoint, seleccionado mediante `targetRefs` o `selector`, no se aplicaba cuando el waypoint servía un `Service` de un namespace diferente. El registro de acceso, las métricas y el trazado configurados de esta forma se descartaban silenciosamente para todos los `Service` de otros namespaces que el waypoint gestionaba. ([Issue #61538](https://github.com/istio/istio/issues/61538))
