---
title: Anuncio de Istio 1.29.6
linktitle: 1.29.6
subtitle: Versión de Parche
description: Parche de Istio 1.29.6.
publishdate: 2026-07-16
release: 1.29.6
aliases:
    - /news/announcing-1.29.6
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.29.5 e Istio 1.29.6.

{{< relnote >}}

## Cambios

- **Corregido** un problema donde `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` nunca se activaba en los ingress gateways de ambient y los waypoints porque el bucle de vaciado de pilot-agent contaba las conexiones en proceso en los listeners internos HBONE de Envoy (`connect_originate`, `connect_terminate`, `main_internal`, etc.), lo que impedía que el recuento de conexiones activas llegara a cero y obligaba al proxy a esperar hasta `terminationGracePeriodSeconds`.
  ([Issue #60728](https://github.com/istio/istio/issues/60728))

- **Corregido** un problema donde la capacidad HBONE anunciada no se propagaba a los recursos `WorkloadEntry` auto-registrados para workloads que no son de Kubernetes. Ten en cuenta que los workloads auto-registrados antes de la actualización seguirán siendo alcanzados en texto plano hasta que se vuelvan a registrar o se añada la etiqueta `networking.istio.io/tunnel=http` a su `WorkloadEntry` existente.

- **Corregido** un deadlock en el agente CNI del modo ambient donde un evento de eliminación de pod concurrente con una (re)conexión de ztunnel podía bloquear permanentemente el servidor ZDS.
  ([Issue ztunnel/1674](https://github.com/istio/ztunnel/issues/1674))

- **Corregida** una fuga de memoria en Istiod donde las entradas `needResync` para IPs de pods fallidos nunca se limpiaban.

- **Corregido** el tráfico entre redes a través del east-west gateway bloqueado por un filtro RBAC de denegación total espurio cuando el servicio de destino tiene `AuthorizationPolicies` L7.
  ([Issue #60806](https://github.com/istio/istio/issues/60806))
