---
title: data plane Ambient
description: Comprende cómo el data plane ambient enruta el tráfico entre los workloads en una malla ambient.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

En el {{< gloss "ambient" >}}modo ambient{{< /gloss >}}, los workloads pueden clasificarse en 3 categorías:
1. **Fuera de la malla**: un pod estándar sin ninguna característica de malla habilitada. Istio y el {{< gloss >}}data plane{{< /gloss >}} ambient no están habilitados.
1. **En la malla**: un pod que está incluido en el {{< gloss >}}data plane{{< /gloss >}} ambient, y tiene el tráfico interceptado en el nivel de capa 4 por {{< gloss >}}ztunnel{{< /gloss >}}. En este modo, se pueden aplicar políticas L4 para el tráfico del pod. Este modo se puede habilitar estableciendo la etiqueta `istio.io/data plane-mode=ambient`. Consulta [etiquetas](/es/docs/ambient/usage/add-workloads/#ambient-labels) para obtener más detalles.
1. **En la malla, con waypoint habilitado**: un pod que está _en la malla_ *y* tiene un {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} desplegado. En este modo, se pueden aplicar políticas L7 para el tráfico del pod. Este modo se puede habilitar estableciendo la etiqueta `istio.io/use-waypoint`. Consulta [etiquetas](/es/docs/ambient/usage/add-workloads/#ambient-labels) para obtener más detalles.

Dependiendo de la categoría en la que se encuentre una workload, la ruta del tráfico será diferente.

## Enrutamiento en la malla

### Saliente

Cuando un pod en una malla ambient realiza una solicitud saliente, será [redirigido de forma transparente](/es/docs/ambient/architecture/traffic-redirection) al ztunnel local del nodo, que determinará dónde y cómo reenviar la solicitud.
En general, el enrutamiento del tráfico se comporta igual que el enrutamiento de tráfico predeterminado de Kubernetes;
las solicitudes a un `Service` se enviarán a un endpoint dentro del `Service`, mientras que las solicitudes directas a una IP de `Pod` irán directamente a esa IP.

Sin embargo, dependiendo de las capacidades del destino, se producirá un comportamiento diferente.
Si el destino también está agregado en la malla, o si tiene capacidades de proxy de Istio (como un sidecar), la solicitud se actualizará a un túnel {{< gloss "HBONE" >}}HBONE{{< /gloss >}} cifrado.
Si el destino tiene un waypoint proxy, además de actualizarse a HBONE, la solicitud se reenviará a ese waypoint para la aplicación de la política L7.

Ten en cuenta que en el caso de una solicitud a un `Service`, si el servicio *tiene* un waypoint, la solicitud se enviará a su waypoint para aplicar las políticas L7 al tráfico.
Del mismo modo, en el caso de una solicitud a una IP de `Pod`, si el pod *tiene* un waypoint, la solicitud se enviará a su waypoint para aplicar las políticas L7 al tráfico.
Dado que es posible variar las etiquetas asociadas con los pods en un `Deployment`, es técnicamente posible que
algunos pods usen un waypoint mientras que otros no. Generalmente se recomienda a los usuarios que eviten este caso de uso avanzado.

### Entrante

Cuando un pod en una malla ambient recibe una solicitud entrante, será [redirigido de forma transparente](/es/docs/ambient/architecture/traffic-redirection) al ztunnel local del nodo.
Cuando ztunnel recibe la solicitud, aplicará las Políticas de Autorización y reenviará la solicitud solo si la solicitud pasa estas comprobaciones.

Un pod puede recibir tráfico HBONE o tráfico de texto sin formato.
De forma predeterminada, ztunnel aceptará ambos.
Las solicitudes de fuentes fuera de la malla no tendrán identidad de par cuando se evalúen las Políticas de Autorización,
un usuario puede establecer una política que requiera una identidad (ya sea *cualquier* identidad o una específica) para bloquear todo el tráfico de texto sin formato.

Cuando el destino está habilitado para waypoint, si el origen está en la malla ambient, el ztunnel del origen garantiza que la solicitud **pasará** a través
del waypoint donde se aplica la política. Sin embargo, una workload fuera de la malla no sabe nada sobre los proxies de waypoint, por lo que envía
solicitudes directamente al destino sin pasar por ningún proxy de waypoint, incluso si el destino está habilitado para waypoint.
Actualmente, el tráfico de los sidecars y las gateways tampoco pasará por ningún proxy de waypoint y se les informará sobre los proxies de waypoint
en una versión futura.

#### Detalles del data plane

##### Identidad

Todo el tráfico TCP L4 entrante y saliente entre los workloads en la malla ambient está protegido por el data plane, utilizando mTLS a través de {{< gloss >}}HBONE{{< /gloss >}}, ztunnel y certificados x509.

Según lo exige {{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}}, el origen y el destino deben tener identidades x509 únicas, y esas identidades deben usarse para establecer el canal cifrado para esa conexión.

Esto requiere que ztunnel gestione múltiples certificados de workload distintos, en nombre de los workloads proxiadas, uno para cada identidad única (cuenta de servicio) para cada pod local del nodo. La propia identidad de Ztunnel nunca se utiliza para las conexiones mTLS entre los workloads.

Al obtener certificados, ztunnel se autenticará en la CA con su propia identidad, pero solicitará la identidad de otra workload. Críticamente, la CA debe hacer cumplir que el ztunnel tiene permiso para solicitar esa identidad. Las solicitudes de identidades que no se ejecutan en el nodo se rechazan. Esto es fundamental para garantizar que un nodo comprometido no comprometa toda la malla.

Esta aplicación de la CA la realiza la CA de Istio utilizando un token JWT de la Cuenta de Servicio de Kubernetes, que codifica la información del pod. Esta aplicación también es un requisito para cualquier CA alternativa que se integre con ztunnel.

Ztunnel solicitará certificados para todas las identidades en el nodo. Lo determina en función de la configuración del {{< gloss >}}control plane{{< /gloss >}} que recibe. Cuando se descubre una nueva identidad en el nodo, se pondrá en cola para su obtención con una prioridad baja, como una optimización. Sin embargo, si una solicitud necesita una cierta identidad que aún no se ha obtenido, se solicitará de inmediato.

Ztunnel además se encargará de la rotación de estos certificados a medida que se acerquen a su vencimiento.

##### Telemetría

Ztunnel emite el conjunto completo de [Métricas TCP estándar de Istio](/es/docs/reference/config/metrics/).

##### Ejemplo de data plane para tráfico de capa 4

El data plane L4 ambient se representa en la siguiente figura.

{{< image width="100%"
link="ztunnel-datapath-1.png"
caption="Ruta de datos básica de solo L4 de ztunnel"
>}}

La figura muestra varios workloads agregadas a la malla ambient, que se ejecutan en los nodos W1 y W2 de un cluster de Kubernetes. Hay una única instancia del proxy ztunnel en cada nodo. En este escenario, los pods de cliente de la aplicación C1, C2 y C3 necesitan acceder a un servicio proporcionado por el pod S1. No hay ningún requisito para las características avanzadas de L7, como el enrutamiento de tráfico L7 o la gestión de tráfico L7, por lo que un data plane L4 es suficiente para obtener {{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}} y la aplicación de políticas L4; no se requiere ningún proxy de waypoint.

La figura muestra que los pods C1 y C2, que se ejecutan en el nodo W1, se conectan con el pod S1 que se ejecuta en el nodo W2.

El tráfico TCP para C1 y C2 se tuneliza de forma segura a través de conexiones {{< gloss >}}HBONE{{< /gloss >}} creadas por ztunnel. Se utiliza {{< gloss "mutual tls authentication" >}}TLS mutuo (mTLS){{< /gloss >}} para el cifrado, así como para la autenticación mutua del tráfico que se tuneliza. Se utilizan identidades [SPIFFE](https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE.md) para identificar los workloads en cada lado de la conexión. Para obtener más detalles sobre el protocolo de tunelización y el mecanismo de redirección de tráfico, consulta las guías sobre [HBONE](/es/docs/ambient/architecture/hbone) y [redirección de tráfico de ztunnel](/es/docs/ambient/architecture/traffic-redirection).

{{< tip >}}
Nota: Aunque la figura muestra que los túneles HBONE se encuentran entre los dos proxies ztunnel, los túneles se encuentran de hecho entre los pods de origen y destino. El tráfico se encapsula y cifra con HBONE enel namespace de red del propio pod de origen, y finalmente se desencapsula y descifra enel namespace de red del pod de destino en el nodo de trabajo de destino. El proxy ztunnel todavía maneja lógicamente tanto el control plane como el data plane necesarios para el transporte HBONE; sin embargo, puede hacerlo desde dentro de los namespaces de red de los pods de origen y destino.
{{< /tip >}}

Ten en cuenta que el tráfico local, que se muestra en la figura desde el pod C3 hasta el pod de destino S1 en el nodo de trabajo W2, también atraviesa la instancia de proxy ztunnel local, de modo que las funciones de gestión de tráfico L4, como la Autorización L4 y la Telemetría L4, se aplicarán de forma idéntica en el tráfico, ya sea que cruce o no un límite de nodo.

## Enrutamiento en malla con waypoint habilitado

Los waypoints de Istio reciben exclusivamente tráfico HBONE.
Al recibir una solicitud, el waypoint se asegurará de que el tráfico sea para un `Pod` o `Service` que lo utilice.

Una vez aceptado el tráfico, el waypoint aplicará las políticas L7 (como `AuthorizationPolicy`, `RequestAuthentication`, `WasmPlugin`, `Telemetry`, etc.) antes de reenviarlo.

Para las solicitudes directas a un `Pod`, las solicitudes simplemente se reenvían directamente después de aplicar la política.

Para las solicitudes a un `Service`, el waypoint también aplicará el enrutamiento y el balanceo de carga.
De forma predeterminada, un `Service` simplemente se enrutará a sí mismo, realizando un balanceo de carga L7 en sus endpoints.
Esto se puede anular con Rutas para ese `Service`.

Por ejemplo, la siguiente política garantizará que las solicitudes al servicio `echo` se reenvíen a `echo-v1`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: echo
  rules:
  - backendRefs:
    - name: echo-v1
      port: 80
{{< /text >}}

La siguiente figura muestra la ruta de datos entre ztunnel y un waypoint, si se configura uno para la aplicación de políticas L7. Aquí, ztunnel utiliza la tunelización HBONE para enviar tráfico a un proxy de waypoint para el procesamiento L7. Después del procesamiento, el waypoint envía tráfico a través de un segundo túnel HBONE al ztunnel en el nodo que aloja el pod de destino del servicio seleccionado. En general, el proxy de waypoint puede o no estar ubicado en los mismos nodos que el pod de origen o destino.

{{< image width="100%"
link="ztunnel-waypoint-datapath.png"
caption="Ruta de datos de Ztunnel a través de un waypoint intermedio"
>}}
