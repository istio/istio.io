---
title: Apache SkyWalking
description: Aprenda a configurar los proxies para enviar solicitudes de trazado a Apache SkyWalking.
weight: 8
keywords: [telemetry,tracing,skywalking,span,port-forwarding]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Después de completar esta tarea, comprenderá cómo hacer que su application participe en el trazado con [Apache SkyWalking](https://skywalking.apache.org),
independientemente del lenguaje, framework o plataforma que utilice para construirla.

Esta tarea utiliza la muestra [Bookinfo](/es/docs/examples/bookinfo/) como la application de ejemplo.

Para aprender cómo Istio maneja el trazado, visite la sección de [Descripción General del Trazado Distribuido](../overview/).

## Configurar el trazado

Si utilizó una configuración de `IstioOperator` para instalar Istio, agregue el siguiente campo a su configuración:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultProviders:
      tracing:
      - "skywalking"
    enableTracing: true
    extensionProviders:
    - name: "skywalking"
      skywalking:
        service: tracing.istio-system.svc.cluster.local
        port: 11800
{{< /text >}}

Con esta configuración, Istio se instala con un Agente de SkyWalking como el trazador predeterminado. Los datos de la traza se enviarán a un backend de SkyWalking.

En el perfil predeterminado, la tasa de muestreo es del 1%. Auméntela al 100% usando la [API de Telemetría](/es/docs/tasks/observability/telemetry/):

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - randomSamplingPercentage: 100.00
EOF
{{< /text >}}

## Desplegar el Collector de SkyWalking

Siga la documentación de [instalación de SkyWalking](/es/docs/ops/integrations/skywalking/#installation) para desplegar SkyWalking en su cluster.

## Desplegar la Application Bookinfo

Despliegue la application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/#deploying-the-application).

## Acceder al dashboard

La tarea [Acceso Remoto a los Addons de Telemetría](/es/docs/tasks/observability/gateways) detalla cómo configurar el acceso a los addons de Istio a través de un gateway.

Para pruebas (y acceso temporal), también puede usar el reenvío de puertos. Use lo siguiente, asumiendo que ha desplegado SkyWalking en el namespace `istio-system`:

{{< text bash >}}
$ istioctl dashboard skywalking
{{< /text >}}

## Generar trazas usando la muestra de Bookinfo

1.  Cuando la application Bookinfo esté en funcionamiento, acceda a `http://$GATEWAY_URL/productpage` una o más veces
    para generar información de traza.

    {{< boilerplate trace-generation >}}

1.  En el panel "General Service", puede ver la lista de services.

    {{< image link="./istio-service-list-skywalking.png" caption="Lista de Services" >}}

1.  Seleccione la pestaña `Trace` en el contenido principal. Puede ver la lista de trazas en la barra lateral izquierda y los detalles de la traza en el panel derecho:

    {{< image link="./istio-tracing-list-skywalking.png" caption="Vista de Traza" >}}

1.  La traza se compone de un conjunto de spans,
    donde cada span corresponde a un service de Bookinfo, invocado durante la ejecución de una solicitud a `/productpage`, o
    a un componente interno de Istio, por ejemplo: `istio-ingressgateway`.

## Explorar la application de demostración oficial de SkyWalking

En este tutorial, utilizamos la application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/#deploying-the-application), en esta application de ejemplo
no hay ningún agente de SkyWalking instalado en los services, todas las trazas son generadas por los proxies sidecar.

Si desea explorar más sobre los [agentes de lenguaje de SkyWalking](https://skywalking.apache.org/docs/#Agent), el equipo de SkyWalking también proporciona
[una application de demostración](http://github.com/apache/skywalking-showcase) que está integrada con los agentes de lenguaje y puede tener trazas más detalladas, así como otras features específicas del agente de lenguaje
como el perfilado.

## Limpieza

1.  Elimine cualquier proceso `istioctl` que aún pueda estar ejecutándose usando control-C o:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

1.  Si no planea explorar ninguna tarea de seguimiento, consulte las
    instrucciones de [limpieza de Bookinfo](/es/docs/examples/bookinfo/#cleanup)
    para apagar la application.
