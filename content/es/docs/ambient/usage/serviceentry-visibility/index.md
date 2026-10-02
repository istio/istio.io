---
title: Visibilidad de ServiceEntry
description: Controla qué namespaces pueden descubrir y resolver cada ServiceEntry.
weight: 40
keywords: [ambient,serviceentry,visibility]
owner: istio/wg-networking-maintainers
test: no
---

Un [`ServiceEntry`](/es/docs/reference/config/networking/service-entry/) agrega un servicio al registro interno de servicios de Istio. De forma predeterminada, un `ServiceEntry` es visible para todos los workloads de la mesh: cualquiera que pueda crear un `ServiceEntry` en *cualquier* namespace puede definir *cualquier* nombre de host —por ejemplo `example.com`— e impactar en cómo toda la mesh lo resuelve y enruta.

El campo [`exportTo`](/es/docs/ops/configuration/mesh/configuration-scoping/) no protege contra esto, porque lo declara el propio autor del `ServiceEntry`: permite que el propietario de un servicio delimite lo que publica, pero no impone ninguna restricción firme. Históricamente, un administrador de la mesh necesitaría restringir la creación de `ServiceEntry` con un control de admisión externo, como un `ValidatingAdmissionPolicy` o un webhook de Kubernetes.

A partir de Istio 1.31, la configuración de mesh [`serviceEntryVisibility`](/es/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility) le da al administrador de la mesh ese control desde un único lugar. El data plane {{< gloss >}}ambient{{< /gloss >}} ({{< gloss >}}ztunnel{{< /gloss >}} y {{< gloss "waypoint" >}}waypoints{{< /gloss >}}) respeta la visibilidad siempre que esté configurada; los sidecars y gateways pueden [habilitarla de forma explícita](#extending-visibility-to-sidecars-and-gateways). La característica es inerte a menos que se configure: si `serviceEntryVisibility` no está establecido, nada cambia.

El diseño refleja deliberadamente un patrón familiar de Kubernetes: un `RoleBinding` solo tiene efecto dentro de su propio namespace, mientras que crear un efecto a nivel de clúster con un `ClusterRoleBinding` está reservado para los administradores del clúster. `serviceEntryVisibility` le permite al administrador de la mesh aplicar el mismo modelo a `ServiceEntry`: al establecer `defaultVisibility: NAMESPACE`, un administrador hace que cada `ServiceEntry` se comporte como cualquier otro recurso delimitado por namespace, y la visibilidad más allá del propio namespace de un `ServiceEntry` se convierte en una capacidad que el administrador otorga explícitamente.

## Cómo se resuelve la visibilidad

Cuando `serviceEntryVisibility` está configurado, istiod resuelve una visibilidad para cada `ServiceEntry`:

1. La lista `policies` se evalúa en orden. La primera política cuyas `matchingRules` coincidan todas (semántica AND) determina la visibilidad.
1. Si ninguna política coincide, se aplica `defaultVisibility`.

Hoy, la única regla de coincidencia es `namespaceSelector`: un selector de etiquetas estándar de Kubernetes evaluado contra las etiquetas del **namespace en el que está definido el `ServiceEntry`**.

{{< tip >}}
Cada namespace lleva automáticamente la etiqueta `kubernetes.io/metadata.name`, de modo que un `namespaceSelector` puede hacer coincidir un namespace por su nombre.
{{< /tip >}}

Un `ServiceEntry` se resuelve en una de tres visibilidades:

| Visibilidad | Significado |
| --- | --- |
| `PUBLIC` | Visible para todos los workloads conectados a este control plane. Este es el comportamiento existente, y el predeterminado cuando `defaultVisibility` no está establecido. |
| `NAMESPACE` | Visible únicamente dentro del namespace en el que está definido el `ServiceEntry`. |
| `NONE` | No es visible para nadie: el `ServiceEntry` se puede escribir, pero Istio no configura ningún data plane para él. Útil para prohibir expresamente una clase de `ServiceEntry`. |

Consulta la [referencia de configuración de mesh](/es/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility) para la documentación completa de los campos.

## Configurar la visibilidad

La siguiente configuración mantiene cada `ServiceEntry` privado dentro de su propio namespace, mientras permite que los recursos `ServiceEntry` en `istio-system` —un namespace en el que solo puede escribir el administrador de la mesh— se publiquen a toda la mesh:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    serviceEntryVisibility:
      # Los ServiceEntries que no coincidan con ninguna política a continuación permanecen en su propio namespace.
      defaultVisibility: NAMESPACE
      policies:
        # Los ServiceEntries en istio-system son visibles en toda la mesh.
        - visibility: PUBLIC
          matchingRules:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: istio-system
{{< /text >}}

Las políticas también pueden otorgar visibilidad a grupos de namespaces. Por ejemplo, una política que coincida con una etiqueta de namespace `trusted: "true"` te permite delegar la capacidad de publicar recursos `ServiceEntry` de toda la mesh etiquetando namespaces.

## Visibilidad en modo ambient

Cuando `serviceEntryVisibility` está configurado, el data plane ambient siempre lo respeta. Istiod resuelve la visibilidad de cada `ServiceEntry` y la distribuye junto con la definición del servicio; ztunnel luego la aplica del lado del cliente, en función del namespace del workload que realiza la solicitud:

* Un servicio `PUBLIC` se comporta exactamente como antes.
* Un servicio `NAMESPACE` puede ser descubierto y resuelto por workloads en su propio namespace. Para workloads en cualquier otro namespace, es como si el `ServiceEntry` no existiera.
* Un servicio `NONE` nunca se entrega a ningún data plane en absoluto.

### Oculto significa ausente, no bloqueado

{{< warning >}}
La visibilidad oculta un `ServiceEntry`; no bloquea el tráfico. Los clientes fuera del namespace no reciben respuestas `NXDOMAIN` ni rechazos de conexión; se comportan exactamente como lo harían si el `ServiceEntry` nunca se hubiera creado.
{{< /warning >}}

Esto es deliberado: si ztunnel en su lugar fallara las consultas DNS para los nombres de host ocultos, un `ServiceEntry` que reclamara `example.com` en un namespace rompería `example.com` para toda la mesh, exactamente el problema que esta característica existe para controlar. En concreto, para un cliente fuera del namespace del `ServiceEntry`:

* **DNS**: una consulta para el nombre de host oculto se reenvía al resolvedor upstream, devolviendo la respuesta real (o un `NXDOMAIN` real si el nombre no existe públicamente).
* **Direcciones**: el tráfico hacia una dirección IP que solo reclama un `ServiceEntry` oculto se trata como tráfico desconocido y se pasa a su destino original.
* **Nombres de host compartidos**: si un `ServiceEntry` oculto y uno `PUBLIC` definen el mismo nombre de host, los clientes fuera del namespace de la entrada oculta siempre son atendidos por la definición `PUBLIC`.

### Waypoints

Adjuntar un waypoint de otro namespace a un `ServiceEntry` con visibilidad `NAMESPACE` permitiría que el tráfico y la configuración escaparan del límite del namespace, por lo que el control plane rechaza los enlaces de [waypoint entre namespaces](/es/docs/ambient/usage/waypoint/#usewaypointnamespace) para ellos. El rechazo se reporta en el estado del `ServiceEntry` con la condición `istio.io/WaypointBound: False` y el motivo `CrossNamespaceWaypointForbidden`.

Enlazar un waypoint en el *mismo* namespace funciona normalmente, y los recursos `ServiceEntry` `PUBLIC` no se ven afectados.

## Extender la visibilidad a sidecars y gateways {#extending-visibility-to-sidecars-and-gateways}

En {{< gloss >}}modo sidecar{{< /gloss >}}, los propietarios de servicios ya delimitan sus recursos `ServiceEntry` con `exportTo`, por lo que respetar la visibilidad es opcional para los sidecars, lo que permite una adopción incremental durante una migración a ambient sin cambiar un despliegue sidecar que ya funciona:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    serviceEntryVisibility:
      defaultVisibility: NAMESPACE
      applyToSidecars: true
{{< /text >}}

Con `applyToSidecars` habilitado, la visibilidad resuelta actúa como un límite máximo sobre el `exportTo` del `ServiceEntry`: el alcance efectivo es la intersección del `exportTo` declarado y la visibilidad resuelta. A pesar del nombre del campo, esto se aplica a todos los proxies basados en Envoy, incluidos los gateways de ingress y egress.

La visibilidad puede reducir lo que declara `exportTo`, pero nunca lo amplía. En modo sidecar, `exportTo` es un mecanismo de [delimitación de configuración](/es/docs/ops/configuration/mesh/configuration-scoping/) que controla cuánta configuración envía istiod a cada proxy. Ampliarlo para que coincida con una visibilidad más amplia empujaría la configuración de un `ServiceEntry` de vuelta a proxies de los que su propietario lo había excluido deliberadamente. Por lo tanto, la visibilidad siempre es solo un límite máximo: un `ServiceEntry` con un `exportTo` más estrecho que su visibilidad mantiene su alcance más estrecho.

{{< tip >}}
Los clientes sidecar solo pueden enrutar hacia un `ServiceEntry` con una dirección autoasignada si el [proxying de DNS](/es/docs/ops/configuration/traffic-management/dns-proxy/) está habilitado. En modo ambient, ztunnel proporciona este manejo de DNS automáticamente.
{{< /tip >}}

## Verificar la visibilidad

Cuando `serviceEntryVisibility` está configurado, istiod reporta la visibilidad que recibió el data plane como una condición de estado del `ServiceEntry` de tipo `istio.io/VisibilityApplied`, con el motivo indicando la visibilidad aplicada:

{{< text syntax=bash >}}
$ kubectl get serviceentry my-service -n team-a -o jsonpath='{.status.conditions[?(@.type=="istio.io/VisibilityApplied")].reason}'
Namespace
{{< /text >}}

El estado de la condición siempre es `True`; el campo `reason` lleva la visibilidad resuelta (`Public` o `Namespace`). Cuando `serviceEntryVisibility` no está configurado, la condición no se escribe.

{{< warning >}}
Un `ServiceEntry` con visibilidad `NONE` actualmente no recibe ninguna condición. Esta es una limitación conocida: no uses la ausencia de la condición para concluir que la visibilidad no se está aplicando.
{{< /warning >}}

También puedes inspeccionar la visibilidad que ztunnel está aplicando para cada servicio que conoce. Las salidas en JSON y YAML de `istioctl ztunnel-config service` incluyen un campo `visibility`:

{{< text syntax=bash >}}
$ istioctl ztunnel-config service --service-namespace team-a -o yaml
{{< /text >}}

Los `Service` de Kubernetes siempre reportan `Public`; los servicios respaldados por `ServiceEntry` reportan su visibilidad resuelta. Además, ztunnel registra a nivel `debug` cada vez que oculta un servicio a un cliente durante la resolución.

## Qué no hace la visibilidad

* **La visibilidad no es autorización.** La visibilidad controla si un cliente puede *descubrir y resolver* un servicio; no decide si se permite una solicitud entrante. Usa [`AuthorizationPolicy`](/es/docs/reference/config/security/authorization-policy/) para controlar qué clientes pueden acceder a un workload; consulta [Política de seguridad de capa 4](/es/docs/ambient/usage/l4-policy/).
* **La visibilidad no es secreto.** Reducir la visibilidad de un `ServiceEntry` rige lo que resuelven los workloads cliente; no oculta la existencia del servicio. El recurso permanece legible a través de la API de Kubernetes según el RBAC, y el servicio sigue apareciendo en los volcados de configuración del data plane, como `istioctl ztunnel-config service`.
* **Solo se aplica a `ServiceEntry`.** Los `Service` de Kubernetes siempre son visibles en toda la mesh en modo ambient.
* **No hay un modo de auditoría o de solo advertencia.** Cuando está configurada, la visibilidad siempre tiene efecto.

## Ver también

* [Referencia de configuración de mesh `ServiceEntryVisibility`](/es/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility)
* [Delimitación de configuración](/es/docs/ops/configuration/mesh/configuration-scoping/) — `exportTo` y `Sidecar` para el modo sidecar, además de `discoverySelectors`, que se aplican en todos los modos de data plane
* [Proxying de DNS](/es/docs/ops/configuration/traffic-management/dns-proxy/)
* [Configurar proxies waypoint](/es/docs/ambient/usage/waypoint/)
