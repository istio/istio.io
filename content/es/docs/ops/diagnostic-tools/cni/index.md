---
title: Solución de problemas del plugin CNI de Istio
description: Describe herramientas y técnicas para diagnosticar problemas al usar Istio con el plugin CNI.
weight: 90
keywords: [debug, cni]
owner: istio/wg-networking-maintainers
test: n/a
---

Esta página describe cómo solucionar problemas con el plugin CNI de Istio.
Antes de leerla, deberías leer la [guía de instalación y operación de CNI](/es/docs/setup/additional-setup/cni/).

## Registro {#log}

El registro del plugin CNI de Istio proporciona información sobre cómo el plugin configura la redirección del tráfico de los pods de aplicación
en función del `PodSpec`.

El plugin se ejecuta en el espacio de procesos del entorno de ejecución de contenedores, por lo que puedes ver las entradas de registro de CNI en el registro de `kubelet`.
Para facilitar la depuración, el plugin CNI también envía su registro al DaemonSet `istio-cni-node`.

El nivel de registro por defecto del plugin CNI es `info`. Para obtener una salida de registro más detallada, puedes cambiar el nivel editando la opción de instalación `values.cni.logLevel` y reiniciando el pod del DaemonSet de CNI.

El registro del pod del DaemonSet de CNI de Istio también proporciona información sobre la instalación del plugin CNI
y sobre la [reparación de condiciones de carrera](/es/docs/setup/additional-setup/cni/#race-condition--mitigation).

## Monitoreo {#monitoring}

El DaemonSet de CNI [genera métricas](/es/docs/reference/commands/install-cni/#metrics)
que puedes usar para monitorear la instalación de CNI, su estado de preparación y la mitigación de condiciones de carrera.
Por defecto, se agregan anotaciones de scraping de Prometheus (`prometheus.io/port`, `prometheus.io/path`) al pod del DaemonSet `istio-cni-node`.
Puedes recopilar las métricas generadas mediante una configuración estándar de Prometheus.

## Estado de preparación del DaemonSet {#daemonset-readiness}

El estado de preparación (readiness) del DaemonSet de CNI indica que el plugin CNI de Istio está instalado y configurado correctamente.
Si el DaemonSet de CNI de Istio no está listo, es señal de que algo no funciona bien. Revisa los registros del DaemonSet `istio-cni-node` para diagnosticarlo.
También puedes hacer seguimiento del estado de preparación de la instalación de CNI mediante la métrica `istio_cni_install_ready`.

## Reparación de condiciones de carrera {#race-condition-repair}

Por defecto, el DaemonSet de CNI de Istio tiene habilitada la [mitigación de condiciones de carrera](/es/docs/setup/additional-setup/cni/#race-condition--mitigation),
que desaloja cualquier pod que se haya iniciado antes de que el plugin CNI estuviera listo.
Para saber qué pods se desalojaron, busca líneas de registro como la siguiente:

{{< text plain >}}
2024-01-11T01:19:56.429220Z info Pod detected as broken, deleting: service-graph00/svc00-0v1-95b5885bf-zhbzm
{{< /text >}}

También puedes hacer seguimiento de los pods reparados mediante la métrica `istio_cni_repair_pods_repaired_total`.

## Diagnosticar fallos de inicio de pods {#diagnose-pod-start-up-failure}

Un problema habitual con el plugin CNI es que un pod no se inicie debido a un fallo en la configuración de red del contenedor.
Normalmente, el motivo del fallo se escribe en los eventos del pod y puede verse al describir el pod:

{{< text bash >}}
$ kubectl describe pod POD_NAME -n POD_NAMESPACE
{{< /text >}}

Si un pod sigue obteniendo errores de inicialización, revisa el registro del init container `istio-validation` en busca de
errores "connection refused" como los siguientes:

{{< text bash >}}
$ kubectl logs POD_NAME -n POD_NAMESPACE -c istio-validation
...
2021-07-20T05:30:17.111930Z error Error connecting to 127.0.0.6:15002: dial tcp 127.0.0.1:0->127.0.0.6:15002: connect: connection refused
2021-07-20T05:30:18.112503Z error Error connecting to 127.0.0.6:15002: dial tcp 127.0.0.1:0->127.0.0.6:15002: connect: connection refused
...
2021-07-20T05:30:22.111676Z error validation timeout
{{< /text >}}

El init container `istio-validation` levanta un servidor ficticio local que
escucha en los puertos de entrada y salida a los que se redirige el tráfico,
y comprueba si el tráfico de prueba puede redirigirse al servidor ficticio.
Cuando el plugin CNI no configura correctamente la redirección del tráfico del pod,
el init container `istio-validation` bloquea el inicio del pod para evitar que el tráfico eluda la redirección.
Para ver si hubo errores o comportamientos inesperados en la configuración de red,
busca el ID del pod en los registros de `istio-cni-node`.

Otro síntoma de un plugin CNI que no funciona bien es que el pod de la aplicación se desaloja continuamente durante el inicio.
Esto suele deberse a que el plugin no está instalado correctamente, por lo que no se puede configurar la redirección del tráfico del pod.
La [lógica de reparación de condiciones de carrera](/es/docs/setup/additional-setup/cni/#race-condition--mitigation) de CNI considera que el pod está roto debido a la condición de carrera y lo desaloja continuamente.
Si te encuentras con este problema, revisa el registro del DaemonSet de CNI para saber por qué no se pudo instalar correctamente el plugin.
