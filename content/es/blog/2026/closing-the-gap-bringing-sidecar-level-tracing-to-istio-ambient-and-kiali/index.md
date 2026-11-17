---
title: "Cerrando la brecha: trazado a nivel de sidecar en el modo ambient de Istio con Kiali"
description: La paridad de trazado entre los modos ambient y sidecar llega con Istio 1.29 y Kiali 2.25, cerrando la brecha de visibilidad de los workloads.
publishdate: 2026-10-20
attribution: "Josune Córdoba"
keywords: [istio, ambient, tracing, kiali, telemetry, observability]
target_release: "1.30"
---

El modo ambient de Istio ha evolucionado de forma constante a lo largo de las últimas versiones. Aunque alcanzó GA en la versión 1.24, su comportamiento ha ido cambiando a medida que las funcionalidades se modificaban y estabilizaban en versiones posteriores. Con el lanzamiento de Istio 1.29 y Kiali 2.25, ya podemos afirmar con confianza que el trazado en modo ambient ha alcanzado la paridad total con el modo sidecar.

## El papel de los waypoint proxies

Como contexto, es importante señalar que la telemetría de capa 7 (L7), tanto las métricas como las trazas, la proporcionan los **[waypoint proxies](/es/docs/ambient/overview/#waypoint-proxies)**. A diferencia del modo sidecar, donde el proxy reside en el mismo pod que la aplicación, un waypoint es un recurso compartido y desacoplado que puede tener como alcance un namespace, un servicio o incluso workloads específicos. Actúa como el "guardián" del tráfico que gestiona, procesando toda la lógica L7. Por el contrario, el agente de nodo de ambient, [ztunnel](/es/docs/ambient/overview/#ztunnel), solo opera en la capa 4, por lo que no puede generar telemetría L7.

{{< image width="90%" link="./waypoint-traffic-graph.png" caption="El waypoint gestionando el tráfico: vista desde el grafo de tráfico de Kiali" >}}

## El cambio de identidad: de servicio a waypoint

Como los waypoint proxies son externos al workload, identificar al "propietario" de una traza ha sido un desafío de arquitectura. En Istio 1.27, el waypoint proxy creaba la traza usando el _nombre del waypoint_ como servicio.

{{< image width="90%" link="./service-traces-istio-127.png" caption="Trazas de servicio con Istio 1.27" >}}

En Istio 1.28 se introdujo un cambio para atribuir la traza directamente al servicio de destino, en lugar de al waypoint. Este comportamiento se mantuvo durante las versiones 1.29.

{{< tip >}}
Ten en cuenta que este cambio fue exclusivo del proveedor OpenTelemetry (OTel); los formatos tradicionales como Zipkin siguieron usando la identidad del waypoint.
{{< /tip >}}

{{< image width="90%" link="./service-traces-istio-129.png" caption="Trazas de servicio con Istio 1.29" >}}

Istio 1.30 refinó la situación al tratar al waypoint como un "ciudadano de primera clase". Ahora el waypoint preserva la realidad arquitectónica del salto sin ocultar el destino. El _nombre de la operación_ del span refleja correctamente el tráfico de servicio redirigido, mientras que los _metadatos de infraestructura_ apuntan al waypoint.

{{< image width="90%" link="./service-traces-istio-130.png" caption="Trazas de servicio con Istio 1.30" >}}

## El eslabón perdido: la visibilidad de los workloads

Aunque el trazado de servicio a servicio funcionaba, existía una brecha importante: la granularidad a nivel de workload. En modo sidecar, nos apoyamos en el atributo `node_id` para identificar pods específicos. En modo ambient, este atributo faltaba. Si un servicio enrutaba tráfico a varias versiones de un workload (por ejemplo, v1, v2 y v3), podíamos ver el salto del servicio, pero perdíamos la capacidad de identificar qué workload concreto estaba procesando la solicitud, con la consiguiente pérdida de información importante para la depuración.

{{< image width="90%" link="./workload-visibility-gap.png" caption="Trazabilidad incompleta sin la información de los workloads" >}}

Esta brecha se cerró en Istio 1.29. Al introducir atributos explícitos como `istio.source_workload` y `istio.destination_workload`, y aprovechando la posición privilegiada de "intermediario" del waypoint, ahora tenemos una vista completa tanto del origen como del destino final.

{{< image width="90%" link="./span-attributes-trace.png" caption="Atributos de los spans de una traza" >}}

## Kiali: el plano de observabilidad unificado

[Kiali](https://kiali.io/) es la consola de la service mesh de Istio. Te ayuda a configurar, visualizar, validar y solucionar problemas de tu mesh correlacionando métricas, trazas y configuración en una única vista.

Entonces, ¿cómo se reflejan estas mejoras de trazado en Kiali? Gracias a estos nuevos atributos, la funcionalidad **Trace Overlay** de Kiali es ahora más potente que nunca. Al seleccionar una traza, Kiali resalta todo el recorrido de la solicitud, incluidos tanto los servicios como los workloads específicos involucrados, completando la vista de una traza en el grafo de aplicaciones versionadas.

Kiali construye el grafo de tráfico a partir de los datos de métricas, que proporcionan la topología, y ofrece una representación visual de cómo fluyen las solicitudes a través de la mesh. La funcionalidad Trace Overlay usa entonces la traza seleccionada para resaltar los nodos y las aristas que pertenecen a ese recorrido concreto. En otras palabras, las métricas aportan la estructura del grafo y el trazado identifica la ruta exacta que siguió la solicitud dentro de esa estructura.

Esto funciona salto a salto. La traza seleccionada proporciona una secuencia de spans, y cada span incluye ahora atributos que identifican tanto el servicio como el workload involucrados en ese salto. Con esa información, Kiali puede asociar cada span con los elementos correspondientes del grafo de aplicaciones versionadas y reconstruir el recorrido completo de la solicitud, incluidas las versiones exactas de los workloads que realmente procesaron el tráfico.

{{< image width="90%" link="./kiali-trace-overlay.png" caption="Trace overlay de Kiali" >}}

Una de las misiones de Kiali es facilitar la resolución de problemas. En la vista de detalles del workload, correlaciona los datos automáticamente para que no tengas que buscar manualmente trazas ocultas bajo el nombre de un waypoint. En su lugar, identifica el waypoint asociado a un workload, consulta al proveedor de trazado y filtra los resultados por ti.

{{< image width="90%" link="./kiali-service-details-traces.png" caption="Trazas de servicio en la página de detalles del servicio de Kiali" >}}

Aunque, por defecto, Kiali busca trazas usando el nombre del servicio, puedes ajustar este comportamiento. Si tu entorno lo requiere, según la versión de Istio y el uso del modo ambient, puedes configurar cómo Kiali asocia estas identidades cambiando a `true` la configuración de Kiali `external_services.tracing.use_waypoint_name`.

Más allá de la visualización, este enriquecimiento de la telemetría abre la puerta a capacidades aún más avanzadas. Con un trazado y unas métricas consistentes en toda la mesh, las funcionalidades de IA de Kiali, incluido el [asistente de Kiali](https://kiali.io/docs/ai/kiali-chatbot/), pueden ahora ayudar con mayor precisión en el análisis de causa raíz. Al tener todas las piezas del rompecabezas en su sitio, el asistente puede identificar de forma proactiva cuellos de botella o configuraciones erróneas en tu mesh ambient, convirtiendo la observabilidad en bruto en inteligencia automatizada.

{{< image width="90%" link="./kiali-chatbot-trace-overview.png" caption="El asistente de Kiali ofreciendo un resumen de trazas basado en el contexto actual" >}}

{{< quote >}}
A medida que Istio sigue madurando, Kiali garantiza que pasar al modo ambient no signifique perder el control. Completa el rompecabezas, permitiéndote centrarte en tus servicios mientras Kiali se encarga del intrincado mapeo de la mesh.
{{< /quote >}}

_Una versión de este artículo se publicó por primera vez en [el blog de Kiali en Medium](https://medium.com/kialiproject/closing-the-gap-bringing-sidecar-level-tracing-to-istio-ambient-and-kiali-817b1f9bc61d). Síguenos allí para recibir actualizaciones más frecuentes._
