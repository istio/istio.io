---
title: Notas de Cambios de Istio 1.26.0
linktitle: 1.26.0
subtitle: Versión Principal
description: Notas de versión de Istio 1.26.0.
publishdate: 2025-05-08
release: 1.26.0
weight: 10
aliases:
    - /news/announcing-1.26.0
---

## Gestión de tráfico

* **Mejorado** el agente CNI para que ya no requiera `hostNetwork`, mejorando la compatibilidad. El cambio dinámico a la red del host se realiza ahora según sea necesario. El comportamiento anterior puede restaurarse temporalmente configurando el campo `ambient.shareHostNetworkNamespace` en el chart `istio-cni`. ([Issue #54726](https://github.com/istio/istio/issues/54726))

* **Mejorada** la detección del binario de iptables para validar el soporte básico del kernel y preferir `nft` cuando tanto legacy como `nft` están disponibles pero ninguno tiene reglas existentes.

* **Actualizado** el valor predeterminado del número máximo de conexiones aceptadas por evento de socket a 1 para mejorar el rendimiento. Para revertir al comportamiento anterior, establece `MAX_CONNECTIONS_PER_SOCKET_EVENT_LOOP` en cero.

* **Añadida** la capacidad para que `EnvoyFilter` coincida con un `VirtualHost` por nombre de dominio.

* **Añadido** soporte inicial para las funcionalidades experimentales `BackendTLSPolicy` y `XBackendTrafficPolicy` del Gateway API. Están deshabilitadas por defecto y requieren configurar `PILOT_ENABLE_ALPHA_GATEWAY_API=true`.
  ([Issue #54131](https://github.com/istio/istio/issues/54131)), ([Issue #54132](https://github.com/istio/istio/issues/54132))

* **Añadido** soporte para referenciar `ConfigMap`s, además de `Secret`s, en TLS de `DestinationRule` en modo `SIMPLE`, útil cuando solo se requiere un certificado CA.
  ([Issue #54131](https://github.com/istio/istio/issues/54131)), ([Issue #54132](https://github.com/istio/istio/issues/54132))

* **Añadido** soporte de personalización para [despliegues automáticos del Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment). Aplica a los tipos `Gateway` de Istio (ingress y egress) y a los tipos `Gateway` de Istio Waypoint (waypoints de ambient). Los usuarios pueden personalizar recursos generados como `Service`, `Deployment`, `ServiceAccount`, `HorizontalPodAutoscaler` y `PodDisruptionBudget`.

* **Añadida** una nueva variable de entorno `ENABLE_GATEWAY_API_MANUAL_DEPLOYMENT` para `istiod`. Cuando se establece en `false`, deshabilita la asociación automática de recursos del Gateway API a despliegues de gateway existentes. Por defecto, es `true` para mantener el comportamiento actual.

* **Añadida** la capacidad de configurar predicados de host de reintento mediante la Retry API (`retry_ignore_previous_hosts`).

* **Añadido** soporte para especificar intervalos de backoff durante los reintentos.

* **Añadido** soporte para usar `TCPRoute` en waypoint proxies.

* **Corregido** un error donde el webhook de validación reportaba incorrectamente una advertencia cuando un `ServiceEntry` configuraba un `workloadSelector` con resolución DNS.
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

* **Corregido** un problema donde los FQDNs no funcionaban en un `WorkloadEntry` usando modo ambient.

* **Corregido** un caso donde `ReferenceGrants` no funcionaba cuando mTLS estaba habilitado en un listener de Gateway.
  ([Issue #55623](https://github.com/istio/istio/issues/55623))

* **Corregido** un problema donde Istio no recuperaba correctamente `allowedRoutes` para un waypoint en sandbox.
  ([Issue #56010](https://github.com/istio/istio/issues/56010))

* **Corregido** un error donde los endpoints de `ServiceEntry` se filtraban cuando un pod era desalojado.
  ([Issue #54997](https://github.com/istio/istio/issues/54997))

* **Corregido** un problema donde la dirección del listener se duplicaba para servicios dual stack con prioridad IPv6. ([Issue #56151](https://github.com/istio/istio/issues/56151))

## Seguridad

* **Añadido** soporte experimental para la API `ClusterTrustBundle` v1alpha1. Puede habilitarse configurando `values.pilot.env.ENABLE_CLUSTER_TRUST_BUNDLE_API=true`. Asegúrate de que los feature gates correspondientes estén habilitados en tu clúster; consulta [KEP-3257](https://github.com/kubernetes/enhancements/tree/master/keps/sig-auth/3257-cluster-trust-bundles) para más detalles.
  ([Issue #43986](https://github.com/istio/istio/issues/43986))

## Telemetría

* **Añadido** soporte para el campo `omit_empty_values` en el proveedor `EnvoyFileAccessLog` mediante la Telemetry API.
  ([Issue #54930](https://github.com/istio/istio/issues/54930))

* **Añadida** la variable de entorno `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY`, que separa los spans de tracing para gateways de servidor y cliente. Actualmente tiene valor predeterminado `false`, pero se convertirá en el valor predeterminado en el futuro.

* **Añadido** un mensaje de advertencia por el uso de los proveedores de telemetría obsoletos Lightstep y OpenCensus.
  ([Issue #54002](https://github.com/istio/istio/issues/54002))

## Instalación

* **Mejorada** la experiencia de instalación en GKE. Cuando se configura `global.platform=gke`, los recursos `ResourceQuota` necesarios se despliegan automáticamente. Al instalar mediante `istioctl`, esta configuración también se activa automáticamente si se detecta GKE. Además, `cniBinDir` ahora se configura correctamente.

* **Mejorado** el chart Helm de `ztunnel` para no asignar nombres de recursos a `.Release.Name`, usando `ztunnel` como valor predeterminado. Esto revierte un cambio introducido en Istio 1.25.

* **Añadido** soporte para configurar `reinvocationPolicy` en el webhook de revision-tag al instalar Istio mediante `istioctl` o Helm.

* **Añadida** la capacidad de configurar el `loadBalancerClass` del servicio en el chart Helm de Gateway.
  ([Issue #39079](https://github.com/istio/istio/issues/39079))

* **Añadido** un `ConfigMap` de valores que almacena tanto los valores Helm proporcionados por el usuario como los valores combinados tras aplicar los perfiles del chart `istiod`.

* **Añadido** soporte para leer valores de cabecera desde variables de entorno de `istiod`.
  ([Issue #53408](https://github.com/istio/istio/issues/53408))

* **Añadida** una `updateStrategy` configurable para los charts Helm `ztunnel` e `istio-cni`.

* **Corregido** un error en la plantilla de inyección de sidecar que eliminaba incorrectamente los init containers existentes cuando tanto la intercepción de tráfico como el sidecar nativo estaban deshabilitados.
  ([Issue #54562](https://github.com/istio/istio/issues/54562))

* **Corregidas** las etiquetas `topology.istio.io/network` faltantes en los pods de gateway cuando se usa `--set networkGateway`.
  ([Issue #54909](https://github.com/istio/istio/issues/54909))

* **Corregido** un problema donde configurar `replicaCount=0` en el chart Helm `istio/gateway` causaba que el campo `replicas` se omitiera en lugar de establecerse explícitamente en `0`.
  ([Issue #55092](https://github.com/istio/istio/issues/55092))

* **Corregido** un problema que causaba que las referencias a certificados basadas en archivos (por ejemplo, desde `DestinationRule` o `Gateway`) fallaran al usar SPIRE como CA.

* **Eliminado** el flag `ENABLE_AUTO_SNI` obsoleto y sus rutas de código asociadas.

## istioctl

* **Añadido** el parámetro `--locality` en `istioctl experimental workload group create`.
  ([Issue #54022](https://github.com/istio/istio/issues/54022))

* **Añadida** la capacidad de ejecutar comprobaciones específicas del analizador mediante el comando `istioctl analyze`.

* **Añadido** el parámetro `--tls-server-name` a `istioctl create-remote-secret`, que permite configurar `tls-server-name` en el kubeconfig generado. Esto garantiza conexiones TLS exitosas cuando el campo `server` se reemplaza con un hostname de gateway proxy.

* **Añadido** soporte para el campo `envVarFrom` en el chart `istiod`.

* **Corregido** un problema donde `istioctl analyze` reportaba la anotación `sidecar.istio.io/statsCompression` como desconocida.
  ([Issue #52082](https://github.com/istio/istio/issues/52082))

* **Corregido** un error que bloqueaba la instalación cuando `IstioOperator.components.gateways.ingressGateways.label` era omitido.
  ([Issue #54955](https://github.com/istio/istio/issues/54955))

* **Corregido** un error donde `istioctl` ignoraba los campos `tag` bajo `IstioOperator.components.gateways.ingressGateways` y `egressGateways`.
  ([Issue #54955](https://github.com/istio/istio/issues/54955))

* **Corregido** un problema donde `istioctl waypoint delete` podía eliminar un recurso Gateway que no era waypoint cuando se especificaba un nombre.
  ([Issue #55235](https://github.com/istio/istio/issues/55235))

* **Corregido** un problema donde `istioctl experimental describe` no respetaba el flag `--namespace`.
  ([Issue #55243](https://github.com/istio/istio/issues/55243))

* **Corregido** un error que impedía la generación simultánea de las etiquetas `istio.io/waypoint-for` e `istio.io/rev` al crear un waypoint proxy mediante `istioctl`.
  ([Issue #55437](https://github.com/istio/istio/issues/55437))

* **Corregido** un problema donde `istioctl admin log` no podía modificar el nivel de log para `ingress status`.
  ([Issue #55741](https://github.com/istio/istio/issues/55741))

* **Corregido** un error de validación cuando se configuraba `reconcileIptablesOnStartup: true` en la configuración YAML de `istioctl`.
  ([Issue #55347](https://github.com/istio/istio/issues/55347))
