---
title: Anuncio de Istio 1.30.3
linktitle: 1.30.3
subtitle: Versión de Parche
description: Parche de Istio 1.30.3.
publishdate: 2026-07-16
release: 1.30.3
aliases:
    - /news/announcing-1.30.3
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.30.2 e Istio 1.30.3.

{{< relnote >}}

## Cambios

- **Añadido** soporte para un nombre de taint personalizado en el controlador de descontaminación de nodos de pilot mediante la
  variable de entorno `PILOT_NODE_UNTAINT_CONTROLLERS_TAINT_NAME`. El valor predeterminado es `cni.istio.io/not-ready`.
  ([Issue #57844](https://github.com/istio/istio/issues/57844))

- **Mejorada** la escalabilidad de istiod en modo ambient al limitar los pushes XDS derivados de cambios en
  `Address` de workload/servicio únicamente a los waypoints afectados, en lugar de enviarlos a todos los waypoints y proxies.
  Puede deshabilitarse con `AMBIENT_SCOPED_ADDRESS_PUSHES=false`.

- **Corregida** la recarga de certificados faltante en pilot-agent en la segunda y sucesivas rotaciones de secrets de Kubernetes
  para certificados montados como archivos.
  ([Issue #59912](https://github.com/istio/istio/issues/59912))

- **Corregido** un problema donde los namespaces adicionales en `meshConfig.defaultServiceExportTo` y
  `meshConfig.defaultVirtualServiceExportTo` no se respetaban cuando el valor predeterminado incluía
  el namespace actual como `.`.
  ([Issue #60560](https://github.com/istio/istio/issues/60560))

- **Corregido** un error donde istiod no recogía los secrets de clústeres remotos actualizados (p.ej., durante
  la rotación de credenciales/tokens) hasta que se reiniciaba. El nuevo registro de clústeres podía entrar en deadlock esperando
  sincronizarse, dejando el registro de servicios obsoleto para el clúster remoto afectado.
  ([Issue #60612](https://github.com/istio/istio/issues/60612))

- **Corregido** un problema introducido en Istio 1.30 donde los cambios solo de metadatos en objetos `VirtualService`
  (p.ej., anotaciones de Helm, etiquetas de Argo CD o `kubectl.kubernetes.io/last-applied-configuration`)
  desencadenaban pushes XDS innecesarios a todos los proxies. Esto podía causar un aumento significativo en
  el uso de CPU del control plane y la latencia de push en clústeres con muchos `VirtualServices` gestionados por herramientas GitOps.
  La corrección restaura el comportamiento anterior donde solo los cambios de especificación o cambios de
  etiqueta/anotación `istio.io` desencadenan un push.
  ([Issue #60629](https://github.com/istio/istio/issues/60629))

- **Corregido** un error donde un `Service` que hacía referencia a un waypoint en un namespace diferente no tenía
  el recurso `Telemetry` de todo el namespace incluido como parte de su configuración.
  ([Issue #60665](https://github.com/istio/istio/issues/60665))

- **Corregidos** los reintentos HTTP predeterminados para las rutas entrantes de waypoints. La
  `defaultHttpRetryPolicy` de la configuración de mesh se aplicará a los servicios locales adjuntos a waypoints.
  ([Issue #60682](https://github.com/istio/istio/issues/60682))

- **Corregido** un problema donde `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` nunca se activaba en gateways de ingreso ambient
  y waypoints porque el bucle de drenaje de pilot-agent contaba conexiones en curso en los listeners internos HBONE de Envoy
  (`connect_originate`, `connect_terminate`, `main_internal`, etc.), impidiendo que el recuento de conexiones activas
  llegara a cero y forzando al proxy a esperar hasta `terminationGracePeriodSeconds`.
  ([Issue #60728](https://github.com/istio/istio/issues/60728))

- **Corregido** un problema donde la capacidad HBONE anunciada no se propagaba a los recursos `WorkloadEntry` auto-registrados
  para workloads no-Kubernetes. Ten en cuenta que los workloads auto-registrados antes de la actualización continuarán
  siendo alcanzados en texto plano hasta que se vuelvan a registrar o se añada la etiqueta
  `networking.istio.io/tunnel=http` a su `WorkloadEntry` existente.

- **Corregido** un deadlock en el agente CNI ambient donde un evento de eliminación de pod concurrente con una
  (re)conexión de ztunnel podía bloquear permanentemente el servidor ZDS.
  ([Issue ztunnel/1674](https://github.com/istio/ztunnel/issues/1674))

- **Corregida** una fuga de memoria en Istiod donde las entradas `needResync` para IPs de pods fallidas nunca se limpiaban.

- **Corregido** un error donde un `WasmPlugin` en un namespace de aplicación que apuntaba a un `Service` mediante `targetRefs`
  causaba que un proxy waypoint entrara en un bucle de reinicio al arrancar. La ruta LDS incluía correctamente el plugin para
  el waypoint, pero la ruta de búsqueda ECDS lo rechazaba como cross-namespace, dejando a Envoy esperando un
  recurso que nunca llegaría.
  ([Issue #60530](https://github.com/istio/istio/issues/60530))

- **Corregido** el tráfico cross-network a través del gateway east-west que era bloqueado por un filtro RBAC
  deny-all espurio cuando el servicio destino tenía `AuthorizationPolicies` L7.
  ([Issue #60806](https://github.com/istio/istio/issues/60806))
