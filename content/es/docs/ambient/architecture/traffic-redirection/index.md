---
title: Redirección de tráfico de Ztunnel
description: Comprende cómo se redirige el tráfico entre los pods y el proxy de nodo ztunnel.
weight: 2
aliases:
  - /docs/ops/ambient/usage/traffic-redirection
  - /latest/docs/ops/ambient/usage/traffic-redirection
owner: istio/wg-networking-maintainers
test: no
---

En el contexto del modo ambient, la _redirección de tráfico_ se refiere a la funcionalidad del data plane que intercepta el tráfico enviado hacia y desde los workloads habilitadas para ambient, enrutándolo a través de los proxies de nodo {{< gloss >}}ztunnel{{< /gloss >}} que manejan la ruta de datos principal. A veces también se utiliza el término _captura de tráfico_.

Como ztunnel tiene como objetivo cifrar y enrutar de forma transparente el tráfico de la aplicación, se necesita un mecanismo para capturar todo el tráfico que entra y sale de los pods "en malla". Esta es una tarea crítica para la seguridad: si se puede omitir el ztunnel, se pueden omitir las políticas de autorización.

## Modelo de redirección de tráfico en el pod de Istio

El principio de diseño central que subyace a la redirección de tráfico en el pod del modo ambient es que el proxy ztunnel tiene la capacidad de realizar la captura de la ruta de datos dentro del namespace de red de Linux del pod de el workload. Esto se logra mediante una cooperación de funcionalidades entre el agente de nodo [`istio-cni`](/es/docs/setup/additional-setup/cni/) y el proxy de nodo ztunnel. Un beneficio clave de este modelo es que permite que el modo ambient de Istio funcione junto con cualquier complemento CNI de Kubernetes, de forma transparente y sin afectar las características de red de Kubernetes.

La siguiente figura ilustra la secuencia de eventos cuando se inicia un nuevo pod de workload en (o se agrega a) un namespaces habilitado para ambient.

{{< image width="100%"
link="./pod-added-to-ambient.svg"
alt="flujo de pod agregado a la mesh ambient"
>}}

El agente de nodo `istio-cni` responde a los eventos de CNI, como la creación y eliminación de pods, y también observa el servidor de la API de Kubernetes subyacente en busca de eventos como la adición de la etiqueta ambient a un pod o namespaces.

El agente de nodo `istio-cni` además instala un complemento CNI encadenado que es ejecutado por el tiempo de ejecución del contenedor después de que se ejecuta el complemento CNI principal dentro de ese cluster de Kubernetes. Su único propósito es notificar al agente de nodo `istio-cni` cuando el tiempo de ejecución del contenedor crea un nuevo pod en un namespaces que ya está inscrito en el modo ambient, y propagar el contexto del nuevo pod a `istio-cni`.

Una vez que se notifica al agente de nodo `istio-cni` que se debe agregar un pod a la mesh (ya sea desde el complemento CNI, si el pod es nuevo, o desde el servidor de la API de Kubernetes, si el pod ya se está ejecutando pero necesita ser agregado), se realiza la siguiente secuencia de operaciones:

- `istio-cni` ingresa al namespaces de red del pod y establece reglas de redirección de red, de modo que los paquetes que entran y salen del pod se interceptan y se redirigen de forma transparente a la instancia de proxy ztunnel local del nodo que escucha en los [puertos conocidos](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports) (15008, 15006, 15001).

- El agente de nodo `istio-cni` luego informa al proxy ztunnel, a través de un socket de dominio Unix, que debe establecer puertos de escucha de proxy locales dentro del namespace de red del pod (en los puertos 15008, 15006 y 15001), y proporciona a ztunnel un [descriptor de archivo](https://en.wikipedia.org/wiki/File_descriptor) de Linux de bajo nivel que representael namespace de red del pod.
    - Si bien normalmente los sockets se crean dentro de un namespaces de red de Linux por el proceso que se ejecuta realmente dentro de ese namespaces de red, es perfectamente posible aprovechar la API de sockets de bajo nivel de Linux para permitir que un proceso que se ejecuta en un namespaces de red cree sockets de escucha en otro namespaces de red, asumiendo queel namespace de red de destino se conoce en el momento de la creación.

- El ztunnel local del nodo internamente crea una nueva instancia de proxy lógico y un conjunto de puertos de escucha, dedicados al pod recién agregado. Ten en cuenta que esto todavía se está ejecutando dentro del mismo proceso y es simplemente una tarea dedicada para el pod.

- Una vez que las reglas de redirección en el pod están en su lugar y el ztunnel ha establecido los puertos de escucha, el pod se agrega a la mesh y el tráfico comienza a fluir a través del ztunnel local del nodo.

El tráfico hacia y desde los pods en la mesh se cifrará completamente con mTLS de forma predeterminada.

Los datos ahora entrarán y saldrán del namespace de red del pod cifrados. Cada pod en la mesh tiene la capacidad de hacer cumplir la política de la mesh y cifrar el tráfico de forma segura, aunque la aplicación de usuario que se ejecuta en el pod no tiene conocimiento de ninguna de las dos cosas.

Este diagrama ilustra cómo fluye el tráfico cifrado entre los pods en la mesh ambient en el nuevo modelo:

{{< image width="100%"
    link="./traffic-flows-between-pods-in-ambient.svg"
    alt="El tráfico HBONE fluye entre los pods en la mesh ambient"
    >}}

## Observación y depuración de la redirección de tráfico en modo ambient

Si la redirección de tráfico no funciona correctamente en el modo ambient, se pueden realizar algunas comprobaciones rápidas para ayudar a reducir el problema. Recomendamos que la solución de problemas comience con los pasos descritos en la [guía de depuración de ztunnel](/es/docs/ambient/usage/troubleshoot-ztunnel/).

### Comprobar los registros del proxy ztunnel

Cuando un pod de aplicación forma parte de un ambient mesh, puedes comprobar los registros del proxy ztunnel para confirmar que la mesh está redirigiendo el tráfico. Como se muestra en el siguiente ejemplo, los registros de ztunnel relacionados con `inpod` indican que el modo de redirección en el pod está habilitado, que el proxy ha recibido la información del namespace de red (netns) sobre un pod de aplicación ambient y que ha comenzado a actuar como proxy para él.

{{< text bash >}}
$ kubectl logs ds/ztunnel -n istio-system  | grep inpod
Found 3 pods, using pod/ztunnel-hl94n
inpod_enabled: true
inpod_uds: /var/run/ztunnel/ztunnel.sock
inpod_port_reuse: true
inpod_mark: 1337
2024-02-21T22:01:49.916037Z  INFO ztunnel::inpod::workloadmanager: handling new stream
2024-02-21T22:01:49.919944Z  INFO ztunnel::inpod::statemanager: pod WorkloadUid("1e054806-e667-4109-a5af-08b3e6ba0c42") received netns, starting proxy
2024-02-21T22:01:49.925997Z  INFO ztunnel::inpod::statemanager: pod received snapshot sent
2024-02-21T22:03:49.074281Z  INFO ztunnel::inpod::statemanager: pod delete request, draining proxy
2024-02-21T22:04:58.446444Z  INFO ztunnel::inpod::statemanager: pod WorkloadUid("1e054806-e667-4109-a5af-08b3e6ba0c42") received netns, starting proxy
{{< /text >}}

### Confirmar el estado de los sockets

Sigue los pasos a continuación para confirmar que los sockets en los puertos 15001, 15006 y 15008 están abiertos y en estado de escucha.

{{< text bash >}}
$ kubectl debug $(kubectl get pod -l app=curl -n ambient-demo -o jsonpath='{.items[0].metadata.name}') -it -n ambient-demo  --image nicolaka/netshoot  -- ss -ntlp
Defaulting debug container name to debugger-nhd4d.
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      128        127.0.0.1:15080      0.0.0.0:*
LISTEN 0      128                *:15006            *:*
LISTEN 0      128                *:15001            *:*
LISTEN 0      128                *:15008            *:*
{{< /text >}}

### Comprobar la configuración de las reglas de iptables

Para ver la configuración de las reglas de iptables dentro de uno de los pods de la aplicación, ejecuta este comando:

{{< text bash >}}
$ kubectl debug $(kubectl get pod -l app=curl -n ambient-demo -o jsonpath='{.items[0].metadata.name}') -it --image gcr.io/istio-release/base --profile=netadmin -n ambient-demo -- iptables-save

Defaulting debug container name to debugger-m44qc.
# Generated by iptables-save
*mangle
:PREROUTING ACCEPT [320:53261]
:INPUT ACCEPT [23753:267657744]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [23352:134432712]
:POSTROUTING ACCEPT [23352:134432712]
:ISTIO_OUTPUT - [0:0]
:ISTIO_PRERT - [0:0]
-A PREROUTING -j ISTIO_PRERT
-A OUTPUT -j ISTIO_OUTPUT
-A ISTIO_OUTPUT -m connmark --mark 0x111/0xfff -j CONNMARK --restore-mark --nfmask 0xffffffff --ctmask 0xffffffff
-A ISTIO_PRERT -m mark --mark 0x539/0xfff -j CONNMARK --set-xmark 0x111/0xfff
-A ISTIO_PRERT -s 169.254.7.127/32 -p tcp -m tcp -j ACCEPT
-A ISTIO_PRERT ! -d 127.0.0.1/32 -i lo -p tcp -j ACCEPT
-A ISTIO_PRERT -p tcp -m tcp --dport 15008 -m mark ! --mark 0x539/0xfff -j TPROXY --on-port 15008 --on-ip 0.0.0.0 --tproxy-mark 0x111/0xfff
-A ISTIO_PRERT -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ISTIO_PRERT ! -d 127.0.0.1/32 -p tcp -m mark ! --mark 0x539/0xfff -j TPROXY --on-port 15006 --on-ip 0.0.0.0 --tproxy-mark 0x111/0xfff
COMMIT
# Completed
# Generated by iptables-save
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [175:13694]
:POSTROUTING ACCEPT [205:15494]
:ISTIO_OUTPUT - [0:0]
-A OUTPUT -j ISTIO_OUTPUT
-A ISTIO_OUTPUT -d 169.254.7.127/32 -p tcp -m tcp -j ACCEPT
-A ISTIO_OUTPUT -p tcp -m mark --mark 0x111/0xfff -j ACCEPT
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -o lo -j ACCEPT
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -p tcp -m mark ! --mark 0x539/0xfff -j REDIRECT --to-ports 15001
COMMIT
{{< /text >}}

La salida del comando muestra que se agregan cadenas adicionales específicas de Istio a las tablas NAT y Mangle en netfilter/iptables dentro del namespace de red del pod de la aplicación. Todo el tráfico TCP que llega al pod se redirige al proxy ztunnel para el procesamiento de entrada. Si el tráfico es de texto sin formato (puerto de destino != 15008), se redirigirá al puerto de escucha de texto sin formato 15006 de ztunnel en el pod. Si el tráfico es HBONE (puerto de destino == 15008), se redirigirá al puerto de escucha HBONE 15008 de ztunnel en el pod. Cualquier tráfico TCP que salga del pod se redirige al puerto 15001 de ztunnel para el procesamiento de salida, antes de ser enviado por ztunnel mediante la encapsulación HBONE.
