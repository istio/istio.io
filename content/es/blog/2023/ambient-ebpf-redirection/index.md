---
title: "Uso de eBPF para la redirección de tráfico en el modo ambient de Istio"
description: Un enfoque alternativo para redirigir el tráfico del pod de aplicación al ztunnel por nodo.
publishdate: 2023-03-29
attribution: "Iris Ding (Intel), Chun Li (Intel)"
keywords: [istio,ambient,ztunnel,eBPF]
---

{{< idea >}}
El modo ambient ahora usa [redirección en el pod](/blog/2024/inpod-traffic-redirection-ambient/) para redirigir el tráfico entre los pods de carga de trabajo y ztunnel. El método descrito en este blog ya no es necesario, y esta publicación se ha dejado por interés histórico.
{{< /idea >}}

En el nuevo [modo ambient](/blog/2022/introducing-ambient-mesh/) de Istio, el componente `istio-cni` que se ejecuta en cada nodo de trabajo de Kubernetes es responsable de redirigir el tráfico de la aplicación al túnel de confianza cero (ztunnel) en ese nodo. Por defecto, se basa en iptables y
túneles de superposición [Generic Network Virtualization Encapsulation (Geneve)](https://www.rfc-editor.org/rfc/rfc8926.html) para lograr esta redirección. Ahora hemos agregado soporte para un método de redirección de tráfico basado en eBPF.

## Por qué eBPF

Aunque las consideraciones de rendimiento son esenciales en la implementación de la redirección del modo ambient de Istio, también es importante considerar la facilidad de programabilidad, para permitir la implementación de requisitos versátiles y personalizados. Con eBPF, puede aprovechar el contexto adicional en el kernel para omitir el enrutamiento complejo y simplemente enviar paquetes a su destino final.

Además, eBPF permite una visibilidad más profunda y un contexto adicional para los paquetes en el kernel, lo que permite una gestión del flujo de datos más eficiente y flexible en comparación con iptables.

## Cómo funciona

Un programa eBPF, adjunto al gancho de entrada y salida de [traffic control](https://man7.org/linux/man-pages/man8/tc-bpf.8.html), se ha compilado en el componente Istio CNI. `istio-cni` observará los eventos de pods y adjuntará/desconectará el programa eBPF a otras interfaces de red relacionadas cuando el pod se mueva dentro o fuera del modo ambient.

El uso de un programa eBPF (en lugar de iptables) elimina la necesidad de tareas de encapsulación (para Geneve), lo que permite personalizar las tareas de enrutamiento en el espacio del kernel. Esto produce tanto ganancias en el rendimiento como flexibilidad adicional en el enrutamiento.

{{< image width="55%"
    link="ambient-ebpf.png"
    caption="arquitectura de ambient eBPF"
    >}}

Todo el tráfico hacia/desde el pod de aplicación será interceptado por eBPF y redirigido al pod ztunnel correspondiente. En el lado de ztunnel, se realizará la redirección adecuada basada en los resultados de búsqueda de conexión dentro del programa eBPF. Esto proporciona un control más eficiente del tráfico de red entre la aplicación y ztunnel.

## Cómo habilitar la redirección eBPF en el modo ambient de Istio

Siga las instrucciones en [Comenzando con Ambient Mesh](/blog/2022/get-started-ambient/) para configurar su clúster, con un pequeño cambio: cuando instale Istio, configure el parámetro de configuración `values.cni.ambient.redirectMode` en `ebpf`.

{{< text bash >}}
$ istioctl install --set profile=ambient --set values.cni.ambient.redirectMode="ebpf"
{{< /text >}}

Verifique los registros de `istio-cni` para confirmar que la redirección eBPF está activada:

{{< text plain >}}
ambient Writing ambient config: {"ztunnelReady":true,"redirectMode":"eBPF"}
{{< /text >}}

## Ganancias de rendimiento

La latencia y el rendimiento (QPS) para la redirección eBPF son algo mejores que el uso de iptables. Las siguientes pruebas se ejecutaron en un clúster `kind` con un cliente Fortio enviando solicitudes a un servidor Fortio, ambos ejecutándose en modo ambient (con el registro de depuración de eBPF deshabilitado) y en el mismo nodo de trabajo de Kubernetes.

{{< text bash >}}
$ fortio load -uniform -t 60s -qps 0 -c <num_connections> http://<fortio-svc-name>:8080
{{< /text >}}

{{< image width="90%" link="./MaxQPS.png" alt="QPS máximo con número variable de conexiones" title="QPS máximo con número variable de conexiones" caption="QPS máximo, con número variable de conexiones" >}}

{{< text bash >}}
$ fortio load -uniform -t 60s -qps 8000 -c <num_connections> http://<fortio-svc-name>:8080
{{< /text >}}

{{< image width="90%" link="./P75-Latency-with-8000-qps.png" alt="Latencia (ms) para QPS 8000 con número variable de conexiones" title="Latencia P75 (ms) para 8000 QPS, con número variable de conexiones" caption="Latencia P75 (ms) para QPS 8000 con número variable de conexiones" >}}

## Conclusión

Tanto eBPF como iptables tienen sus propias ventajas y desventajas cuando se trata de redirección de tráfico. eBPF es una alternativa moderna, flexible y potente que permite más personalización en la creación de reglas y ofrece un mejor rendimiento. Sin embargo, requiere una versión moderna del kernel (4.20 o posterior para el caso de redirección) que puede no estar disponible en algunos sistemas. Por otro lado, iptables es ampliamente utilizado y compatible con la mayoría de las distribuciones de Linux, incluso aquellas con kernels más antiguos. Sin embargo, carece de la flexibilidad y extensibilidad de eBPF y puede tener un rendimiento inferior.

En última instancia, la elección entre eBPF e iptables para la redirección de tráfico dependerá de las necesidades y requisitos específicos del sistema, así como del nivel de experiencia del usuario en el uso de cada herramienta. Algunos usuarios pueden preferir la simplicidad y compatibilidad de iptables, mientras que otros pueden requerir la flexibilidad y el rendimiento de eBPF.

Todavía hay mucho trabajo por hacer, incluida la integración con varios complementos CNI, y las contribuciones para mejorar la facilidad de uso serían muy bienvenidas. Únase a nosotros en #ambient en el [slack de Istio](https://slack.istio.io/).


