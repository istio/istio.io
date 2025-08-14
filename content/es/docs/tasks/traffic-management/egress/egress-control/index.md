---
title: Acceso a Services Externos
description: Describe cómo configurar Istio para enrutar el tráfico de services en la mesh a servicios externos.
weight: 10
aliases:
    - /docs/tasks/egress.html
    - /docs/tasks/egress
keywords: [traffic-management,egress]
owner: istio/wg-networking-maintainers
test: yes
---

Debido a que todo el tráfico saliente de un pod habilitado para Istio se redirige a su proxy sidecar por defecto,
la accesibilidad de las URLs fuera del cluster depende de la configuración del proxy.
Por defecto, Istio configura el proxy Envoy para pasar las solicitudes a services desconocidos.
Aunque esto proporciona una forma conveniente de empezar a usar Istio, configurar
un control más estricto suele ser preferible.

Esta tarea le muestra cómo acceder a services externos de tres maneras diferentes:

1. Permitir que el proxy Envoy pase las solicitudes a services que no están configurados dentro de la mesh.
1. Configurar [entradas de service](/es/docs/reference/config/networking/service-entry/) para proporcionar acceso controlado a services externos.
1. Omitir completamente el proxy Envoy para un rango específico de IPs.

## Antes de empezar

*   Configure Istio siguiendo las instrucciones de la [guía de instalación](/es/docs/setup/).
    Utilice el perfil de [configuración `demo`](/es/docs/setup/additional-setup/config-profiles/) o, de lo contrario,
    [habilite el registro de acceso de Envoy](/es/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging).

*   Despliegue la aplicación de ejemplo [curl]({{< github_tree >}}/samples/curl) para usarla como fuente de prueba para enviar solicitudes.
    Si tiene
    la [inyección automática de sidecar](/es/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
    habilitada, ejecute el siguiente comando para desplegar la aplicación de ejemplo:

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    De lo contrario, inyecte manualmente el sidecar antes de desplegar la aplicación `curl` con el siguiente comando:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    {{< tip >}}
    Puede usar cualquier pod con `curl` instalado como fuente de prueba.
    {{< /tip >}}

*   Establezca la variable de entorno `SOURCE_POD` con el nombre de su pod de origen:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
    {{< /text >}}

## Passthrough de Envoy a services externos

Istio tiene una [opción de instalación](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-OutboundTrafficPolicy-Mode),
`meshConfig.outboundTrafficPolicy.mode`, que configura el manejo del sidecar
de services externos, es decir, aquellos services que no están definidos en el service registry interno de Istio.
Si esta opción se establece en `ALLOW_ANY`, el proxy de Istio permite que las llamadas a services desconocidos pasen.
Si la opción se establece en `REGISTRY_ONLY`, el proxy de Istio bloquea cualquier host sin un service HTTP o
una entrada de service definida dentro de la mesh.
`ALLOW_ANY` es el valor predeterminado, lo que le permite comenzar a evaluar Istio rápidamente,
sin controlar el acceso a services externos.
Luego puede decidir [configurar el acceso a services externos](#controlled-access-to-external-services) más tarde.

1.  Para ver este enfoque en acción, debe asegurarse de que su instalación de Istio esté configurada
    con la opción `meshConfig.outboundTrafficPolicy.mode` establecida en `ALLOW_ANY`. A menos que la haya
    establecido explícitamente en modo `REGISTRY_ONLY` cuando instaló Istio, probablemente esté habilitada por defecto.

    Si no está seguro, puede ejecutar el siguiente comando para mostrar la configuración de su malla:

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system -o yaml
    {{< /text >}}

    A menos que vea una configuración explícita de `meshConfig.outboundTrafficPolicy.mode` con el valor `REGISTRY_ONLY`,
    puede estar seguro de que la opción está establecida en `ALLOW_ANY`, que es el único otro valor posible y el predeterminado.

    {{< tip >}}
    Si ha configurado explícitamente el modo `REGISTRY_ONLY`, puede cambiarlo
    volviendo a ejecutar su comando `istioctl install` original con la configuración cambiada, por ejemplo:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.outboundTrafficPolicy.mode=ALLOW_ANY
    {{< /text >}}

    {{< /tip >}}

1.  Realice un par de solicitudes a services HTTPS externos desde el `SOURCE_POD` para confirmar
    respuestas `200` exitosas:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSI https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c curl -- curl -sI https://edition.cnn.com | grep "HTTP/"
    HTTP/2 200
    HTTP/2 200
    {{< /text >}}

¡Felicidades! Ha enviado tráfico de salida desde su mesh con éxito.

Este enfoque simple para acceder a services externos tiene el inconveniente de que se pierde el monitoreo y control de Istio
para el tráfico a services externos. La siguiente sección le muestra cómo monitorear y controlar el acceso de su mesh a
servicios externos.

## Acceso controlado a services externos

Utilizando las configuraciones de `ServiceEntry` de Istio, puede acceder a cualquier service accesible públicamente
desde dentro de su cluster de Istio. Esta sección le muestra cómo configurar el acceso a un service HTTP externo,
[httpbin.org](http://httpbin.org), así como a un service HTTPS externo,
[www.google.com](https://www.google.com) sin perder las features de monitoreo y control de tráfico de Istio.

### Cambiar a la política de bloqueo por defecto

Para demostrar la forma controlada de habilitar el acceso a services externos, debe cambiar la opción
`meshConfig.outboundTrafficPolicy.mode` del modo `ALLOW_ANY` al modo `REGISTRY_ONLY`.

{{< tip >}}
Puede agregar acceso controlado a services que ya son accesibles en modo `ALLOW_ANY`.
De esta manera, puede comenzar a usar las features de Istio en algunos services externos sin bloquear ningún otro.
Una vez que haya configurado todos sus services, puede cambiar el modo a `REGISTRY_ONLY` para bloquear
cualquier otro acceso no intencional.
{{< /tip >}}

1.  Cambie la opción `meshConfig.outboundTrafficPolicy.mode` a `REGISTRY_ONLY`.

    Si utilizó una configuración de `IstioOperator` para instalar Istio, agregue el siguiente campo a su configuración:

    {{< text yaml >}}
    spec:
      meshConfig:
        outboundTrafficPolicy:
          mode: REGISTRY_ONLY
    {{< /text >}}

    De lo contrario, agregue la configuración equivalente a su comando `istioctl install` original, por ejemplo:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> \
                       --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
    {{< /text >}}

1.  Realice un par de solicitudes a services HTTPS externos desde `SOURCE_POD` para verificar que ahora están bloqueados:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sI https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c curl -- curl -sI https://edition.cnn.com | grep "HTTP/"
    command terminated with exit code 35
    command terminated with exit code 35
    {{< /text >}}

    {{< warning >}}
    Puede que la propagación del cambio de configuración tarde un poco, por lo que aún podría obtener conexiones exitosas.
    Espere varios segundos y luego vuelva a intentar el último comando.
    {{< /warning >}}

### Acceder a un service HTTP externo

1.  Cree una `ServiceEntry` para permitir el acceso a un service HTTP externo.

    {{< warning >}}
    La resolución `DNS` se utiliza en la entrada de service a continuación como medida de seguridad. Establecer la resolución en `NONE`
    abre la posibilidad de un ataque. Un cliente malicioso podría fingir que está
    accediendo a `httpbin.org` estableciéndolo en la cabecera `HOST`, mientras que en realidad se conecta a una IP diferente
    (que no está asociada con `httpbin.org`). El proxy sidecar de Istio confiará en la cabecera HOST, y permitirá incorrectamente
    el tráfico, aunque se esté entregando a la dirección IP de un host diferente. Ese host puede ser un sitio malicioso,
    o un sitio legítimo, prohibido por las políticas de seguridad de la mesh.

    Con la resolución `DNS`, el proxy sidecar ignorará la dirección IP de destino original y dirigirá el tráfico
    a `httpbin.org`, realizando una consulta DNS para obtener una dirección IP de `httpbin.org`.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: httpbin-ext
    spec:
      hosts:
      - httpbin.org
      ports:
      - number: 80
        name: http
        protocol: HTTP
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Realice una solicitud al service HTTP externo desde `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sS http://httpbin.org/headers
    {
      "headers": {
        "Accept": "*/*",
        "Host": "httpbin.org",
        ...
        "X-Envoy-Decorator-Operation": "httpbin.org:80/*",
        ...
      }
    }
    {{< /text >}}

    Observe las cabeceras agregadas por el proxy sidecar de Istio: `X-Envoy-Decorator-Operation`.

1.  Verifique el registro del proxy sidecar de `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl logs "$SOURCE_POD" -c istio-proxy | tail
    [2019-01-24T12:17:11.640Z] "GET /headers HTTP/1.1" 200 - 0 599 214 214 "-" "curl/7.60.0" "17fde8f7-fa62-9b39-8999-302324e6def2" "httpbin.org" "35.173.6.94:80" outbound|80||httpbin.org - 35.173.6.94:80 172.30.109.82:55314 -
    {{< /text >}}

    Observe la entrada relacionada con su solicitud HTTP a `httpbin.org/headers`.

### Acceder a un service HTTPS externo

1.  Cree una `ServiceEntry` para permitir el acceso a un service HTTPS externo.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: google
    spec:
      hosts:
      - www.google.com
      ports:
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Realice una solicitud al service HTTPS externo desde `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSI https://www.google.com | grep  "HTTP/"
    HTTP/2 200
    {{< /text >}}

1.  Verifique el registro del proxy sidecar de `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl logs "$SOURCE_POD" -c istio-proxy | tail
    [2019-01-24T12:48:54.977Z] "- - -" 0 - 601 17766 1289 - "-" "-" "-" "-" "172.217.161.36:443" outbound|443||www.google.com 172.30.109.82:59480 172.217.161.36:443 172.30.109.82:59478 www.google.com
    {{< /text >}}

    Observe la entrada relacionada con su solicitud HTTPS a `www.google.com`.

### Gestionar el tráfico a services externos

De forma similar a las solicitudes entre clusters, las reglas de enrutamiento
también se pueden configurar para services externos a los que se accede mediante configuraciones de `ServiceEntry`.
En este ejemplo, se establece una regla de tiempo de espera en las llamadas al service `httpbin.org`.

{{< boilerplate gateway-api-support >}}

1)  Desde dentro del pod que se utiliza como fuente de prueba, realice una solicitud _curl_ al endpoint `/delay` del
    service externo httpbin.org:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- time curl -o /dev/null -sS -w "%{\http_code}\n" http://httpbin.org/delay/5
    200
    real    0m5.024s
    user    0m0.003s
    sys     0m0.003s
    {{< /text >}}

    La solicitud debería devolver 200 (OK) en aproximadamente 5 segundos.

2)  Use `kubectl` para establecer un tiempo de espera de 3s en las llamadas al service externo `httpbin.org`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin-ext
spec:
  hosts:
  - httpbin.org
  http:
  - timeout: 3s
    route:
    - destination:
        host: httpbin.org
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin-ext
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: httpbin-ext
  hostnames:
  - httpbin.org
  rules:
  - timeouts:
      request: 3s
    backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: httpbin.org
      port: 80
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Espere unos segundos, luego realice la solicitud _curl_ nuevamente:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- time curl -o /dev/null -sS -w "%{\http_code}\n" http://httpbin.org/delay/5
    504
    real    0m3.149s
    user    0m0.004s
    sys     0m0.004s
    {{< /text >}}

    Esta vez aparece un 504 (Gateway Timeout) después de 3 segundos.
    Aunque httpbin.org estaba esperando 5 segundos, Istio cortó la solicitud a los 3 segundos.

### Limpieza del acceso controlado a services externos

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry httpbin-ext google
$ kubectl delete virtualservice httpbin-ext --ignore-not-found=true
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry httpbin-ext
$ kubectl delete httproute httpbin-ext --ignore-not-found=true
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Acceso directo a services externos

Si desea omitir completamente Istio para un rango de IP específico,
puede configurar los sidecars de Envoy para evitar que
[intercepten](/es/docs/concepts/traffic-management/)
las solicitudes externas. Para configurar la omisión, cambie `global.proxy.includeIPRanges`
o `global.proxy.excludeIPRanges` [opción de configuración](https://archive.istio.io/v1.4/docs/reference/config/installation-options/) y
actualice el mapa de configuración `istio-sidecar-injector` usando el comando `kubectl apply`. Esto también
se puede configurar en un pod estableciendo las [anotaciones](/es/docs/reference/config/annotations/) correspondientes, como
`traffic.sidecar.istio.io/includeOutboundIPRanges`.
Después de actualizar la configuración de `istio-sidecar-injector`, afecta a todos
los futuros despliegues de pods de aplicación.

{{< warning >}}
A diferencia del [passthrough de Envoy a services externos](/es/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services),
que utiliza la política de tráfico `ALLOW_ANY` para indicar al proxy sidecar de Istio que
pase las llamadas a services desconocidos,
este enfoque omite completamente el sidecar, deshabilitando esencialmente todas las features de Istio
para las IPs especificadas. No puede agregar incrementalmente entradas de service para destinos
específicos, como puede hacerlo con el enfoque `ALLOW_ANY`.
Por lo tanto, este enfoque de configuración solo se recomienda como último recurso
cuando, por razones de rendimiento u otras, el acceso externo no se puede configurar utilizando el sidecar.
{{< /warning >}}

Una forma sencilla de excluir todas las IPs externas de ser redirigidas al proxy sidecar es
establecer la opción de configuración `global.proxy.includeIPRanges` en el rango o rangos de IP
utilizados para los services internos del cluster.
Estos valores de rango de IP dependen de la plataforma donde se ejecuta su cluster.

### Determinar los rangos de IP internos para su plataforma

Establezca el valor de `values.global.proxy.includeIPRanges` de acuerdo con su proveedor de cluster.

#### IBM Cloud Private

1.  Obtenga su `service_cluster_ip_range` del fichero de configuración de IBM Cloud Private en `cluster/config.yaml`:

    {{< text bash >}}
    $ grep service_cluster_ip_range cluster/config.yaml
    {{< /text >}}

    La siguiente es una salida de ejemplo:

    {{< text plain >}}
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  Use `--set values.global.proxy.includeIPRanges="10.0.0.1/24"

#### IBM Cloud Kubernetes Service

Para ver qué CIDR se utiliza en el cluster, use `ibmcloud ks cluster get -c <CLUSTER-NAME>` y busque el `Service Subnet`:

{{< text bash >}}
$ ibmcloud ks cluster get -c my-cluster | grep "Service Subnet"
Service Subnet:                 172.21.0.0/16
{{< /text >}}

Luego use `--set values.global.proxy.includeIPRanges="172.21.0.0/16"

{{< warning >}}
En clusters muy antiguos, esto puede no funcionar, por lo que puede usar `--set values.global.proxy.includeIPRanges="172.30.0.0/16,172.21.0.0/16,10.10.10.0/24"` o usar `kubectl get svc -o wide -A` para acotar aún más el valor CIDR para la configuración.
{{< /warning >}}

#### Google Kubernetes Engine (GKE)

Los rangos no son fijos, por lo que deberá ejecutar el comando `gcloud container clusters describe` para determinar los
rangos a usar. Por ejemplo:

{{< text bash >}}
$ gcloud container clusters describe XXXXXXX --zone=XXXXXX | grep -e clusterIpv4Cidr -e servicesIpv4Cidr
clusterIpv4Cidr: 10.4.0.0/14
servicesIpv4Cidr: 10.7.240.0/20
{{< /text >}}

Use `--set values.global.proxy.includeIPRanges="10.4.0.0/14\,10.7.240.0/20"

#### Azure Kubernetes Service (AKS)

##### Kubenet

Para ver qué CIDR de service y CIDR de pod se utilizan en el cluster, use `az aks show` y busque el `serviceCidr`:

{{< text bash >}}
$ az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep Cidr
    "podCidr": "10.244.0.0/16",
    "podCidrs": [
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
{{< /text >}}

Luego use `--set values.global.proxy.includeIPRanges="10.244.0.0/16\,10.0.0.0/16"

##### Azure CNI

Siga estos pasos si está utilizando Azure CNI con un modo de red sin superposición. Si utiliza Azure CNI con red de superposición, siga las [instrucciones de Kubenet](#kubenet). Para obtener más información, consulte la [documentación de Azure CNI Overlay](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay).

Para ver qué CIDR de service se utiliza en el cluster, use `az aks show` y busque el `serviceCidr`:

{{< text bash >}}
$ az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep serviceCidr
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
{{< /text >}}

Para ver qué CIDR de pod se utiliza en el cluster, use la CLI de `az` para inspeccionar la `vnet`:

{{< text bash >}}
$ az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep nodeResourceGroup
  "nodeResourceGroup": "MC_user-rg_user-cluster_region",
  "nodeResourceGroupProfile": null,
$ az network vnet list -g MC_user-rg_user-cluster_region | grep name
    "name": "aks-vnet-74242220",
        "name": "aks-subnet",
$ az network vnet show -g MC_user-rg_user-cluster_region -n aks-vnet-74242220 | grep addressPrefix
    "addressPrefixes": [
      "addressPrefix": "10.224.0.0/16",
{{< /text >}}

Luego use `--set values.global.proxy.includeIPRanges="10.244.0.0/16\,10.0.0.0/16"

#### Minikube, Docker For Desktop, Bare Metal

El valor predeterminado es `10.96.0.0/12`, pero no es fijo. Use el siguiente comando para determinar su valor real:

{{< text bash >}}
$ kubectl describe pod kube-apiserver -n kube-system | grep 'service-cluster-ip-range'
      --service-cluster-ip-range=10.96.0.0/12
{{< /text >}}

Use `--set values.global.proxy.includeIPRanges="10.96.0.0/12"

### Configuración de la omisión del proxy

{{< warning >}}
Elimine la entrada de service y el virtual service desplegados previamente en esta guía.
{{< /warning >}}

Actualice su mapa de configuración `istio-sidecar-injector` utilizando los rangos de IP específicos de su plataforma.
Por ejemplo, si el rango es 10.0.0.1&#47;24, use el siguiente comando:

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio> --set values.global.proxy.includeIPRanges="10.0.0.1/24"
{{< /text >}}

Use el mismo comando que usó para [instalar Istio](/es/docs/setup/install/istioctl) y
agregue `--set values.global.proxy.includeIPRanges="10.0.0.1/24"

### Acceder a los services externos

Debido a que la configuración de omisión solo afecta a los nuevos despliegues, debe terminar y luego volver a desplegar la aplicación `curl`
como se describe en la sección [Antes de empezar](#before-you-begin).

Después de actualizar el configmap `istio-sidecar-injector` y volver a desplegar la aplicación `curl`,
el sidecar de Istio solo interceptará y gestionará las solicitudes internas
dentro del cluster. Cualquier solicitud externa omite el sidecar y va directamente a su destino previsto.
Por ejemplo:

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c curl -- curl -sS http://httpbin.org/headers
{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    ...
  }
}
{{< /text >}}

Unlike accessing external services through HTTP or HTTPS, you don't see any headers related to the Istio sidecar and the
requests sent to external services do not appear in the log of the sidecar. Bypassing the Istio sidecars means you can
no longer monitor the access to external services.

### Limpieza del acceso directo a services externos

Actualice la configuración para dejar de omitir los proxies sidecar para un rango de IPs:

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio>
{{< /text >}}

## Comprender lo que sucedió

En esta tarea, examinó tres formas de llamar a services externos desde un mesh de Istio:

1. Configurar Envoy para permitir el acceso a cualquier service externo.

1. Usar una entrada de service para registrar un service externo accesible dentro de la mesh. Este es el
   enfoque recomendado.

1. Configurar el sidecar de Istio para excluir IPs externas de su tabla de IPs remapeadas.

El primer enfoque dirige el tráfico a través del proxy sidecar de Istio, incluidas las llamadas a services
desconocidos dentro de la mesh. Al usar este enfoque,
no puede monitorear el acceso a services externos ni aprovechar las features de control de tráfico de Istio para ellos.
Para cambiar fácilmente al segundo enfoque para services específicos, simplemente cree entradas de service para esos services externos.
Este proceso le permite acceder inicialmente a cualquier service externo y luego
decidir si desea o no controlar el acceso, habilitar el monitoreo de tráfico y usar las features de control de tráfico según sea necesario.

El segundo enfoque le permite usar todas las mismas features de service mesh de Istio para llamadas a services dentro o
fuera del cluster. En esta tarea, aprendió cómo monitorear el acceso a services externos y establecer una regla de tiempo de espera
para las llamadas a un service externo.

El tercer enfoque omite el proxy sidecar de Istio, dando a sus services acceso directo a cualquier servidor externo.
Sin embargo, configurar el proxy de esta manera requiere conocimientos y configuración específicos del proveedor del cluster.
De manera similar al primer enfoque, también pierde el monitoreo del acceso a services externos y no puede aplicar
las features de Istio al tráfico a services externos.

## Nota de seguridad

{{< warning >}}
Tenga en cuenta que los ejemplos de configuración en esta tarea **no habilitan el control seguro del tráfico de salida** en Istio.
Una aplicación maliciosa puede omitir el proxy sidecar de Istio y acceder a cualquier service externo sin el control de Istio.
{{< /warning >}}

Para implementar el control de tráfico de salida de una manera más segura, debe
[dirigir el tráfico de salida a través de un egress gateway](/es/docs/tasks/traffic-management/egress/egress-gateway/)
y revisar las preocupaciones de seguridad descritas en la sección
[consideraciones de seguridad adicionales](/es/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations).

## Limpieza

Apague el service [curl]({{< github_tree >}}/samples/curl):

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
{{< /text >}}
