---
title: Antes de comenzar
description: Pasos iniciales antes de instalar Istio en múltiples clústeres.
weight: 1
keywords: [kubernetes,multicluster,ambient]
test: n/a
owner: istio/wg-environments-maintainers
next: /docs/ambient/install/multicluster/multi-primary_multi-network
prev: /docs/ambient/install/multicluster
---

Antes de comenzar una instalación multiclúster, revisa la
[guía de modelos de despliegue](/docs/ops/deployment/deployment-models)
que describe los conceptos fundamentales usados a lo largo de esta guía.

Además, revisa los requisitos y realiza los pasos iniciales a continuación.

## Requisitos

### Clúster

Esta guía requiere que tengas dos clústeres de Kubernetes con soporte para Services de tipo `LoadBalancer` en cualquiera de las
[versiones de Kubernetes soportadas:](/docs/releases/supported-releases#support-status-of-istio-releases) {{< supported_kubernetes_versions >}}.

### Acceso al API Server

El API Server en cada clúster debe ser accesible para los otros clústeres de la mesh. Muchos proveedores de nube hacen que los API Servers sean públicamente accesibles a través de balanceadores de carga de red (NLB). El gateway east-west en modo ambient no puede usarse para exponer el API Server ya que solo soporta tráfico HBONE doble. Un gateway [east-west](https://en.wikipedia.org/wiki/East-west_traffic) no-ambient podría usarse para habilitar el acceso al API Server.

## Variables de entorno

Esta guía hará referencia a dos clústeres: `cluster1` y `cluster2`. Las siguientes
variables de entorno se usarán a lo largo de la guía para simplificar las instrucciones:

Variable | Descripción
-------- | -----------
`CTX_CLUSTER1` | El nombre del contexto en el [archivo de configuración de Kubernetes](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) predeterminado usado para acceder al clúster `cluster1`.
`CTX_CLUSTER2` | El nombre del contexto en el [archivo de configuración de Kubernetes](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) predeterminado usado para acceder al clúster `cluster2`.

Establece las dos variables antes de proceder:

{{< text syntax=bash snip_id=none >}}
$ export CTX_CLUSTER1=<tu contexto del cluster1>
$ export CTX_CLUSTER2=<tu contexto del cluster2>
{{< /text >}}

## Configurar la confianza

Un despliegue de mesh de servicio multiclúster requiere que establezcas confianza
entre todos los clústeres de la mesh. Dependiendo de los requisitos de tu
sistema, puede haber múltiples opciones disponibles para establecer confianza.
Consulta [gestión de certificados](/docs/tasks/security/cert-management/) para
descripciones detalladas e instrucciones de todas las opciones disponibles.
Dependiendo de la opción que elijas, las instrucciones de instalación de
Istio pueden cambiar ligeramente.

Esta guía asumirá que usas una raíz común para generar certificados intermedios
para cada clúster primario.
Sigue las [instrucciones](/docs/tasks/security/cert-management/plugin-ca-cert/)
para generar y enviar un secreto de certificado CA a ambos clústeres `cluster1` y `cluster2`.

{{< tip >}}
Si actualmente tienes un solo clúster con una CA auto-firmada (como se describe
en [Comenzando](/docs/setup/getting-started/)), necesitas
cambiar la CA usando uno de los métodos descritos en
[gestión de certificados](/docs/tasks/security/cert-management/). Cambiar la
CA generalmente requiere reinstalar Istio. Las instrucciones de instalación
a continuación pueden necesitar modificarse según tu elección de CA.
{{< /tip >}}

## Próximos pasos

Ahora estás listo para instalar una mesh ambient de Istio en múltiples clústeres.

- [Instalar multi-primary en redes diferentes](/docs/ambient/install/multicluster/multi-primary_multi-network)

{{< tip >}}
Si planeas instalar Istio multiclúster usando Helm, primero sigue los
[prerequisitos de Helm](/docs/setup/install/helm/#prerequisites) en la guía de instalación con Helm.
{{< /tip >}}
