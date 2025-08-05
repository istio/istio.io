---
title: Ambient y NetworkPolicy de Kubernetes
description: Comprender cómo la NetworkPolicy de Kubernetes L4 aplicada por CNI interactúa con el modo ambient de Istio.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

La [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) de Kubernetes te permite controlar cómo llega el tráfico de capa 4 a tus pods.

La `NetworkPolicy` es típicamente aplicada por el {{< gloss >}}CNI{{< /gloss >}} instalado en tu cluster. Istio no es un CNI, y no aplica ni gestiona la `NetworkPolicy`, y en todos los casos la respeta; ambient no omite ni omitirá nunca la aplicación de la `NetworkPolicy` de Kubernetes.

Una implicación de esto es que es posible crear una `NetworkPolicy` de Kubernetes que bloqueará el tráfico de Istio, o impedirá de otro modo la funcionalidad de Istio, por lo que al usar `NetworkPolicy` y ambient juntos, hay algunas cosas que tener en cuenta.

## Superposición de tráfico ambient y NetworkPolicy de Kubernetes

Una vez que hayas agregado aplicaciones a la mesh ambient, la superposición segura L4 de ambient tunelizará el tráfico entre tus pods a través del puerto 15008. Una vez que el tráfico seguro ingrese al pod de destino con un puerto de destino de 15008, el tráfico se redirigirá al puerto de destino original.

Sin embargo, la `NetworkPolicy` se aplica en el host, fuera del pod. Esto significa que si tienes una `NetworkPolicy` preexistente que, por ejemplo, denegará el tráfico entrante a un pod ambient en todos los puertos excepto en el 443, tendrás que agregar una excepción a esa `NetworkPolicy` para el puerto 15008. Las cargas de trabajo de sidecar que reciben tráfico también deberán permitir el tráfico entrante en el puerto 15008 para permitir que las cargas de trabajo ambient se comuniquen con ellas.

Por ejemplo, la siguiente `NetworkPolicy` bloqueará el tráfico entrante de {{< gloss >}}HBONE{{< /gloss >}} a `my-app` en el puerto 15008:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-allow-ingress-web
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
  - ports:
    - port: 8080
      protocol: TCP
{{< /text >}}

y debería cambiarse a

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-allow-ingress-web
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
  - ports:
    - port: 8080
      protocol: TCP
    - port: 15008
      protocol: TCP
{{< /text >}}

si `my-app` se agrega a la mesh.

## Ambient, sondas de salud y NetworkPolicy de Kubernetes

Las sondas de verificación de estado de Kubernetes presentan un problema y crean un caso especial para la política de tráfico de Kubernetes en general. Se originan en el kubelet que se ejecuta como un proceso en el nodo, y no en algún otro pod del cluster. Son de texto sin formato y no están protegidas. Ni el kubelet ni el nodo de Kubernetes suelen tener su propia identidad criptográfica, por lo que el control de acceso no es posible. No es suficiente simplemente permitir todo el tráfico a través del puerto de la sonda de salud, ya que el tráfico malicioso podría usar ese puerto con la misma facilidad que el kubelet. Además, muchas aplicaciones usan el mismo puerto para las sondas de salud y el tráfico legítimo de la aplicación, por lo que los permisos simples basados en puertos son inaceptables.

Varias implementaciones de CNI resuelven esto de diferentes maneras y buscan solucionar el problema excluyendo silenciosamente las sondas de salud de kubelet de la aplicación normal de políticas, o configurando excepciones de políticas para ellas.

En Istio ambient, este problema se resuelve mediante una combinación de reglas de iptables y traducción de direcciones de red de origen (SNAT) para reescribir solo los paquetes que se originan de manera demostrable en el nodo local con una IP de enlace local fija, de modo que puedan ser ignorados explícitamente por la aplicación de políticas de Istio como tráfico de sonda de salud no seguro. Se eligió una IP de enlace local como predeterminada, ya que generalmente se ignoran para los controles de entrada y salida, y [por estándar de la IETF](https://datatracker.ietf.org/doc/html/rfc3927) no se pueden enrutar fuera de la subred local.

Este comportamiento se habilita de forma transparente cuando agregas pods a la mesh ambient, y de forma predeterminada, ambient usa la dirección de enlace local `169.254.7.127` para identificar y permitir correctamente los paquetes de sondeo de salud de kubelet.

Sin embargo, si tu carga de trabajo, namespace o cluster tiene una `NetworkPolicy` de entrada o salida preexistente, dependiendo del CNI que estés utilizando, los paquetes con esta dirección de enlace local pueden ser bloqueados por la `NetworkPolicy` explícita, lo que hará que las sondas de salud de tu pod de aplicación comiencen a fallar cuando agregues tus pods a la mesh ambient.

Por ejemplo, aplicar la siguiente `NetworkPolicy` en un namespace bloquearía todo el tráfico (de Istio o de otro tipo) al pod `my-app`, **incluidas** las sondas de salud de kubelet. Dependiendo de tu CNI, las sondas de kubelet y las direcciones de enlace local pueden ser ignoradas por esta política o ser bloqueadas por ella:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  policyTypes:
  - Ingress
{{< /text >}}

Una vez que el pod esté inscrito en la mesh ambient, los paquetes de sondeo de salud comenzarán a recibir una dirección de enlace local a través de SNAT, lo que significa que las sondas de salud pueden comenzar a ser bloqueadas por la implementación de `NetworkPolicy` de tu CNI. Para permitir que las sondas de salud ambient omitan la `NetworkPolicy`, permite explícitamente el tráfico desde el nodo host a tu pod permitiendo la dirección de enlace local que ambient usa para este tráfico:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress-allow-kubelet-healthprobes
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
    - from:
      - ipBlock:
          cidr: 169.254.7.127/32
{{< /text >}}
