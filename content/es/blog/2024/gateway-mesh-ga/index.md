---
title: "El soporte de mesh de la API de Gateway es promovido a Estable"
description: Las API de enrutamiento de tráfico de Kubernetes de próxima generación ya están disponibles de forma general para casos de uso de service mesh.
publishdate: 2024-05-13
attribution: John Howard - solo.io
keywords: [istio, traffic, API]
target_release: 1.22
---

¡Estamos encantados de anunciar que el soporte de Service Mesh en la [API de Gateway](https://gateway-api.sigs.k8s.io/) es ahora oficialmente "Estable"!
Con esta versión (parte de la API de Gateway v1.1 e Istio v1.22), los usuarios pueden hacer uso de las API de gestión de tráfico de próxima generación tanto para casos de uso de entrada ("norte-sur") como de service mesh ("este-oeste").

## ¿Qué es la API de Gateway?

La API de Gateway es una colección de API que forman parte de Kubernetes, centradas en el enrutamiento y la gestión del tráfico.
Las API están inspiradas y cumplen muchas de las mismas funciones que las API `Ingress` de Kubernetes y `VirtualService` y `Gateway` de Istio.

Estas API han estado en desarrollo tanto en Istio, como con una [amplia colaboración](https://gateway-api.sigs.k8s.io/implementations/), desde 2020, y han recorrido un largo camino desde entonces.
Si bien la API inicialmente solo se enfocaba en servir casos de uso de entrada (que se convirtió en GA [el año pasado](https://kubernetes.io/blog/2023/10/31/gateway-api-ga/)), siempre habíamos previsto permitir que las mismas API se usaran también para el tráfico *dentro* de un cluster.

Con esta versión, esa visión se hace realidad: ¡los usuarios de Istio pueden usar la misma API de enrutamiento para todo su tráfico!

## Primeros pasos

A lo largo de la documentación de Istio, todos nuestros ejemplos se han actualizado para mostrar cómo usar la API de Gateway, así que explora algunas de las [tareas](/es/docs/tasks/traffic-management/) para obtener una comprensión más profunda.

El uso de la API de Gateway para la service mesh debería resultar familiar tanto para los usuarios que ya usan la API de Gateway para la entrada, como para los usuarios que usan `VirtualService` para la service mesh en la actualidad.

* En comparación con la API de Gateway para la entrada, las rutas apuntan a un `Service` en lugar de a un `Gateway`.
* En comparación con `VirtualService`, donde las rutas se asocian con un conjunto de `hosts`, las rutas apuntan a un `Service`.

Aquí hay un ejemplo simple, que demuestra el enrutamiento de solicitudes a dos versiones diferentes de un `Service` según el encabezado de la solicitud:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - matches:
    - headers:
      - name: my-favorite-service-mesh
        value: istio
    filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
      add:
        - name: hello
          value: world
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
{{< /text >}}

Desglosando esto, tenemos algunas partes:
* Primero, identificamos qué rutas debemos hacer coincidir.
  Al adjuntar nuestra ruta al `Service` de `reviews`, aplicaremos esta configuración de enrutamiento a todas las solicitudes que originalmente apuntaban a `reviews`.
* A continuación, `matches` configura los criterios para seleccionar qué tráfico debe manejar esta ruta.
* Opcionalmente, podemos modificar la solicitud. Aquí, agregamos un encabezado.
* Finalmente, seleccionamos un destino para la solicitud. En este ejemplo, estamos eligiendo entre dos versiones de nuestra aplicación.

Para obtener más detalles, consulta los [internos de enrutamiento de tráfico de Istio](/es/docs/ops/configuration/traffic-management/traffic-routing/) y la [documentación de Service de la API de Gateway](https://gateway-api.sigs.k8s.io/mesh/service-facets/).

## ¿Qué API debo usar?

Con responsabilidades (¡y nombres!) superpuestos, elegir qué API usar puede ser un poco confuso.

Aquí está el desglose:

| Nombre de la API | Tipos de objeto                                                                                                                       | Estado                            | Recomendación                                                                      |
|--------------|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------|------------------------------------------------------------------------------------|
| API de Gateway | [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/), [Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/), ... | Estable en la API de Gateway v1.0 (2023) | Usar para nuevas implementaciones, en particular con [modo ambient](/es/docs/ambient/) |
| API de Istio   | [Virtual Service](/es/docs/reference/config/networking/virtual-service/), [Gateway](/es/docs/reference/config/networking/gateway/)          | `v1` en Istio 1.22 (2024)         | Usar para implementaciones existentes, o donde se necesiten características avanzadas |
| API de Ingress  | [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress)                                                            | Estable en Kubernetes v1.19 (2020) | Usar solo para implementaciones heredadas                                          |

Quizás te preguntes, dado lo anterior, ¿por qué las API de Istio fueron [promovidas a `v1`](/blog/2024/v1-apis) simultáneamente?
Esto fue parte de un esfuerzo por categorizar con precisión la *estabilidad* de las API.
Si bien vemos la API de Gateway como el futuro (¡y el presente!) de las API de enrutamiento de tráfico, nuestras API existentes llegaron para quedarse a largo plazo, con total compatibilidad.
Esto refleja el enfoque de Kubernetes con [`Ingress`](https://kubernetes.io/docs/concepts/services-networking/ingress), que fue promovido a `v1` mientras se dirigía el trabajo futuro hacia la API de Gateway.

## Comunidad

Esta graduación de estabilidad representa la culminación de innumerables horas de trabajo y colaboración en todo el proyecto.
Es increíble ver la [lista de organizaciones](https://gateway-api.sigs.k8s.io/implementations/) involucradas en la API y recordar lo lejos que hemos llegado.

Un agradecimiento especial a mis [colíderes en el esfuerzo](https://gateway-api.sigs.k8s.io/mesh/gamma/): Flynn, Keith Mattix y Mike Morris, así como a los innumerables otros involucrados.

¿Interesado en participar, o incluso solo en dar tu opinión?
¡Consulta la [página de la comunidad](/get-involved/) de Istio o la [guía de contribución](https://gateway-api.sigs.k8s.io/contributing/) de la API de Gateway!
