---
title: Autorización basada en políticas usando Kyverno
description: Delega la lógica de decisión de autorización de capa 7 usando el Authz Server de Kyverno, aprovechando las políticas basadas en CEL.
publishdate: 2024-11-25
attribution: "Charles-Edouard Brétéché (Nirmata)"
keywords: [istio,kyverno,policy,platform,authorization]
---

Istio admite la integración con muchos proyectos diferentes. El blog de Istio presentó recientemente una publicación sobre la [funcionalidad de políticas L7 con OpenPolicyAgent](../l7-policy-with-opa). Kyverno es un proyecto similar, y hoy profundizaremos en cómo Istio y el Kyverno Authz Server pueden usarse juntos para hacer cumplir las políticas de capa 7 en tu plataforma.

Te mostraremos cómo empezar con un ejemplo simple.
Verás cómo esta combinación es una opción sólida para entregar políticas de forma rápida y transparente al equipo de aplicaciones en todas partes del negocio, al mismo tiempo que proporciona los datos que los equipos de seguridad necesitan para la auditoría y el cumplimiento.

## Pruébalo

Cuando se integra con Istio, el Kyverno Authz Server se puede utilizar para hacer cumplir políticas de control de acceso de grano fino para microservicios.

Esta guía muestra cómo hacer cumplir las políticas de control de acceso para una aplicación de microservicios simple.

### Prerrequisitos

- Un cluster de Kubernetes con Istio instalado.
- La herramienta de línea de comandos `istioctl` instalada.

Instala Istio y configura tus [opciones de malla](/es/docs/reference/config/istio.mesh.v1alpha1/) para habilitar Kyverno:

{{< text bash >}}
$ istioctl install -y -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    accessLogFormat: |
      [KYVERNO DEMO] my-new-dynamic-metadata: '%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%'
    extensionProviders:
    - name: kyverno-authz-server
      envoyExtAuthzGrpc:
        service: kyverno-authz-server.kyverno.svc.cluster.local
        port: '9081'
EOF
{{< /text >}}

Observa que en la configuración, definimos una sección `extensionProviders` que apunta a la instalación del Kyverno Authz Server:

{{< text yaml >}}
[...]
    extensionProviders:
    - name: kyverno-authz-server
      envoyExtAuthzGrpc:
        service: kyverno-authz-server.kyverno.svc.cluster.local
        port: '9081'
[...]
{{< /text >}}

#### Desplegar el Kyverno Authz Server

El Kyverno Authz Server es un servidor GRPC capaz de procesar solicitudes de Autorización Externa de Envoy.

Es configurable usando recursos `AuthorizationPolicy` de Kyverno, ya sea almacenados en el cluster o proporcionados externamente.

{{< text bash >}}
$ kubectl create ns kyverno
$ kubectl label namespace kyverno istio-injection=enabled
$ helm install kyverno-authz-server --namespace kyverno --wait --version 0.1.0 --repo https://kyverno.github.io/kyverno-envoy-plugin kyverno-authz-server
{{< /text >}}

#### Desplegar la aplicación de ejemplo

httpbin es una aplicación conocida que se puede utilizar para probar solicitudes HTTP y ayuda a mostrar rápidamente cómo podemos jugar con los atributos de la solicitud y la respuesta.

{{< text bash >}}
$ kubectl create ns my-app
$ kubectl label namespace my-app istio-injection=enabled
$ kubectl apply -f {{< github_file >}}/samples/httpbin/httpbin.yaml -n my-app
{{< /text >}}

#### Desplegar una AuthorizationPolicy de Istio

Una `AuthorizationPolicy` define los servicios que serán protegidos por el Kyverno Authz Server.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: my-kyverno-authz
  namespace: istio-system # Esto aplica la política en toda la malla, siendo istio-system el namespace raíz de la malla
spec:
  selector:
    matchLabels:
      ext-authz: enabled
  action: CUSTOM
  provider:
    name: kyverno-authz-server
  rules: [{}] # Reglas vacías, se aplicará a los selectores con la etiqueta ext-authz: enabled
EOF
{{< /text >}}

Observa que en este recurso, definimos el `extensionProvider` del Kyverno Authz Server que estableciste en la configuración de Istio:

{{< text yaml >}}
[...]
  provider:
    name: kyverno-authz-server
[...]
{{< /text >}}

#### Etiquetar la aplicación para hacer cumplir la política

Etiquetemos la aplicación para hacer cumplir la política. La etiqueta es necesaria para que la `AuthorizationPolicy` de Istio se aplique a los pods de la aplicación de ejemplo.

{{< text bash >}}
$ kubectl patch deploy httpbin -n my-app --type=merge -p='{
  "spec": {
    "template": {
      "metadata": {
        "labels": {
          "ext-authz": "enabled"
        }
      }
    }
  }
}'
{{< /text >}}

#### Desplegar una AuthorizationPolicy de Kyverno

Una `AuthorizationPolicy` de Kyverno define las reglas utilizadas por el Kyverno Authz Server para tomar una decisión basada en una [CheckRequest](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkrequest) de Envoy dada.

Utiliza el [lenguaje CEL](https://github.com/google/cel-spec) para analizar una `CheckRequest` entrante y se espera que produzca una [CheckResponse](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkresponse) a cambio.

La solicitud entrante está disponible bajo el campo `object`, y la política puede definir `variables` que estarán disponibles para todas las `authorizations`.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  failurePolicy: Fail
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.?headers["x-force-authorized"].orValue("")
  - name: allowed
    expression: variables.force_authorized in ["enabled", "true"]
  authorizations:
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
EOF
{{< /text >}}

Observa que puedes construir la `CheckResponse` a mano o usar [funciones de ayuda de CEL](https://kyverno.github.io/kyverno-envoy-plugin/latest/cel-extensions/) como `envoy.Allowed()` y `envoy.Denied(403)` para simplificar la creación del mensaje de respuesta:

{{< text yaml >}}
[...]
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
[...]
{{< /text >}}

## Cómo funciona

Al aplicar la `AuthorizationPolicy`, el control plane de Istio (istiod) envía las configuraciones requeridas al proxy sidecar (Envoy) de los servicios seleccionados en la política.
Envoy luego enviará la solicitud al Kyverno Authz Server para verificar si la solicitud está permitida o no.

{{< image width="75%" link="./overview.svg" alt="Istio and Kyverno Authz Server" >}}

El proxy Envoy funciona configurando filtros en una cadena. Uno de esos filtros es `ext_authz`, que implementa un servicio de autorización externa con un mensaje específico. Cualquier servidor que implemente el protobuf correcto puede conectarse al proxy Envoy y proporcionar la decisión de autorización; el Kyverno Authz Server es uno de esos servidores.

{{< image link="./filters-chain.svg" alt="Filters" >}}

Revisando la [documentación del servicio de Autorización de Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto), puedes ver que el mensaje tiene estos atributos:

- Respuesta Ok

    {{< text json >}}
    {
      "status": {...},
      "ok_response": {
        "headers": [],
        "headers_to_remove": [],
        "response_headers_to_add": [],
        "query_parameters_to_set": [],
        "query_parameters_to_remove": []
      },
      "dynamic_metadata": {...}
    }
    {{< /text >}}

- Respuesta denegada

    {{< text json >}}
    {
      "status": {...},
      "denied_response": {
        "status": {...},
        "headers": [],
        "body": "..."
      },
      "dynamic_metadata": {...}
    }
    {{< /text >}}

Esto significa que, basándose en la respuesta del servidor authz, Envoy puede agregar o eliminar encabezados, parámetros de consulta e incluso cambiar el cuerpo de la respuesta.

Podemos hacer esto también, como se documenta en la [documentación del Kyverno Authz Server](https://kyverno.github.io/kyverno-envoy-plugin).

## Pruebas

Probemos el uso simple (autorización) y luego creemos una política más avanzada para mostrar cómo podemos usar el Kyverno Authz Server para modificar la solicitud y la respuesta.

Despliega una aplicación para ejecutar comandos curl a la aplicación de ejemplo httpbin:

{{< text bash >}}
$ kubectl apply -n my-app -f {{< github_file >}}/samples/curl/curl.yaml
{{< /text >}}

Aplica la política:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  failurePolicy: Fail
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.?headers["x-force-authorized"].orValue("")
  - name: allowed
    expression: variables.force_authorized in ["enabled", "true"]
  authorizations:
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
EOF
{{< /text >}}

El escenario simple es permitir solicitudes si contienen el encabezado `x-force-authorized` con el valor `enabled` o `true`.
Si el encabezado no está presente o tiene un valor diferente, la solicitud será denegada.

En este caso, combinamos el manejo de respuestas permitidas y denegadas en una sola expresión. Sin embargo, es posible usar múltiples expresiones, la primera que devuelva una respuesta no nula será utilizada por el Kyverno Authz Server, esto es útil cuando una regla no quiere tomar una decisión y delega a la siguiente regla:

{{< text yaml >}}
[...]
  authorizations:
  # permitir la solicitud cuando el valor del encabezado coincide
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : null
  # si no, denegar la solicitud
  - expression: >
      envoy.Denied(403).Response()
[...]
{{< /text >}}

### Regla simple

La siguiente solicitud devolverá `403`:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "
http_code=%{http_code}" httpbin:8000/get
{{< /text >}}

La siguiente solicitud devolverá `200`:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "
http_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

### Manipulaciones avanzadas

Ahora el caso de uso más avanzado, aplica la segunda política:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.headers[?"x-force-authorized"].orValue("") in ["enabled", "true"]
  - name: force_unauthenticated
    expression: object.attributes.request.http.headers[?"x-force-unauthenticated"].orValue("") in ["enabled", "true"]
  - name: metadata
    expression: '{"my-new-metadata": "my-new-value"}'
  authorizations:
    # si force_unauthenticated -> 401
  - expression: >
      variables.force_unauthenticated
        ? envoy
            .Denied(401)
            .WithBody("Authentication Failed")
            .Response()
        : null
    # si force_authorized -> 200
  - expression: >
      variables.force_authorized
        ? envoy
            .Allowed()
            .WithHeader("x-validated-by", "my-security-checkpoint")
            .WithoutHeader("x-force-authorized")
            .WithResponseHeader("x-add-custom-response-header", "added")
            .Response()
            .WithMetadata(variables.metadata)
        : null
    # si no -> 403
  - expression: >
      envoy
        .Denied(403)
        .WithBody("Unauthorized Request")
        .Response()
EOF
{{< /text >}}

En esa política, puedes ver:

- Si la solicitud tiene el encabezado `x-force-unauthenticated: true` (o `x-force-unauthenticated: enabled`), devolveremos `401` con el cuerpo "Authentication Failed"
- Si no, si la solicitud tiene el encabezado `x-force-authorized: true` (o `x-force-authorized: enabled`), devolveremos `200` y manipularemos los encabezados de la solicitud, los encabezados de la respuesta e inyectaremos metadatos dinámicos
- En todos los demás casos, devolveremos `403` con el cuerpo "Unauthorized Request"

La CheckResponse correspondiente se devolverá al proxy Envoy desde el Kyverno Authz Server. Envoy usará esos valores para modificar la solicitud y la respuesta en consecuencia.

#### Cambiar el cuerpo devuelto

Probemos las nuevas capacidades:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "
http_code=%{http_code}" httpbin:8000/get
{{< /text >}}

Ahora podemos cambiar el cuerpo de la respuesta.

Con `403` el cuerpo se cambiará a "Unauthorized Request", ejecutando el comando anterior, deberías recibir:

{{< text plain >}}
Unauthorized Request
http_code=403
{{< /text >}}

#### Cambiar el cuerpo y el código de estado devueltos

Ejecutando la solicitud con el encabezado `x-force-unauthenticated: true`:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "
http_code=%{http_code}" httpbin:8000/get -H "x-force-unauthenticated: true"
{{< /text >}}

Esta vez deberías recibir el cuerpo "Authentication Failed" y el error `401`:

{{< text plain >}}
Authentication Failed
http_code=401
{{< /text >}}

#### Agregar encabezados a la solicitud

Ejecutando una solicitud válida:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "
http_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

Deberías recibir el cuerpo de eco con el nuevo encabezado `x-validated-by: my-security-checkpoint` y el encabezado `x-force-authorized` eliminado:

{{< text plain >}}
[...]
    "X-Validated-By": [
      "my-security-checkpoint"
    ]
[...]
http_code=200
{{< /text >}}

#### Agregar encabezados a la respuesta

Ejecutando la misma solicitud pero mostrando solo el encabezado:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -I -w "
http_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

Encontrarás el encabezado de respuesta agregado durante la verificación de Authz `x-add-custom-response-header: added`:

{{< text plain >}}
HTTP/1.1 200 OK
[...]
x-add-custom-response-header: added
[...]
http_code=200
{{< /text >}}

### Compartir datos entre filtros

Finalmente, puedes pasar datos a los siguientes filtros de Envoy usando `dynamic_metadata`.

Esto es útil cuando quieres pasar datos a otro filtro `ext_authz` en la cadena o quieres imprimirlos en los registros de la aplicación.

{{< image link="./dynamic-metadata.svg" alt="Metadata" >}}

Para hacerlo, revisa el formato del registro de acceso que estableciste anteriormente:

{{< text plain >}}
[...]
    accessLogFormat: |
      [KYVERNO DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
[...]
{{< /text >}}

`DYNAMIC_METADATA` es una palabra clave reservada para acceder al objeto de metadatos. El resto es el nombre del filtro al que quieres acceder.

En nuestro caso, el nombre `envoy.filters.http.ext_authz` es creado automáticamente por Istio. Puedes verificar esto volcando la configuración de Envoy:

{{< text bash >}}
$ istioctl pc all deploy/httpbin -n my-app -oyaml | grep envoy.filters.http.ext_authz
{{< /text >}}

Verás las configuraciones para el filtro.

Probemos los metadatos dinámicos. En la regla avanzada, estamos creando una nueva entrada de metadatos: `{"my-new-metadata": "my-new-value"}`.

Ejecuta la solicitud y verifica los registros de la aplicación:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

{{< text bash >}}
$ kubectl logs -n my-app deploy/httpbin -c istio-proxy --tail 1
{{< /text >}}

Verás en la salida los nuevos atributos configurados por la política de Kyverno:

{{< text plain >}}
[...]
[KYVERNO DEMO] my-new-dynamic-metadata: '{"my-new-metadata":"my-new-value","ext_authz_duration":5}'
[...]
{{< /text >}}

## Conclusión

En esta guía, hemos mostrado cómo integrar Istio y el Kyverno Authz Server para hacer cumplir las políticas para una aplicación de microservicios simple.
También mostramos cómo usar políticas para modificar los atributos de la solicitud y la respuesta.

Este es el ejemplo fundamental para construir un sistema de políticas para toda la plataforma que pueda ser utilizado por todos los equipos de aplicaciones.
