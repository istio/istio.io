---
title: "Análisis en profundidad de la seguridad del modo Ambient"
description: "Analizamos las implicaciones de seguridad del modo ambient recientemente anunciado de Istio, un plano de datos sin sidecars."
publishdate: 2022-09-07T09:00:00-06:00
attribution: "Ethan Jackson (Google), Yuval Kohavi (Solo.io), Justin Pettit (Google), Christian Posta (Solo.io)"
keywords: [ambient]
---

Recientemente anunciamos el nuevo modo ambient de Istio, que es un plano de datos para Istio sin sidecars y la implementación de referencia del patrón “ambient mesh”. [Como se indica en el post de anuncio](/blog/2022/introducing-ambient-mesh/), las principales preocupaciones que abordamos con ambient mesh son simplificar las operaciones, ampliar la compatibilidad con aplicaciones, reducir costes de infraestructura y mejorar el rendimiento. Al diseñar el plano de datos ambient, queríamos equilibrar cuidadosamente los aspectos de operación, coste y rendimiento sin sacrificar seguridad ni funcionalidad. Como los componentes de ambient mesh se ejecutan fuera de los pods de las aplicaciones, los límites de seguridad han cambiado (creemos que para mejor). En este artículo entramos en detalle sobre estos cambios y cómo se comparan con un despliegue con sidecars.

{{< image link="./ambient-layers.png" caption="Capas del plano de datos de ambient mesh" >}}

En resumen, el modo ambient de Istio introduce un plano de datos en capas con una “capa segura” (secure overlay) responsable de la seguridad de transporte y el enrutamiento, con la opción de añadir capacidades L7 para los namespaces que lo necesiten.
Para entender más, consulta el [artículo de anuncio](/blog/2022/introducing-ambient-mesh/) y el [artículo de primeros pasos](/blog/2022/get-started-ambient).
La capa segura consiste en un componente compartido por nodo, el ztunnel, responsable de la telemetría L4 y mTLS, y que se despliega como un DaemonSet.
La capa L7 del mesh la proporcionan los waypoint proxies: proxies Envoy completos de L7 que se despliegan por identidad/tipo de workload.
Algunas implicaciones clave de este diseño incluyen:

* Separación de la aplicación respecto del plano de datos
* Los componentes de la capa segura se parecen a los de un CNI
* La simplicidad operativa es mejor para la seguridad
* Evitar proxies L7 multi‑tenant
* Los sidecars siguen siendo un modo de despliegue soportado de primera clase

## Separación de la aplicación y el plano de datos

Aunque el objetivo principal de ambient mesh es simplificar las operaciones del service mesh, también mejora la seguridad. La complejidad genera vulnerabilidades, y las aplicaciones empresariales (y sus dependencias transitivas, librerías y frameworks) son extremadamente complejas y propensas a vulnerabilidades. Desde gestionar lógica de negocio compleja hasta depender de librerías OSS o librerías internas compartidas con bugs, el código de la aplicación de un usuario es un objetivo prioritario para atacantes (internos o externos). Si una aplicación se compromete, credenciales, secretos y claves quedan expuestos al atacante, incluidas las montadas o almacenadas en memoria. En el modelo de sidecar, un compromiso de la aplicación implica también la toma de control del sidecar y de cualquier material de identidad/clave asociado. En el modo ambient de Istio, ningún componente del plano de datos se ejecuta en el mismo pod que la aplicación y, por tanto, un compromiso de la aplicación no conduce al acceso a secretos del plano de datos.

¿Y qué hay de Envoy Proxy como posible objetivo de vulnerabilidades? Envoy es una pieza de infraestructura extremadamente endurecida, sometida a un intenso escrutinio y [ejecutada a escala en entornos críticos](https://www.infoq.com/news/2018/12/envoycon-service-mesh/) (por ejemplo, [usada en producción para estar delante de la red de Google](https://cloud.google.com/load-balancing/docs/https)). Sin embargo, como Envoy es software, no es inmune a vulnerabilidades. Cuando aparecen, Envoy cuenta con un proceso robusto de CVEs para identificarlas, corregirlas rápidamente y desplegarlas a los usuarios antes de que puedan tener un impacto amplio.

Volviendo al comentario de que “la complejidad genera vulnerabilidades”, las partes más complejas de Envoy Proxy están en su procesamiento L7 y, de hecho, históricamente la mayoría de vulnerabilidades de Envoy han estado en su stack de procesamiento L7. Pero ¿y si solo usas Istio para mTLS? ¿Por qué asumir el riesgo de desplegar un proxy L7 completo (con mayor probabilidad de CVE) si no vas a usar esa funcionalidad? Aquí entra en juego separar capacidades L4 y L7. Mientras que en despliegues con sidecar adoptas todo el proxy aunque solo uses una fracción de sus capacidades, en modo ambient podemos limitar la exposición proporcionando una capa segura y añadiendo L7 solo cuando se necesita. Además, los componentes L7 se ejecutan completamente separados de las aplicaciones y no ofrecen una vía de ataque directa desde la aplicación.

## Llevar L4 “hacia abajo” al CNI

Los componentes L4 del plano de datos en modo ambient se ejecutan como un DaemonSet (uno por nodo). Esto significa que son infraestructura compartida para cualquier pod que se ejecute en un nodo determinado. Este componente es especialmente sensible y debe tratarse al mismo nivel que cualquier otro componente compartido del nodo, como agentes del CNI, kube-proxy, kubelet o incluso el kernel de Linux. El tráfico de los workloads se redirige al ztunnel, que identifica el workload y selecciona los certificados adecuados para representar ese workload en una conexión mTLS.

El ztunnel usa una credencial distinta para cada pod, que solo se emite si el pod se está ejecutando actualmente en el nodo. Esto asegura que, si un ztunnel se compromete, el “blast radius” queda limitado a que solo podrían robarse credenciales de pods actualmente programados en ese nodo. Esta propiedad es similar a la de otras infraestructuras compartidas por nodo bien implementadas, incluyendo implementaciones seguras de CNI. El ztunnel no usa credenciales de clúster completo ni credenciales por nodo que, si se robaran, podrían comprometer inmediatamente todo el tráfico de aplicaciones del clúster, a menos que también se implemente un complejo mecanismo secundario de autorización.

Si lo comparamos con el modelo de sidecar, observamos que el ztunnel es compartido y un compromiso podría resultar en la exfiltración de las identidades de las aplicaciones que se ejecutan en el nodo. Sin embargo, la probabilidad de un CVE en este componente es menor que en un sidecar de Istio, ya que la superficie de ataque se reduce significativamente (solo manejo L4); el ztunnel no realiza procesamiento L7. Además, un CVE en un sidecar (con mayor superficie de ataque en L7) no queda realmente contenido solo al workload comprometido: es probable que un CVE serio en un sidecar pueda repetirse en cualquiera de los workloads del mesh.

## La simplicidad operativa es mejor para la seguridad

En última instancia, Istio es una pieza crítica de infraestructura que debe mantenerse. Se confía en Istio para implementar algunos principios de seguridad de red “zero trust” en nombre de las aplicaciones, y desplegar parches de forma planificada o bajo demanda es esencial. Los equipos de plataforma suelen tener ciclos de parcheo o mantenimiento predecibles, muy distintos de los de las aplicaciones. Las aplicaciones normalmente se actualizan cuando se requieren nuevas capacidades y funcionalidad, y suele formar parte de un proyecto. Este enfoque de cambios en aplicaciones, upgrades y parches de frameworks y librerías es muy impredecible, permite que pase mucho tiempo y no favorece prácticas de seguridad seguras. Por lo tanto, mantener estas funciones de seguridad como parte de la plataforma y separadas de las aplicaciones probablemente conduce a una mejor postura de seguridad.

Como señalamos en el artículo de anuncio, operar sidecars puede ser más complejo debido a su naturaleza invasiva (inyectar el sidecar/cambiar descriptores de despliegue, reiniciar aplicaciones, condiciones de carrera entre contenedores, etc.). Las actualizaciones de workloads con sidecars requieren algo más de planificación y reinicios “rolling” que quizá haya que coordinar para no tumbar la aplicación. Con el modo ambient, las actualizaciones del ztunnel pueden coincidir con los parches o upgrades habituales del nodo, mientras que los waypoint proxies forman parte de la red y pueden actualizarse de forma completamente transparente para las aplicaciones cuando sea necesario.

## Evitar proxies L7 multi‑tenant

Soportar protocolos L7 como HTTP 1/2/3, gRPC, parseo de cabeceras, reintentos, personalizaciones con Wasm y/o Lua en el plano de datos es significativamente más complejo que soportar L4. Hay mucho más código para implementar estos comportamientos (incluyendo código personalizado de usuarios para Lua y Wasm), y esa complejidad puede llevar a vulnerabilidades. Por ello, hay más probabilidad de descubrir CVEs en estas áreas de funcionalidad L7.

{{< image link="./ambient-l7-data-plane.png" caption="Cada namespace/identidad tiene sus propios proxies L7; sin proxies multi‑tenant" >}}

En modo ambient no compartimos el procesamiento L7 en un proxy entre múltiples identidades. Cada identidad (service account en Kubernetes) tiene su propio proxy L7 dedicado (waypoint proxy), muy similar al modelo que usamos con sidecars. Intentar co-ubicar múltiples identidades y sus políticas complejas y personalizaciones distintas añade mucha variabilidad a un recurso compartido, lo que conduce, en el mejor de los casos, a una atribución de costes injusta y, en el peor, a un compromiso total del proxy.

## Los sidecars siguen siendo un modo de despliegue soportado de primera clase

Entendemos que algunas personas se sienten cómodas con el modelo de sidecar y sus límites de seguridad conocidos y desean mantenerse en ese modelo. Con Istio, los sidecars son ciudadanos de primera clase del mesh y los propietarios de la plataforma pueden seguir usándolos. Si un propietario de la plataforma quiere soportar tanto sidecar como ambient, puede hacerlo. Un workload con el plano de datos ambient puede comunicarse de forma nativa con workloads que tienen un sidecar desplegado. A medida que se entienda mejor la postura de seguridad del modo ambient, confiamos en que se convierta en el modo de plano de datos preferido de Istio, dejando los sidecars para optimizaciones específicas.
