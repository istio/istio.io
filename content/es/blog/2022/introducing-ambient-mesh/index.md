---
title: "Presentamos Ambient Mesh"
description: "Un nuevo modo de plano de datos para Istio sin sidecars."
publishdate: 2022-09-07T07:00:00-06:00
attribution: "John Howard (Google), Ethan J. Jackson (Google), Yuval Kohavi (Solo.io), Idit Levine (Solo.io), Justin Pettit (Google), Lin Sun (Solo.io)"
keywords: [ambient]
---

{{< tip >}}
[¡El modo Ambient ya está disponible de forma general!](/blog/2024/ambient-reaches-ga/)
{{< /tip >}}

Hoy nos entusiasma presentar “ambient mesh” y su implementación de referencia: un nuevo modo de plano de datos de Istio diseñado para simplificar las operaciones, ampliar la compatibilidad con aplicaciones y reducir los costes de infraestructura. Ambient mesh ofrece a los usuarios la opción de prescindir de proxies sidecar en favor de un plano de datos integrado en su infraestructura, manteniendo las características principales de Istio: seguridad zero‑trust, telemetría y gestión del tráfico. Compartimos con la comunidad de Istio una vista previa de ambient mesh en la que estamos trabajando para llevarla a un nivel apto para producción en los próximos meses.

## Istio y los sidecars

Desde sus inicios, una característica definitoria de la arquitectura de Istio ha sido el uso de _sidecars_: proxies programables desplegados junto a los contenedores de la aplicación. Los sidecars permiten a los operadores obtener los beneficios de Istio sin obligar a las aplicaciones a someterse a una “cirugía mayor” y a sus costes asociados.

{{< image width="100%"
    link="traditional-istio.png"
    caption="El modelo tradicional de Istio despliega proxies Envoy como sidecars dentro de los pods de los workloads"
    >}}

Aunque los sidecars tienen ventajas importantes frente a refactorizar aplicaciones, no proporcionan una separación perfecta entre las aplicaciones y el plano de datos de Istio. Esto conlleva algunas limitaciones:

* **Invasividad** - Los sidecars deben “inyectarse” en las aplicaciones modificando el pod spec de Kubernetes y redirigiendo el tráfico dentro del pod. Como resultado, instalar o actualizar sidecars requiere reiniciar el pod de la aplicación, lo cual puede ser disruptivo para los workloads.
* **Infrautilización de recursos** - Dado que el proxy sidecar está dedicado a su workload asociado, los recursos de CPU y memoria deben provisionarse para el peor caso de cada pod individual. Esto se acumula en grandes reservas que pueden llevar a infrautilización de recursos en todo el clúster.
* **Ruptura de tráfico** - La captura de tráfico y el procesamiento HTTP, tal y como se realiza típicamente en los sidecars de Istio, es computacionalmente costoso y puede romper algunas aplicaciones con implementaciones HTTP no conformes.

Aunque los sidecars tienen su lugar — hablaremos más de esto más adelante — creemos que existe la necesidad de una opción menos invasiva y más sencilla que encaje mejor para muchos usuarios de service mesh.

## Dividir las capas

Tradicionalmente, Istio implementa toda la funcionalidad del plano de datos — desde el cifrado básico hasta políticas L7 avanzadas — en un único componente arquitectónico: el sidecar.
En la práctica, esto convierte a los sidecars en una propuesta de “todo o nada”.
Incluso si un workload solo necesita seguridad de transporte simple, los administradores deben pagar el coste operativo de desplegar y mantener un sidecar.
Los sidecars tienen un coste operativo fijo por workload que no escala para ajustarse a la complejidad del caso de uso.

El plano de datos ambient adopta un enfoque diferente.
Divide la funcionalidad de Istio en dos capas distintas.
En la base, hay una capa segura (secure overlay) que gestiona el enrutamiento y la seguridad zero trust del tráfico.
Encima, cuando se necesita, los usuarios pueden habilitar el procesamiento L7 para acceder a todo el conjunto de funcionalidades de Istio.
El modo de procesamiento L7, aunque más pesado que la capa segura, sigue ejecutándose como un componente “ambient” de la infraestructura, sin requerir modificaciones en los pods de la aplicación.

{{< image width="100%"
    link="ambient-layers.png"
    caption="Capas de la ambient mesh"
    >}}

Este enfoque por capas permite a los usuarios adoptar Istio de manera más incremental, transitando suavemente desde “sin mesh”, a la capa segura, y luego a procesamiento L7 completo — por namespace, según sea necesario. Además, los workloads que se ejecutan en diferentes capas ambient, o con sidecars, interoperan sin problemas, permitiendo combinar capacidades según las necesidades específicas a medida que cambian con el tiempo.

## Construyendo una ambient mesh

El modo de plano de datos ambient de Istio usa un agente compartido que se ejecuta en cada nodo del clúster Kubernetes. Este agente es un túnel zero‑trust (o **_ztunnel_**) y su responsabilidad principal es conectar y autenticar de forma segura los elementos dentro del mesh. La pila de red del nodo redirige todo el tráfico de los workloads participantes a través del agente ztunnel local. Esto separa completamente las preocupaciones del plano de datos de Istio de las de la aplicación, permitiendo que los operadores habiliten, deshabiliten, escalen y actualicen el plano de datos sin perturbar a las aplicaciones. El ztunnel no realiza procesamiento L7 en el tráfico de los workloads, lo que lo hace significativamente más ligero que los sidecars. Esta gran reducción en complejidad y en costes de recursos asociados hace que sea viable como infraestructura compartida.

Los ztunnels habilitan la funcionalidad central de un service mesh: zero trust. Cuando se habilita el modo ambient para un namespace, se crea una capa segura. Proporciona a los workloads mTLS, telemetría, autenticación y autorización L4, sin terminar ni parsear HTTP.

{{< image width="100%"
    link="ambient-secure-overlay.png"
    caption="Ambient mesh usa un ztunnel compartido por nodo para proporcionar una capa segura zero‑trust"
    >}}

Después de habilitar el modo ambient y crear la capa segura, un namespace puede configurarse para utilizar funcionalidades L7.
Esto permite implementar el conjunto completo de capacidades de Istio, incluyendo la [API de Virtual Service](/docs/reference/config/networking/virtual-service/), la [telemetría L7](/docs/reference/config/telemetry/) y las [políticas de autorización L7](/docs/reference/config/security/authorization-policy/).
Los namespaces que operan en este modo usan uno o más **_waypoint proxies_** basados en Envoy para manejar el procesamiento L7 de los workloads del namespace.
El plano de control de Istio configura los ztunnels del clúster para pasar todo el tráfico que requiere procesamiento L7 a través del waypoint proxy.
De forma importante, desde la perspectiva de Kubernetes, los waypoint proxies son pods normales que pueden autoescalarse como cualquier otro deployment de Kubernetes.
Esperamos que esto genere ahorros significativos de recursos, ya que los waypoint proxies pueden autoescalarse para ajustarse a la demanda de tráfico en tiempo real de los namespaces a los que sirven, no al máximo “peor caso” que esperan los operadores.

{{< image width="100%"
    link="ambient-waypoint.png"
    caption="Cuando se necesitan funcionalidades adicionales, ambient mesh despliega waypoint proxies, y los ztunnels se conectan a través de ellos para aplicar políticas"
    >}}

Ambient mesh usa HTTP CONNECT sobre mTLS para implementar sus túneles seguros e insertar waypoint proxies en la ruta, un patrón que llamamos [HBONE (HTTP-Based Overlay Network Environment)](/docs/ambient/architecture/hbone/). HBONE proporciona una encapsulación de tráfico más limpia que TLS por sí solo, a la vez que permite interoperabilidad con infraestructura común de balanceadores de carga. Por defecto se usan builds FIPS para cumplir requisitos de conformidad. Se darán más detalles sobre HBONE, su enfoque basado en estándares y los planes para UDP y otros protocolos no TCP en un artículo futuro.

Mezclar modos sidecar y ambient en un mismo mesh no introduce limitaciones en las capacidades ni en las propiedades de seguridad del sistema. El plano de control de Istio asegura que las políticas se apliquen correctamente independientemente del modelo de despliegue elegido. El modo ambient simplemente introduce una opción con mejor ergonomía y más flexibilidad.

## ¿Por qué no hay procesamiento L7 en el nodo local?

El modo ambient usa un agente ztunnel compartido en el nodo, que maneja los aspectos zero trust del mesh, mientras que el procesamiento L7 ocurre en el waypoint proxy en pods programados por separado. ¿Por qué esta indirección y no usar simplemente un proxy L7 completo compartido en el nodo? Hay varias razones:

* Envoy no es inherentemente multi‑tenant. Por ello, tenemos preocupaciones de seguridad al mezclar reglas de procesamiento complejas para tráfico L7 de múltiples tenants no restringidos en una instancia compartida. Al limitarnos estrictamente a procesamiento L4, reducimos significativamente la superficie de vulnerabilidad.
* Las funcionalidades mTLS y L4 proporcionadas por el ztunnel requieren una huella de CPU y memoria mucho menor comparada con el procesamiento L7 requerido en el waypoint proxy. Al ejecutar waypoint proxies como un recurso compartido del namespace, podemos escalarlos de manera independiente según las necesidades de ese namespace, y sus costes no se reparten injustamente entre tenants no relacionados.
* Al reducir el alcance del ztunnel permitimos que pueda ser reemplazado por otras implementaciones de túneles seguros que cumplan un contrato de interoperabilidad bien definido.

## ¿Y qué pasa con esos saltos extra?

Con el modo ambient, no se garantiza necesariamente que un waypoint esté en el mismo nodo que los workloads a los que sirve. Aunque a primera vista esto pueda parecer una preocupación de rendimiento, estamos convencidos de que la latencia acabará estando en línea con la implementación actual de sidecar de Istio. Hablaremos más en un artículo dedicado a rendimiento, pero por ahora lo resumimos en dos puntos:

* La mayor parte de la latencia de red de Istio no proviene, en realidad, de la red ([los proveedores cloud modernos tienen redes extremadamente rápidas](https://www.clockwork.io/there-is-no-upside-to-vm-colocation/)). En cambio, el principal culpable es el procesamiento L7 intensivo que Istio necesita para implementar su sofisticado conjunto de capacidades. A diferencia de los sidecars, que implementan dos pasos de procesamiento L7 por conexión (uno por cada sidecar), el modo ambient colapsa esos dos pasos en uno. En la mayoría de casos, esperamos que esta reducción de coste de procesamiento compense un salto de red adicional.
* Los usuarios suelen desplegar un mesh como primer paso para habilitar una postura de seguridad zero‑trust y después habilitan selectivamente capacidades L7 según se necesiten. El modo ambient permite a esos usuarios evitar por completo el coste del procesamiento L7 cuando no es necesario.

## Sobrecoste de recursos

En general, esperamos que el modo ambient de Istio tenga requisitos de recursos menores y más predecibles para la mayoría de usuarios.
Las responsabilidades limitadas del ztunnel permiten desplegarlo como un recurso compartido en el nodo.
Esto reducirá sustancialmente las reservas por workload requeridas para la mayoría de usuarios.
Además, como los waypoint proxies son pods normales de Kubernetes, pueden desplegarse y escalarse dinámicamente en función de las demandas de tráfico en tiempo real de los workloads a los que sirven.

Los sidecars, por el contrario, necesitan reservar memoria y CPU para el peor caso de cada workload.
Hacer estos cálculos es complicado, así que en la práctica los administradores tienden a sobre‑aprovisionar.
Esto conduce a nodos infrautilizados debido a reservas altas que impiden programar otros workloads.
El menor overhead fijo por nodo del modo ambient y los waypoint proxies escalados dinámicamente requerirán muchas menos reservas de recursos en agregado, lo que llevará a un uso más eficiente del clúster.

## ¿Y la seguridad?

Con una arquitectura radicalmente nueva es natural que surjan preguntas sobre seguridad. El [artículo sobre seguridad del modo ambient](/blog/2022/ambient-security/) profundiza, pero aquí lo resumimos.

Los sidecars se co‑ubican con los workloads a los que sirven y, como resultado, una vulnerabilidad en uno compromete al otro.
En el modelo ambient mesh, incluso si una aplicación se compromete, los ztunnels y waypoint proxies pueden seguir aplicando políticas de seguridad estrictas al tráfico de la aplicación comprometida.
Además, dado que Envoy es un software maduro y probado en batalla, usado por los mayores operadores de red del mundo, es probable que sea menos vulnerable que las aplicaciones junto a las que se ejecuta.

Aunque el ztunnel es un recurso compartido, solo tiene acceso a las claves de los workloads actualmente en el nodo donde se ejecuta.
Así, su blast radius no es peor que el de cualquier otro CNI cifrado que dependa de claves por nodo para el cifrado.
Y, dado el área de superficie de ataque limitada (solo L4) del ztunnel y las propiedades de seguridad mencionadas de Envoy, consideramos que este riesgo es limitado y aceptable.

Por último, aunque los waypoint proxies son un recurso compartido, pueden limitarse a servir solo a una service account.
Esto hace que no sean peores que los sidecars de hoy; si un waypoint proxy se compromete, se pierde la credencial asociada a ese waypoint y nada más.

## ¿Es este el final del camino para el sidecar?

Definitivamente no.
Aunque creemos que ambient mesh será la mejor opción para muchos usuarios de mesh de aquí en adelante, los sidecars siguen siendo una buena elección para quienes necesitan recursos de plano de datos dedicados, por ejemplo por cumplimiento normativo o para ajuste fino de rendimiento.
Istio seguirá soportando sidecars y, de forma importante, permitirá que interoperan sin problemas con el modo ambient.
De hecho, el código de modo ambient que publicamos hoy ya soporta interoperabilidad con Istio basado en sidecars.

## Aprende más

Echa un vistazo a este breve vídeo para ver a Christian repasando los componentes del modo ambient de Istio y demostrando algunas capacidades:

<iframe width="560" height="315" src="https://www.youtube.com/embed/nupRBh9Iypo" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Participa

Lo que publicamos hoy es una versión temprana del modo ambient en Istio y todavía está en desarrollo activo. Nos emociona compartirlo con la comunidad y esperamos involucrar a más personas para darle forma a medida que avanzamos hacia la preparación para producción en 2023.

Nos encantaría recibir tu feedback para ayudar a construir la solución.
Hay disponible una build de Istio con soporte de modo ambient para [descargar y probar](/blog/2022/get-started-ambient/) en el [repositorio Istio Experimental]({{< github_raw >}}/tree/experimental-ambient).
Hay una lista de funcionalidades faltantes y tareas de trabajo en el [README]({{< github_raw >}}/blob/experimental-ambient/README.md).
¡Pruébalo y [cuéntanos qué te parece!](https://slack.istio.io/)

_¡Gracias al equipo que contribuyó al lanzamiento de ambient mesh!_
* _Google: Craig Box, John Howard, Ethan J. Jackson, Abhi Joglekar, Steven Landow, Oliver Liu, Justin Pettit, Doug Reid, Louis Ryan, Kuat Yessenov, Francis Zhou_
* _Solo.io: Aaron Birkland, Kevin Dorosh, Greg Hanson, Daniel Hawton, Denis Jannot, Yuval Kohavi, Idit Levine, Yossi Mesika, Neeraj Poddar, Nina Polshakova, Christian Posta, Lin Sun, Eitan Yarmush_
