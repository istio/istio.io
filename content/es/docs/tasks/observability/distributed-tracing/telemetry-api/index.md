---
title: Configurar el trazado con la API de Telemetría
description: Cómo configurar las opciones de trazado usando la API de Telemetría.
weight: 2
keywords: [telemetry,tracing]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio proporciona la capacidad de configurar opciones de trazado, como la tasa de muestreo y la adición de tags personalizados a los spans reportados.
Esta tarea muestra cómo personalizar las opciones de trazado con la API de Telemetría.

## Antes de empezar

1.  Asegúrese de que sus applications propaguen las cabeceras de trazado como se describe [aquí](/es/docs/tasks/observability/distributed-tracing/overview/).

1.  Siga la guía de instalación de trazado que se encuentra en [Integraciones](/es/docs/ops/integrations/)
    según su backend de trazado preferido para instalar el software apropiado y
    configurar un proveedor de extensión.

## Instalación

En este ejemplo, enviaremos trazas a [Zipkin](/es/docs/ops/integrations/zipkin/). Instale Zipkin antes de continuar.

### Configurar un proveedor de extensión

Instale Istio con un [proveedor de extensión](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider) que haga referencia al service de Zipkin:

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
    - name: "zipkin"
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
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
    - name: "zipkin"
EOF
{{< /text >}}

### Verificar los resultados

Puede verificar los resultados [accediendo a la interfaz de usuario de Zipkin](/es/docs/tasks/observability/distributed-tracing/zipkin/).

## Personalización

### Personalizar el muestreo de trazas

La opción de tasa de muestreo se puede utilizar para controlar qué porcentaje de solicitudes se
informan a su sistema de trazado. Esto debe configurarse en función de su
tráfico en la mesh y la cantidad de datos de trazado que desea recopilar.
La tasa predeterminada es del 1%.

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
    - name: "zipkin"
    randomSamplingPercentage: 100.00
EOF
{{< /text >}}

### Personalizar los tags de trazado

Se pueden agregar tags personalizados a los spans en función de literales, variables de entorno y
cabeceras de solicitud del cliente para proporcionar información adicional en los spans
específicos de su entorno.

{{< warning >}}
No hay límite en la cantidad de tags personalizados que puede agregar, pero los nombres de los tags deben ser únicos.
{{< /warning >}}

Puede personalizar los tags usando cualquiera de las tres opciones admitidas a continuación.

1.  Literal representa un valor estático que se agrega a cada span.

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
    name: mesh-default
    namespace: istio-system
    spec:
      tracing:
      - providers:
        - name: "zipkin"
        randomSamplingPercentage: 100.00
        customTags:
          "provider":
            literal:
              value: "zipkin"
    {{< /text >}}

1.  Las variables de entorno se pueden usar cuando el valor del tag personalizado se
    completa a partir de una variable de entorno del proxy del workload.

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: mesh-default
      namespace: istio-system
    spec:
      tracing:
        - providers:
          - name: "zipkin"
          randomSamplingPercentage: 100.00
          customTags:
            "cluster_id":
              environment:
                name: ISTIO_META_CLUSTER_ID
                defaultValue: Kubernetes # optional
    {{< /text >}}

    {{< warning >}}
    Para agregar tags personalizados basados en variables de entorno, debe
    modificar el ConfigMap `istio-sidecar-injector` en su namespace raíz del sistema Istio.
    {{< /warning >}}

1.  La opción de cabecera de solicitud del cliente se puede utilizar para completar el valor del tag a partir de una
    cabecera de solicitud del cliente entrante.

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: mesh-default
      namespace: istio-system
    spec:
      tracing:
        - providers:
          - name: "zipkin"
          randomSamplingPercentage: 100.00
          customTags:
            my_tag_header:
              header:
                name: <CLIENT-HEADER>
                defaultValue: <VALUE>      # optional
    {{< /text >}}

### Personalizar la longitud del tag de trazado

De forma predeterminada, la longitud máxima de la ruta de la solicitud incluida como parte del tag del span `HttpUrl` es 256.
Para modificar esta longitud máxima, agregue lo siguiente a su fichero `tracing.yaml`.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # disable legacy tracing options via `MeshConfig`
    extensionProviders:
    - name: "zipkin"
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
        maxTagLength: <VALUE>
{{< /text >}}
