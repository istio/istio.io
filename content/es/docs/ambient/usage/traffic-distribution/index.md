---
title: Distribución de tráfico
description: Controla cómo se distribuye el tráfico a los endpoints en modo ambient.
weight: 35
owner: istio/wg-networking-maintainers
test: no
---

La anotación `networking.istio.io/traffic-distribution` controla cómo {{< gloss >}}ztunnel{{< /gloss >}} distribuye el tráfico entre los endpoints disponibles. Es útil para mantener el tráfico local y reducir la latencia y los costos entre zonas.

## Valores soportados

| Valor | Comportamiento |
| --- | --- |
| `PreferSameZone` | Prioriza los endpoints por proximidad: red, región, zona y subzona. El tráfico va primero a los endpoints más cercanos y disponibles. |
| `PreferClose` | Alias obsoleto de `PreferSameZone`. Ver [propuesta de mejora de Kubernetes 3015](https://github.com/kubernetes/enhancements/tree/master/keps/sig-network/3015-prefer-same-node). |
| `PreferSameNode` | Prefiere endpoints en el mismo nodo que el cliente. |
| (sin definir) | Sin preferencia de localidad. El tráfico se distribuye entre todos los endpoints disponibles. |

## Aplicar la anotación

La anotación puede aplicarse a:

- **`Service`**: Afecta el tráfico hacia ese servicio específico
- **`Namespace`**: Establece el valor por defecto para todos los servicios del namespace
- **`ServiceEntry`**: Afecta el tráfico hacia servicios externos

### Precedencia

Cuando se configuran múltiples niveles, el más específico prevalece:

1. Campo `spec.trafficDistribution` (solo en `Service`)
1. Anotación en `Service`/`ServiceEntry`
1. Anotación en `Namespace`
1. Comportamiento por defecto (sin preferencia de localidad)

## Ejemplos

### Configuración por servicio

Aplica a un servicio único:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
spec:
  selector:
    app: my-app
  ports:
  - port: 80
{{< /text >}}

### Configuración a nivel de namespace

Aplica a todos los servicios de un namespace:

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
{{< /text >}}

Los servicios del namespace heredan esta configuración a menos que tengan su propia anotación.

### Anular el valor por defecto del namespace

Un servicio puede anular la configuración del namespace con su propia anotación:

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
---
apiVersion: v1
kind: Service
metadata:
  name: different-service
  namespace: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameNode
spec:
  selector:
    app: different-app
  ports:
  - port: 80
{{< /text >}}

Los servicios sin anotación heredan la configuración del namespace.

## Comportamiento

### `PreferSameZone`

Con `PreferSameZone`, ztunnel categoriza los endpoints por localidad y enruta hacia los más cercanos disponibles:

1. Misma red, región, zona y subzona
1. Misma red, región y zona
1. Misma red y región
1. Misma red
1. Cualquier endpoint disponible

Si todos los endpoints de una localidad más cercana quedan no disponibles, el tráfico hace failover automáticamente al siguiente nivel.

Por ejemplo, un servicio con endpoints en las zonas `us-west`, `us-west` y `us-east`:

- Un cliente en `us-west` envía todo el tráfico a los dos endpoints de `us-west`
- Si un endpoint de `us-west` falla, el tráfico va al endpoint de `us-west` restante
- Si ambos endpoints de `us-west` fallan, el tráfico hace failover a `us-east`

### `PreferSameNode`

Con `PreferSameNode`, ztunnel prefiere los endpoints que se ejecutan en el mismo nodo de Kubernetes que el cliente. Esto minimiza los saltos de red y la latencia para la comunicación local al nodo.

## Relación con `trafficDistribution` de Kubernetes

Kubernetes 1.31 introdujo el campo [`spec.trafficDistribution`](https://kubernetes.io/docs/concepts/services-networking/service/#traffic-distribution) en los `Service`s. Esta anotación de Istio proporciona la misma funcionalidad con beneficios adicionales:

| | `spec.trafficDistribution` | Anotación |
| --- | --- | --- |
| Versión de Kubernetes | 1.31+ | Cualquiera |
| `Service` | Sí | Sí |
| `ServiceEntry` | No | Sí |
| `Namespace` | No | Sí |

Cuando se establecen tanto el campo spec como la anotación en un `Service`, el campo spec tiene precedencia.

Los waypoints configuran esta anotación automáticamente.

## Ver también

- [Balanceo de carga por localidad](/docs/tasks/traffic-management/locality-load-balancing/) para el enrutamiento por localidad basado en sidecar
- [Referencia de anotaciones](/docs/reference/config/annotations/#NetworkingTrafficDistribution)
