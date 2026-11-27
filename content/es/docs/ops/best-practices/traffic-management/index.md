---
title: Mejores prácticas de gestión de tráfico
description: Mejores prácticas de configuración para evitar problemas de red o de gestión de tráfico.
force_inline_toc: true
weight: 20
aliases:
  - /help/ops/traffic-management/deploy-guidelines
  - /help/ops/deploy-guidelines
  - /docs/ops/traffic-management/deploy-guidelines
owner: istio/wg-networking-maintainers
test: n/a
---

Esta sección ofrece pautas específicas de despliegue o configuración para evitar problemas de red o de gestión de tráfico.

## Define rutas por defecto para los servicios

Aunque el comportamiento por defecto de Istio envía cómodamente el tráfico de cualquier
origen a todas las versiones de un servicio de destino sin necesidad de definir ninguna regla,
crear un `VirtualService` con una ruta por defecto para cada servicio,
desde el principio, se considera en general una buena práctica en Istio.

Aunque al principio solo tengas una versión de un servicio, en cuanto decidas
desplegar una segunda versión necesitas tener una regla de enrutamiento configurada **antes**
de que se inicie la nueva versión, para evitar que empiece a recibir tráfico de inmediato
de forma descontrolada.

Otro posible problema al depender del enrutamiento round-robin por defecto de Istio se
debe a una sutileza del algoritmo de evaluación de destination rules de Istio.
Al enrutar una solicitud, Envoy evalúa primero las reglas de enrutamiento de los virtual services
para determinar si se está enrutando a un subconjunto concreto.
Solo en ese caso activará las políticas de destination rule correspondientes a ese subconjunto.
En consecuencia, Istio solo aplica las políticas que defines para subconjuntos concretos si
has enrutado el tráfico **explícitamente** al subconjunto correspondiente.

Por ejemplo, considera la siguiente destination rule como la única configuración definida para el
servicio *reviews*, es decir, no hay reglas de enrutamiento en una definición de `VirtualService` correspondiente:

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

Aunque el enrutamiento round-robin por defecto de Istio llame en ocasiones a instancias "v1",
o incluso siempre si "v1" es la única versión en ejecución, la política de tráfico anterior
nunca se activará.

Puedes corregir el ejemplo anterior de dos formas. Puedes subir la
política de tráfico un nivel en la `DestinationRule` para que se aplique a cualquier versión:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
  subsets:
  - name: v1
    labels:
      version: v1
{{< /text >}}

O, mejor aún, define una regla de enrutamiento adecuada para el servicio en la definición del `VirtualService`.
Por ejemplo, añade una regla de enrutamiento sencilla para "reviews:v1":

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
{{< /text >}}

## Controla el uso compartido de la configuración entre namespaces {#cross-namespace-configuration}

Puedes definir virtual services, destination rules o service entries
en un namespace y reutilizarlos después en otros namespaces, siempre que se exporten
a esos namespaces.
Por defecto, Istio exporta todos los recursos de gestión de tráfico a todos los namespaces,
pero puedes sobrescribir la visibilidad con el campo `exportTo`.
Por ejemplo, el siguiente virtual service solo puede afectar a las solicitudes de workloads del mismo namespace:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myservice
spec:
  hosts:
  - myservice.com
  exportTo:
  - "."
  http:
  - route:
    - destination:
        host: myservice
{{< /text >}}

{{< tip >}}
De forma similar, puedes controlar la visibilidad de un `Service` de Kubernetes con la anotación `networking.istio.io/exportTo`.
{{< /tip >}}

Establecer la visibilidad de las destination rules en un namespace concreto no
garantiza que la regla se use. Exportar una destination rule a otros namespaces te permite usarla
en esos namespaces, pero para que se aplique realmente durante una solicitud, el namespace también debe estar
en la ruta de búsqueda de destination rules:

1. namespace del cliente
1. namespace del servicio
1. el namespace configurado en `meshconfig.rootNamespace` (`istio-system` por defecto)

Por ejemplo, considera la siguiente destination rule:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: myservice
spec:
  host: myservice.default.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
{{< /text >}}

Supongamos que creas esta destination rule en el namespace `ns1`.

Si envías una solicitud al servicio `myservice` desde un cliente en `ns1`, la destination rule
se aplicaría, porque está en el primer namespace de la ruta de búsqueda, es decir,
en el namespace del cliente.

Si ahora envías la solicitud desde otro namespace, por ejemplo `ns2`,
el cliente ya no está en el mismo namespace que la destination rule, `ns1`.
Como el servicio correspondiente, `myservice.default.svc.cluster.local`, tampoco está en `ns1`,
sino en el namespace `default`, la destination rule tampoco se encontrará en
el segundo namespace de la ruta de búsqueda, el namespace del servicio.

Aunque el servicio `myservice` se exporte a todos los namespaces y, por tanto, sea visible
en `ns2`, y aunque la destination rule también se exporte a todos los namespaces, incluido `ns2`,
no se aplicará durante la solicitud desde `ns2`, porque no está en ninguno
de los namespaces de la ruta de búsqueda.

Puedes evitar este problema creando la destination rule en el mismo namespace que
el servicio correspondiente, `default` en este ejemplo. Así se aplicaría a las solicitudes
de clientes de cualquier namespace.
También puedes mover la destination rule al namespace `istio-system`, el tercer namespace de
la ruta de búsqueda, aunque no se recomienda salvo que la destination rule sea realmente una configuración
global aplicable a todos los namespaces, y requeriría permisos de administrador.

Istio usa esta ruta de búsqueda restringida de destination rules por dos motivos:

1. Evitar que se definan destination rules que puedan sobrescribir el comportamiento de servicios
   en namespaces que no tienen ninguna relación con ellas.
1. Tener un orden de búsqueda claro en caso de que haya más de una destination rule para
   el mismo host.

## Divide los virtual services y las destination rules grandes en varios recursos {#split-virtual-services}

En situaciones en las que no resulta práctico definir el conjunto completo de reglas de enrutamiento o políticas de un
host concreto en un único recurso `VirtualService` o `DestinationRule`, puede ser preferible especificar
la configuración del host de forma incremental en varios recursos.
El control plane fusionará esas destination rules
y fusionará esos virtual services si están vinculados a un gateway.

Considera el caso de un `VirtualService` vinculado a un ingress gateway que expone un host de aplicación que usa
delegación basada en rutas hacia varios servicios de implementación, algo así:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service1
    route:
    - destination:
        host: service1.default.svc.cluster.local
  - match:
    - uri:
        prefix: /service2
    route:
    - destination:
        host: service2.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

La desventaja de este tipo de configuración es que cualquier otra configuración (p. ej., reglas de enrutamiento) de cualquiera de los
microservicios subyacentes también tendrá que incluirse en este único archivo de configuración, en lugar de
en recursos separados asociados a los equipos de cada servicio y, posiblemente, gestionados por ellos.
Consulta [Las reglas de enrutamiento no tienen efecto en las solicitudes del ingress gateway](/es/docs/ops/common-problems/network-issues/#route-rules-have-no-effect-on-ingress-gateway-requests)
para obtener más detalles.

Para evitar este problema, puede ser preferible dividir la configuración de `myapp.com` en varios
fragmentos de `VirtualService`, uno por cada servicio de backend. Por ejemplo:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myapp-service1
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service1
    route:
    - destination:
        host: service1.default.svc.cluster.local
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myapp-service2
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service2
    route:
    - destination:
        host: service2.default.svc.cluster.local
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myapp-...
{{< /text >}}

Cuando se aplica un segundo `VirtualService`, o cualquier otro posterior, para un host existente, `istiod` fusiona
las reglas de enrutamiento adicionales en la configuración existente del host. Sin embargo, esta funcionalidad
tiene varias salvedades que debes tener muy en cuenta al usarla.

1. Aunque se conserva el orden de evaluación de las reglas dentro de cada `VirtualService` de origen,
   el orden entre recursos está INDEFINIDO. Es decir, no hay un orden de evaluación garantizado
   para las reglas de los distintos fragmentos de configuración, así que el comportamiento solo será predecible si
   no hay reglas en conflicto ni dependencias de orden entre reglas de distintos fragmentos.
1. Solo debe haber una regla "catch-all" (es decir, una regla sin campo `match`) en los fragmentos.
   Todas esas reglas "catch-all" se moverán al final de la lista en la configuración fusionada, pero
   como capturan todas las solicitudes, la que se aplique primero sobrescribirá y deshabilitará en la práctica a todas las demás.
1. Un `VirtualService` solo se puede fragmentar de esta forma si está vinculado a un gateway.
   La fusión de hosts no se admite en los sidecars.

Una `DestinationRule` también se puede fragmentar, con una semántica de fusión y unas restricciones similares.

1. Solo debe haber una definición de cada subconjunto entre todas las destination rules del mismo host.
   Si hay más de una con el mismo nombre, se usa la primera definición y se descartan los duplicados posteriores.
   No se admite fusionar el contenido de los subconjuntos.
1. Solo debe haber una `trafficPolicy` de nivel superior para el mismo host.
   Cuando se definen políticas de tráfico de nivel superior en varias destination rules, se usa la primera que se procesa.
   Cualquier configuración posterior de `trafficPolicy` de nivel superior se descarta.
1. A diferencia de la fusión de virtual services, la fusión de destination rules funciona tanto en sidecars como en gateways.

## Evita errores 503 al reconfigurar las rutas de los servicios

Al configurar reglas de enrutamiento para dirigir el tráfico a versiones específicas (subconjuntos) de un servicio, debes asegurarte
de que los subconjuntos estén disponibles antes de usarlos en las rutas. De lo contrario, las llamadas al servicio pueden devolver
errores 503 durante un período de reconfiguración.

Crear tanto los `VirtualServices` como las `DestinationRules` que definen los subconjuntos correspondientes con una sola llamada a `kubectl`
(p. ej., `kubectl apply -f myVirtualServiceAndDestinationRule.yaml`) no es suficiente, porque los
recursos se propagan (desde el servidor de configuración, es decir, el servidor de API de Kubernetes) a las instancias de istiod con consistencia eventual. Si el
`VirtualService` que usa los subconjuntos llega antes que la `DestinationRule` en la que se definen, la configuración de Envoy generada por istiod haría referencia a pools upstream inexistentes. Esto provoca errores HTTP 503 hasta que todos los objetos de configuración están disponibles para istiod.

Para asegurarte de que los servicios no tengan ningún tiempo de inactividad al configurar rutas con subconjuntos, sigue un proceso "make-before-break" como el que se describe a continuación:

* Al añadir subconjuntos nuevos:

    1. Actualiza primero las `DestinationRules` para añadir el nuevo subconjunto, antes de actualizar los `VirtualServices` que lo usen. Aplica la regla con `kubectl` o con cualquier herramienta específica de la plataforma.

    1. Espera unos segundos a que la configuración de la `DestinationRule` se propague a los sidecars de Envoy

    1. Actualiza el `VirtualService` para que haga referencia a los subconjuntos recién añadidos.

* Al eliminar subconjuntos:

    1. Actualiza los `VirtualServices` para eliminar cualquier referencia a un subconjunto antes de eliminarlo de una `DestinationRule`.

    1. Espera unos segundos a que la configuración del `VirtualService` se propague a los sidecars de Envoy.

    1. Actualiza la `DestinationRule` para eliminar los subconjuntos que ya no se usan.
