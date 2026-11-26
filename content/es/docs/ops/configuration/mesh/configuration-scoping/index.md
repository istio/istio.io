---
title: Delimitación de la configuración
description: Muestra cómo delimitar el alcance de la configuración en Istio para obtener beneficios operativos y de rendimiento.
weight: 60
keywords: [scalability]
owner: istio/wg-networking-maintainers
test: no
---

Para programar la service mesh, el control plane de Istio (Istiod) lee diversas configuraciones, incluidos tipos básicos de Kubernetes como `Service` y `Node`,
y tipos propios de Istio como `Gateway`.
Después, estas configuraciones se envían al data plane (consulta [Arquitectura](/es/docs/ops/deployment/architecture/) para más información).

Por defecto, el control plane lee toda la configuración de todos los namespaces.
Cada instancia de proxy también recibe la configuración de todos los namespaces.
Esto incluye información sobre workloads que no forman parte de la mesh.

Este comportamiento por defecto garantiza que todo funcione correctamente desde el primer momento, pero tiene un costo en escalabilidad.
Mantener cada configuración y tenerla actualizada tiene un costo (principalmente, en CPU y memoria).
A gran escala, es fundamental limitar el alcance de la configuración para evitar un consumo excesivo de recursos.

## Mecanismos de delimitación {#scoping-mechanisms}

Istio ofrece varias herramientas para controlar el alcance de una configuración y adaptarse a distintos casos de uso.
Según tus requisitos, puedes usarlas por separado o combinadas.

* `Sidecar` proporciona un mecanismo para que workloads específicos _importen_ un conjunto de configuraciones
* `exportTo` proporciona un mecanismo para _exportar_ una configuración a un conjunto de workloads
* `discoverySelectors` proporciona un mecanismo para que Istio ignore por completo un conjunto de configuraciones

### Importación con `Sidecar`

El campo [`egress.hosts`](/es/docs/reference/config/networking/sidecar/#IstioEgressListener) de `Sidecar`
permite especificar una lista de configuraciones que se van a importar.
Los sidecars afectados por el recurso `Sidecar` solo verán las configuraciones que cumplan los criterios especificados.

Por ejemplo:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata:
  name: default
spec:
  egress:
  - hosts:
    - "./*" # Import all configuration from our own namespace
    - "bookinfo/*" # Import all configuration from the bookinfo namespace
    - "external-services/example.com" # Import only 'example.com' from the external-services namespace
{{< /text >}}

### `exportTo`

Los recursos `VirtualService`, `DestinationRule` y `ServiceEntry` de Istio ofrecen un campo `spec.exportTo`.
De forma similar, `Service` se puede configurar con la anotación `networking.istio.io/exportTo`.

A diferencia de `Sidecar`, que permite al propietario de un workload controlar qué dependencias tiene, `exportTo` funciona al revés y permite a los propietarios de servicios controlar
la visibilidad de sus propios servicios.

Por ejemplo, esta configuración hace que el `Service` `details` solo sea visible en su propio namespace y en el namespace `client`:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: details
  annotations:
    networking.istio.io/exportTo: ".,client"
spec: ...
{{< /text >}}

{{< tip >}}
Como `exportTo` lo declara el autor de cada recurso, permite que los propietarios de servicios delimiten su propia configuración,
pero no le da a un administrador de la mesh control sobre lo que publican otros. A partir de Istio 1.31, un administrador
de la mesh puede controlar la visibilidad de los recursos `ServiceEntry` con
[`meshConfig.serviceEntryVisibility`](/es/docs/ambient/usage/serviceentry-visibility/), que el data plane ambient
siempre respeta.
{{< /tip >}}

### `DiscoverySelectors`

Mientras que los controles anteriores actúan a nivel del propietario del workload o del servicio, [`DiscoverySelectors`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) proporciona control sobre la visibilidad de la configuración en toda la mesh.
Los discovery selectors permiten especificar criterios para determinar qué namespaces deben ser visibles para el control plane.
El control plane ignora por completo cualquier namespace que no coincida.

Esto se puede configurar como parte de `meshConfig` durante la instalación. Por ejemplo:

{{< text yaml >}}
meshConfig:
  discoverySelectors:
    - matchLabels:
        # Allow any namespaces with `istio-discovery=enabled`
        istio-discovery: enabled
    - matchLabels:
        # Allow "kube-system"; Kubernetes automatically adds this label to each namespace
        kubernetes.io/metadata.name: kube-system
{{< /text >}}

{{< warning >}}
Istiod siempre abrirá un watch en Kubernetes sobre todos los namespaces.
Sin embargo, los discovery selectors descartan los objetos no seleccionados en una fase muy temprana del procesamiento, lo que minimiza los costos.
{{</ warning >}}

## Preguntas frecuentes

### ¿Cómo puedo saber cuánto cuesta una configuración determinada?

Para obtener el mejor retorno de la inversión al reducir el alcance de la configuración, puede ser útil entender el costo de cada objeto.
Lamentablemente, no hay una respuesta sencilla: la escalabilidad depende de una gran cantidad de factores.
Aun así, hay algunas pautas generales:

Los *cambios* de configuración son costosos en Istio, ya que obligan a volver a calcularla.
Aunque los cambios en `Endpoints` (que suelen producirse al aumentar o reducir el número de Pods) están muy optimizados, la mayoría de las demás configuraciones son bastante costosas.
Esto puede ser especialmente perjudicial cuando hay controladores que modifican un objeto constantemente (¡a veces ocurre por accidente!).
Algunas herramientas para detectar qué configuraciones están cambiando:
* Istiod registra cada cambio con un mensaje como: `Push debounce stable 1 for config Gateway/default/gateway: ..., full=true`.
  Esto indica que cambió un objeto `Gateway` en el namespace `default`. `full=false` representaría una actualización optimizada, como la de un `Endpoint`.
  Nota: todos los cambios en `Service` y `Endpoints` aparecen como `ServiceEntry`.
* Istiod expone las métricas `pilot_k8s_cfg_events` y `pilot_k8s_reg_events` para cada cambio.
* `kubectl get <resource> --watch -oyaml --show-managed-fields` puede mostrar los cambios en un objeto (o en varios) para ayudarte a entender qué está cambiando y quién lo cambia.

Los [Services headless](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) (salvo los declarados como [HTTP](/es/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection))
escalan con el número de instancias. Por eso, los Services headless grandes son costosos y buenos candidatos para excluirlos con `exportTo` o un mecanismo equivalente.

### ¿Qué pasa si me conecto a un servicio que queda fuera del alcance de mi configuración?

Al conectarte a un servicio que se excluyó mediante uno de los mecanismos de delimitación, el data plane no sabrá nada del destino,
por lo que se tratará como [tráfico sin coincidencia](/es/docs/ops/configuration/traffic-management/traffic-routing/#unmatched-traffic).

### ¿Y los gateways?

Aunque los [gateways](/es/docs/setup/additional-setup/gateway/) respetan `exportTo` y `DiscoverySelectors`, los objetos `Sidecar` no afectan a los gateways.
Sin embargo, a diferencia de los sidecars, los gateways no tienen por defecto configuración para todo el clúster.
En su lugar, cada configuración se asocia explícitamente al gateway, lo que evita este problema en gran medida.

No obstante, [actualmente](https://github.com/istio/istio/issues/29131) una parte de la configuración del data plane (un "cluster", en terminología de Envoy) siempre se envía para
todo el clúster, aunque no se haga referencia a ella explícitamente.
