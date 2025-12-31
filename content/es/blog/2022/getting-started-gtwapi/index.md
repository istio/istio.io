---
title: Primeros pasos con la Kubernetes Gateway API
description: Uso de la Gateway API para configurar el tráfico de ingress de tu clúster Kubernetes.
publishdate: 2022-12-14
attribution: Frank Budinsky (IBM)
keywords: [traffic-management,gateway,gateway-api,api,gamma,sig-network]
---

Tanto si ejecutas tus servicios de aplicaciones en Kubernetes usando Istio (o cualquier service mesh),
como si simplemente usas servicios “normales” en un clúster Kubernetes, necesitas proporcionar acceso
a tus servicios de aplicación para clientes fuera del clúster. Si estás usando Kubernetes “a pelo”, probablemente
estés usando recursos [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) de Kubernetes
para configurar el tráfico entrante. Si usas Istio, es más probable que uses los recursos de configuración recomendados por Istio,
[Gateway](/docs/reference/config/networking/gateway/) y [VirtualService](/docs/reference/config/networking/virtual-service/),
para hacer este trabajo.

Desde hace tiempo se sabe que el recurso Ingress de Kubernetes tiene carencias importantes, especialmente
cuando se usa para configurar tráfico de ingress en aplicaciones grandes y cuando se trabaja con protocolos distintos de HTTP.
Un problema es que configura tanto propiedades L4‑L6 del lado del cliente (por ejemplo, puertos, TLS, etc.) como el enrutamiento L7 del lado del servicio
en un único recurso: configuraciones que, en aplicaciones grandes, deberían gestionarse por equipos distintos y en namespaces diferentes.
Además, al intentar ser un mínimo común denominador entre distintos proxies HTTP, Ingress solo puede soportar lo más básico del enrutamiento HTTP
y empuja el resto de funcionalidades de proxies modernos hacia anotaciones no portables.

Para superar las carencias de Ingress, Istio introdujo su propia API de configuración para la gestión de tráfico de ingress.
Con la API de Istio, la representación del lado del cliente se define con un recurso Istio Gateway, mientras que el tráfico L7 se mueve a un VirtualService,
que (no por casualidad) es el mismo recurso que se usa para enrutar tráfico entre servicios dentro del mesh.
Aunque la API de Istio ofrece una buena solución para la gestión de tráfico de ingress en aplicaciones a gran escala, por desgracia es una API exclusiva de Istio.
Si estás usando otra implementación de service mesh, o ningún service mesh, no tienes esa opción.

## Entra en juego Gateway API

Hay mucha expectación en torno a una nueva API de Kubernetes para la gestión de tráfico,
llamada [Gateway API](https://gateway-api.sigs.k8s.io/), que recientemente ha sido
[promocionada a Beta](https://kubernetes.io/blog/2022/07/13/gateway-api-graduates-to-beta/).
Gateway API proporciona un conjunto de recursos de configuración de Kubernetes para el control del tráfico de ingress que, al igual que la API de Istio,
supera las carencias de Ingress pero, a diferencia de la de Istio, es una API estándar de Kubernetes con amplio acuerdo en la industria.
Hay [varias implementaciones](https://gateway-api.sigs.k8s.io/implementations/) en marcha, incluida una implementación Beta en Istio,
así que quizá sea un buen momento para empezar a pensar en cómo migrar tu configuración de tráfico de ingress desde Kubernetes Ingress o desde Istio Gateway/VirtualService
hacia la nueva Gateway API.

Ya uses o no (o planees usar) Istio para gestionar tu service mesh, la implementación de Gateway API de Istio se puede usar fácilmente
para empezar con el control de ingress de tu clúster.
Aunque en Istio sigue siendo una funcionalidad Beta (en gran parte porque la propia Gateway API es Beta), la implementación de Istio es bastante robusta
porque “por debajo” utiliza los mismos recursos internos de Istio, probados y maduros, para implementar la configuración.

## Inicio rápido con Gateway API

Para empezar a usar Gateway API, primero necesitas instalar los CRDs, que aún no vienen instalados por defecto en la mayoría de clústeres Kubernetes:

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
{{< /text >}}

Una vez instalados los CRDs, puedes crear recursos de Gateway API para configurar el tráfico de ingress, pero para que funcionen el clúster necesita
tener un gateway controller ejecutándose.
Puedes habilitar la implementación de gateway controller de Istio simplemente instalando Istio con el perfil minimal:

{{< text bash >}}
$ curl -L https://istio.io/downloadIstio | sh -
$ cd istio-{{< istio_full_version >}}
$ ./bin/istioctl install --set profile=minimal -y
{{< /text >}}

Ahora tu clúster tendrá una implementación completamente funcional de Gateway API a través del gateway controller de Istio, llamado `istio.io/gateway-controller`,
lista para usar.

### Desplegar un servicio destino de Kubernetes

Para probar Gateway API, usaremos el ejemplo [helloworld]({{< github_tree >}}/samples/helloworld) de Istio como destino de ingress,
pero ejecutándolo únicamente como un servicio Kubernetes simple, sin inyección de sidecar habilitada.
Como solo vamos a usar Gateway API para controlar el tráfico de ingress "hacia el clúster Kubernetes", no importa si el servicio destino está dentro o fuera de un mesh.

Usaremos el siguiente comando para desplegar el servicio helloworld:

{{< text bash >}}
$ kubectl create ns sample
$ kubectl apply -f @samples/helloworld/helloworld.yaml@ -n sample
{{< /text >}}

El servicio helloworld incluye dos deployments “backing”, correspondientes a dos versiones (`v1` y `v2`).
Podemos confirmar que ambos están ejecutándose con el siguiente comando:

{{< text bash >}}
$ kubectl get pod -n sample
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-776f57d5f6-s7zfc   1/1     Running   0          10s
helloworld-v2-54df5f84b-9hxgww   1/1     Running   0          10s
{{< /text >}}

### Configurar el tráfico de ingress de helloworld

Con el servicio helloworld ya desplegado, podemos usar Gateway API para configurar su tráfico de ingress.

El punto de entrada de ingress se define usando un recurso
[Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway) resource:

{{< text bash >}}
$ kubectl create namespace sample-ingress
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: sample-gateway
  namespace: sample-ingress
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: "*.sample.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF
{{< /text >}}

El controller que implementará un Gateway se selecciona referenciando un recurso
[GatewayClass](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.GatewayClass).
Debe existir al menos una GatewayClass definida en el clúster para que los Gateways sean funcionales.
En nuestro caso, seleccionamos el gateway controller de Istio, `istio.io/gateway-controller`, referenciando su GatewayClass asociada (llamada `istio`)
mediante la propiedad `gatewayClassName: istio` del Gateway.

Observa que, a diferencia de Ingress, un Gateway de Kubernetes no incluye referencias al servicio destino (helloworld).
En Gateway API, las rutas hacia servicios se definen en recursos de configuración separados que se “adjuntan” al Gateway para dirigir subconjuntos de tráfico
a servicios concretos (como helloworld en nuestro ejemplo). Esta separación permite definir el Gateway y las rutas en namespaces distintos, presumiblemente gestionados por equipos diferentes.
Aquí, actuando como operador del clúster, aplicamos el Gateway en el namespace `sample-ingress`. Añadiremos la ruta, más abajo, en el namespace `sample`,
junto al propio servicio helloworld, en nombre del desarrollador de la aplicación.

Como el recurso Gateway es propiedad del operador del clúster, puede usarse perfectamente para proporcionar ingress a servicios de más de un equipo;
en nuestro caso, a más servicios además de helloworld. Para enfatizar este punto, hemos establecido el hostname a `*.sample.com` en el Gateway,
permitiendo adjuntar rutas para múltiples subdominios.

Después de aplicar el recurso Gateway, debemos esperar a que esté listo antes de obtener su dirección externa:

{{< text bash >}}
$ kubectl wait -n sample-ingress --for=condition=programmed gateway sample-gateway
$ export INGRESS_HOST=$(kubectl get -n sample-ingress gateway sample-gateway -o jsonpath='{.status.addresses[0].value}')
{{< /text >}}

A continuación, adjuntamos un [HTTPRoute](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.HTTPRoute) al `sample-gateway`
(usando el campo `parentRefs`) para exponer y enrutar el tráfico hacia el servicio helloworld:

{{< text bash >}}
$ kubectl apply -n sample -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: sample-gateway
    namespace: sample-ingress
  hostnames: ["helloworld.sample.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld
      port: 5000
EOF
{{< /text >}}

Aquí hemos expuesto la ruta `/hello` del servicio helloworld para clientes fuera del clúster, específicamente mediante el host `helloworld.sample.com`.
Puedes confirmar que el ejemplo helloworld es accesible usando curl:

{{< text bash >}}
$ for run in {1..10}; do curl -HHost:helloworld.sample.com http://$INGRESS_HOST/hello; done
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
{{< /text >}}

Como no se ha configurado enrutamiento por versión en la regla de ruta, deberías ver un reparto de tráfico igualitario:
aproximadamente la mitad manejado por `helloworld-v1` y la otra mitad por `helloworld-v2`.

### Configurar enrutamiento por versión basado en peso

Entre otras capacidades de “traffic shaping”, puedes usar Gateway API para enviar todo el tráfico a una de las versiones o dividirlo por porcentajes.
Por ejemplo, puedes usar la siguiente regla para distribuir el tráfico de helloworld en un 90% a `v1` y un 10% a `v2`:

{{< text bash >}}
$ kubectl apply -n sample -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: sample-gateway
    namespace: sample-ingress
  hostnames: ["helloworld.sample.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld-v1
      port: 5000
      weight: 90
    - name: helloworld-v2
      port: 5000
      weight: 10
EOF
{{< /text >}}

Gateway API se apoya en definiciones de servicios backend específicas por versión para los destinos de ruta:
`helloworld-v1` y `helloworld-v2` en este ejemplo.
El ejemplo helloworld ya incluye definiciones de servicio para las versiones `v1` y `v2`; solo necesitamos ejecutar el siguiente comando para definirlas:

{{< text bash >}}
$ kubectl apply -n sample -f @samples/helloworld/gateway-api/helloworld-versions.yaml@
{{< /text >}}

Ahora podemos ejecutar de nuevo los comandos curl anteriores:

{{< text bash >}}
$ for run in {1..10}; do curl -HHost:helloworld.sample.com http://$INGRESS_HOST/hello; done
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
{{< /text >}}

Esta vez vemos que aproximadamente 9 de cada 10 peticiones las gestiona `helloworld-v1` y solo alrededor de 1 de cada 10 las gestiona `helloworld-v2`.

## Gateway API para tráfico interno del mesh

Puede que hayas notado que hemos estado hablando de Gateway API únicamente como una API de configuración de ingress,
a menudo llamada gestión de tráfico north‑south, y no como una API para la gestión de tráfico servicio‑a‑servicio (también llamada east‑west) dentro de un clúster.

Si estás usando un service mesh, sería muy deseable usar los mismos recursos de API para configurar tanto el enrutamiento de tráfico de ingress como el tráfico interno,
de forma similar a como Istio usa VirtualService para definir reglas de ruta para ambos. Afortunadamente, la Gateway API de Kubernetes está trabajando para añadir este soporte.
Aunque no es tan madura como Gateway API para tráfico de ingress, está en marcha una iniciativa conocida como
[Gateway API for Mesh Management and Administration (GAMMA)](https://gateway-api.sigs.k8s.io/contributing/gamma/) para hacerlo realidad,
y Istio pretende convertir Gateway API en la API por defecto para toda su gestión de tráfico [en el futuro](/blog/2022/gateway-api-beta/).

La primera [Gateway Enhancement Proposal (GEP)](https://gateway-api.sigs.k8s.io/geps/gep-1426/) significativa se ha aceptado recientemente y, de hecho,
ya está disponible para usar en Istio.
Para probarla, necesitarás usar la [versión experimental](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)
de los CRDs de Gateway API, en lugar de la versión Beta estándar que instalamos arriba, pero por lo demás estarás listo.
Consulta la tarea de Istio de [request routing](/docs/tasks/traffic-management/request-routing/) para empezar.

## Resumen

En este artículo hemos visto cómo una instalación ligera (minimal) de Istio puede usarse para proporcionar una implementación de calidad Beta
de la nueva Kubernetes Gateway API para el control del tráfico de ingress del clúster. Para usuarios de Istio, la implementación de Istio también permite
empezar a probar el soporte experimental de Gateway API para la gestión de tráfico east‑west dentro del mesh.

Gran parte de la documentación de Istio, incluidas todas las [tareas de ingress](/docs/tasks/traffic-management/ingress/) y varias tareas de gestión de tráfico interno,
ya incluyen instrucciones paralelas para configurar el tráfico usando Gateway API o la API de configuración de Istio.
Consulta la [tarea de Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/) para más información sobre la implementación de Gateway API en Istio.
