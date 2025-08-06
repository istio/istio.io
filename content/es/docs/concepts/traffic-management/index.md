---
title: Gestión de Tráfico
description: Describe las diversas features de Istio centradas en el enrutamiento y control del tráfico.
weight: 20
keywords: [traffic-management, pilot, envoy-proxies, service-discovery, load-balancing]
aliases:
    - /docs/concepts/traffic-management/pilot
    - /docs/concepts/traffic-management/rules-configuration
    - /docs/concepts/traffic-management/fault-injection
    - /docs/concepts/traffic-management/handling-failures
    - /docs/concepts/traffic-management/load-balancing
    - /docs/concepts/traffic-management/request-routing
    - /docs/concepts/traffic-management/pilot.html
    - /docs/concepts/traffic-management/overview.html
owner: istio/wg-networking-maintainers
test: n/a
---

Las reglas de enrutamiento de tráfico de Istio le permiten controlar fácilmente el flujo
de tráfico y las llamadas API entre services. Istio simplifica la configuración de
propiedades a nivel de service como disyuntores, tiempos de espera y reintentos, y facilita
la configuración de tareas importantes como pruebas A/B, despliegues canary y despliegues por etapas
con divisiones de tráfico basadas en porcentajes. También proporciona features de fiabilidad listas para usar
que ayudan a que su application
sea más resiliente contra fallos de services dependientes o de la red.

El modelo de gestión de tráfico de Istio se basa en los proxies {{< gloss >}}Envoy{{</ gloss >}}
que se despliegan junto con sus services. Todo el tráfico que sus services de malla
envían y reciben (tráfico del {{< gloss >}}data plane{{</ gloss >}}) se proxy a través de Envoy, lo que facilita
dirigir y controlar el tráfico alrededor de su mesh sin realizar ningún
cambio en sus services.

Si está interesado en los detalles de cómo funcionan las features descritas en esta guía,
puede encontrar más información sobre la implementación de la gestión de tráfico de Istio en la
[descripción general de la arquitectura](/es/docs/ops/deployment/architecture/). El resto de
esta guía presenta las features de gestión de tráfico de Istio.

## Introducción a la gestión de tráfico de Istio

Para dirigir el tráfico dentro de su malla, Istio necesita saber dónde están todos sus
endpoints y a qué services pertenecen. Para poblar su propio
{{< gloss >}}service registry{{</ gloss >}}, Istio se conecta a un sistema de
descubrimiento de services. Por ejemplo, si ha instalado Istio en un cluster de Kubernetes,
entonces Istio detecta automáticamente los services y endpoints en ese cluster.

Utilizando este service registry, los proxies Envoy pueden dirigir el tráfico a los
services relevantes. La mayoría de las applications basadas en microservicios tienen múltiples instancias
de cada workload de service para manejar el tráfico de service, a veces denominado
pool de balanceo de carga. Por defecto, los proxies Envoy distribuyen el tráfico entre
el pool de balanceo de carga de cada service utilizando un modelo de menos solicitudes, donde cada
solicitud se enruta al host con menos solicitudes activas de una
selección aleatoria de dos hosts del pool; de esta manera, el host más cargado
no recibirá solicitudes hasta que no esté más cargado que cualquier otro host.

Si bien el descubrimiento de services básico y el balanceo de carga de Istio le brindan una service mesh funcional,
está lejos de todo lo que Istio puede hacer. En muchos casos, es posible que desee
un control más granular sobre lo que sucede con el tráfico de su malla.
Es posible que desee dirigir un porcentaje particular de tráfico a una nueva versión de
un service como parte de las pruebas A/B, o aplicar una política de balanceo de carga diferente al
tráfico para un subconjunto particular de instancias de service. También es posible que desee
aplicar reglas especiales al tráfico que entra o sale de su malla, o agregar una
dependencia externa de su mesh al service registry. Puede hacer todo esto
y más agregando su propia configuración de tráfico a Istio utilizando la API de gestión de tráfico de Istio.

Al igual que otras configuraciones de Istio, la API se especifica utilizando definiciones de recursos personalizados de Kubernetes
({{< gloss >}}CRDs{{</ gloss >}}), que puede configurar
utilizando YAML, como verá en los ejemplos.

El resto de esta guía examina cada uno de los recursos de la API de gestión de tráfico
y lo que puede hacer con ellos. Estos recursos son:

- [Virtual services](#virtual-services)
- [Destination rules](#destination-rules)
- [Gateways](#gateways)
- [Service entries](#service-entries)
- [Sidecars](#sidecars)

Esta guía también ofrece una descripción general de algunas de las
[features de resiliencia y pruebas de red](#network-resilience-and-testing) que
están integradas en los recursos de la API.

## Virtual services {#virtual-services}

Los [Virtual services](/es/docs/reference/config/networking/virtual-service/#VirtualService),
junto con las [reglas de destino](#destination-rules), son los bloques de construcción clave de la funcionalidad de enrutamiento de tráfico de Istio.
Un virtual service le permite configurar cómo se enrutan las solicitudes a un service dentro de una service mesh de Istio,
basándose en la conectividad y el descubrimiento básicos proporcionados por Istio y su plataforma. Cada virtual
service consta de un conjunto de reglas de enrutamiento que se evalúan en orden, lo que permite
a Istio hacer coincidir cada solicitud dada al virtual service con un destino real específico dentro de la mesh.
Su mesh puede requerir múltiples virtual services o ninguno, dependiendo de su caso de uso.

### ¿Por qué usar virtual services? {#why-use-virtual-services}

Los virtual services desempeñan un papel clave para hacer que la gestión de tráfico de Istio sea flexible
y potente. Lo hacen desacoplando fuertemente el lugar donde los clientes envían sus
solicitudes de los workloads de destino que realmente las implementan. Los virtual services también
proporcionan una forma rica de especificar diferentes reglas de enrutamiento de tráfico
para enviar tráfico a esos workloads.

¿Por qué es tan útil? Sin virtual services, Envoy distribuye
el tráfico utilizando el balanceo de carga de menos solicitudes entre todas las instancias de service, como
se describe en la introducción. Puede mejorar este comportamiento con lo que sabe
sobre los workloads. Por ejemplo, algunos podrían representar una versión diferente. Esto
puede ser útil en las pruebas A/B, donde es posible que desee configurar rutas de tráfico
basadas en porcentajes entre diferentes versiones de service, o para dirigir
el tráfico de sus usuarios internos a un conjunto particular de instancias.

Con un virtual service, puede especificar el comportamiento del tráfico para uno o más hostnames.
Utiliza reglas de enrutamiento en el virtual service que le indican a Envoy cómo enviar el
tráfico del virtual service a los destinos apropiados. Los destinos de ruta pueden
ser diferentes versiones del mismo service o services completamente diferentes.

Un caso de uso típico es enviar tráfico a diferentes versiones de un service,
especificadas como subconjuntos de service. Los clientes envían solicitudes al host del virtual service como si
fuera una única entidad, y Envoy luego enruta el tráfico a las diferentes
versiones según las reglas del virtual service: por ejemplo, "el 20% de las llamadas van a
la nueva versión" o "las llamadas de estos usuarios van a la versión 2". Esto le permite,
por ejemplo, crear un despliegue canary donde aumenta gradualmente el
porcentaje de tráfico que se envía a una nueva versión de service. El enrutamiento de tráfico
está completamente separado del despliegue de la instancia, lo que significa que el número de
instancias que implementan la nueva versión de service puede escalar hacia arriba y hacia abajo según
la carga de tráfico sin referirse en absoluto al enrutamiento de tráfico. Por el contrario, las plataformas
de orquestación de contenedores como Kubernetes solo admiten la distribución de tráfico basada
en el escalado de instancias, lo que rápidamente se vuelve complejo. Puede leer más sobre cómo
los virtual services ayudan con los despliegues canary en [Despliegues Canary usando Istio](/blog/2017/0.1-canary/).

Los virtual services también le permiten:

-   Dirigir múltiples applications de services a través de un único virtual service. Si
    su mesh utiliza Kubernetes, por ejemplo, puede configurar un virtual service
    para manejar todos los services en un namespace específico. Mapear un único
    virtual service a múltiples services "reales" es particularmente útil para
    facilitar la transformación de una aplicación monolítica en un service compuesto
    por microservicios distintos sin requerir que los consumidores del service
    se adapten a la transición. Sus reglas de enrutamiento pueden especificar "las llamadas a estas URIs de
    `monolith.com` van al `microservicio A`", y así sucesivamente. Puede ver cómo funciona esto
    en [uno de nuestros ejemplos a continuación](#more-about-routing-rules).
-   Configurar reglas de tráfico en combinación con
    [gateways](/es/docs/concepts/traffic-management/#gateways) para controlar el tráfico de entrada
    y salida.

En algunos casos, también necesita configurar reglas de destino para usar estas
features, ya que aquí es donde especifica sus subconjuntos de service. Especificar
subconjuntos de service y otras políticas específicas de destino en un objeto separado
le permite reutilizarlos limpiamente entre virtual services. Puede encontrar más
información sobre las reglas de destino en la siguiente sección.

### Ejemplo de virtual service {#virtual-service-example}

El siguiente virtual service enruta
solicitudes a diferentes versiones de un service dependiendo de si la solicitud
proviene de un usuario en particular.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v3
{{< /text >}}

#### El campo hosts {#the-hosts-field}

El campo `hosts` enumera los hosts del virtual service, es decir, el destino o destinos
accesibles por el usuario a los que se aplican estas reglas de enrutamiento. Esta es la
dirección o direcciones que el cliente utiliza al enviar solicitudes al service.

{{< text yaml >}}
hosts:
- reviews
{{< /text >}}

El hostname del virtual service puede ser una dirección IP, un nombre DNS o, dependiendo de
la plataforma, un nombre corto (como un nombre corto de service de Kubernetes) que se resuelve,
implícita o explícitamente, en un nombre de dominio completamente calificado (FQDN). También puede
utilizar prefijos comodín ("*"), lo que le permite crear un único conjunto de reglas de enrutamiento para
todos los services coincidentes. Los hosts del virtual service no tienen que formar parte del
service registry de Istio, son simplemente destinos virtuales. Esto le permite modelar
el tráfico para hosts virtuales que no tienen entradas enrutables dentro de la mesh.

#### Reglas de enrutamiento {#routing-rules}

La sección `http` contiene las reglas de enrutamiento del virtual service, que describen
las condiciones de coincidencia y las acciones para enrutar el tráfico HTTP/1.1, HTTP2 y gRPC enviado
a los destinos especificados en el campo hosts (también puede usar las secciones `tcp` y
`tls` para configurar reglas de enrutamiento para
tráfico [TCP](/es/docs/reference/config/networking/virtual-service/#TCPRoute) y
[TLS](/es/docs/reference/config/networking/virtual-service/#TLSRoute) no terminado).
Una regla de enrutamiento consta del destino al que desea que vaya el tráfico y cero o más condiciones de coincidencia, según su caso de uso.

##### Condición de coincidencia {#match-condition}

La primera regla de enrutamiento del ejemplo tiene una condición y, por lo tanto, comienza con el
campo `match`. En este caso, desea que este enrutamiento se aplique a todas las solicitudes del
usuario "jason", por lo que utiliza los campos `headers`, `end-user` y `exact` para seleccionar
las solicitudes apropiadas.

{{< text yaml >}}
- match:
   - headers:
       end-user:
         exact: jason
{{< /text >}}

##### Destino {#destination}

El campo `destination` de la sección de ruta especifica el destino real para
el tráfico que coincide con esta condición. A diferencia de los hosts del virtual service,
el host de destino debe ser un destino real que exista en el service registry de Istio
o Envoy no sabrá a dónde enviar el tráfico. Puede ser un service de malla
con proxies o un service no de mesh agregado mediante una entrada de service. En este
caso, nos estamos ejecutando en Kubernetes y el nombre de host es un nombre de service de Kubernetes:

{{< text yaml >}}
route:
- destination:
    host: reviews
    subset: v2
{{< /text >}}

Observe que en este y en los otros ejemplos de esta página, utilizamos un nombre corto de Kubernetes para los
hosts de destino para simplificar. Cuando se evalúa esta regla, Istio agrega un sufijo de dominio basado
en el namespace del virtual service que contiene la regla de enrutamiento para obtener
el nombre de dominio completamente calificado para el host. El uso de nombres cortos en nuestros ejemplos
también significa que puede copiarlos y probarlos en cualquier namespace que desee.

{{< warning >}}
El uso de nombres cortos como este solo funciona si los
hosts de destino y el virtual service están realmente en el mismo namespace de Kubernetes.
Debido a que el uso del nombre corto de Kubernetes puede dar lugar a
configuraciones erróneas, le recomendamos que especifique nombres de host completamente calificados en
entornos de producción.
{{< /warning >}}

La sección de destino también especifica a qué subconjunto de este service de Kubernetes
desea que vayan las solicitudes que coinciden con las condiciones de esta regla, en este caso el
subconjunto llamado v2. Verá cómo se define un subconjunto de service en la sección sobre
[reglas de destino](#destination-rules) a continuación.

#### Precedencia de las reglas de enrutamiento {#routing-rule-precedence}

Las reglas de enrutamiento se **evalúan en orden secuencial de arriba a abajo**, siendo la
primera regla en la definición del virtual service la que tiene mayor prioridad. En
este caso, desea que cualquier cosa que no coincida con la primera regla de enrutamiento vaya a un
destino predeterminado, especificado en la segunda regla. Debido a esto, la segunda
regla no tiene condiciones de coincidencia y simplemente dirige el tráfico al subconjunto v3.

{{< text yaml >}}
- route:
  - destination:
      host: reviews
      subset: v3
{{< /text >}}

Recomendamos proporcionar una regla predeterminada "sin condición" o basada en peso (descrita
a continuación) como la última regla en cada virtual service para asegurar que el tráfico
al virtual service siempre tenga al menos una ruta coincidente.

### Más sobre las reglas de enrutamiento {#more-about-routing-rules}

Como vio anteriormente, las reglas de enrutamiento son una herramienta poderosa para enrutar subconjuntos
particulares de tráfico a destinos particulares. Puede establecer condiciones de coincidencia en
puertos de tráfico, campos de cabecera, URIs y más. Por ejemplo, este virtual service
permite a los usuarios enviar tráfico a dos services separados, ratings y reviews, como si
fueran parte de un virtual service más grande en `http://bookinfo.com/.` Las
reglas del virtual service coinciden con el tráfico basándose en las URIs de solicitud y dirigen las solicitudes al
service apropiado.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
    - bookinfo.com
  http:
  - match:
    - uri:
        prefix: /reviews
    route:
    - destination:
        host: reviews
  - match:
    - uri:
        prefix: /ratings
    route:
    - destination:
        host: ratings
{{< /text >}}

Para algunas condiciones de coincidencia, también puede optar por seleccionarlas utilizando el valor exacto,
un prefijo o una expresión regular.

Puede agregar múltiples condiciones de coincidencia al mismo bloque `match` para aplicar un AND a sus
condiciones, o agregar múltiples bloques `match` a la misma regla para aplicar un OR a sus condiciones.
También puede tener múltiples reglas de enrutamiento para cualquier virtual service dado. Esto
le permite hacer que sus condiciones de enrutamiento sean tan complejas o simples como desee dentro de un
único virtual service. Una lista completa de los campos de condición de coincidencia y sus posibles
valores se puede encontrar en la
[referencia de `HTTPMatchRequest`](/es/docs/reference/config/networking/virtual-service/#HTTPMatchRequest).

Además de usar condiciones de coincidencia, puede distribuir el tráfico
por porcentaje de "peso". Esto es útil para pruebas A/B y despliegues canary:

{{< text yaml >}}
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 75
    - destination:
        host: reviews
        subset: v2
      weight: 25
{{< /text >}}

También puede usar reglas de enrutamiento para realizar algunas acciones sobre el tráfico, por
ejemplo:

-   Agregar o eliminar cabeceras.
-   Reescribir la URL.
-   Establecer una [política de reintentos](#retries) para las llamadas a este destino.

Para obtener más información sobre las acciones disponibles, consulte la
[referencia de `HTTPRoute`](/es/docs/reference/config/networking/virtual-service/#HTTPRoute).

## Reglas de destino {#destination-rules}

Junto con los [virtual services](#virtual-services),
las [reglas de destino](/es/docs/reference/config/networking/destination-rule/#DestinationRule)
son una parte clave de la funcionalidad de enrutamiento de tráfico de Istio. Puede pensar en
los virtual services como la forma en que enruta su tráfico **a** un destino dado, y
luego usa las reglas de destino para configurar lo que sucede con el tráfico **para** ese
destino. Las reglas de destino se aplican después de que se evalúan las reglas de enrutamiento del virtual service,
por lo que se aplican al destino "real" del tráfico.

En particular, utiliza las reglas de destino para especificar subconjuntos de service con nombre, como
agrupar todas las instancias de un service dado por versión. Luego puede usar estos
subconjuntos de service en las reglas de enrutamiento de los virtual services para controlar el
tráfico a diferentes instancias de sus services.

Las reglas de destino también le permiten personalizar las políticas de tráfico de Envoy al llamar
al service de destino completo o a un subconjunto de service particular, como su
modelo de balanceo de carga preferido, el modo de seguridad TLS o la configuración del disyuntor.
Puede ver una lista completa de las opciones de reglas de destino en la
[referencia de reglas de destino](/es/docs/reference/config/networking/destination-rule/).

### Opciones de balanceo de carga

Por defecto, Istio utiliza una política de balanceo de carga de menos solicitudes, donde las solicitudes
se distribuyen entre las instancias con el menor número de solicitudes. Istio también admite los
siguientes modelos, que puede especificar en las reglas de destino para las solicitudes a un
service o subconjunto de service particular.

-   Aleatorio: las solicitudes se reenvían aleatoriamente a las instancias del pool.
-   Ponderado: las solicitudes se reenvían a las instancias del pool según un
    porcentaje específico.
-   Round robin: las solicitudes se reenvían a cada instancia en secuencia.
-   Hash consistente: proporciona afinidad de sesión suave basada en cabeceras HTTP, cookies u otras propiedades.
-   Hash de anillo: implementa el hash consistente a los hosts upstream utilizando el [algoritmo Ketama](https://www.metabrew.com/article/libketama-consistent-hashing-algo-memcached-clients).
-   Maglev: implementa el hash consistente a los hosts upstream como se describe en el [documento de Maglev](https://research.google/pubs/maglev-a-fast-and-reliable-software-network-load-balancer/).

Consulte la
[documentación de balanceo de carga de Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/load_balancers)
para obtener más información sobre cada opción.

### Ejemplo de regla de destino {#destination-rule-example}

El siguiente ejemplo de regla de destino configura tres subconjuntos diferentes para
el service de destino `my-svc`, con diferentes políticas de balanceo de carga:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: my-destination-rule
spec:
  host: my-svc
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
  - name: v3
    labels:
      version: v3
{{< /text >}}

Cada subconjunto se define en función de una o más `labels`, que en Kubernetes son
pares clave/valor que se adjuntan a objetos como Pods. Estas etiquetas se
aplican en el despliegue del service de Kubernetes como `metadata` para identificar
diferentes versiones.

Además de definir subconjuntos, esta regla de destino tiene una política de tráfico predeterminada
para todos los subconjuntos en este destino y una política específica del subconjunto que
la anula solo para ese subconjunto. La política predeterminada, definida encima del campo `subsets`,
establece un balanceador de carga aleatorio simple para los subconjuntos `v1` y `v3`. En la
política `v2`, se especifica un balanceador de carga round-robin en el campo correspondiente
del subconjunto.

## Gateways {#gateways}

Utiliza un [gateway](/es/docs/reference/config/networking/gateway/#Gateway) para
gestionar el tráfico de entrada y salida de su malla, lo que le permite especificar qué
tráfico desea que entre o salga de la mesh. Las configuraciones de gateway se aplican
a proxies Envoy independientes que se ejecutan en el borde de la mesh, en lugar
de proxies Envoy sidecar que se ejecutan junto a sus workloads de service.

A diferencia de otros mecanismos para controlar el tráfico que ingresa a sus sistemas, como
las API de Ingress de Kubernetes, los gateways de Istio le permiten usar todo el poder y
la flexibilidad del enrutamiento de tráfico de Istio. Puede hacer esto porque el recurso Gateway de Istio
simplemente le permite configurar propiedades de balanceo de carga de capa 4-6, como
puertos a exponer, configuraciones TLS, etc. Luego, en lugar de agregar
enrutamiento de tráfico a nivel de aplicación (L7) al mismo recurso de API, vincula un
virtual service de Istio regular al gateway. Esto le permite
básicamente gestionar el tráfico del gateway como cualquier otro tráfico del data plane en un mesh de Istio.

Los gateways se utilizan principalmente para gestionar el tráfico de entrada, pero también puede
configurar egress gateways. Un egress gateway le permite configurar un nodo de salida dedicado
para el tráfico que sale de la mesh, lo que le permite limitar qué services pueden o
deben acceder a redes externas, o para habilitar
el [control seguro del tráfico de salida](/blog/2019/egress-traffic-control-in-istio-part-1/)
para agregar seguridad a su malla, por ejemplo. También puede usar un gateway para
configurar un proxy puramente interno.

Istio proporciona algunos despliegues de proxy de gateway preconfigurados
(`istio-ingressgateway` e `istio-egressgateway`) que puede usar; ambos se
despliegan si usa nuestra [instalación de demostración](/es/docs/setup/getting-started/),
mientras que solo el ingress gateway se despliega con nuestro
[perfil predeterminado](/es/docs/setup/additional-setup/config-profiles/).
Puede aplicar sus propias configuraciones de gateway a estos despliegues o desplegar y
configurar sus propios proxies de gateway.

### Ejemplo de gateway {#gateway-example}

El siguiente ejemplo muestra una posible configuración de gateway para el tráfico HTTPS
de entrada externo:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: ext-host-gwy
spec:
  selector:
    app: my-gateway-controller
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - ext-host.example.com
    tls:
      mode: SIMPLE
      credentialName: ext-host-cert
{{< /text >}}

Esta configuración de gateway permite el tráfico HTTPS de `ext-host.example.com` en la mesh en
el puerto 443, pero no especifica ningún enrutamiento para el tráfico.

Para especificar el enrutamiento y para que el gateway funcione según lo previsto, también debe vincular
el gateway a un virtual service. Esto se hace utilizando el campo `gateways` del virtual service,
como se muestra en el siguiente ejemplo:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: virtual-svc
spec:
  hosts:
  - ext-host.example.com
  gateways:
  - ext-host-gwy
{{< /text >}}

Luego puede configurar el virtual service con reglas de enrutamiento para el tráfico externo.

## Entradas de service {#service-entries}

Utiliza una
[entrada de service](/es/docs/reference/config/networking/service-entry/#ServiceEntry) para agregar
una entrada al service registry que Istio mantiene internamente. Después de agregar
la entrada de service, los proxies Envoy pueden enviar tráfico al service como si
fuera un service en su malla. La configuración de entradas de service le permite gestionar
el tráfico para services que se ejecutan fuera de la mesh, incluyendo las siguientes tareas:

-   Redirigir y reenviar tráfico para destinos externos, como API
    consumidas de la web, o tráfico a services en infraestructura heredada.
-   Definir políticas de [reintentos](#retries), [tiempos de espera](#timeouts) e
    [inyección de fallos](#fault-injection) para destinos externos.
-   Ejecutar un service de mesh en una Máquina Virtual (VM) [agregando VMs a su malla](/es/docs/examples/virtual-machines/).

No necesita agregar una entrada de service para cada service externo que desee
que utilicen sus services de malla. Por defecto, Istio configura los proxies Envoy para
pasar las solicitudes a services desconocidos. Sin embargo, no puede usar las features de Istio
para controlar el tráfico a destinos que no están registrados en la mesh.

### Ejemplo de entrada de service {#service-entry-example}

El siguiente ejemplo de entrada de service externa a la mesh agrega la dependencia externa
`ext-svc.example.com` al service registry de Istio:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: svc-entry
spec:
  hosts:
  - ext-svc.example.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  location: MESH_EXTERNAL
  resolution: DNS
{{< /text >}}

Usted especifica el recurso externo utilizando el campo `hosts`. Puede calificarlo
completamente o usar un nombre de dominio con prefijo comodín.

Puede configurar virtual services y reglas de destino para controlar el tráfico a una
entrada de service de una manera más granular, de la misma manera que configura el tráfico para
cualquier otro service en la mesh. Por ejemplo, la siguiente regla de destino
ajusta el tiempo de espera de conexión TCP para las solicitudes al service externo
`ext-svc.example.com` que configuramos utilizando la entrada de service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: ext-res-dr
spec:
  host: ext-svc.example.com
  trafficPolicy:
    connectionPool:
      tcp:
        connectTimeout: 1s
{{< /text >}}

Consulte la
[referencia de entrada de service](/es/docs/reference/config/networking/service-entry)
para obtener más opciones de configuración posibles.

## Sidecars {#sidecars}

Por defecto, Istio configura cada proxy Envoy para aceptar tráfico en todos los
puertos de su workload asociado, y para alcanzar cada workload en la mesh al
reenviar tráfico. Puede usar una configuración de [sidecar](/es/docs/reference/config/networking/sidecar/#Sidecar) para hacer lo siguiente:

-   Ajustar el conjunto de puertos y protocolos que acepta un proxy Envoy.
-   Limitar el conjunto de services a los que puede llegar el proxy Envoy.

Es posible que desee limitar la accesibilidad del sidecar de esta manera en applications más grandes,
donde tener cada proxy configurado para alcanzar cada otro service en la mesh puede
potencialmente afectar el rendimiento de la mesh debido al alto uso de memoria.

Puede especificar que desea que una configuración de sidecar se aplique a todos los workloads
en un namespace particular, o elegir workloads específicos usando un
`workloadSelector`. Por ejemplo, la siguiente configuración de sidecar configura
todos los services en el namespace `bookinfo` para que solo lleguen a los services que se ejecutan en el
mismo namespace y al control plane de Istio (necesario para las features de
salida y telemetría de Istio):

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata:
  name: default
  namespace: bookinfo
spec:
  egress:
  - hosts:
    - "./*"
    - "istio-system/*"
{{< /text >}}

Consulte la [referencia de Sidecar](/es/docs/reference/config/networking/sidecar/)
para obtener más detalles.

## Resiliencia y pruebas de red {#network-resilience-and-testing}

Además de ayudarle a dirigir el tráfico por su malla, Istio proporciona features opcionales
de recuperación de fallos e inyección de fallos que puede configurar dinámicamente
en tiempo de ejecución. El uso de estas features ayuda a que sus applications funcionen de forma fiable,
garantizando que la service mesh pueda tolerar nodos fallidos y evitando
que los fallos localizados se propaguen a otros nodos.

### Tiempos de espera {#timeouts}

Un tiempo de espera es la cantidad de tiempo que un proxy Envoy debe esperar respuestas de
un service dado, asegurando que los services no se queden esperando respuestas
indefinidamente y que las llamadas tengan éxito o fallen dentro de un plazo predecible. El
tiempo de espera de Envoy para las solicitudes HTTP está deshabilitado en Istio por defecto.

Para algunas applications y services, el tiempo de espera predeterminado de Istio podría no ser
apropiado. Por ejemplo, un tiempo de espera demasiado largo podría resultar en una latencia excesiva
al esperar respuestas de services fallidos, mientras que un tiempo de espera demasiado corto podría
resultar en que las llamadas fallen innecesariamente mientras esperan que una operación
que involucre múltiples services regrese. Para encontrar y usar su configuración de tiempo de espera óptima,
Istio le permite ajustar fácilmente los tiempos de espera dinámicamente por service
utilizando [virtual services](#virtual-services) sin tener que editar el código de su service.
Aquí hay un virtual service que especifica un tiempo de espera de 10 segundos para
las llamadas al subconjunto v1 del service ratings:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
    timeout: 10s
{{< /text >}}

### Reintentos {#retries}

Una configuración de reintento especifica el número máximo de veces que un proxy Envoy intenta
conectarse a un service si la llamada inicial falla. Los reintentos pueden mejorar la
disponibilidad del service y el rendimiento de la aplicación asegurando que las llamadas no fallen
permanentemente debido a problemas transitorios como un service o red temporalmente sobrecargados.
El intervalo entre reintentos (25ms+) es variable y
determinado automáticamente por Istio, evitando que el service llamado se
sobrecargue con solicitudes. El comportamiento de reintento predeterminado para las solicitudes HTTP es
reintentar dos veces antes de devolver el error.

Al igual que los tiempos de espera, el comportamiento de reintento predeterminado de Istio podría no adaptarse a las necesidades de su aplicación
en términos de latencia (demasiados reintentos a un service fallido pueden ralentizar las cosas)
o disponibilidad. También, al igual que los tiempos de espera, puede ajustar su configuración de reintento
por service en [virtual services](#virtual-services) sin tener que
tocar el código de su service. También puede refinar aún más su comportamiento de reintento
agregando tiempos de espera por reintento, especificando la cantidad de tiempo que desea esperar para
cada intento de reintento para conectarse con éxito al service. El siguiente ejemplo
configura un máximo de 3 reintentos para conectarse a este subconjunto de service después de un
fallo de llamada inicial, cada uno con un tiempo de espera de 2 segundos.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
    retries:
      attempts: 3
      perTryTimeout: 2s
{{< /text >}}

### Disyuntores {#circuit-breakers}

Los disyuntores son otro mecanismo útil que Istio proporciona para crear
applications basadas en microservicios resilientes. En un disyuntor, se establecen límites
para las llamadas a hosts individuales dentro de un service, como el número de conexiones concurrentes
o cuántas veces han fallado las llamadas a este host. Una vez que se alcanza ese límite,
el disyuntor se "dispara" y detiene más conexiones a ese host. El uso de un patrón de disyuntor
permite un fallo rápido en lugar de que los clientes intenten conectarse a un host sobrecargado o fallido.

Como el interruptor de circuito se aplica a destinos de mesh "reales" en un pool de balanceo de carga,
se configuran umbrales de disyuntor en
[reglas de destino](#destination-rules), con la configuración aplicándose a cada
host individual en el service. El siguiente ejemplo limita el número de
conexiones concurrentes para los workloads del service `reviews` del subconjunto v1 a
100:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
{{< /text >}}

Puede encontrar más información sobre la creación de disyuntores en
[interruptor de circuito](/es/docs/tasks/traffic-management/circuit-breaking/).

### Inyección de fallos {#fault-injection}

Después de haber configurado su red, incluidas las políticas de recuperación de fallos, puede
utilizar los mecanismos de inyección de fallos de Istio para probar la capacidad de recuperación de fallos
de su aplicación en su conjunto. La inyección de fallos es un método de prueba que
introduce errores en un sistema para asegurar que puede soportar y recuperarse de
condiciones de error. El uso de la inyección de fallos puede ser particularmente útil para asegurar
que sus políticas de recuperación de fallos no sean incompatibles o demasiado restrictivas,
lo que podría resultar en que services críticos no estén disponibles.

{{< warning >}}
Actualmente, la configuración de inyección de fallos no se puede combinar con la configuración de reintentos o tiempos de espera
en el mismo virtual service; consulte
[Problemas de Gestión de Tráfico](/es/docs/ops/common-problems/network-issues/#virtual-service-with-fault-injection-and-retrytimeout-policies-not-working-as-expected).
{{< /warning >}}

A diferencia de otros mecanismos para introducir errores, como retrasar paquetes o
matar pods en la capa de red, Istio le permite inyectar fallos en la
capa de aplicación. Esto le permite inyectar fallos más relevantes, como códigos de error HTTP,
para obtener resultados más relevantes.

Puede inyectar dos tipos de fallos, ambos configurados utilizando un
[virtual service](#virtual-services):

-   Retrasos: Los retrasos son fallos de tiempo. Imitan el aumento de la latencia de la red o
    un service upstream sobrecargado.
-   Abortos: Los abortos son fallos de bloqueo. Imitan fallos en services upstream.
    Los abortos suelen manifestarse en forma de códigos de error HTTP o fallos de conexión TCP.

Por ejemplo, este virtual service introduce un retraso de 5 segundos para 1 de cada 1000
solicitudes al service `ratings`.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

Para obtener instrucciones detalladas sobre cómo configurar retrasos y abortos, consulte
[Inyección de Fallos](/es/docs/tasks/traffic-management/fault-injection/).

### Trabajar con sus applications {#working-with-your-applications}

Las features de recuperación de fallos de Istio son completamente transparentes para la
aplicación. Las applications no saben si un proxy sidecar de Envoy está manejando
fallos para un service llamado antes de devolver una respuesta. Esto significa que
si también está configurando políticas de recuperación de fallos en el código de su aplicación,
debe tener en cuenta que ambas funcionan de forma independiente y, por lo tanto, podrían
conflictir. Por ejemplo, suponga que puede tener dos tiempos de espera, uno configurado en
un virtual service y otro en la aplicación. La aplicación establece un tiempo de espera de 2
segundos para una llamada API a un service. Sin embargo, usted configuró un tiempo de espera de 3
segundos con 1 reintento en su virtual service. En este caso, el tiempo de espera de la
aplicación se activa primero, por lo que el tiempo de espera y el intento de reintento de Envoy
no tienen ningún efecto.

Si bien las features de recuperación de fallos de Istio mejoran la fiabilidad y
disponibilidad de los services en la mesh, las applications deben manejar el fallo
o los errores y tomar las acciones de respaldo apropiadas. Por ejemplo, cuando todas
las instancias en un pool de balanceo de carga han fallado, Envoy devuelve un código `HTTP 503`.
La aplicación debe implementar cualquier lógica de respaldo necesaria para manejar el
código de error `HTTP 503`.
