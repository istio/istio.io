---
title: Visualizando su Malla
description: Esta tarea muestra cómo visualizar sus services dentro de un mesh de Istio.
weight: 49
keywords: [telemetry,visualization]
aliases:
 - /docs/tasks/telemetry/kiali/
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

Esta tarea muestra cómo visualizar diferentes aspectos de su mesh de Istio.
Como parte de esta tarea, instalará el addon [Kiali](https://www.kiali.io)
y utilizará la interfaz gráfica de usuario basada en web para ver los gráficos de service de
la mesh y sus objetos de configuración de Istio.

{{< idea >}}
Esta tarea no cubre todas las features proporcionadas por Kiali.
Para obtener información sobre el conjunto completo de features que admite,
consulte el [sitio web de Kiali](https://kiali.io/docs/features/).
{{< /idea >}}

Esta tarea utiliza la application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/) como ejemplo. Esta tarea
asume que la application Bookinfo está instalada en el namespace `bookinfo`.

## Antes de empezar

Siga la documentación de [instalación de Kiali](/es/docs/ops/integrations/kiali/#installation) para desplegar Kiali en su cluster.

## Generar un gráfico

1.  Para verificar que el service se está ejecutando en su cluster, ejecute el siguiente comando:

    {{< text bash >}}
    $ kubectl -n istio-system get svc kiali
    {{< /text >}}

1.  Para determinar la URL de Bookinfo, siga las instrucciones para determinar la [IP de ingress y el puerto de Bookinfo `GATEWAY_URL`](/es/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

1.  Para enviar tráfico a la mesh, tiene tres opciones

    *   Visite `http://$GATEWAY_URL/productpage` en su navegador web

    *   Use el siguiente comando varias veces:

        {{< text bash >}}
        $ curl http://$GATEWAY_URL/productpage
        {{< /text >}}

    *   Si instaló el comando `watch` en su sistema, envíe solicitudes continuamente con:

        {{< text bash >}}
        $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
        {{< /text >}}

1.  Para abrir la UI de Kiali, ejecute el siguiente comando en su entorno Kubernetes:

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1.  Vea la descripción general de su mesh en la página **Overview** que aparece inmediatamente después de iniciar sesión.
    La página **Overview** muestra todos los namespaces que tienen services en su malla.
    La siguiente captura de pantalla muestra una página similar:

    {{< image width="75%"
        link="./kiali-overview.png"
        caption="Ejemplo de Descripción General" >}}

1.  Para ver un gráfico de namespace, seleccione la opción `Graph` en el menú kebab de la tarjeta de descripción general de Bookinfo. El menú kebab
    está en la parte superior derecha de la tarjeta y parece 3 puntos verticales. Haga clic en él para ver las opciones disponibles.
    La página se parece a:

    {{< image width="75%"
        link="./kiali-graph.png"
        caption="Ejemplo de Gráfico" >}}

1.  El gráfico representa el tráfico que fluye a través de la service mesh durante un período de tiempo. Se genera utilizando
    la telemetría de Istio.

1.  Para ver un resumen de las métricas, seleccione cualquier nodo o borde en el gráfico para mostrar
    sus detalles de métricas en el panel de detalles de resumen a la derecha.

1.  Para ver su service mesh usando diferentes tipos de gráficos, seleccione un tipo de gráfico
    del menú desplegable **Graph Type**. Hay varios tipos de gráficos
    para elegir: **App**, **Versioned App**, **Workload**, **Service**.

    *   El tipo de gráfico **App** agrega todas las versiones de una app en un solo nodo de gráfico.
        El siguiente ejemplo muestra un solo nodo **reviews** que representa las tres versiones
        de la app de reviews. Tenga en cuenta que la opción de visualización `Show Service Nodes` se ha deshabilitado.

        {{< image width="75%"
            link="./kiali-app.png"
            caption="Ejemplo de Gráfico de App" >}}

    *   El tipo de gráfico **Versioned App** muestra un nodo para cada versión de una app,
        pero todas las versiones de una app en particular se agrupan. El siguiente ejemplo
        muestra el cuadro de grupo **reviews** que contiene los tres nodos que representan las
        tres versiones de la app de reviews.

        {{< image width="75%"
            link="./kiali-versionedapp.png"
            caption="Ejemplo de Gráfico de App Versionada" >}}

    *   El tipo de gráfico **Workload** muestra un nodo para cada workload en su service mesh.
        Este tipo de gráfico no requiere que use las etiquetas `app` y `version`, por lo que si
        opta por no usar esas etiquetas en sus componentes, este puede ser su tipo de gráfico preferido.

        {{< image width="70%"
            link="./kiali-workload.png"
            caption="Ejemplo de Gráfico de Workload" >}}

    *   El tipo de gráfico **Service** muestra una agregación de alto nivel del tráfico de service en su malla.

        {{< image width="70%"
            link="./kiali-service-graph.png"
            caption="Ejemplo de Gráfico de Service" >}}

## Examinar la configuración de Istio

1.  Las opciones del menú izquierdo conducen a vistas de lista para **Applications**, **Workloads**, **Services** y
    **Istio Config**.
    La siguiente captura de pantalla muestra la información de **Services** para el namespace Bookinfo:

    {{< image width="80%"
        link="./kiali-services.png"
        caption="Ejemplo de Detalles" >}}

## Desplazamiento de Tráfico

Puede usar el asistente de desplazamiento de tráfico de Kiali para definir el porcentaje específico de
tráfico de solicitud que se enrutará a dos o más workloads.

1.  Vea el **gráfico de la aplicación versionada** del gráfico `bookinfo`.

    *   Asegúrese de haber habilitado la opción **Traffic Distribution** Edge Label **Display** para ver
        el porcentaje de tráfico enrutado a cada workload.

    *   Asegúrese de haber habilitado la opción Show **Service Nodes** **Display**
        para ver los nodos de service en el gráfico.

    {{< image width="80%"
        link="./kiali-wiz0-graph-options.png"
        caption="Opciones del Gráfico de Bookinfo" >}}

1.  Concéntrese en el service `ratings` dentro del gráfico `bookinfo` haciendo clic en el nodo del service `ratings` (triángulo).
    Observe que el tráfico del service `ratings` se distribuye uniformemente a los dos workloads `ratings` `v1` y `v2`
    (el 50% de las solicitudes se enrutan a cada workload).

    {{< image width="80%"
        link="./kiali-wiz1-graph-ratings-percent.png"
        caption="Gráfico que Muestra el Porcentaje de Tráfico" >}}

1.  Haga clic en el enlace **ratings** que se encuentra en el panel lateral para ir a la vista detallada del service `ratings`. Esto
    también se podría hacer haciendo clic secundario en el nodo del service `ratings` y seleccionando `Details` en el menú contextual.

1.  En el menú desplegable **Actions**, seleccione **Traffic Shifting** para acceder al asistente de desplazamiento de tráfico.

    {{< image width="80%"
        link="./kiali-wiz2-ratings-service-action-menu.png"
        caption="Menú de Acciones del Service" >}}

1.  Arrastre los controles deslizantes para especificar el porcentaje de tráfico que se enrutará a cada workload.
    Para `ratings-v1`, configúrelo en 10%; para `ratings-v2`, configúrelo en 90%.

    {{< image width="80%"
        link="./kiali-wiz3-traffic-shifting-wizard.png"
        caption="Asistente de Enrutamiento Ponderado" >}}

1.  Haga clic en el botón **Preview** para ver el YAML que generará el asistente.

    {{< image width="80%"
        link="./kiali-wiz3b-traffic-shifting-wizard-preview.png"
        caption="Vista Previa del Asistente de Enrutamiento" >}}

1.  Haga clic en el botón **Create** y confirme para aplicar la nueva configuración de tráfico.

1.  Haga clic en **Graph** en la barra de navegación izquierda para volver al gráfico `bookinfo`. Observe que el
    nodo del service `ratings` ahora tiene la insignia del icono de `virtual service`.

1.  Envíe solicitudes a la application `bookinfo`. Por ejemplo, para enviar una solicitud por segundo,
    puede ejecutar este comando si tiene `watch` instalado en su sistema:

    {{< text bash >}}
    $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
    {{< /text >}}

1.  Después de unos minutos, notará que el porcentaje de tráfico reflejará la nueva ruta de tráfico,
    confirmando así el hecho de que su nueva ruta de tráfico está enrutando con éxito el 90% de todas las solicitudes
    de tráfico a `ratings-v2`.

    {{< image width="80%"
        link="./kiali-wiz4-traffic-shifting-90-10.png"
        caption="90% del Tráfico de Ratings Enrutado a ratings-v2" >}}

## Validar la configuración de Istio

Kiali puede validar sus recursos de Istio para asegurar que sigan las convenciones y semánticas adecuadas. Cualquier problema detectado en la configuración de sus recursos de Istio puede ser marcado como errores o advertencias dependiendo de la gravedad de la configuración incorrecta. Consulte la [página de validaciones de Kiali](https://kiali.io/docs/features/validations/) para ver la lista de todas las comprobaciones de validación que realiza Kiali.

{{< idea >}}
Istio proporciona `istioctl analyze` que ofrece análisis de una manera que se puede utilizar en una pipeline de CI. Los dos enfoques pueden ser complementarios.
{{< /idea >}}

Fuerce una configuración inválida del nombre de puerto de un service para ver cómo Kiali informa un error de validación.

1.  Cambie el nombre del puerto del service `details` de `http` a `foo`:

    {{< text bash >}}
    $ kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"foo"}]'
    {{< /text >}}

1.  Navegue a la lista de **Services** haciendo clic en **Services** en la barra de navegación izquierda.

1.  Seleccione `bookinfo` en el menú desplegable **Namespace** si aún no está seleccionado.

1.  Observe el icono de error que se muestra en la columna **Configuration** de la fila `details`.

    {{< image width="80%"
        link="./kiali-validate1-list.png"
        caption="Lista de Services que Muestra Configuración Inválida" >}}

1.  Haga clic en el enlace **details** en la columna **Name** para navegar a la vista de detalles del service.

1.  Pase el cursor sobre el icono de error para mostrar una sugerencia que describe el error.

    {{< image width="80%"
        link="./kiali-validate2-errormsg.png"
        caption="Detalles del Service que Describen la Configuración Inválida" >}}

1.  Cambie el nombre del puerto de nuevo a `http` para corregir la configuración y devolver `bookinfo` a su estado normal.

    {{< text bash >}}
    $ kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"http"}]'
    {{< /text >}}

    {{< image width="80%"
        link="./kiali-validate3-ok.png"
        caption="Detalles del Service que Muestran Configuración Válida" >}}

## Ver y editar el YAML de configuración de Istio

Kiali proporciona un editor YAML para ver y editar los recursos de configuración de Istio. El editor YAML también proporcionará mensajes de validación cuando detecte configuraciones incorrectas.

1.  Introduzca un error en el VirtualService `bookinfo`

    {{< text bash >}}
    $ kubectl patch vs bookinfo -n bookinfo --type json -p '[{"op":"replace","path":"/spec/gateways/0", "value":"bookinfo-gateway-invalid"}]'
    {{< /text >}}

1.  Haga clic en `Istio Config` en la barra de navegación izquierda para navegar a la lista de configuración de Istio.

1.  Seleccione `bookinfo` en el menú desplegable **Namespace** si aún no está seleccionado.

1.  Observe el icono de error que le alerta de un problema de configuración.

    {{< image width="80%"
        link="./kiali-istioconfig0-errormsgs.png"
        caption="Lista de Configuración de Istio con Configuración Incorrecta" >}}

1.  Haga clic en el icono de error en la columna **Configuration** de la fila `bookinfo` para navegar a la vista del virtual service `bookinfo`.

1.  La pestaña **YAML** está preseleccionada. Observe los resaltados de color y los iconos en las filas que tienen notificaciones de verificación de validación asociadas.

    {{< image width="80%"
        link="./kiali-istioconfig3-details-yaml1.png"
        caption="Editor YAML que Muestra Notificaciones de Validación" >}}

1.  Pase el cursor sobre el icono rojo para ver el mensaje de la sugerencia que le informa de la verificación de validación que activó el error.
    Para obtener más detalles sobre la causa del error y cómo resolverlo, busque el mensaje de error de validación en la [página de Validaciones de Kiali](https://kiali.io/docs/features/validations/).

    {{< image width="80%"
        link="./kiali-istioconfig3-details-yaml3.png"
        caption="Editor YAML que Muestra la Sugerencia de Error" >}}

1.  Restablezca el virtual service `bookinfo` a su estado original.

    {{< text bash >}}
    $ kubectl patch vs bookinfo -n bookinfo --type json -p '[{"op":"replace","path":"/spec/gateways/0", "value":"bookinfo-gateway"}]'
    {{< /text >}}

## Features Adicionales

Kiali tiene muchas más features de las revisadas en esta tarea, como una [integración con el trazado de Jaeger](https://kiali.io/docs/features/tracing/).

Para obtener más detalles sobre estas features adicionales, consulte la [documentación de Kiali](https://kiali.io/docs/features/).

Para una exploración más profunda de Kiali, se recomienda realizar el [Tutorial de Kiali](https://kiali.io/docs/tutorials/).

## Limpieza

Si no planea realizar ninguna tarea de seguimiento, elimine la application de ejemplo Bookinfo y Kiali de su cluster.

1. Para eliminar la application Bookinfo, consulte las instrucciones de [limpieza de Bookinfo](/es/docs/examples/bookinfo/#cleanup).

1. Para eliminar Kiali de un entorno Kubernetes:

    {{< text bash >}}
    $ kubectl delete -f {{< github_file >}}/samples/addons/kiali.yaml
    {{< /text >}}
