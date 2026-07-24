---
title: Instalar en múltiples clústeres
description: Instala una mesh de Istio en modo ambient en múltiples clústeres de Kubernetes.
weight: 40
keywords: [kubernetes,multicluster,ambient]
simple_list: true
content_above: true
test: table-of-contents
owner: istio/wg-environments-maintainers
next: /docs/ambient/install/multicluster/before-you-begin
---

Sigue esta guía para instalar una {{< gloss "ambient" >}}mesh de servicio ambient{{< /gloss >}} de Istio
que abarca múltiples {{< gloss "cluster" >}}clústeres{{< /gloss >}}.

## Estado actual y limitaciones

{{< warning >}}
Aunque el multiclúster **multi-red** en modo ambient ha alcanzado estado beta y se considera listo
para producción, aún existen limitaciones conocidas que aplican al despliegue multiclúster en modo ambient. La intención
es abordar esas limitaciones en futuras releases de Istio; mientras tanto, consulta
la lista a continuación para ver si las limitaciones conocidas aplican a tu caso de uso.
{{< /warning >}}

Antes de proceder con la instalación multiclúster en modo ambient, es fundamental entender
el estado actual y las limitaciones de esta característica.

### Limitaciones conocidas

#### Restricciones de topología de red

Las configuraciones multiclúster de red única no han sido probadas y pueden estar rotas:

- Usa precaución al desplegar ambient en clústeres que comparten la misma red
- Solo se soportan configuraciones multi-red

#### Limitaciones del control plane

La configuración primary-remote no está soportada actualmente:

- Solo puedes tener múltiples clústeres primarios
- Las configuraciones con uno o más clústeres remotos no funcionarán correctamente

#### Requisitos de waypoint

Se asume que los despliegues de waypoint son uniformes entre clústeres:

- Todos los clústeres deben tener despliegues de waypoint con nombres idénticos
- Las configuraciones de waypoint deben sincronizarse manualmente entre clústeres (por ejemplo, usando Flux, ArgoCD o herramientas similares)
- El enrutamiento de tráfico depende de convenciones de nombres de waypoint consistentes

#### Visibilidad y alcance de servicios

Las configuraciones de alcance de servicio no se leen entre clústeres:

- Solo se soportan configuraciones de alcance de servicio uniformes — el alcance del servicio debe coincidir en todos los clústeres
- Solo la configuración de alcance de servicio del clúster local se usa como fuente de verdad
- Los alcances de servicio de clústeres remotos no se respetan, lo que puede llevar a comportamiento inesperado de tráfico cuando el mismo servicio tiene diferentes alcances en diferentes clústeres
- El descubrimiento de servicios entre clústeres puede no respetar los límites de servicio previstos

Si el waypoint de un servicio está marcado como global, ese servicio también será global:

- Esto puede llevar a tráfico entre clústeres no deseado en despliegues multiclúster de red única
- La solución a este problema se rastrea [aquí](https://github.com/istio/istio/issues/57710)

#### Distribución de carga en red remota

El tráfico hacia una red remota no se distribuye igualmente entre endpoints:

- Al hacer failover a una red remota, un solo endpoint en una red remota puede recibir un número desproporcionado de requests debido al multiplexing de requests HTTP y el pooling de conexiones
- Un problema muy similar existe actualmente también en modo sidecar
- La solución a este problema se rastrea [aquí](https://github.com/istio/istio/issues/58039)

#### Limitaciones del gateway

Los gateways east-west en modo ambient actualmente solo soportan tráfico mTLS en la mesh:

- Actualmente no es posible exponer `istiod` entre redes usando gateways east-west en modo ambient. Puedes seguir usando un gateway e/w clásico para esto.

{{< tip >}}
A medida que el multiclúster en modo ambient madura, muchas de estas limitaciones se abordarán.
Consulta las [notas de release de Istio](https://istio.io/latest/news/) para actualizaciones sobre
las capacidades multiclúster en modo ambient.
{{< /tip >}}
