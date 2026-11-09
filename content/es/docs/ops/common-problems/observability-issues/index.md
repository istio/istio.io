---
title: Problemas de observabilidad
description: Cómo resolver problemas con la recopilación de telemetría.
force_inline_toc: true
weight: 30
aliases:
    - /docs/ops/troubleshooting/grafana
    - /docs/ops/troubleshooting/missing-traces
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

## No aparecen trazas en Zipkin al ejecutar Istio localmente en Mac {#no-traces-appearing-in-zipkin-when-running-istio-locally-on-mac}

Istio está instalado y todo parece funcionar, excepto que no aparecen trazas en Zipkin cuando
debería haberlas.

Esto puede deberse a un [problema conocido de Docker](https://github.com/docker/for-mac/issues/1260) por el que la hora dentro de
los contenedores puede desfasarse significativamente de la hora de la máquina host. Si este es el caso,
cuando selecciones un rango de fechas muy amplio en Zipkin, verás que las trazas aparecen hasta varios días antes de lo que deberían.

También puedes confirmar este problema comparando la fecha dentro de un contenedor de Docker con la de fuera:

{{< text bash >}}
$ docker run --entrypoint date registry.istio.io/testing/ubuntu-16-04-slave:latest
Sun Jun 11 11:44:18 UTC 2017
{{< /text >}}

{{< text bash >}}
$ date -u
Thu Jun 15 02:25:42 UTC 2017
{{< /text >}}

Para solucionar el problema, tendrás que detener y luego reiniciar Docker antes de reinstalar Istio.

## Falta la salida de Grafana {#missing-grafana-output}

Si no puedes obtener la salida de Grafana al conectarte desde un cliente web local a un Istio alojado de forma remota,
debes comprobar que la fecha y la hora del cliente y del servidor coincidan.

La hora del cliente web (p. ej., Chrome) afecta a la salida de Grafana. Una solución sencilla
a este problema es verificar que un servicio de sincronización horaria se esté ejecutando correctamente dentro del
clúster de Kubernetes y que la máquina del cliente web también esté usando correctamente un servicio de sincronización
horaria. Algunos sistemas habituales de sincronización horaria son NTP y Chrony. Esto es especialmente
problemático en laboratorios de ingeniería con firewalls. En estos escenarios, es posible que NTP no esté configurado
correctamente para apuntar a los servicios NTP del laboratorio.

## Verifica que los pods de Istio CNI se estén ejecutando (si se usan) {#verify-istio-cni-pods-are-running-if-used}

El plugin Istio CNI realiza la redirección del tráfico de los pods de la mesh de Istio en la fase de configuración de red del ciclo de vida del pod de Kubernetes, lo que elimina el [requisito de las capacidades `NET_ADMIN` y `NET_RAW`](/es/docs/ops/deployment/application-requirements/) para los usuarios que despliegan pods en la mesh de Istio. El plugin Istio CNI reemplaza la funcionalidad que proporciona el contenedor `istio-init`.

1. Verifica que los pods `istio-cni-node` se estén ejecutando:

    {{< text bash >}}
    $ kubectl -n istio-system get pod -l k8s-app=istio-cni-node
    {{< /text >}}

1. Si [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) se aplica en tu clúster, asegúrate de que el namespace donde se ejecutan los pods `istio-cni-node` (de forma predeterminada, `istio-system`) use el perfil `privileged` de los [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/#privileged) para permitir las capacidades `NET_ADMIN` y `NET_RAW`.
