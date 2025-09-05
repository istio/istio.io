---
title: Autorización Externa
description: Muestra cómo integrar y delegar el control de acceso a un sistema de autorización externo.
weight: 35
keywords: [security,access-control,rbac,authorization,custom, opa, oauth, oauth2-proxy]
owner: istio/wg-security-maintainers
test: yes
---

Esta tarea muestra cómo configurar una política de autorización de Istio utilizando un nuevo valor para el [campo de acción](/es/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action), `CUSTOM`,
para delegar el control de acceso a un sistema de autorización externo. Esto se puede utilizar para integrar con [autorización OPA](https://www.openpolicyagent.org/docs/envoy),
[`oauth2-proxy`](https://github.com/oauth2-proxy/oauth2-proxy), su propio servidor de autorización externo personalizado y más.

## Antes de empezar

Antes de comenzar esta tarea, haga lo siguiente:

* Lea los [conceptos de autorización de Istio](/es/docs/concepts/security/#authorization).

* Siga la [guía de instalación de Istio](/es/docs/setup/install/istioctl/) para instalar Istio.

* Despliegue workloads de prueba:

    Esta tarea utiliza dos workloads, `httpbin` y `curl`, ambos desplegados en el namespace `foo`.
    Ambos workloads se ejecutan con un proxy Envoy sidecar. Despliegue el namespace `foo`
    y los workloads con el siguiente comando:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label ns foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    $ kubectl apply -f @samples/curl/curl.yaml@ -n foo
    {{< /text >}}

* Verifique que `curl` puede acceder a `httpbin` con el siguiente comando:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{\http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
Si no ve la salida esperada mientras sigue la tarea, inténtelo de nuevo después de unos segundos.
La sobrecarga de caché y propagación puede causar algún retraso.
{{< /warning >}}

## Desplegar el autorizador externo

Primero, debe desplegar el autorizador externo. Para ello, simplemente desplegará el autorizador externo de ejemplo en un pod independiente en la mesh.

1. Ejecute el siguiente comando para desplegar el autorizador externo de ejemplo:

    {{< text bash >}}
    $ kubectl apply -n foo -f {{< github_file >}}/samples/extauthz/ext-authz.yaml
    service/ext-authz created
    deployment.apps/ext-authz created
    {{< /text >}}

1. Verifique que el autorizador externo de ejemplo está en funcionamiento:

    {{< text bash >}}
    $ kubectl logs "$(kubectl get pod -l app=ext-authz -n foo -o jsonpath={.items..metadata.name})" -n foo -c ext-authz
    2021/01/07 22:55:47 Starting HTTP server at [::]:8000
    2021/01/07 22:55:47 Starting gRPC server at [::]:9000
    {{< /text >}}

Alternativamente, también puede desplegar el autorizador externo como un contenedor separado en el mismo pod de la aplicación
que necesita la autorización externa o incluso desplegarlo fuera de la mesh. En cualquier caso, también deberá crear un
recurso de entrada de service para registrar el service en la mesh y asegurarse de que sea accesible para el proxy.

El siguiente es un ejemplo de entrada de service para un autorizador externo desplegado en un contenedor separado en el mismo pod
de la aplicación que necesita la autorización externa.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-authz-grpc-local
spec:
  hosts:
  - "external-authz-grpc.local" # El nombre del service a usar en el proveedor de extensión en la configuración de la mesh.
  endpoints:
  - address: "127.0.0.1"
  ports:
  - name: grpc
    number: 9191 # El número de puerto a usar en el proveedor de extensión en la configuración de la mesh.
    protocol: GRPC
  resolution: STATIC
{{< /text >}}

## Definir el autorizador externo

Para utilizar la acción `CUSTOM` en la política de autorización, debe definir el autorizador externo que está permitido
utilizar en la mesh. Esto se define actualmente en el [proveedor de extensión](https://github.com/istio/api/blob/a205c627e4b955302bbb77dd837c8548e89e6e64/mesh/v1alpha1/config.proto#L534)
en la configuración de la mesh.

Actualmente, el único tipo de proveedor de extensión compatible es el proveedor [Envoy `ext_authz`](https://www.envoyproxy.io/docs/envoy/v1.16.2/intro/arch_overview/security/ext_authz_filter).
El autorizador externo debe implementar la API de verificación `ext_authz` de Envoy correspondiente.

En esta tarea, utilizará un [autorizador externo de ejemplo]({{< github_tree >}}/samples/extauthz) que
permite solicitudes con la cabecera `x-ext-authz: allow`.

1. Edite la configuración de la mesh con el siguiente comando:

    {{< text bash >}}
    $ kubectl edit configmap istio -n istio-system
    {{< /text >}}

1. En el editor, agregue las definiciones de proveedor de extensión que se muestran a continuación:

    El siguiente contenido define dos proveedores externos `sample-ext-authz-grpc` y `sample-ext-authz-http` utilizando el
    mismo service `ext-authz.foo.svc.cluster.local`. El service implementa tanto la API de verificación HTTP como gRPC según lo definido por
    el filtro `ext_authz` de Envoy. Desplegará el service en el siguiente paso.

    {{< text yaml >}}
    data:
      mesh: |-
        # Agregue el siguiente contenido para definir los autorizadores externos.
        extensionProviders:
        - name: "sample-ext-authz-grpc"
          envoyExtAuthzGrpc:
            service: "ext-authz.foo.svc.cluster.local"
            port: "9000"
        - name: "sample-ext-authz-http"
          envoyExtAuthzHttp:
            service: "ext-authz.foo.svc.cluster.local"
            port: "8000"
            includeRequestHeadersInCheck: ["x-ext-authz"]
    {{< /text >}}

    Alternativamente, puede modificar el proveedor de extensión para controlar el comportamiento del filtro `ext_authz` para cosas como
    qué cabeceras enviar al autorizador externo, qué cabeceras enviar al backend de la aplicación, el estado a devolver
    en caso de error y más.
    Por ejemplo, lo siguiente define un proveedor de extensión que se puede utilizar con [`oauth2-proxy`](https://github.com/oauth2-proxy/oauth2-proxy):

    {{< text yaml >}}
    data:
      mesh: |-
        extensionProviders:
        - name: "oauth2-proxy"
          envoyExtAuthzHttp:
            service: "oauth2-proxy.foo.svc.cluster.local"
            port: "4180" # El puerto predeterminado utilizado por oauth2-proxy.
            includeRequestHeadersInCheck: ["authorization", "cookie"] # cabeceras enviadas a oauth2-proxy en la solicitud de verificación.
            headersToUpstreamOnAllow: ["authorization", "path", "x-auth-request-user", "x-auth-request-email", "x-auth-request-access-token"] # cabeceras enviadas al backend de la aplicación cuando se permite la solicitud.
            headersToDownstreamOnAllow: ["set-cookie"] # cabeceras enviadas de vuelta al cliente cuando se permite la solicitud.
            headersToDownstreamOnDeny: ["content-type", "set-cookie"] # cabeceras enviadas de vuelta al cliente cuando se deniega la solicitud.
    {{< /text >}}

## Habilitar con autorización externa

El autorizador externo ya está listo para ser utilizado por la política de autorización.

1. Habilite la autorización externa con el siguiente comando:

    El siguiente comando aplica una política de autorización con el valor de acción `CUSTOM` para el workload `httpbin`. La política habilita la autorización externa para
    las solicitudes a la ruta `/headers` utilizando el autorizador externo definido por `sample-ext-authz-grpc`.

    {{< text bash >}}
    $ kubectl apply -n foo -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: ext-authz
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: CUSTOM
      provider:
        # El nombre del proveedor debe coincidir con el proveedor de extensión definido en la configuración de la mesh.
        # También puede reemplazar esto con sample-ext-authz-http para probar la otra definición de autorizador externo.
        name: sample-ext-authz-grpc
      rules:
      # Las reglas especifican cuándo activar el autorizador externo.
      - to:
        - operation:
            paths: ["/headers"]
    EOF
    {{< /text >}}

    En tiempo de ejecución, las solicitudes a la ruta `/headers` del workload `httpbin` serán pausadas por el filtro `ext_authz`, y una
    solicitud de verificación será enviada al autorizador externo para decidir si la solicitud debe ser permitida o denegada.

1. Verifique que una solicitud a la ruta `/headers` con la cabecera `x-ext-authz: deny` es denegada por el servidor `ext_authz` de ejemplo:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -H "x-ext-authz: deny" -s
    denied by ext_authz for not found header `x-ext-authz: allow` in the request
    {{< /text >}}

1. Verifique que una solicitud a la ruta `/headers` con la cabecera `x-ext-authz: allow` es permitida por el servidor `ext_authz` de ejemplo:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -H "x-ext-authz: allow" -s | jq '.headers'
    ...
      "X-Ext-Authz-Check-Result": [
        "allowed"
      ],
    ...
    {{< /text >}}

1. Verifique que una solicitud a la ruta `/ip` es permitida y no activa la autorización externa:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/ip" -s -o /dev/null -w "%{\http_code}\n"
    200
    {{< /text >}}

1. Verifique el registro del servidor `ext_authz` de ejemplo para confirmar que fue llamado dos veces (para las dos solicitudes). La primera fue permitida y la segunda fue denegada:

    {{< text bash >}}
    $ kubectl logs "$(kubectl get pod -l app=ext-authz -n foo -o jsonpath={.items..metadata.name})" -n foo -c ext-authz
    2021/01/07 22:55:47 Starting HTTP server at [::]:8000
    2021/01/07 22:55:47 Starting gRPC server at [::]:9000
    2021/01/08 03:25:00 [gRPCv3][denied]: httpbin.foo:8000/headers, attributes: source:{address:{socket_address:{address:"10.44.0.22"  port_value:52088}}  principal:"spiffe://cluster.local/ns/foo/sa/curl"}  destination:{address:{socket_address:{address:"10.44.3.30"  port_value:80}}  principal:"spiffe://cluster.local/ns/foo/sa/httpbin"}  request:{time:{seconds:1610076306  nanos:473835000}  http:{id:"13869142855783664817"  method:"GET"  headers:{key:":authority"  value:"httpbin.foo:8000"}  headers:{key:":method"  value:"GET"}  headers:{key:":path"  value:"/headers"}  headers:{key:"accept"  value:"*/*"}  headers:{key:"content-length"  value:"0"}  headers:{key:"user-agent"  value:"curl/7.74.0-DEV"}  headers:{key:"x-b3-sampled"  value:"1"}  headers:{key:"x-b3-spanid"  value:"377ba0cdc2334270"}  headers:{key:"x-b3-traceid"  value:"635187cb20d92f62377ba0cdc2334270"}  headers:{key:"x-envoy-attempt-count"  value:"1"}  headers:{key:"x-ext-authz"  value:"deny"}  headers:{key:"x-forwarded-client-cert"  value:"By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=dd14782fa2f439724d271dbed846ef843ff40d3932b615da650d028db655fc8d;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/curl"}  headers:{key:"x-forwarded-proto"  value:"http"}  headers:{key:"x-request-id"  value:"9609691a-4e9b-9545-ac71-3889bc2dffb0"}  path:"/headers"  host:"httpbin.foo:8000"  protocol:"HTTP/1.1"}}  metadata_context:{}
    2021/01/08 03:25:06 [gRPCv3][allowed]: httpbin.foo:8000/headers, attributes: source:{address:{socket_address:{address:"10.44.0.22"  port_value:52184}}  principal:"spiffe://cluster.local/ns/foo/sa/curl"}  destination:{address:{socket_address:{address:"10.44.3.30"  port_value:80}}  principal:"spiffe://cluster.local/ns/foo/sa/httpbin"}  request:{time:{seconds:1610076300  nanos:925912000}  http:{id:"17995949296433813435"  method:"GET"  headers:{key:":authority"  value:"httpbin.foo:8000"}  headers:{key:":method"  value:"GET"}  headers:{key:":path"  value:"/headers"}  headers:{key:"accept"  value:"*/*"}  headers:{key:"content-length"  value:"0"}  headers:{key:"user-agent"  value:"curl/7.74.0-DEV"}  headers:{key:"x-b3-sampled"  value:"1"}  headers:{key:"x-b3-spanid"  value:"a66b5470e922fa80"}  headers:{key:"x-b3-traceid"  value:"300c2f2b90a618c8a66b5470e922fa80"}  headers:{key:"x-envoy-attempt-count"  value:"1"}  headers:{key:"x-ext-authz"  value:"allow"}  headers:{key:"x-forwarded-client-cert"  value:"By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=dd14782fa2f439724d271dbed846ef843ff40d3932b615da650d028db655fc8d;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/curl"}  headers:{key:"x-forwarded-proto"  value:"http"}  headers:{key:"x-request-id"  value:"2b62daf1-00b9-97d9-91b8-ba6194ef58a4"}  path:"/headers"  host:"httpbin.foo:8000"  protocol:"HTTP/1.1"}}  metadata_context:{}
    {{< /text >}}

    También puede ver en el registro que mTLS está habilitado para la conexión entre el filtro `ext-authz` y el
    servidor `ext-authz` de ejemplo porque el principal de origen se rellena con el valor `spiffe://cluster.local/ns/foo/sa/curl`.

    Ahora puede aplicar otra política de autorización para el servidor `ext-authz` de ejemplo para controlar quién puede acceder a él.

## Limpieza

1. Elimine el namespace `foo` de su configuración:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

1. Elimine la definición del proveedor de extensión de la configuración de la mesh.

## Expectativas de rendimiento

Consulte [benchmarking de rendimiento](https://github.com/istio/tools/tree/master/perf/benchmark/configs/istio/ext_authz).
