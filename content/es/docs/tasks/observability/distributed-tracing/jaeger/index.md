---
title: Jaeger
description: Aprenda a configurar los proxies para enviar solicitudes de trazado a Jaeger.
weight: 6
keywords: [telemetry,tracing,jaeger,span,port-forwarding]
aliases:
 - /docs/tasks/telemetry/distributed-tracing/jaeger/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Después de completar esta tarea, comprenderá cómo hacer que su application participe en el trazado con [Jaeger](https://www.jaegertracing.io/),
independientemente del lenguaje, framework o plataforma que utilice para construir su application.

Esta tarea utiliza la muestra [Bookinfo](/es/docs/examples/bookinfo/) como la application de ejemplo.

Para aprender cómo Istio maneja el trazado, visite la [descripción general](../overview/) de esta tarea.

## Antes de empezar

1.  Siga la documentación de [Instalación de Jaeger](/es/docs/ops/integrations/jaeger/#installation) para desplegar Jaeger en su cluster.

1.  Despliegue la application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/#deploying-the-application).

## Configurar Istio para el trazado distribuido

### Configurar un proveedor de extensión

Instale Istio con un [proveedor de extensión](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider) que haga referencia al service del colector de Jaeger:

{{< text bash >}}
$ cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # disable legacy MeshConfig tracing options
    extensionProviders:
    - name: jaeger
      opentelemetry:
        port: 4317
        service: jaeger-collector.istio-system.svc.cluster.local
EOF
$ istioctl install -f ./tracing.yaml --skip-confirmation
{{< /text >}}

### Habilitar el trazado

Habilite el trazado aplicando la siguiente configuración:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: jaeger
EOF
{{< /text >}}

## Acceder al dashboard

La tarea [Acceso Remoto a los Addons de Telemetría](/es/docs/tasks/observability/gateways) detalla cómo configurar el acceso a los addons de Istio a través de un gateway.

Para pruebas (y acceso temporal), también puede usar el reenvío de puertos. Use lo siguiente, asumiendo que ha desplegado Jaeger en el namespace `istio-system`:

{{< text bash >}}
$ istioctl dashboard jaeger
{{< /text >}}

## Generar trazas usando la muestra de Bookinfo

1.  Cuando la application Bookinfo esté en funcionamiento, acceda a `http://$GATEWAY_URL/productpage` una o más veces
    para generar información de traza.

    {{< boilerplate trace-generation >}}

1.  En el panel izquierdo del dashboard, seleccione `productpage.default` de la lista desplegable **Service** y haga clic en
    **Find Traces**:

    {{< image link="./istio-tracing-list.png" caption="Dashboard de Trazado" >}}

1.  Haga clic en la traza más reciente en la parte superior para ver los detalles correspondientes a la
    última solicitud a `/productpage`:

    {{< image link="./istio-tracing-details.png" caption="Vista Detallada de la Traza" >}}

1.  La traza se compone de un conjunto de spans,
    donde cada span corresponde a un service de Bookinfo, invocado durante la ejecución de una solicitud a `/productpage`, o
    a un componente interno de Istio, por ejemplo: `istio-ingressgateway`.

## Limpieza

1.  Elimine cualquier proceso `istioctl` que aún pueda estar ejecutándose usando control-C o:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

1.  Si no planea explorar ninguna tarea de seguimiento, consulte las
    instrucciones de [limpieza de Bookinfo](/es/docs/examples/bookinfo/#cleanup)
    para apagar la application.
