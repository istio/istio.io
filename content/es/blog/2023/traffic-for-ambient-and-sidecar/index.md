---
title: "Inmersión profunda en la ruta de tráfico de red de la coexistencia de Ambient y Sidecar"
description: "Inmersión profunda en la ruta de tráfico de la coexistencia de Ambient y Sidecar."
publishdate: 2023-09-18
attribution: "Steve Zhang (Intel), John Howard (Google), Yuxing Zeng(Alibaba), Peter Jausovec(Solo.io)"
keywords: [traffic,ambient,sidecar,coexistence]
---

Existen 2 modos de despliegue para Istio: modo ambient y modo sidecar. El primero todavía está en camino, el segundo es el clásico. Por lo tanto, la coexistencia del modo ambient y el modo sidecar debería ser una forma de despliegue normal y la razón por la cual este blog puede ser útil para los usuarios de Istio.

## Antecedentes

En la arquitectura de microservicios modernos, la comunicación y gestión entre servicios es crítica. Para abordar el desafío, Istio emergió como una tecnología de service mesh. Proporciona control de tráfico, seguridad y capacidades de observación superiores al utilizar el sidecar. Para mejorar aún más la adaptabilidad y flexibilidad de Istio, la comunidad de Istio comenzó a explorar un nuevo modo - modo ambient. En este modo, Istio ya no depende de la inyección explícita del sidecar, sino que logra la comunicación y gestión de malla entre servicios a través de ztunnel y proxies waypoint. Ambient también trae una serie de mejoras, como menor consumo de recursos, despliegue más simple y opciones de configuración más flexibles. Al habilitar el modo ambient, ya no tenemos que reiniciar los pods, lo que permite que Istio juegue un mejor papel en varios escenarios.

Hay muchos blogs, que se pueden encontrar en la sección de [Recursos de Referencia](#reference-resources) de este blog, que introducen y analizan ambient, y este blog analizará la ruta de tráfico de red en los modos ambient y sidecar de Istio.

Para aclarar las rutas de tráfico de red y facilitar su comprensión, esta publicación del blog explora los siguientes dos escenarios con diagramas correspondientes:

- **La ruta de red de servicios en modo ambient a servicios en modo sidecar**
- **La ruta de red de servicios en modo sidecar a servicios en modo ambient**

## Información sobre el análisis

El análisis se basa en Istio 1.18.2, donde el modo ambient usa iptables para la redirección.

## `sleep` en modo Ambient a `httpbin` en modo sidecar

### Despliegue y configuración para el primer escenario

- `sleep` está desplegado en el namespace foo
    - el pod `sleep` está programado en el Nodo A
- `httpbin` está desplegado en el namespace bar
    - `httpbin` está programado en el Nodo B
- el namespace foo habilita el modo ambient (el namespace foo contiene la etiqueta: `istio.io/dataplane-mode=ambient`)
- el namespace bar habilita la inyección de sidecar (el namespace bar contiene la etiqueta: `istio-injection: enabled`)

Con la descripción anterior, el despliegue y las rutas de tráfico de red son:

{{< image width="100%"
    link="ambient-to-sidecar.png"
    caption="sleep en modo Ambient a httpbin en modo Sidecar"
    >}}

ztunnel se desplegará como un DaemonSet en el namespace istio-system si el modo ambient está habilitado, mientras que istio-cni y ztunnel generarían reglas de iptables y rutas tanto para el pod ztunnel como para los pods en cada nodo.

Todo el tráfico de red que entra/sale del pod con modo ambient habilitado pasará por ztunnel basándose en la lógica de redirección de red. El ztunnel luego reenviará el tráfico a los endpoints correctos.

### Análisis de la ruta de tráfico de red de `sleep` en modo ambient a `httpbin` en modo sidecar

Según el diagrama anterior, los detalles de la ruta de tráfico de red se demuestran a continuación:

**(1) (2) (3)** El tráfico de solicitud del servicio `sleep` se envía desde el `veth` del pod `sleep` donde será marcado y reenviado al dispositivo `istioout` en el nodo siguiendo las reglas de iptables y reglas de ruta. El dispositivo `istioout` en el nodo A es un túnel [Geneve](https://www.rfc-editor.org/rfc/rfc8926.html), y el otro extremo del túnel es `pistioout`, que está dentro del pod ztunnel en el mismo nodo.

**(4) (5)** Cuando el tráfico llega a través del dispositivo `pistioout`, las reglas de iptables dentro del pod interceptan y redirigen el tráfico a través de la interfaz `eth0` en el pod al puerto `15001`.

**(6)** Según la información de la solicitud original, ztunnel puede obtener la lista de endpoints del servicio de destino. Luego manejará el envío de la solicitud al endpoint, como uno de los pods `httpbin`. Finalmente, el tráfico de solicitud entraría en el pod `httpbin` a través de la red de contenedor.

**(7)** El tráfico de solicitud que llega al pod `httpbin` será interceptado y redirigido a través del puerto `15006` del sidecar por sus reglas de iptables.

**(8)** El sidecar maneja el tráfico de solicitud entrante que viene a través del puerto 15006, y reenvía el tráfico al contenedor `httpbin` en el mismo pod.

## `sleep` en modo Sidecar a `httpbin` y `helloworld` en modo ambient

### Despliegue y configuración para el segundo escenario

- `sleep` está desplegado en el namespace foo
    - el pod `sleep` está programado en el Nodo A
- `httpbin` desplegado en el namespace bar-1
    - el pod `httpbin` está programado en el Nodo B
    - el proxy waypoint de `httpbin` está deshabilitado
- `helloworld` está desplegado en el namespace bar-2
    - el pod `helloworld` está programado en el Nodo D
    - el proxy waypoint de `helloworld` está habilitado
    - el proxy waypoint está programado en el Nodo C
- el namespace foo habilita la inyección de sidecar (el namespace foo contiene la etiqueta: `istio-injection: enabled`)
- el namespace bar-1 habilita el modo ambient (el namespace bar-1 contiene la etiqueta: `istio.io/dataplane-mode=ambient`)

Con la descripción anterior, el despliegue y las rutas de tráfico de red son:

{{< image width="100%"
    link="sidecar-to-ambient.png"
    caption="sleep a httpbin y helloworld"
    >}}

### Análisis de la ruta de tráfico de red de `sleep` en modo sidecar a `httpbin` en modo ambient

La ruta de tráfico de red de una solicitud desde el pod `sleep` (modo sidecar) al pod `httpbin` (modo ambient) se representa en la mitad superior del diagrama anterior.

**(1) (2) (3) (4)** el contenedor `sleep` envía una solicitud a `httpbin`. La solicitud es interceptada por reglas de iptables y dirigida al puerto `15001` en el sidecar en el pod `sleep`. Luego, el sidecar maneja la solicitud y enruta el tráfico basándose en la configuración recibida de istiod (control plane) reenviando el tráfico a una dirección IP correspondiente al pod `httpbin` en el nodo B.

**(5) (6)** Después de que la solicitud se envía al par de dispositivos (`veth httpbin <-> eth0 dentro del pod httpbin`), la solicitud es interceptada y reenviada usando las reglas de iptables y reglas de ruta al dispositivo `istioin` en el nodo B donde se está ejecutando el pod `httpbin` siguiendo sus reglas de iptables y reglas de ruta. El dispositivo `istioin` en el nodo B y el dispositivo `pistion` dentro del pod ztunnel en el mismo nodo están conectados por un túnel [Geneve](https://www.rfc-editor.org/rfc/rfc8926.html).

**(7) (8)** Después de que la solicitud entra en el dispositivo `pistioin` del pod ztunnel, las reglas de iptables en el pod ztunnel interceptan y redirigen el tráfico a través del puerto 15008 en el proxy ztunnel que se ejecuta dentro del pod.

**(9)** El tráfico que entra en el puerto 15008 se consideraría una solicitud entrante, y el ztunnel luego reenviará la solicitud al pod `httpbin` en el mismo nodo B.

### Análisis de la ruta de tráfico de red de `sleep` en modo sidecar a `httpbin` en modo ambient vía proxy waypoint

Comparando con la parte superior del diagrama, la parte inferior inserta un proxy waypoint en la ruta entre los pods `sleep`, ztunnel y `httpbin`. El control plane de Istio tiene toda la información de servicio y configuración del service mesh. Cuando el pod `helloworld` se despliega con un proxy waypoint, la configuración EDS del servicio `helloworld` recibida por el sidecar del pod `sleep` se cambiará al tipo de `envoy_internal_address`. Esto hace que el tráfico de solicitud que pasa por el sidecar se reenvíe al puerto 15008 del proxy waypoint en el nodo C a través del protocolo [HTTP Based Overlay Network (HBONE)](https://docs.google.com/document/d/1Ofqtxqzk-c_wn0EgAXjaJXDHB9KhDuLe-W3YGG67Y8g/edit).

El proxy Waypoint es una instancia del proxy Envoy y reenvía la solicitud al pod `helloworld` basándose en la configuración de enrutamiento recibida del control plane. Una vez que el tráfico alcanza el `veth` en el nodo D, sigue el mismo camino que el escenario anterior.

## Conclusión

El modo sidecar es lo que hizo de Istio un gran service mesh. Sin embargo, el modo sidecar también puede causar problemas ya que requiere que los contenedores de aplicación y sidecar se ejecuten en el mismo pod. El modo ambient de Istio implementa la comunicación entre servicios a través de proxies centralizados (ztunnel y waypoint). El modo ambient proporciona mayor flexibilidad y escalabilidad, reduce el consumo de recursos ya que no requiere un sidecar para cada pod en la malla, y permite una configuración más precisa. Por lo tanto, no hay duda de que el modo ambient es la próxima evolución de Istio. Es obvio que la coexistencia de los modos sidecar y ambient puede durar mucho tiempo, aunque el modo ambient todavía está en etapa alpha y el modo sidecar sigue siendo el modo recomendado de Istio, le dará a los usuarios una opción más liviana de ejecutar y adoptar el service mesh de Istio a medida que el modo ambient avance hacia beta y futuras versiones.

## Recursos de Referencia

- [Traffic in ambient mesh: Istio CNI and node configuration](https://www.solo.io/blog/traffic-ambient-mesh-istio-cni-node-configuration/)
- [Traffic in ambient mesh: Redirection using iptables and Geneve tunnels](https://www.solo.io/blog/traffic-ambient-mesh-redirection-iptables-geneve-tunnels/)
- [Traffic in ambient mesh: ztunnel, eBPF configuration, and waypoint proxies](https://www.solo.io/blog/traffic-ambient-mesh-ztunnel-ebpf-waypoint/)
