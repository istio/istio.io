---
title: "Madurando Istio Ambient: Compatibilidad a través de varios proveedores de Kubernetes y CNI"
description: Un innovador mecanismo de redirección de tráfico entre los pods de workload y ztunnel.
publishdate: 2024-01-29
attribution: "Ben Leggett (Solo.io), Yuval Kohavi (Solo.io), Lin Sun (Solo.io)"
keywords: [Ambient,Istio,CNI,ztunnel,traffic]
---

El proyecto Istio [anunció ambient mesh, su nuevo modo de data plane sin sidecar](/blog/2022/introducing-ambient-mesh/) en 2022,
y [lanzó una implementación alfa](/news/releases/1.18.x/announcing-1.18/#ambient-mesh) a principios de 2023.

Nuestra alfa se centró en demostrar el valor del modo de data plane ambient en configuraciones y entornos limitados.
Sin embargo, las condiciones eran bastante limitadas. El modo ambient se basa en la redirección transparente del tráfico entre los pods de workload y [ztunnel](/blog/2023/rust-based-ztunnel/), y el mecanismo inicial
que utilizamos para hacerlo entraba en conflicto con varias categorías de implementaciones de la Interfaz de Red de Contenedores (CNI) de terceros.
A través de los problemas de GitHub y las discusiones de Slack, escuchamos que nuestros usuarios querían poder usar el modo ambient en [minikube](https://github.com/istio/istio/issues/46163)
y [Docker Desktop](https://github.com/istio/istio/issues/47436), con implementaciones de CNI como [Cilium](https://github.com/istio/istio/issues/44198) y [Calico](https://github.com/istio/istio/issues/40973),
y en servicios que envían implementaciones de CNI internas
como [OpenShift](https://github.com/istio/istio/issues/42341) y [Amazon EKS](https://github.com/istio/istio/issues/42340).
Obtener un amplio soporte para Kubernetes en cualquier lugar se ha convertido en el requisito número 1 para que ambient mesh pase a beta; la gente espera que Istio
funcione en cualquier plataforma de Kubernetes y con cualquier implementación de CNI. Después de todo, ¡ambient no sería ambient sin estar a tu alrededor!

En Solo, hemos estado integrando el modo ambient en nuestro producto Gloo Mesh, y se nos ocurrió una solución innovadora a este problema.
Decidimos [hacer upstream](https://github.com/istio/istio/issues/48212) de nuestros cambios a finales de 2023 para ayudar a que ambient llegue a beta más rápido,
para que más usuarios puedan operar ambient en Istio 1.21 o más reciente, y disfrutar de los beneficios de la malla sin sidecar ambient en sus plataformas
independientemente de su implementación de CNI existente o preferida.

## ¿Cómo llegamos aquí?

### Service meshes y CNI: es complicado

Istio es una service mesh, y todas las service meshes, por definición estricta, no son *implementaciones de CNI*: las service meshes requieren una
[implementación de CNI primaria que cumpla con las especificaciones](https://www.cni.dev/docs/spec/#overview-1) para estar presente en cada cluster de Kubernetes, y se apoyan en ella.

Esta implementación de CNI primaria puede ser proporcionada por tu proveedor de la nube (AKS, GKE y EKS envían la suya propia), o por implementaciones de CNI de terceros
como Calico y Cilium. Algunas service meshes también pueden enviarse junto con su propia implementación de CNI primaria, que
requieren explícitamente para funcionar.

Básicamente, antes de que puedas hacer cosas como proteger el tráfico de los pods con mTLS y aplicar políticas de autenticación y autorización de alto nivel en la
capa de la service mesh, debes tener un cluster de Kubernetes funcional con una implementación de CNI funcional, para asegurarte de que las vías de red básicas
estén configuradas para que los paquetes puedan ir de un pod a otro (y de un nodo a otro) en tu cluster.

Aunque algunas service meshes también pueden enviar y requerir su propia implementación de CNI primaria interna, y a veces es posible ejecutar dos
implementaciones de CNI primarias en paralelo dentro del mismo cluster (por ejemplo, una enviada por el proveedor de la nube y una implementación de terceros
), en la práctica esto introduce una gran cantidad de problemas de compatibilidad, comportamientos extraños, conjuntos de características reducidos y algunas
incompatibilidades debido a los mecanismos muy variados que cada implementación de CNI podría emplear internamente.

Para evitar esto, el proyecto Istio ha optado por no enviar ni requerir nuestra propia implementación de CNI primaria, ni siquiera requerir una implementación de CNI "preferida"
, sino que ha optado por admitir el encadenamiento de CNI con el ecosistema más amplio posible de implementaciones de CNI, y garantizar la máxima
compatibilidad con las ofertas gestionadas, el soporte entre proveedores y la componibilidad con el ecosistema más amplio de la CNCF.

### Redirección de tráfico en la alfa de ambient

El componente [istio-cni](/es/docs/setup/additional-setup/cni/) es un componente opcional en el modo de data plane de sidecar,
comúnmente utilizado para eliminar el [requisito de las capacidades `NET_ADMIN` y `NET_RAW`](/es/docs/ops/deployment/application-requirements/) para
los usuarios que implementan pods en la malla. `istio-cni` es un componente obligatorio en el modo de data plane
ambient. El componente `istio-cni` _no_ es una implementación de CNI primaria, es un agente de nodo que extiende cualquier implementación de CNI primaria que ya esté presente en el cluster.

Cada vez que se agregan pods a una malla ambient, el componente `istio-cni` configura la redirección de tráfico para todo
el tráfico entrante y saliente entre los pods y el [ztunnel](/blog/2023/rust-based-ztunnel/) que se ejecuta en
el nodo del pod, a través del namespace de red a nivel de nodo. La diferencia clave entre el mecanismo de sidecar y el mecanismo alfa de ambient
es que en este último, el tráfico del pod se redirigía fuera del namespace de red del pod y hacia el namespace de red del pod ztunnel coubicado, pasando necesariamente por el namespace de red del host en el camino, que es donde se implementó la mayor parte de las reglas de redirección de tráfico para lograr esto.

A medida que probamos más ampliamente en múltiples entornos de Kubernetes del mundo real, que tienen su propio CNI predeterminado, quedó claro que capturar y
redirigir el tráfico de los pods en el namespace de red del host, como lo estábamos haciendo durante el desarrollo alfa, no iba a cumplir con nuestros requisitos. Lograr nuestros objetivos de manera genérica en estos diversos entornos simplemente no era factible con este enfoque.

El problema fundamental con la redirección del tráfico en el namespace de red del host es que este es precisamente el mismo lugar donde la implementación de CNI primaria del cluster *debe* configurar las reglas de enrutamiento/red. Esto creó conflictos inevitables, los más críticos:

- La configuración de red básica a nivel de host de la implementación de CNI primaria podría interferir con la configuración de red ambient a nivel de host de la extensión CNI de Istio, causando interrupciones en el tráfico y otros conflictos.
- Si los usuarios implementaran una política de red para que la hiciera cumplir la implementación de CNI primaria, la política de red podría no aplicarse cuando se
implementa la extensión CNI de Istio (dependiendo de cómo la implementación de CNI primaria aplique la NetworkPolicy)

Si bien podríamos diseñar en torno a esto caso por caso para _algunas_ implementaciones de CNI primarias, no podríamos abordar de manera sostenible
el soporte universal de CNI. Consideramos eBPF, pero nos dimos cuenta de que cualquier implementación de eBPF tendría el mismo problema básico, ya que no hay una
forma estandarizada de encadenar/extender de forma segura programas eBPF arbitrarios en este momento, y todavía tendríamos dificultades para admitir
CNI que no son eBPF con este enfoque.

### Abordando los desafíos

Era necesaria una nueva solución: hacer una redirección de cualquier tipo en el namespace de red del nodo crearía conflictos inevitables,
a menos que comprometiéramos nuestros requisitos de compatibilidad.

En el modo sidecar, es trivial configurar la redirección de tráfico entre el sidecar y el pod de la aplicación, ya que ambos operan dentro
del namespace de red del pod. Esto llevó a un momento de iluminación: ¿por qué no imitar a los sidecars y configurar la redirección en
el namespace de red del pod de la aplicación?

Si bien esto suena como una idea "simple", ¿cómo sería posible? Un requisito crítico de ambient es que ztunnel debe ejecutarse fuera de los pods de la aplicación, en el namespace del sistema de Istio. Después de investigar un poco, descubrimos que un proceso de Linux que se ejecuta en un namespace de red podría crear y poseer sockets de escucha dentro de otro namespace de red. Esta es una capacidad básica de la API de sockets de Linux.
Sin embargo, para que esto funcione operativamente y cubra todos los escenarios del ciclo de vida del pod, tuvimos que realizar cambios arquitectónicos en el ztunnel, así como en el agente de nodo `istio-cni`.

Después de crear prototipos y validar suficientemente que este enfoque novedoso funciona para todas las plataformas de Kubernetes a las que tenemos acceso, desarrollamos confianza en el trabajo y decidimos contribuir para hacer upstream de este nuevo modelo de redirección de tráfico
, un mecanismo de redirección de tráfico *in-Pod* entre los pods de workload y el componente de proxy de nodo ztunnel que se ha construido desde cero para ser altamente compatible con todos los principales proveedores de la nube y CNI.

La innovación clave es entregar el namespace de red del pod al ztunnel coubicado para que ztunnel pueda iniciar sus sockets de redirección
_dentro_ del namespace de red del pod, sin dejar de ejecutarse fuera del pod. Con este enfoque, la redirección de tráfico
entre ztunnel y los pods de la aplicación ocurre de una manera muy similar a los sidecars y los pods de la aplicación en la actualidad y es
estrictamente invisible para cualquier CNI primario de Kubernetes que opere en el namespace de red del nodo. La política de red puede seguir siendo aplicada y gestionada por cualquier CNI primario de Kubernetes,
independientemente de si el CNI utiliza eBPF o iptables, sin ningún conflicto.

## Inmersión técnica profunda en la redirección de tráfico in-Pod

Primero, repasemos los conceptos básicos de cómo viaja un paquete entre pods en Kubernetes.

### Linux, Kubernetes y CNI: ¿qué es un namespace de red y por qué es importante?

En Linux, un *contenedor* es uno o más procesos de Linux que se ejecutan dentro de namespaces de Linux aislados. Un namespace de Linux
es simplemente una bandera del kernel que controla lo que los procesos que se ejecutan dentro de ese namespace pueden ver. Por ejemplo, si
creas un nuevo namespace de red de Linux a través del comando `ip netns add my-linux-netns` y ejecutas un proceso dentro de él, ese proceso solo puede ver las reglas de red creadas
dentro de ese namespace de red. No puede ver ninguna regla de red creada fuera de él, aunque todo lo que se ejecuta en esa máquina todavía comparte una pila de red de Linux.

Los namespaces de Linux son conceptualmente muy parecidos a los namespaces de Kubernetes: etiquetas lógicas que organizan y aíslan diferentes
procesos activos, y te permiten crear reglas sobre qué cosas dentro de un namespace determinado pueden ver y qué reglas se
les aplican; simplemente operan a un nivel mucho más bajo.

Cuando un proceso que se ejecuta dentro de un namespace de red crea un paquete TCP con destino a otra cosa, el paquete debe ser
procesado primero por cualquier regla local dentro del namespace de red local, luego abandonar el namespace de red local, pasando
a otro.

Por ejemplo, en un Kubernetes simple sin ninguna malla instalada, un pod podría crear un paquete y enviarlo a otro pod, y
el paquete podría (dependiendo de cómo se configuró la red):
- Ser procesado por cualquier regla dentro del namespace de red del pod de origen.
- Abandonar el namespace de red del pod de origen y subir al namespace de red del nodo, donde es procesado por cualquier regla en ese namespace.
- Desde allí, finalmente ser redirigido al namespace de red del pod de destino (y procesado por cualquier regla allí).

En Kubernetes, la [Interfaz de *Tiempo de Ejecución* de Contenedores (CRI)](https://kubernetes.io/docs/concepts/architecture/cri/) es responsable de hablar con el kernel de Linux, crear namespaces de red
para nuevos pods e iniciar procesos dentro de ellos. Luego, la CRI invoca la [Interfaz de *Red* de Contenedores (CNI)](https://github.com/containernetworking/cni),
que es responsable de conectar las reglas de red en los diversos namespaces de red de Linux, para que los paquetes que salen y
entran al nuevo pod puedan llegar a donde se supone que deben ir. A Kubernetes o al tiempo de ejecución del contenedor no le importa mucho qué topología o mecanismo utiliza la CNI para lograr esto; mientras los paquetes lleguen a donde se supone que deben estar, Kubernetes funciona y todos están contentos.

### ¿Por qué abandonamos el modelo anterior?

En la malla ambient de Istio, cada nodo tiene un mínimo de dos contenedores que se ejecutan como DaemonSets de Kubernetes:
- Un ztunnel eficiente que se encarga de las tareas de proxy de tráfico de la malla y la aplicación de políticas L4.
- Un agente de nodo `istio-cni` que se encarga de agregar pods nuevos y existentes a la malla ambient.

En la implementación anterior de la malla ambient, así es como se agrega un pod de aplicación a la malla ambient:
- El agente de nodo `istio-cni` detecta un pod de Kubernetes existente o recién iniciado con su namespace etiquetado con `istio.io/data plane-mode=ambient`, lo que indica que debe incluirse en la malla ambient.
- El agente de nodo `istio-cni` luego establece reglas de redirección de red en el namespace de red del host, de modo que
los paquetes que entran o salen del pod de la aplicación serían interceptados y redirigidos al ztunnel de ese nodo en los [puertos](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports) de proxy
relevantes (15008, 15006 o 15001).

Esto significa que para un paquete creado por un pod en la malla ambient, ese paquete saldría de ese pod de origen, entraría en el namespace de red del host
del nodo y luego, idealmente, sería interceptado y redirigido al ztunnel de ese nodo (que se ejecuta en su propio namespace de red
) para el proxy al pod de destino, con un viaje de regress similar.

Este modelo funcionó lo suficientemente bien como un marcador de posición para la implementación alfa inicial de la malla ambient, pero como se mencionó, tiene un problema fundamental
: hay muchas implementaciones de CNI, y en Linux hay muchas formas fundamentalmente diferentes e incompatibles
en las que puedes configurar cómo los paquetes van de un namespace de red a otro. Puedes usar túneles, redes superpuestas,
pasar por el namespace de red del host o evitarlo. Puedes pasar por la pila de red del espacio de usuario de Linux,
o puedes omitirla y transportar paquetes de un lado a otro en la pila del espacio del kernel, etc. Para cada enfoque posible,
probablemente haya una implementación de CNI que lo utilice.

Lo que significaba que con el enfoque de redirección anterior, había muchas implementaciones de CNI con las que ambient simplemente no
funcionaría. Dada su dependencia de la redirección de paquetes del namespace de red del host, cualquier CNI que no enrutara paquetes a través del
namespace de red del host necesitaría una implementación de redirección diferente. E incluso para las CNI que sí lo hacían, tendríamos
problemas inevitables y potencialmente irresolubles con reglas conflictivas a nivel de host. ¿Interceptamos antes de la CNI
o después? ¿Se romperán algunas CNI si hacemos una cosa u otra, y no lo esperan? ¿Dónde y cuándo se aplica la NetworkPolicy
, ya que la NetworkPolicy debe aplicarse en el namespace de red del host? ¿Necesitamos mucho código para casos especiales
de cada CNI popular?

### Redirección de tráfico ambient de Istio: el nuevo modelo

En el nuevo modelo ambient, así es como se agrega un pod de aplicación a la malla ambient:
- El agente de nodo `istio-cni` detecta un pod de Kubernetes (existente o recién iniciado) con su namespace etiquetado con `istio.io/data plane-mode=ambient`, lo que indica que debe incluirse en la malla ambient.
  - Si se inicia un pod *nuevo* que debe agregarse a la malla ambient, un complemento CNI (instalado y administrado por el agente `istio-cni`) es activado por la CRI.
  Este complemento se utiliza para enviar un nuevo evento de pod al agente `istio-cni` del nodo y bloquear el inicio del pod hasta que el agente configure correctamente la
  redirección. Dado que los complementos CNI son invocados por la CRI lo antes posible en el proceso de creación de pods de Kubernetes, esto garantiza que podamos
  establecer la redirección de tráfico lo suficientemente temprano como para evitar que el tráfico se escape durante el inicio, sin depender de cosas como los contenedores de inicialización.
  - Si un pod *ya en ejecución* se agrega a la malla ambient, se activa un nuevo evento de pod. El observador de la API de Kubernetes
  del agente de nodo `istio-cni` detecta esto y la redirección se configura de la misma manera.
- El agente de nodo `istio-cni` ingresa al namespace de red del pod y establece reglas de redirección de red dentro del namespace de red del pod, de modo que los paquetes que entran y salen del pod se interceptan y se redirigen de forma transparente a la instancia de proxy ztunnel local del nodo que escucha en los [puertos conocidos](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports) (15008, 15006, 15001).
- El agente de nodo `istio-cni` luego informa al ztunnel del nodo a través de un socket de dominio Unix que debe establecer puertos de escucha de proxy
locales dentro del namespace de red del pod (en 15008, 15006 y 15001), y proporciona a ztunnel un [descriptor de archivo](https://en.wikipedia.org/wiki/File_descriptor) de Linux
de bajo nivel que representa el namespace de red del pod.
  - Si bien normalmente los sockets se crean dentro de un namespace de red de Linux por el proceso que se ejecuta realmente dentro de ese
namespace de red, es perfectamente posible aprovechar la API de sockets de bajo nivel de Linux para permitir que un proceso que se ejecuta en un
namespace de red cree sockets de escucha en otro namespace de red, asumiendo que el namespace de red de destino se conoce
en el momento de la creación.
- El ztunnel local del nodo internamente crea una nueva instancia de proxy y un conjunto de puertos de escucha, dedicados al pod recién agregado.
- Una vez que las reglas de redirección in-Pod están en su lugar y el ztunnel ha establecido los puertos de escucha, el pod se agrega a la
malla y el tráfico comienza a fluir a través del ztunnel local del nodo, como antes.

Aquí hay un diagrama básico que muestra el flujo de un pod de aplicación que se agrega a la malla ambient:

{{< image width="100%"
    link="./pod-added-to-ambient.svg"
    alt="flujo de pod agregado a la malla ambient"
    >}}

Una vez que el pod se agrega con éxito a la malla ambient, el tráfico hacia y desde los pods en la malla se cifrará completamente con mTLS de forma predeterminada, como siempre con Istio.

El tráfico ahora entrará y saldrá del namespace de red del pod como tráfico cifrado; parecerá que cada pod en la malla ambient tiene la capacidad de hacer cumplir la política de la malla y cifrar el tráfico de forma segura, aunque la aplicación de usuario que se ejecuta en el pod
no tiene conocimiento de ninguna de las dos cosas.

Aquí hay un diagrama para ilustrar cómo fluye el tráfico cifrado entre los pods en la malla ambient en el nuevo modelo:

{{< image width="100%"
    link="./traffic-flows-between-pods-in-ambient.svg"
    alt="El tráfico HBONE fluye entre los pods en la malla ambient"
    >}}

Y, como antes, el tráfico de texto sin cifrar no cifrado desde fuera de la malla todavía se puede manejar y la política se puede aplicar, para los casos de uso
en los que sea necesario:

{{< image width="100%"
    link="./traffic-flows-plaintext.svg"
    alt="Flujo de tráfico de texto sin cifrar entre pods en malla"
    >}}

### La nueva redirección de tráfico ambient: lo que esto nos da

El resultado final del nuevo modelo de captura ambient es que toda la captura y redirección de tráfico ocurre dentro del namespace de red del pod.
Para el nodo, la CNI y todo lo demás, parece que hay un proxy sidecar dentro del pod, aunque **no hay ningún proxy sidecar ejecutándose en el pod**
en absoluto. Recuerda que el trabajo de las implementaciones de CNI es llevar paquetes **hacia y desde** el pod. Por diseño y por la especificación de CNI,
no les importa lo que suceda con los paquetes después de ese punto.

Este enfoque elimina automáticamente los conflictos con una amplia gama de implementaciones de CNI y NetworkPolicy, y mejora drásticamente
la compatibilidad de la malla ambient de Istio con todas las principales ofertas de Kubernetes gestionadas en todas las principales CNI.

## Conclusión

Gracias a la cantidad significativa de esfuerzo de nuestra encantadora comunidad en probar el cambio con una gran variedad de plataformas de Kubernetes y CNI, y muchas rondas de revisiones de los mantenedores de Istio, nos complace anunciar que los PR de [ztunnel](https://github.com/istio/ztunnel/pull/747) e [istio-cni](https://github.com/istio/istio/pull/48253) que implementan esta característica se fusionaron en Istio 1.21 y están habilitados de forma predeterminada para ambient, por lo que los usuarios de Istio pueden comenzar a ejecutar la malla ambient en cualquier plataforma de Kubernetes con cualquier CNI en Istio 1.21 o más reciente. Hemos probado esto con GKE,
AKS y EKS y todas las implementaciones de CNI que ofrecen, así como con CNI de terceros como
Calico y Cilium, así como plataformas como OpenShift, con resultados sólidos.

Estamos extremadamente emocionados de poder
hacer avanzar la malla ambient de Istio para que se ejecute en todas partes con este innovador enfoque de redirección de tráfico in-Pod entre ztunnel
y los pods de aplicación de los usuarios. Con este principal obstáculo técnico para la beta de ambient resuelto, ¡estamos ansiosos por trabajar con el
resto de la comunidad de Istio para llevar la malla ambient a beta pronto! Para obtener más información sobre el progreso de la beta de la malla ambient, únete a nosotros en
el canal #ambient y #ambient-dev en el [slack](https://slack.istio.io) de Istio, o asiste a la [reunión semanal de contribuyentes de ambient](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings) los miércoles,
o echa un vistazo al [tablero del proyecto](https://github.com/orgs/istio/projects/9/views/3?filterQuery=beta) beta de la malla ambient y ¡ayúdanos a arreglar algo!
