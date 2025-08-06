---
title: Agregar workloads a la mesh
description: Comprende cómo agregar workloads a un ambient mesh.
weight: 10
owner: istio/wg-networking-maintainers
test: no
---

En la mayoría de los casos, un administrador de cluster desplegará la infraestructura de la mesh de Istio. Una vez que Istio se despliegue con éxito con soporte para el modo de {{< gloss >}}data plane{{< /gloss >}} ambient, estará disponible de forma transparente para las aplicaciones desplegadas por todos los usuarios en los namespaces que se hayan configurado para usarlo.

## Habilitar el modo ambient para aplicaciones en la mesh

Para agregar aplicaciones o namespaces a la mesh en modo ambient, agrega la etiqueta `istio.io/data plane-mode=ambient` al recurso correspondiente. Puedes aplicar esta etiqueta a un namespaces o a un pod individual.

El modo ambient se puede habilitar (o deshabilitar) de forma completamente transparente en lo que respecta a los pods de la aplicación. A diferencia del modo de data plane de {{< gloss >}}sidecar{{< /gloss >}}, no es necesario reiniciar las aplicaciones para agregarlas a la mesh, y no se mostrarán con un contenedor adicional desplegado en su pod.

### Funcionalidad de capa 4 y capa 7

La superposición segura L4 admite políticas de autenticación y autorización. [Aprende sobre el soporte de políticas L4 en modo ambient](/es/docs/ambient/usage/l4-policy/). Para optar por usar la funcionalidad L7 de Istio, como el enrutamiento de tráfico, deberás [desplegar un proxy de waypoint e inscribir tus workloads para usarlo](/es/docs/ambient/usage/waypoint/).

### Ambient y NetworkPolicy de Kubernetes

Consulta [ambient y NetworkPolicy de Kubernetes](/es/docs/ambient/usage/networkpolicy/).

## Comunicación entre pods en diferentes modos de data plane

Existen múltiples opciones para la interoperabilidad entre los pods de la aplicación que utilizan el modo de data plane ambient y los puntos finales no ambient (incluidos los pods de la aplicación de Kubernetes, las gateways de Istio o las instancias de la API de Gateway de Kubernetes). Esta interoperabilidad proporciona múltiples opciones para integrar sin problemas los workloads ambient y no ambient dentro de la misma mesh de Istio, lo que permite una introducción por fases de la capacidad ambient según las necesidades de despliegue y operación de tu malla.

### Pods fuera de la mesh

Puede que tengas namespaces que no forman parte de la mesh en absoluto, ni en modo sidecar ni en modo ambient. En este caso, los pods que no están en la mesh inician el tráfico directamente a los pods de destino sin pasar por el ztunnel del nodo de origen, mientras que el ztunnel del pod de destino aplica cualquier política L4 para controlar si se debe permitir o denegar el tráfico.

Por ejemplo, establecer una política `PeerAuthentication` con el modo mTLS establecido en `STRICT`, en un namespaces con el modo ambient habilitado, hará que se deniegue el tráfico desde fuera de la mesh.

### Pods dentro de la mesh usando el modo sidecar

Istio admite la interoperabilidad Este-Oeste entre un pod con un sidecar y un pod que usa el modo ambient, dentro de la misma malla. El proxy sidecar sabe que debe usar el protocolo HBONE, ya que se ha descubierto que el destino es un destino HBONE.

{{< tip >}}
Para que los proxies sidecar usen la opción de señalización HBONE/mTLS al comunicarse con destinos ambient, deben configurarse con `ISTIO_META_ENABLE_HBONE` establecido en `true` en los metadatos del proxy. Este es el valor predeterminado en `MeshConfig` cuando se usa el perfil `ambient`, por lo que no tienes que hacer nada más al usar este perfil.
{{< /tip >}}

Una política `PeerAuthentication` con el modo mTLS establecido en `STRICT` permitirá el tráfico desde un pod con un proxy sidecar de Istio.

### gateways de entrada y salida y pods en modo ambient

Una gateway de entrada puede ejecutarse en un namespace no ambient y exponer los servicios proporcionados por los pods en modo ambient, modo sidecar o que no están en la mesh. También se admite la interoperabilidad entre los pods en modo ambient y las gateways de Istio.

## Lógica de selección de pods para los modos ambient y sidecar

Los dos modos de data plane de Istio, sidecar y ambient, pueden coexistir en el mismo cluster. Es importante asegurarse de que el mismo pod o namespaces no se configure para usar ambos modos al mismo tiempo. Sin embargo, si esto ocurre, el modo sidecar actualmente tiene prioridad para dicho pod o namespaces.

Ten en cuenta que dos pods dentro del mismo namespaces podrían, en teoría, configurarse para usar diferentes modos etiquetando los pods individuales por separado de la etiqueta del namespace; sin embargo, esto no se recomienda. Para la mayoría de los casos de uso comunes, se debe usar un solo modo para todos los pods dentro de un solo namespaces.

La lógica exacta para determinar si un pod está configurado para usar el modo ambient es la siguiente:

1. La lista de exclusión de la configuración del complemento `istio-cni` configurada en `cni.values.excludeNamespaces` se utiliza para omitir los namespaces en la lista de exclusión.
1. El modo `ambient` se utiliza para un pod si

    *el namespace o el pod tiene la etiqueta `istio.io/data plane-mode=ambient`
    * El pod no tiene la etiqueta de exclusión `istio.io/data plane-mode=none`
    * La anotación `sidecar.istio.io/status` no está presente en el pod

La opción más simple para evitar un conflicto de configuración es que un usuario se asegure de que para cada namespaces, tenga la etiqueta para la inyección de sidecar (`istio-injection=enabled`) o para el modo ambient (`istio.io/data plane-mode=ambient`), pero nunca ambas.
