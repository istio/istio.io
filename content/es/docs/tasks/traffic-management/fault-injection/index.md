---
title: Inyección de Fallos
description: Esta tarea muestra cómo inyectar fallos para probar la resiliencia de su application.
weight: 20
keywords: [traffic-management,fault-injection]
aliases:
    - /docs/tasks/fault-injection.html
owner: istio/wg-networking-maintainers
test: yes
---

Esta tarea muestra cómo inyectar fallos para probar la resiliencia de su application.

## Antes de empezar

* Configure Istio siguiendo las instrucciones de la
  [guía de instalación](/es/docs/setup/).

* Despliegue la application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/) incluyendo las
  [reglas de destino predeterminadas](/es/docs/examples/bookinfo/#apply-default-destination-rules).

* Revise la discusión sobre la inyección de fallos en el documento de conceptos de
[Gestión de Tráfico](/es/docs/concepts/traffic-management).

* Aplique el enrutamiento de versiones de la application realizando la tarea de
  [enrutamiento de solicitudes](/es/docs/tasks/traffic-management/request-routing/) o ejecutando los siguientes comandos:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
    {{< /text >}}

* Con la configuración anterior, así es como fluyen las solicitudes:
    *  `productpage` → `reviews:v2` → `ratings` (solo para el usuario `jason`)
    *  `productpage` → `reviews:v1` (para todos los demás)

## Inyectar un fallo de retardo HTTP

Para probar la resiliencia de los microservicios de la application Bookinfo, inyecte un retardo de 7s
entre los microservicios `reviews:v2` y `ratings` para el usuario `jason`. Esta prueba
descubrirá un bug que se introdujo intencionalmente en la aplicación Bookinfo.

Tenga en cuenta que el service `reviews:v2` tiene un tiempo de espera de conexión codificado de 10s para
las llamadas al service `ratings`. Incluso con el retardo de 7s que introdujo, aún
espera que el flujo de extremo a extremo continúe sin errores.

1.  Cree una regla de inyección de fallos para retrasar el tráfico proveniente del usuario de prueba
`jason`.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml@
    {{< /text >}}

1. Confirme que la regla fue creada:

    {{< text bash yaml >}}
    $ kubectl get virtualservice ratings -o yaml
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    ...
    spec:
      hosts:
      - ratings
      http:
      - fault:
          delay:
            fixedDelay: 7s
            percentage:
              value: 100
        match:
        - headers:
            end-user:
              exact: jason
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

    Permita varios segundos para que la nueva regla se propague a todos los pods.

## Probar la configuración de retardo

1. Abra la aplicación web [Bookinfo](/es/docs/examples/bookinfo) en su navegador.

1. En la página web `/productpage`, inicie sesión como usuario `jason`.

    Espera que la página de inicio de Bookinfo se cargue sin errores en aproximadamente
    7 segundos. Sin embargo, hay un problema: la sección de Reseñas muestra un mensaje de error:

    {{< text plain >}}
    Lo sentimos, las reseñas de productos no están disponibles actualmente para este libro.
    {{< /text >}}

1. Verifique los tiempos de respuesta de la página web:

    1. Abra el menú *Herramientas de Desarrollador* en su navegador web.
    1. Abra la pestaña Red
    1. Vuelva a cargar la página web `/productpage`. Verá que la página se carga en unos 6 segundos.

## Comprender lo que sucedió

Ha encontrado un bug. Hay tiempos de espera codificados en los microservicios que han
causado que el service `reviews` falle.

Como se esperaba, el retardo de 7s que introdujo no afecta al service `reviews`
porque el tiempo de espera entre el service `reviews` y `ratings` está codificado en 10s.
Sin embargo, también hay un tiempo de espera codificado entre el service `productpage` y `reviews`,
codificado como 3s + 1 reintento para un total de 6s.
Como resultado, la llamada de `productpage` a `reviews` agota el tiempo de espera prematuramente y lanza un error después de 6s.

Errores como este pueden ocurrir en applications empresariales típicas donde diferentes equipos
desarrollan diferentes microservicios de forma independiente. Las reglas de inyección de fallos de Istio le ayudan a identificar tales anomalías
sin afectar a los usuarios finales.

{{< tip >}}
Observe que la prueba de inyección de fallos se restringe a cuando el usuario conectado es
`jason`. Si inicia sesión como cualquier otro usuario, no experimentará ningún retraso.
{{< /tip >}}

## Corregir el bug

Normalmente, solucionaría el problema de la siguiente manera:

1. Aumentando el tiempo de espera del service `productpage` a `reviews` o disminuyendo el tiempo de espera de `reviews` a `ratings`
1. Deteniendo y reiniciando el microservicio corregido
1. Confirmando que la página web `/productpage` devuelve su respuesta sin errores.

Sin embargo, ya tiene una solución ejecutándose en la v3 del service `reviews`.
El service `reviews:v3` reduce el tiempo de espera de `reviews` a `ratings` de 10s a 2.5s
para que sea compatible con (menos que) el tiempo de espera de las solicitudes `productpage` descendentes.

Si migra todo el tráfico a `reviews:v3` como se describe en la tarea de
[cambio de tráfico](/es/docs/tasks/traffic-management/traffic-shifting/), puede
intentar cambiar la regla de retardo a cualquier cantidad inferior a 2.5s, por ejemplo 2s, y confirmar
que el flujo de extremo a extremo continúa sin errores.

## Inyectar un fallo de aborto HTTP

Otra forma de probar la resiliencia de los microservicios es introducir un fallo de aborto HTTP.
En esta tarea, introducirá un aborto HTTP en los microservicios `ratings` para
el usuario de prueba `jason`.

En este caso, espera que la página se cargue inmediatamente y muestre el mensaje `El service de calificaciones no está disponible actualmente`.

1.  Cree una regla de inyección de fallos para enviar un aborto HTTP para el usuario `jason`:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml@
    {{< /text >}}

1. Confirme que la regla fue creada:

    {{< text bash yaml >}}
    $ kubectl get virtualservice ratings -o yaml
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    ...
    spec:
      hosts:
      - ratings
      http:
      - fault:
          abort:
            httpStatus: 500
            percentage:
              value: 100
        match:
        - headers:
            end-user:
              exact: jason
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

## Probar la configuración de aborto

1. Abra la aplicación web [Bookinfo](/es/docs/examples/bookinfo) en su navegador.

1. En la `/productpage`, inicie sesión como usuario `jason`.

    Si la regla se propagó correctamente a todos los pods, la página se carga
    inmediatamente y aparece el mensaje `El service de calificaciones no está disponible actualmente`.

1. Si cierra la sesión del usuario `jason` o abre la aplicación Bookinfo en una ventana anónima
   (o en otro navegador), verá que `/productpage` todavía llama a `reviews:v1`
   (que no llama a `ratings` en absoluto) para todos excepto para `jason`. Por lo tanto, no
   verá ningún mensaje de error.

## Limpieza

1. Elimine las reglas de enrutamiento de la aplicación:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. Si no planea explorar ninguna tarea de seguimiento, consulte las
[instrucciones de limpieza de Bookinfo](/es/docs/examples/bookinfo/#cleanup)
para apagar la application.
