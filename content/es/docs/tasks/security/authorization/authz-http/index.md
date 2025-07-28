---
title: Tráfico HTTP
description: Muestra cómo configurar el control de acceso para el tráfico HTTP.
weight: 10
keywords: [security,access-control,rbac,authorization]
aliases:
    - /docs/tasks/security/role-based-access-control.html
    - /docs/tasks/security/authz-http/
owner: istio/wg-security-maintainers
test: yes
---

Esta tarea muestra cómo configurar la política de autorización de Istio de acción `ALLOW` para el tráfico HTTP en una malla de Istio.

## Antes de empezar

Antes de comenzar esta tarea, haga lo siguiente:

* Lea los [conceptos de autorización de Istio](/es/docs/concepts/security/#authorization).

* Siga la [guía de instalación de Istio](/es/docs/setup/install/istioctl/) para instalar Istio con mTLS habilitado.

* Despliegue la application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/#deploying-the-application).

Después de desplegar la application Bookinfo, vaya a la página del producto Bookinfo en `http://$GATEWAY_URL/productpage`. En
la página del producto, puede ver las siguientes secciones:

* **Detalles del Libro** en el medio de la página, que incluye: tipo de libro, número de
  páginas, editorial, etc.
* **Reseñas del Libro** en la parte inferior de la página.

Cuando actualiza la página, la aplicación muestra diferentes versiones de reseñas en la página del producto.
La aplicación presenta las reseñas en un estilo round robin: estrellas rojas, estrellas negras o sin estrellas.

{{< tip >}}
Si no ve la salida esperada en el navegador mientras sigue la tarea, inténtelo de nuevo en unos segundos
ya que es posible un retraso debido al almacenamiento en caché y otros gastos generales de propagación.
{{< /tip >}}

{{< warning >}}
Esta tarea requiere mTLS habilitado porque los siguientes ejemplos usan principal
y namespace en las políticas.
{{< /warning >}}

## Configurar el control de acceso para workloads usando tráfico HTTP

Usando Istio, puede configurar fácilmente el control de acceso para los {{< gloss "workload" >}}workloads{{< /gloss >}}
en su malla. Esta tarea muestra cómo configurar el control de acceso usando la autorización de Istio.
Primero, configure una política simple de `allow-nothing` que rechace todas las solicitudes al workload,
y luego otorgue más acceso al workload de forma gradual e incremental.

1. Ejecute el siguiente comando para crear una política `allow-nothing` en el namespace `default`.
   La política no tiene un campo `selector`, lo que aplica la política a cada workload en el
   namespace `default`. El campo `spec:` de la política tiene el valor vacío `{}`.
   Ese valor significa que no se permite ningún tráfico, denegando efectivamente todas las solicitudes.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: allow-nothing
      namespace: default
    spec:
      {}
    EOF
    {{< /text >}}

    Apunte su navegador a la `productpage` de Bookinfo (`http://$GATEWAY_URL/productpage`).
    Debería ver `"RBAC: acceso denegado"`. El error muestra que la política `deny-all` configurada
    está funcionando como se esperaba, y Istio no tiene ninguna regla que permita ningún acceso a
    los workloads en la malla.

1. Ejecute el siguiente comando para crear una política `productpage-viewer` para permitir el acceso
   con el método `GET` al workload `productpage`. La política no establece el campo `from`
   en las `rules`, lo que significa que todas las fuentes están permitidas, permitiendo efectivamente
   a todos los usuarios y workloads:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: "productpage-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: productpage
      action: ALLOW
      rules:
      - to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    Apunte su navegador a la `productpage` de Bookinfo (`http://$GATEWAY_URL/productpage`).
    Ahora debería ver la página "Bookinfo Sample".
    Sin embargo, puede ver los siguientes errores en la página:

    * `Error al obtener los detalles del producto`
    * `Error al obtener las reseñas del producto` en la página.

    Estos errores son esperados porque no hemos otorgado al workload `productpage`
    acceso a los workloads `details` y `reviews`. A continuación, debe
    configurar una política para otorgar acceso a esos workloads.

1. Ejecute el siguiente comando para crear la política `details-viewer` para permitir que el workload `productpage`,
   que emite solicitudes utilizando la cuenta de service `cluster.local/ns/default/sa/bookinfo-productpage`,
   acceda al workload `details` a través de métodos `GET`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: "details-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: details
      action: ALLOW
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. Ejecute el siguiente comando para crear una política `reviews-viewer` para permitir que el workload `productpage`,
   que emite solicitudes utilizando la cuenta de service `cluster.local/ns/default/sa/bookinfo-productpage`,
   acceda al workload `reviews` a través de métodos `GET`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: "reviews-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: reviews
      action: ALLOW
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    Apunte su navegador a la `productpage` de Bookinfo (`http://$GATEWAY_URL/productpage`). Ahora, debería ver la página "Bookinfo Sample"
    con "Detalles del Libro" en la parte inferior izquierda, y "Reseñas del Libro" en la parte inferior derecha. Sin embargo, en la sección "Reseñas del Libro",
    hay un error `Service de calificaciones no disponible actualmente`.

    Esto se debe a que el workload `reviews` no tiene permiso para acceder al workload `ratings`.
    Para solucionar este problema, debe otorgar al workload `reviews` acceso al workload `ratings`.
    A continuación, configuramos una política para otorgar al workload `reviews` ese acceso.

1. Ejecute el siguiente comando para crear la política `ratings-viewer` para permitir que el workload `reviews`,
   que emite solicitudes utilizando la cuenta de service `cluster.local/ns/default/sa/bookinfo-reviews`,
   acceda al workload `ratings` a través de métodos `GET`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: "ratings-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: ratings
      action: ALLOW
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-reviews"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    Apunte su navegador a la `productpage` de Bookinfo (`http://$GATEWAY_URL/productpage`).
    Debería ver las calificaciones "negras" y "rojas" en la sección "Reseñas del Libro".

    **¡Felicidades!** Ha aplicado con éxito la política de autorización para aplicar el control de acceso
    para workloads usando tráfico HTTP.

## Limpieza

Elimine todas las políticas de autorización de su configuración:

{{< text bash >}}
$ kubectl delete authorizationpolicy.security.istio.io/allow-nothing
$ kubectl delete authorizationpolicy.security.istio.io/productpage-viewer
$ kubectl delete authorizationpolicy.security.istio.io/details-viewer
$ kubectl delete authorizationpolicy.security.istio.io/reviews-viewer
$ kubectl delete authorizationpolicy.security.istio.io/ratings-viewer
{{< /text >}}
