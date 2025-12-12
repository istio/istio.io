---
title: "El Proxy Waypoint de Istio Ambient simplificado"
description: Presentando el nuevo proxy waypoint orientado a destino para simplicidad y escalabilidad.
publishdate: 2023-03-31
attribution: "Lin Sun (Solo.io), John Howard (Google)"
keywords: [istio,ambient,waypoint]
---

Ambient divide la funcionalidad de Istio en dos capas distintas, una capa de superposición segura y una capa de procesamiento de Capa 7. El proxy waypoint es un componente opcional basado en Envoy
y maneja el procesamiento L7 para las cargas de trabajo que gestiona. Desde el [lanzamiento inicial de ambient](/blog/2022/introducing-ambient-mesh/) en 2022,
hemos realizado cambios significativos para simplificar la configuración, capacidad de depuración y escalabilidad del waypoint.

## Arquitectura de los proxies waypoint

Similar al sidecar, el proxy waypoint también está basado en Envoy y es configurado dinámicamente por Istio
para servir la configuración de sus aplicaciones. Lo que es único sobre el proxy waypoint es que se ejecuta ya sea
por namespace (por defecto) o por cuenta de servicio. Al ejecutarse fuera del pod de aplicación, un proxy waypoint
puede instalarse, actualizarse y escalar independientemente de la aplicación, así como reducir los costos operacionales.

{{< image width="100%"
    link="waypoint-architecture.png"
    caption="Arquitectura de Waypoint"
    >}}

Los proxies waypoint se despliegan declarativamente usando recursos Gateway de Kubernetes o el útil comando `istioctl`:

{{< text bash >}}
$ istioctl experimental waypoint generate
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: namespace
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
{{< /text >}}

Istiod monitoreará estos recursos y desplegará y gestionará el despliegue de waypoint correspondiente para los usuarios automáticamente.

## Cambiar configuración del proxy de origen al proxy de destino

En la arquitectura de sidecar existente, la mayoría de las políticas de modelado de tráfico (por ejemplo [enrutamiento de solicitudes](/docs/tasks/traffic-management/request-routing/) o [cambio de tráfico](/docs/tasks/traffic-management/traffic-shifting/) o [inyección de fallos](/docs/tasks/traffic-management/fault-injection/)) se implementan por el proxy de origen (cliente) mientras que la mayoría de las políticas de seguridad se implementan por el proxy de destino (servidor). Esto lleva a una serie de preocupaciones:

* Escalado - cada sidecar de origen necesita conocer información sobre cada otro destino en la malla. Este es un problema de escalado polinomial. Peor aún, si cambia alguna configuración de destino, necesitamos notificar a todos los sidecars a la vez.
* Depuración - debido a que la aplicación de políticas se divide entre los sidecars del cliente y servidor, puede ser difícil entender el comportamiento del sistema al solucionar problemas.
* Entornos mixtos - si tenemos sistemas donde no todos los clientes son parte de la malla, obtenemos un comportamiento inconsistente. Por ejemplo, un cliente fuera de la malla no respetaría una política de rollout canario, lo que llevaría a una distribución de tráfico inesperada.
* Propiedad y atribución - idealmente una política escrita en un namespace solo debería afectar el trabajo realizado por proxies ejecutándose en el mismo namespace. Sin embargo, en este modelo, está distribuida y aplicada por cada sidecar. Aunque Istio ha diseñado alrededor de esta restricción para hacer esto seguro, todavía no es óptimo.

En ambient, todas las políticas son aplicadas por el waypoint de destino. De muchas maneras, el waypoint actúa como un gateway hacia el namespace (alcance por defecto) o cuenta de servicio. Istio hace cumplir que todo el tráfico que entra en el namespace pase por el waypoint, que luego hace cumplir todas las políticas para ese namespace. Debido a esto, cada waypoint solo necesita conocer la configuración para su propio namespace.

El problema de escalabilidad, en particular, es una molestia para los usuarios que ejecutan en clústeres grandes. Si lo visualizamos, podemos ver cuán grande es la mejora de la nueva arquitectura.

Considere un despliegue simple, donde tenemos 2 namespaces, cada uno con 2 despliegues (codificados por colores). La configuración de Envoy (XDS) requerida para programar los sidecars se muestra como círculos:

{{< image width="70%"
    link="sidecar-config.png"
    caption="Cada sidecar tiene configuración sobre todos los otros sidecars"
    >}}

En el modelo sidecar, tenemos 4 cargas de trabajo, cada una con 4 conjuntos de configuración. Si cualquiera de esas configuraciones cambiara, todas necesitarían actualizarse. En total hay 16 configuraciones distribuidas.

En la arquitectura waypoint, sin embargo, la configuración se simplifica dramáticamente:

{{< image width="70%"
    link="waypoint-config.png"
    caption="Cada waypoint solo tiene configuración para su propio namespace"
    >}}

Aquí, vemos una historia muy diferente. Tenemos solo 2 proxies waypoint, ya que cada uno puede servir todo el namespace, y cada uno solo necesita configuración para su propio namespace. En total tenemos 25% de la cantidad de configuración enviada, incluso para un ejemplo simple.

Si escalamos cada namespace a 25 despliegues con 10 pods cada uno y cada despliegue de waypoint con 2 pods para alta disponibilidad, los números son aún más impresionantes - ¡la distribución de configuración de waypoint requiere solo el 0.8% de la distribución de configuración del sidecar, como ilustra la tabla a continuación!

|| Distribución de Config     |         Namespace 1              |       Namespace 2                |     Total     |
|| --------------------------- | -------------------------------- | -------------------------------- | ------------- |
|| Sidecars                    | 25 configuraciones * 250 sidecars | 25 configuraciones * 250 sidecars |    12500      |
|| Waypoints                   | 25 configuraciones * 2 waypoints  | 25 configuraciones * 2 waypoints  |     100       |
|| Waypoints / Sidecars        |              0.8%                |               0.8%               |      0.8%     |

Aunque usamos proxies waypoint con alcance de namespace para ilustrar la simplificación anterior, la simplificación es similar
cuando lo aplica a proxies waypoint de cuenta de servicio.

Esta configuración reducida significa menor uso de recursos (CPU, RAM y ancho de banda de red) tanto para el
plano de control como para el plano de datos. Aunque los usuarios de hoy pueden ver mejoras similares con un uso cuidadoso de
`exportTo` en sus recursos de red de Istio o de la API [Sidecar](/docs/reference/config/networking/sidecar/),
en modo ambient esto ya no es necesario, haciendo que el escalado sea muy sencillo.

## ¿Qué pasa si mi destino no tiene un proxy waypoint?

El diseño del modo ambient se centra en la suposición de que la mayoría de la configuración se implementa mejor por el productor del servicio, en lugar del consumidor del servicio. Sin embargo, esto no siempre es el caso - a veces necesitamos configurar gestión de tráfico para destinos que no controlamos. Un ejemplo común de esto sería conectarse a un servicio externo con resiliencia mejorada para manejar problemas ocasionales de conexión (por ejemplo, agregar un timeout para llamadas a `example.com`).

Esta es un área bajo desarrollo activo en la comunidad, donde diseñamos cómo el tráfico puede enrutarse a su gateway de salida y cómo puede configurar el gateway de salida con sus políticas deseadas. ¡Esté atento a futuras publicaciones de blog en esta área!

## Una inmersión profunda en la configuración de waypoint

Asumiendo que ha seguido la [guía de inicio de ambient](/docs/ambient/getting-started/) hasta e incluyendo la [sección de controlar tráfico](/docs/ambient/getting-started/#control), ha desplegado un proxy waypoint para la cuenta de servicio bookinfo-reviews para dirigir el 90% del tráfico a reviews v1 y el 10% del tráfico a reviews v2.

Use `istioctl` para recuperar los listeners para el proxy waypoint de `reviews`:

{{< text bash >}}
$ istioctl proxy-config listener deploy/bookinfo-reviews-istio-waypoint --waypoint
LISTENER              CHAIN                                                 MATCH                                         DESTINATION
envoy://connect_originate                                                       ALL                                           Cluster: connect_originate
envoy://main_internal inbound-vip|9080||reviews.default.svc.cluster.local-http  ip=10.96.104.108 -> port=9080                 Inline Route: /*
envoy://main_internal direct-tcp                                            ip=10.244.2.14 -> ANY                         Cluster: encap
envoy://main_internal direct-tcp                                            ip=10.244.1.6 -> ANY                          Cluster: encap
envoy://main_internal direct-tcp                                            ip=10.244.2.11 -> ANY                         Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.11 -> application-protocol='h2c'  Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.11 -> application-protocol='http/1.1' Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.14 -> application-protocol='http/1.1' Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.14 -> application-protocol='h2c'  Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.1.6 -> application-protocol='h2c'   Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.1.6 -> application-protocol='http/1.1'  Cluster: encap
envoy://connect_terminate default                                               ALL                                           Inline Route:
{{< /text >}}

Para solicitudes que llegan en el puerto `15008`, que por defecto es el puerto {{< gloss >}}HBONE{{< /gloss >}} entrante de Istio, el proxy waypoint termina la conexión HBONE y reenvía la solicitud al listener `main_internal` para hacer cumplir cualquier política de carga de trabajo como AuthorizationPolicy. Si no está familiarizado con [listeners internos](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_features/internal_listener), son listeners de Envoy que aceptan conexiones en espacio de usuario sin usar la API de red del sistema. El flag `--waypoint` agregado al comando `istioctl proxy-config`, arriba, le indica que muestre los detalles del listener `main_internal`, sus cadenas de filtros, coincidencias de cadenas y destinos.

Tenga en cuenta que `10.96.104.108` es la VIP del servicio reviews y `10.244.x.x` son las IPs de pod de reviews v1/v2/v3, que puede ver para su clúster usando el comando `kubectl get svc,pod -o wide`. Para tráfico entrante de texto plano o HBONE terminado, se coincidirá con la VIP del servicio y el puerto 9080 para reviews o por dirección IP de pod y protocolo de aplicación (ya sea `ANY`, `h2c`, o `http/1.1`).

Verificando los clusters para el proxy waypoint de `reviews`, obtiene el cluster `main_internal` junto con algunos clusters entrantes. Aparte de los clusters para infraestructura, los únicos clusters de Envoy creados son para servicios y pods ejecutándose en la misma cuenta de servicio. No se crean clusters para servicios o pods ejecutándose en otro lugar.

{{< text bash >}}
$ istioctl proxy-config clusters deploy/bookinfo-reviews-istio-waypoint
SERVICE FQDN                         PORT SUBSET  DIRECTION   TYPE         DESTINATION RULE
agent                                -    -       -           STATIC
connect_originate                    -    -       -           ORIGINAL_DST
encap                                -    -       -           STATIC
kubernetes.default.svc.cluster.local 443  tcp     inbound-vip EDS
main_internal                        -    -       -           STATIC
prometheus_stats                     -    -       -           STATIC
reviews.default.svc.cluster.local    9080 http    inbound-vip EDS
reviews.default.svc.cluster.local    9080 http/v1 inbound-vip EDS
reviews.default.svc.cluster.local    9080 http/v2 inbound-vip EDS
reviews.default.svc.cluster.local    9080 http/v3 inbound-vip EDS
sds-grpc                             -    -       -           STATIC
xds-grpc                             -    -       -           STATIC
zipkin                               -    -       -           STRICT_DNS
{{< /text >}}

Tenga en cuenta que no hay clusters `outbound` en la lista, lo cual puede confirmar usando `istioctl proxy-config cluster deploy/bookinfo-reviews-istio-waypoint --direction outbound`! Lo bueno es que no necesitó configurar `exportTo` en ninguno de los otros servicios de bookinfo (por ejemplo, los servicios `productpage` o `ratings`). En otras palabras, el waypoint de `reviews` no se hace consciente de ningún cluster innecesario, sin ninguna configuración manual adicional de su parte.

Muestre la lista de rutas para el proxy waypoint de `reviews`:

{{< text bash >}}
$ istioctl proxy-config routes deploy/bookinfo-reviews-istio-waypoint
NAME                                                    DOMAINS MATCH              VIRTUAL SERVICE
encap                                                   *       /*
inbound-vip|9080|http|reviews.default.svc.cluster.local *       /*                 reviews.default
default
{{< /text >}}

Recuerde que no configuró ningún recurso Sidecar o configuración `exportTo` en sus recursos de red de Istio. Sin embargo, desplegó la ruta `bookinfo-productpage` para configurar un gateway de ingreso para enrutar a `productpage` pero el waypoint de `reviews` no se ha hecho consciente de ninguna ruta irrelevante.

Mostrando la información detallada para la ruta `inbound-vip|9080|http|reviews.default.svc.cluster.local`, verá la configuración de enrutamiento basada en peso dirigiendo el 90% del tráfico a `reviews` v1 y el 10% del tráfico a `reviews` v2, junto con algunas de las configuraciones predeterminadas de reintento y timeout de Istio. Esto confirma que las políticas de tráfico y resiliencia se han cambiado del waypoint orientado a origen al orientado a destino como se discutió anteriormente.

{{< text bash >}}
$ istioctl proxy-config routes deploy/bookinfo-reviews-istio-waypoint --name "inbound-vip|9080|http|reviews.default.svc.cluster.local" -o yaml
- name: inbound-vip|9080|http|reviews.default.svc.cluster.local
 validateClusters: false
 virtualHosts:
 - domains:
   - '*'
   name: inbound|http|9080
   routes:
   - decorator:
       operation: reviews:9080/*
     match:
       prefix: /
     metadata:
       filterMetadata:
         istio:
           config: /apis/networking.istio.io/v1alpha3/namespaces/default/virtual-service/reviews
     route:
       maxGrpcTimeout: 0s
       retryPolicy:
         hostSelectionRetryMaxAttempts: "5"
         numRetries: 2
         retriableStatusCodes:
         - 503
         retryHostPredicate:
         - name: envoy.retry_host_predicates.previous_hosts
           typedConfig:
             '@type': type.googleapis.com/envoy.extensions.retry.host.previous_hosts.v3.PreviousHostsPredicate
         retryOn: connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes
       timeout: 0s
       weightedClusters:
         clusters:
         - name: inbound-vip|9080|http/v1|reviews.default.svc.cluster.local
           weight: 90
         - name: inbound-vip|9080|http/v2|reviews.default.svc.cluster.local
           weight: 10
{{< /text >}}

Verifique los endpoints para el proxy waypoint de `reviews`:

{{< text bash >}}
$ istioctl proxy-config endpoints deploy/bookinfo-reviews-istio-waypoint
ENDPOINT                                            STATUS  OUTLIER CHECK CLUSTER
127.0.0.1:15000                                     HEALTHY OK            prometheus_stats
127.0.0.1:15020                                     HEALTHY OK            agent
envoy://connect_originate/                          HEALTHY OK            encap
envoy://connect_originate/10.244.1.6:9080           HEALTHY OK            inbound-vip|9080|http/v2|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.1.6:9080           HEALTHY OK            inbound-vip|9080|http|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.11:9080          HEALTHY OK            inbound-vip|9080|http/v1|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.11:9080          HEALTHY OK            inbound-vip|9080|http|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.14:9080          HEALTHY OK            inbound-vip|9080|http/v3|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.14:9080          HEALTHY OK            inbound-vip|9080|http|reviews.default.svc.cluster.local
envoy://main_internal/                              HEALTHY OK            main_internal
unix://./etc/istio/proxy/XDS                        HEALTHY OK            xds-grpc
unix://./var/run/secrets/workload-spiffe-uds/socket HEALTHY OK            sds-grpc
{{< /text >}}

Tenga en cuenta que no obtiene ningún endpoint relacionado con ningún servicio que no sea reviews, aunque tiene algunos otros servicios en los namespaces `default` e `istio-system`.

## Conclusión

Estamos muy emocionados con la simplificación de waypoint enfocándose en proxies waypoint orientados a destino. Este es otro paso significativo hacia la simplificación de la usabilidad, escalabilidad y capacidad de depuración de Istio, que son prioridades principales en la hoja de ruta de Istio. ¡Siga nuestra [guía de inicio](/docs/ambient/getting-started/) para probar la compilación alpha de ambient hoy y experimentar el proxy waypoint simplificado!

