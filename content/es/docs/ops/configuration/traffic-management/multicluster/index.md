---
title: Gestión de tráfico multiclúster
description: Cómo configurar la forma en que se distribuye el tráfico entre los clústeres de la mesh.
weight: 70
keywords: [traffic-management,multicluster]
owner: istio/wg-networking-maintainers
test: no
---

En una mesh multiclúster, puede ser conveniente aplicar reglas de tráfico específicas para la topología de clústeres. Este documento describe
algunas formas de gestionar el tráfico en una mesh multiclúster. Antes de leer esta guía:

1. Lee [Modelos de despliegue](/es/docs/ops/deployment/deployment-models/#multiple-clusters)
1. Asegúrate de que tus servicios desplegados siguen el concepto de {{< gloss "namespace sameness" >}}namespace sameness{{< /gloss >}}.

## Mantener el tráfico dentro del clúster {#keeping-traffic-in-cluster}

En algunos casos, el comportamiento predeterminado de balanceo de carga entre clústeres no es deseable. Para mantener el tráfico "local al clúster" (es decir,
que el tráfico enviado desde `cluster-a` solo llegue a destinos en `cluster-a`), marca los nombres de host o los comodines como `clusterLocal`
mediante [`MeshConfig.serviceSettings`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ServiceSettings-Settings).

Por ejemplo, puedes forzar el tráfico local al clúster para un servicio concreto, para todos los servicios de un namespace en particular o de forma global para todos los servicios de la mesh, de la siguiente manera:

{{< tabset category-name="meshconfig" >}}

{{< tab name="per-service" category-value="service" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "mysvc.myns.svc.cluster.local"
{{< /text >}}

{{< /tab >}}

{{< tab name="per-namespace" category-value="namespace" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "*.myns.svc.cluster.local"
{{< /text >}}

{{< /tab >}}

{{< tab name="global" category-value="global" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "*"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

También puedes afinar el acceso a los servicios configurando una regla global local al clúster y agregando excepciones explícitas, que pueden ser específicas o con comodines. En el siguiente ejemplo, todos los servicios del clúster se mantendrán locales al clúster, excepto cualquier servicio del namespace `myns`:

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "*"
- settings:
    clusterLocal: false
  hosts:
  - "*.myns.svc.cluster.local"
{{< /text >}}

## Particionar servicios {#partitioning-services}

[`DestinationRule.subsets`](/es/docs/reference/config/networking/destination-rule/#Subset) permite particionar un servicio
seleccionando etiquetas. Estas etiquetas pueden ser las de los metadatos de Kubernetes o [etiquetas integradas](/es/docs/reference/config/labels/).
Una de estas etiquetas integradas, `topology.istio.io/cluster`, en el selector de subconjunto de un `DestinationRule` permite
crear subconjuntos por clúster.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: mysvc-per-cluster-dr
spec:
  host: mysvc.myns.svc.cluster.local
  subsets:
  - name: cluster-1
    labels:
      topology.istio.io/cluster: cluster-1
  - name: cluster-2
    labels:
      topology.istio.io/cluster: cluster-2
{{< /text >}}

Con estos subconjuntos puedes crear varias reglas de enrutamiento basadas en el clúster, como el [mirroring](/es/docs/tasks/traffic-management/mirroring/)
o el [desplazamiento de tráfico](/es/docs/tasks/traffic-management/traffic-shifting/).

Esto ofrece otra opción para crear reglas de tráfico locales al clúster: restringir el subconjunto de destino en un `VirtualService`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: mysvc-cluster-local-vs
spec:
  hosts:
  - mysvc.myns.svc.cluster.local
  http:
  - name: "cluster-1-local"
    match:
    - sourceLabels:
        topology.istio.io/cluster: "cluster-1"
    route:
    - destination:
        host: mysvc.myns.svc.cluster.local
        subset: cluster-1
  - name: "cluster-2-local"
    match:
    - sourceLabels:
        topology.istio.io/cluster: "cluster-2"
    route:
    - destination:
        host: mysvc.myns.svc.cluster.local
        subset: cluster-2
{{< /text >}}

Usar el enrutamiento basado en subconjuntos de esta forma para controlar el tráfico local al clúster, en lugar de
[`MeshConfig.serviceSettings`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ServiceSettings-Settings),
tiene la desventaja de mezclar la política a nivel de servicio con la política a nivel de topología.
Por ejemplo, una regla que envía el 10% del tráfico a la `v2` de un servicio necesitará el doble
de subconjuntos (p. ej., `cluster-1-v2`, `cluster-2-v2`).
Es mejor limitar este enfoque a situaciones en las que se necesita un control más granular del enrutamiento basado en clústeres.
