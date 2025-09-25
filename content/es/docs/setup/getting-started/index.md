---
title: Comenzando
description: Prueba las características de Istio de forma rápida y fácil.
weight: 5
aliases:
    - /docs/setup/additional-setup/getting-started/
    - /latest/docs/setup/additional-setup/getting-started/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes, gateway-api]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
¿Quieres explorar el {{< gloss "ambient" >}}modo ambient{{< /gloss >}} de Istio? ¡Visita la guía de [Comenzando con el Modo Ambient](/es/docs/ambient/getting-started)!
{{< /tip >}}

Esta guía te permite evaluar Istio rápidamente. Si ya estás familiarizado con
Istio o estás interesado en instalar otros perfiles de configuración o
[modelos de deployment](/es/docs/ops/deployment/deployment-models/) avanzados, consulta nuestra
página de FAQ sobre [¿qué método de instalación de Istio debería usar?](/es/about/faq/#install-method-selection).

Necesitarás un cluster de Kubernetes para continuar. Si no tienes un cluster, puedes usar [kind](/es/docs/setup/platform-setup/kind) o cualquier otra [plataforma de Kubernetes soportada](/es/docs/setup/platform-setup).

Sigue estos pasos para comenzar con Istio:

1. [Descargar e instalar Istio](#download)
1. [Instalar los CRDs del API Gateway de Kubernetes](#gateway-api)
1. [Desplegar la aplicación de ejemplo](#bookinfo)
1. [Abrir la aplicación al tráfico externo](#ip)
1. [Ver el panel de control](#dashboard)

## Descargar Istio {#download}

1.  Ve a la página de [releases de Istio]({{< istio_release_url >}}) para
    descargar el archivo de instalación para tu sistema operativo, o [descarga y
    extrae el release más reciente automáticamente](/es/docs/setup/additional-setup/download-istio-release)
    (Linux o macOS):

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

1.  Muévete al directorio del paquete de Istio. Por ejemplo, si el paquete es
    `istio-{{< istio_full_version >}}`:

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    El directorio de instalación contiene:

    - Aplicaciones de ejemplo en `samples/`
    - El binario cliente [`istioctl`](/es/docs/reference/commands/istioctl) en el
      directorio `bin/`.

1.  Agrega el cliente `istioctl` a tu path (Linux o macOS):

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## Instalar Istio {#install}

Para esta guía, usamos el [perfil de configuración](/es/docs/setup/additional-setup/config-profiles/) `demo`. Está
seleccionado para tener un buen conjunto de valores por defecto para pruebas, pero hay otros
perfiles para producción, pruebas de rendimiento o [OpenShift](/es/docs/setup/platform-setup/openshift/).

A diferencia de los [Gateways de Istio](/es/docs/concepts/traffic-management/#gateways), crear
[Gateways de Kubernetes](https://gateway-api.sigs.k8s.io/api-types/gateway/) por defecto también
[desplegará servidores proxy de gateway](/es/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment).
Debido a que no se usarán, deshabilitamos el deployment de los Services gateway predeterminados de Istio que
normalmente se instalan como parte del perfil `demo`.

1. Instala Istio usando el perfil `demo`, sin ningún gateway:

    {{< text bash >}}
    $ istioctl install -f @samples/bookinfo/demo-profile-no-gateways.yaml@ -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Installation complete
    Made this installation the default for injection and validation.
    {{< /text >}}

1.  Agrega una etiqueta de Namespace para instruir a Istio que inyecte automáticamente proxies
    sidecar de Envoy cuando despliegues tu aplicación más adelante:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    namespace/default labeled
    {{< /text >}}

## Instalar los CRDs del API Gateway de Kubernetes {#gateway-api}

Los CRDs del API Gateway de Kubernetes no vienen instalados por defecto en la mayoría de los clusters de Kubernetes, así que asegúrate de que estén
instalados antes de usar el Gateway API.

1. Instala los CRDs del Gateway API, si no están ya presentes:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
    { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

## Desplegar la aplicación de ejemplo {#bookinfo}

Has configurado Istio para inyectar contenedores sidecar en cualquier aplicación que despliegues en tu Namespace `default`.

1.  Despliega la [aplicación de ejemplo `Bookinfo`](/es/docs/examples/bookinfo/):

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    service/details created
    serviceaccount/bookinfo-details created
    deployment.apps/details-v1 created
    service/ratings created
    serviceaccount/bookinfo-ratings created
    deployment.apps/ratings-v1 created
    service/reviews created
    serviceaccount/bookinfo-reviews created
    deployment.apps/reviews-v1 created
    deployment.apps/reviews-v2 created
    deployment.apps/reviews-v3 created
    service/productpage created
    serviceaccount/bookinfo-productpage created
    deployment.apps/productpage-v1 created
    {{< /text >}}

    La aplicación se iniciará. A medida que cada Pod esté listo, el sidecar de Istio será
    desplegado junto con él.

    {{< text bash >}}
    $ kubectl get services
    NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    details       ClusterIP   10.0.0.212      <none>        9080/TCP   29s
    kubernetes    ClusterIP   10.0.0.1        <none>        443/TCP    25m
    productpage   ClusterIP   10.0.0.57       <none>        9080/TCP   28s
    ratings       ClusterIP   10.0.0.33       <none>        9080/TCP   29s
    reviews       ClusterIP   10.0.0.28       <none>        9080/TCP   29s
    {{< /text >}}

    y

    {{< text bash >}}
    $ kubectl get pods
    NAME                              READY   STATUS    RESTARTS   AGE
    details-v1-558b8b4b76-2llld       2/2     Running   0          2m41s
    productpage-v1-6987489c74-lpkgl   2/2     Running   0          2m40s
    ratings-v1-7dc98c7588-vzftc       2/2     Running   0          2m41s
    reviews-v1-7f99cc4496-gdxfn       2/2     Running   0          2m41s
    reviews-v2-7d79d5bd5d-8zzqd       2/2     Running   0          2m41s
    reviews-v3-7dbcdcbc56-m8dph       2/2     Running   0          2m41s
    {{< /text >}}

    Nota que los Pods muestran `READY 2/2`, confirmando que tienen su contenedor de aplicación y el contenedor sidecar de Istio.

1.  Valida que la aplicación esté corriendo dentro del cluster comprobando el título de la página en la respuesta:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Abrir la aplicación al tráfico externo {#ip}

La aplicación Bookinfo está desplegada, pero no es accesible desde el exterior. Para hacerla accesible,
necesitas crear un gateway de ingreso, que mapea un camino a una
ruta en el borde de tu malla.

1.  Crea un [Gateway de Kubernetes](https://gateway-api.sigs.k8s.io/api-types/gateway/) para la aplicación Bookinfo:

    {{< text syntax=bash snip_id=deploy_bookinfo_gateway >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    gateway.gateway.networking.k8s.io/bookinfo-gateway created
    httproute.gateway.networking.k8s.io/bookinfo created
    {{< /text >}}

    Por defecto, Istio crea un servicio `LoadBalancer` para un gateway. Como accederemos a este gateway por un túnel, no necesitamos un balanceador de carga. Si quieres aprender sobre cómo se configuran los balanceadores de carga para direcciones IP externas, lee la documentación sobre [gateways de ingreso](/es/docs/tasks/traffic-management/ingress/ingress-control/).

1. Cambia el tipo de servicio a `ClusterIP` anotando el gateway:

    {{< text syntax=bash snip_id=annotate_bookinfo_gateway >}}
    $ kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
    {{< /text >}}

1. Para verificar el estado del gateway, ejecuta:

    {{< text bash >}}
    $ kubectl get gateway
    NAME               CLASS   ADDRESS                                            PROGRAMMED   AGE
    bookinfo-gateway   istio   bookinfo-gateway-istio.default.svc.cluster.local   True         42s
    {{< /text >}}

## Acceder a la aplicación

Conectarás al servicio `productpage` de Bookinfo a través del gateway que acabas de provisionar. Para acceder al gateway, necesitas usar el comando `kubectl port-forward`:

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway-istio 8080:80
{{< /text >}}

Abre tu navegador y navega a `http://localhost:8080/productpage` para ver la aplicación Bookinfo.

{{< image width="80%" link="./bookinfo-browser.png" caption="Aplicación Bookinfo" >}}

Si refrescas la página, deberías ver que las reseñas y las calificaciones cambian a medida que las solicitudes se distribuyen entre las diferentes versiones del servicio `reviews`.

## Ver el panel de control {#dashboard}

Istio integra con [varias aplicaciones de telemetría](/es/docs/ops/integrations). Estas pueden ayudarte a
entender la estructura de tu meshde servicios, mostrar la topología de la mesh y analizar la salud de tu malla.

Usa las siguientes instrucciones para desplegar el [Kiali](/es/docs/ops/integrations/kiali/), junto con [Prometheus](/es/docs/ops/integrations/prometheus/), [Grafana](/es/docs/ops/integrations/grafana), y [Jaeger](/es/docs/ops/integrations/jaeger/).

1.  Instala [Kiali y los addons]({{< github_tree >}}/samples/addons) y espera a que se desplieguen.

    {{< text bash >}}
    $ kubectl apply -f @samples/addons@
    $ kubectl rollout status deployment/kiali -n istio-system
    Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
    deployment "kiali" successfully rolled out
    {{< /text >}}

1.  Accede al dashboard de Kiali.

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1.  En el menú de navegación izquierdo, selecciona _Graph_ y en el desplegable _Namespace_, selecciona _default_.

    {{< tip >}}
    {{< boilerplate trace-generation >}}
    {{< /tip >}}

    El dashboard de Kiali muestra una vista general de tu meshcon las relaciones
    entre los servicios en la aplicación de ejemplo `Bookinfo`. También proporciona
    filtros para visualizar el flujo de tráfico.

    {{< image link="./kiali-example2.png" caption="Dashboard de Kiali" >}}

## Pasos siguientes

¡Felicitaciones por completar la instalación de evaluación!

Estos son un excelente lugar para que los principiantes evalúen más a fondo las características de Istio usando esta instalación `demo`:

- [Enrutamiento de solicitudes](/es/docs/tasks/traffic-management/request-routing/)
- [Inyección de fallos](/es/docs/tasks/traffic-management/fault-injection/)
- [Cambio de tráfico](/es/docs/tasks/traffic-management/traffic-shifting/)
- [Consultar métricas](/es/docs/tasks/observability/metrics/querying-metrics/)
- [Visualizar métricas](/es/docs/tasks/observability/metrics/using-istio-dashboard/)
- [Acceso a servicios externos](/es/docs/tasks/traffic-management/egress/egress-control/)
- [Visualizar tu malla](/es/docs/tasks/observability/kiali/)

Antes de personalizar Istio para su uso en producción, consulta estos recursos:

- [Modelos de deployment](/es/docs/ops/deployment/deployment-models/)
- [Mejores prácticas de deployment](/es/docs/ops/best-practices/deployment/)
- [Requisitos de Pod](/es/docs/ops/deployment/application-requirements/)
- [Instrucciones de instalación generales](/es/docs/setup/)

## Únete a la comunidad de Istio

¡Te damos la bienvenida a que nos preguntes y nos des tu feedback uniendo la
[comunidad de Istio](/get-involved/).

## Desinstalar

Para eliminar la aplicación de ejemplo `Bookinfo` y su configuración, consulta
[`Bookinfo` limpieza](/es/docs/examples/bookinfo/#cleanup).

La desinstalación de Istio elimina los permisos RBAC y todos los recursos jerárquicamente
bajo el espacio de nombres `istio-system`. Es seguro ignorar errores por recursos inexistentes porque pueden haber sido eliminados jerárquicamente.

{{< text bash >}}
$ kubectl delete -f @samples/addons@
$ istioctl uninstall -y --purge
{{< /text >}}

El espacio de nombres `istio-system` no se elimina por defecto.
Si ya no es necesario, usa el siguiente comando para eliminarlo:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

La etiqueta para instruir a Istio a inyectar automáticamente proxies sidecar no se elimina por defecto.
Si ya no es necesario, usa el siguiente comando para eliminarlo:

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}

Si instalaste los CRDs del API Gateway de Kubernetes y ahora quieres eliminarlos, ejecuta uno de los siguientes comandos:

- Si ejecutaste tareas que requerían la **versión experimental** de los CRDs:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}

- De lo contrario:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}
