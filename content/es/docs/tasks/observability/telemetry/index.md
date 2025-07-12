---
title: API de Telemetría
description: Esta tarea muestra cómo configurar la API de Telemetría.
weight: 0
keywords: [telemetry]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
status: Stable
---

Istio proporciona una [API de Telemetría](/es/docs/reference/config/telemetry/) que permite una configuración flexible de
[métricas](/es/docs/tasks/observability/metrics/), [registros de acceso](/es/docs/tasks/observability/logs/) y [trazado](/es/docs/tasks/observability/distributed-tracing/).

## Uso de la API

### Alcance, Herencia y Anulaciones

Los recursos de la API de Telemetría heredan la configuración de los recursos padre en la jerarquía de configuración de Istio:

1.  namespace de configuración raíz (ejemplo: `istio-system`)
1.  namespace local (recurso con alcance de namespace **sin** `selector` de workload)
1.  workload (recurso con alcance de namespace con un `selector` de workload)

Un recurso de la API de Telemetría en el namespace de configuración raíz, típicamente `istio-system`, proporciona valores predeterminados para el comportamiento de toda la malla.
Cualquier selector específico de workload en el namespace de configuración raíz será ignorado/rechazado. No es válido definir múltiples
recursos de la API de Telemetría de toda la malla en el namespace de configuración raíz.

Las anulaciones específicas del namespace para la configuración de toda la malla se pueden lograr aplicando un nuevo recurso `Telemetry` en el namespace deseado
(sin un selector de workload). Cualquier campo especificado en la configuración del namespace anulará completamente
el campo de la configuración padre (en el namespace de configuración raíz).

Las anulaciones específicas del workload se pueden lograr aplicando un nuevo recurso Telemetry en el namespace deseado *con un selector de workload*.

### Selección de Workload

Los workloads individuales dentro de un namespace se seleccionan a través de un [`selector`](/es/docs/reference/config/type/workload-selector/#WorkloadSelector)
que permite la selección de workloads basada en etiquetas.

No es válido que dos recursos `Telemetry` diferentes seleccionen el mismo workload usando `selector`. Del mismo modo, no es válido tener dos
recursos `Telemetry` distintos en un namespace sin `selector` especificado.

### Selección de Proveedor

La API de Telemetría utiliza el concepto de proveedores para indicar el protocolo o tipo de integración a utilizar. Los proveedores se pueden configurar en [`MeshConfig`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider).

Un ejemplo de conjunto de configuración de proveedor en `MeshConfig` es:

{{< text yaml >}}
data:
  mesh: |-
      extensionProviders: # El siguiente contenido define dos proveedores de trazado de ejemplo.
      - name: "localtrace"
        zipkin:
          service: "zipkin.istio-system.svc.cluster.local"
          port: 9411
          maxTagLength: 56
      - name: "cloudtrace"
        stackdriver:
          maxTagLength: 256
{{< /text >}}

Para mayor comodidad, Istio viene con algunos proveedores configurados de fábrica con valores predeterminados:

| Nombre del Proveedor | Funcionalidad                    |
| ------------- | -------------------------------- |
| `prometheus`  | Métricas                          |
| `stackdriver` | Métricas, Trazado, Registro de Acceso |
| `envoy`       | Registro de Acceso                   |

Además, se puede establecer un [proveedor predeterminado](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-DefaultProviders) que
se utilizará cuando los recursos `Telemetry` no especifiquen un proveedor.

{{< tip >}}
Si está utilizando la configuración de [Sidecar](/es/docs/reference/config/networking/sidecar/), no olvide agregar el service del proveedor.
{{< /tip >}}

{{< tip >}}
Los proveedores no admiten `$(HOST_IP)`. Si está ejecutando el colector en modo agente, puede usar la [política de tráfico interno del service](https://kubernetes.io/docs/concepts/services-networking/service-traffic-policy/#using-service-internal-traffic-policy), y establecer `InternalTrafficPolicy` en `Local` para un mejor rendimiento.
{{< /tip >}}

## Ejemplos

### Configuración del comportamiento de toda la malla

Los recursos de la API de Telemetría heredan del namespace de configuración raíz para una malla, típicamente `istio-system`. Para configurar
el comportamiento de toda la malla, agregue un nuevo (o edite el existente) recurso `Telemetry` en el namespace de configuración raíz.

Aquí hay un ejemplo de configuración que utiliza la configuración del proveedor de la sección anterior:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: localtrace
    customTags:
      foo:
        literal:
          value: bar
    randomSamplingPercentage: 100
{{< /text >}}

Esta configuración anula el proveedor predeterminado de `MeshConfig`, estableciendo el valor predeterminado de la malla en el proveedor `localtrace`.
También establece el porcentaje de muestreo de toda la malla en `100`, y configura una etiqueta para que se agregue a todos los spans de traza con
un nombre de `foo` y un valor de `bar`.

### Configuración del comportamiento de trazado con alcance de namespace

Para adaptar el comportamiento a namespaces individuales, agregue un recurso `Telemetry` al namespace deseado.
Cualquier campo especificado en el recurso del namespace anulará completamente la configuración de campo heredada de la jerarquía de configuración.
Por ejemplo:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: namespace-override
  namespace: myapp
spec:
  tracing:
  - customTags:
      userId:
        header:
          name: userId
          defaultValue: unknown
{{< /text >}}

Cuando se despliega en una malla con la configuración de ejemplo de toda la malla anterior, esto dará como resultado
un comportamiento de trazado en el namespace `myapp` que envía spans de traza al proveedor `localtrace` y
selecciona aleatoriamente solicitudes para el trazado a una tasa del `100%`, pero que establece etiquetas personalizadas para cada span con
un nombre de `userId` y un valor tomado de la cabecera de solicitud `userId`.
Es importante destacar que la etiqueta `foo: bar` de la configuración padre no se utilizará en el namespace `myapp`.
El comportamiento de las etiquetas personalizadas anula completamente el comportamiento configurado en el recurso `mesh-default.istio-system`.

{{< tip >}}
Cualquier configuración en un recurso `Telemetry` anula completamente la configuración de su recurso padre en la jerarquía de configuración. Esto incluye la selección de proveedor.
{{< /tip >}}

### Configuración del comportamiento específico del workload

Para adaptar el comportamiento a workloads individuales, agregue un recurso `Telemetry` al namespace deseado y use un
`selector`. Cualquier campo especificado en el recurso específico del workload anulará completamente la configuración de campo heredada
de la jerarquía de configuración.

Por ejemplo:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: workload-override
  namespace: myapp
spec:
  selector:
    matchLabels:
      service.istio.io/canonical-name: frontend
  tracing:
  - disableSpanReporting: true
{{< /text >}}

En este caso, el trazado se deshabilitará para el workload `frontend` en el namespace `myapp`.
Istio seguirá reenviando las cabeceras de trazado, pero no se informarán spans al proveedor de trazado configurado.

{{< tip >}}
No es válido que dos recursos `Telemetry` con selectores de workload seleccionen el mismo workload. En esos casos, el comportamiento es indefinido.
{{< /tip >}}
