---
title: "Istio: La solución de mayor rendimiento para la seguridad de la red"
description: El modo ambient proporciona más rendimiento cifrado que cualquier otro proyecto en el ecosistema de Kubernetes.
publishdate: 2025-03-06
attribution: "John Howard (Solo.io)"
keywords: [istio,performance,ambient]
---

El cifrado en tránsito es un requisito básico para casi todos los entornos de Kubernetes en la actualidad y constituye la base de una postura de seguridad de zero-trust.

Sin embargo, el desafío con la seguridad es que no viene sin un costo: a menudo implica una compensación entre la complejidad, la experiencia del usuario y el rendimiento.

Si bien la mayoría de los usuarios de Cloud Native conocerán Istio como una service mesh, que proporciona una funcionalidad HTTP avanzada, también puede desempeñar el papel de proporcionar una capa de seguridad de red fundamental. Cuando nos propusimos construir [el modo ambient de Istio](/es/docs/overview/data plane-modes/#ambient-mode), estas dos capas se dividieron explícitamente. Uno de nuestros objetivos principales era poder ofrecer seguridad (¡y una larga lista de [otras características](/es/docs/concepts/)!) sin compromiso.

Con el modo ambient, **Istio es ahora la forma de mayor ancho de banda para lograr una red segura de zero-trust en Kubernetes**.

Veamos algunos resultados antes de sumergirnos en el cómo y el porqué.

## Poniéndolo a prueba

Para probar el rendimiento, utilizamos una herramienta estándar de evaluación comparativa de redes, [`iperf`](https://iperf.fr/), para medir el ancho de banda del tráfico TCP que fluye a través de varias soluciones populares de seguridad de redes de Kubernetes.

{{< image width="60%"
    link="./service-mesh-throughput.svg"
    alt="Rendimiento de varias soluciones de seguridad de red."
    >}}

Los resultados hablan por sí solos: Istio lidera decisivamente el grupo como la solución de seguridad de red de mayor rendimiento.
Aún más impresionante es que esta brecha continúa creciendo con cada versión de Istio:

{{< image width="60%"
    link="./ztunnel-performance.svg"
    alt="Rendimiento de Ztunnel, por versión."
    >}}

El rendimiento de Istio es impulsado por [ztunnel](https://github.com/istio/ztunnel), un data plane especialmente diseñado que es ligero, rápido y seguro.
¡En las últimas 4 versiones, el rendimiento de Ztunnel ha mejorado en un 75%!

<details>
<summary>Detalles de la prueba</summary>

Implementaciones bajo prueba:
* Istio: versión 1.26 (prelanzamiento), configuración predeterminada
* <a href="https://linkerd.io/">Linkerd</a>: versión `edge-25.2.2`, configuración predeterminada
* <a href="https://cilium.io/">Cilium</a>: versión `v1.16.6` con `kubeProxyReplacement=true`
  * WireGuard usa `encryption.type=wireguard`
  * IPsec usa `encryption.type=ipsec` con el algoritmo `GCM-128-AES`
  * Además, ambos modos se probaron con todas las recomendaciones de la <a href="https://docs.cilium.io/en/stable/operations/performance/tuning/">guía de ajuste de Cilium</a> (incluidos `netkit`, el modo de enrutamiento `nativo`, BIGTCP (para WireGuard; IPsec es incompatible), enmascaramiento BPF y administrador de ancho de banda BBR). Sin embargo, los resultados fueron los mismos con y sin esta configuración aplicada, por lo que solo se informa un resultado.
* <a href="https://www.tigera.io/project-calico/">Calico</a>: versión `v3.29.2` con `calicoNetwork.linuxdata plane=BPF` y `wireguardEnabled=true`
* <a href="https://kindnet.es/">Kindnet</a>: versión `v1.8.5` con `--ipsec-overlay=true`.

Algunas implementaciones solo cifran el tráfico entre nodos, por lo que se excluyen de las pruebas en el mismo nodo.

Las pruebas se ejecutaron en una única conexión `iperf` (`iperf3 -c iperf-server`), promediando el resultado de 3 ejecuciones consecutivas.
Las pruebas se ejecutan en máquinas x86 de 16 núcleos con Linux 6.13. Por varias razones, ninguna implementación hace uso de más de 1-2 núcleos al manejar una sola conexión, por lo que el número de núcleos no es un cuello de botella.

Nota: muchas de estas implementaciones admiten el control HTTP.
Esta prueba no ejerce esta funcionalidad en ninguna implementación.
[Publicaciones anteriores](/blog/2024/ambient-vs-cilium/) se han centrado en esta área de Istio.

</details>

## Superando al Kernel

Una percepción muy común en el rendimiento de las redes es que hacer todo en el kernel, ya sea de forma nativa o mediante el uso de extensiones eBPF, es la forma óptima de lograr un alto rendimiento.
Sin embargo, estos resultados muestran el efecto contrario: las implementaciones en el espacio de usuario, Linkerd e Istio, superan sustancialmente a las implementaciones del kernel. ¿Qué sucede?

Un factor importante es la velocidad de la innovación.
El rendimiento no es estático y hay una progresión constante de microoptimizaciones, innovaciones y adaptaciones a las mejoras de hardware.
El kernel sirve a una gran cantidad de casos de uso y debe evolucionar deliberadamente. Incluso cuando se realizan mejoras, pueden tardar muchos años en filtrarse a los entornos del mundo real.

Por el contrario, las implementaciones en el espacio de usuario pueden cambiar y adaptarse rápidamente a sus casos de uso específicos y ejecutarse en cualquier versión del kernel.
Ztunnel es un gran ejemplo de este efecto en acción, con mejoras sustanciales de rendimiento en cada versión trimestral.
Algunos de los cambios más impactantes:

* Migración a `rustls`, una biblioteca TLS de alto rendimiento centrada en la seguridad ([#820](https://github.com/istio/ztunnel/pull/820)).
* Reducción de la copia de datos en el tráfico saliente ([#1012](https://github.com/istio/ztunnel/pull/1012)).
* Ajuste dinámico de los tamaños de búfer de las conexiones activas ([#1024](https://github.com/istio/ztunnel/pull/1024)).
* Optimización de las copias de memoria ([#1169](https://github.com/istio/ztunnel/pull/1169)).
* Traslado de la biblioteca de criptografía a `AWS-LC`, una biblioteca de criptografía de alto rendimiento optimizada para hardware moderno ([#1466](https://github.com/istio/ztunnel/pull/1466)).

Algunos otros factores incluyen:
* WireGuard y Linkerd usan el algoritmo de cifrado `ChaCha20-Poly1305`, mientras que Istio usa `AES-GCM`. Este último está altamente optimizado en hardware moderno.
* WireGuard e IPsec operan en paquetes individuales (generalmente como máximo 1500 bytes, limitados por la MTU de la red) mientras que TLS opera en registros de hasta 16 KB.

## Prueba el modo ambient hoy

Si buscas mejorar la seguridad de tu cluster sin comprometer la complejidad o el rendimiento, ¡ahora es el momento perfecto para probar el modo ambient de Istio!

Sigue la [guía de inicio](/es/docs/ambient/getting-started/) para saber lo fácil que es instalarlo y habilitarlo.

Puedes interactuar con los desarrolladores en el canal #ambient en [el Slack de Istio](https://slack.istio.io), o usar el [foro de discusión en GitHub](https://github.com/istio/istio/discussions) para cualquier pregunta que puedas tener.
