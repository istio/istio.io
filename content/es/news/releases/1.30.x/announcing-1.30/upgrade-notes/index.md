---
title: Notas de Actualización
description: Cambios importantes a considerar al actualizar a Istio 1.30.0.
weight: 20
---

Al actualizar de Istio 1.29.0 a Istio 1.30.0, debes considerar los cambios en esta página.
Estas notas detallan los cambios que rompen intencionalmente la compatibilidad con versiones anteriores de Istio 1.29.x.
Las notas también mencionan cambios que preservan la compatibilidad con versiones anteriores al mismo tiempo que introducen nuevos comportamientos.
Solo se incluyen cambios si el nuevo comportamiento sería inesperado para un usuario de Istio 1.29.x.

## Permisos del archivo de configuración CNI cambiados a 0600

Los permisos de archivo predeterminados para los archivos de configuración CNI escritos por Istio han cambiado de 0644 a 0600.
Esto se alinea con el requisito del benchmark de Kubernetes CIS `v1.12`. Dado que la configuración CNI solo es leída
por el runtime de contenedores que se ejecuta como root, esto no debería tener ningún impacto funcional. Si tienes herramientas
que necesitan leer archivos de configuración CNI como miembro de un grupo no root, puedes establecer los permisos en 0640 mediante
la configuración de la variable de entorno `values.cni.env.CNI_CONF_GROUP_READ=true` en el `DaemonSet`
`istio-cni-node`.

## El Agente CNI respeta la configuración `excludeNamespaces`

Anteriormente, solo el Plugin CNI respetaba la configuración `excludeNamespaces` omitiendo el procesamiento de los pods de namespaces excluidos,
mientras que el Agente CNI aún reconciliaba y añadía pods con etiqueta ambient en un namespace excluido al mesh.
Ahora, el Agente CNI respeta los namespaces excluidos, lo que significa que los pods existentes y matriculados en un namespace excluido serán des-matriculados, y
los nuevos pods con etiqueta ambient en un namespace excluido no serán matriculados.

## Controlador de descontaminación

La variable de entorno `PILOT_ENABLE_NODE_UNTAINT_CONTROLLERS` ahora se configura automáticamente cuando `taint.enabled` está configurado en el chart de Helm para el despliegue `istiod`. Ya no es necesaria la activación manual de esta variable en el despliegue `istiod`.

## Selección del namespace de servicio del proxy sidecar modificada

Al configurar proxies sidecar, si un nombre de host existe en múltiples namespaces, Istio ahora prefiere los recursos `Service` de Kubernetes
y recurre al servicio no-Kubernetes más antiguo por tiempo de creación. Anteriormente, se elegía el primer namespace visible alfabéticamente.

Esto puede causar que el tráfico se enrute a una instancia de servicio diferente si tienes el mismo nombre de host en múltiples
namespaces con tipos de servicio mixtos (por ejemplo, un `Service` de Kubernetes y un `ServiceEntry`).

Si esto no es deseado, establece la variable de entorno `PILOT_SIDECAR_PICK_BEST_SERVICE_NAMESPACE` en `false`
en Istiod, o usa `compatibilityVersion` 1.28 o anterior para restaurar el comportamiento anterior.

## Los endpoints de depuración XDS ahora requieren autenticación

Los endpoints de depuración XDS (`syncz`, `config_dump`) en el puerto 15010 ahora requieren autenticación.
Esto afecta a los comandos `istioctl` que usan el flag `--plaintext` y las herramientas personalizadas que usan XDS de texto plano.
Para restaurar el comportamiento anterior, establece `ENABLE_DEBUG_ENDPOINT_AUTH=false`.
