---
title: "¿Puede tu plataforma hacer políticas? Acelera equipos con la funcionalidad de políticas L7 de la plataforma"
description: ¿Es la política tu competencia principal? Probablemente no, pero necesitas hacerlo bien. Hazlo una vez con Istio y OPA y recupera el enfoque del equipo en lo que más importa.
publishdate: 2024-10-14
attribution: "Antonio Berben (Solo.io), Charlie Egan (Styra)"
keywords: [istio,opa,policy,platform,authorization]
---

Las plataformas informáticas compartidas ofrecen recursos y funcionalidades compartidas a los equipos de inquilinos para que no necesiten construir todo desde cero. Si bien a veces puede ser difícil equilibrar todas las solicitudes de los inquilinos, es importante que los equipos de la plataforma se pregunten: ¿cuál es la característica de mayor valor que podemos ofrecer a nuestros inquilinos?

A menudo, el trabajo se asigna directamente a los equipos de aplicaciones para que lo implementen, but hay algunas características que se implementan mejor una vez y se ofrecen como un servicio a todos los equipos. Una característica al alcance de la mayoría de los equipos de plataforma es ofrecer un sistema estándar y receptivo para la política de autorización de aplicaciones de capa 7. La política como código permite a los equipos sacar las decisiones de autorización de la capa de aplicación a un sistema desacoplado, ligero y de alto rendimiento. Puede sonar como un desafío, pero no tiene por qué serlo, con las herramientas adecuadas para el trabajo.

Vamos a profundizar en cómo se pueden usar Istio y Open Policy Agent (OPA) para hacer cumplir las políticas de capa 7 en tu plataforma. Te mostraremos cómo empezar con un ejemplo simple. Verás cómo esta combinación es una opción sólida para entregar políticas de forma rápida y transparente al equipo de aplicaciones en todas partes del negocio, al mismo tiempo que proporciona los datos que los equipos de seguridad necesitan para la auditoría y el cumplimiento.

## Pruébalo

Cuando se integra con Istio, OPA se puede utilizar para hacer cumplir políticas de control de acceso de grano fino para microservicios. Esta guía muestra cómo hacer cumplir las políticas de control de acceso para una aplicación de microservicios simple.

### Prerrequisitos

- Un cluster de Kubernetes con Istio instalado.
- La herramienta de línea de comandos `istioctl` instalada.

Instala Istio y configura tus [opciones de malla](/es/docs/reference/config/istio.mesh.v1alpha1/) para habilitar OPA:

{{< text bash >}}
$ istioctl install -y -f - <<'EOF'
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    accessLogFormat: |
      [OPA DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
    extensionProviders:
    - name: "opa.local"
      envoyExtAuthzGrpc:
        service: "opa.opa.svc.cluster.local"
        port: "9191"
EOF
{{< /text >}}

Observa que en la configuración, definimos una sección `extensionProviders` que apunta a la instalación independiente de OPA.

Despliega la aplicación de ejemplo. Httpbin es una aplicación conocida que se puede utilizar para probar solicitudes HTTP y ayuda a mostrar rápidamente cómo podemos jugar con los atributos de la solicitud y la respuesta.

{{< text bash >}}
$ kubectl create ns my-app
$ kubectl label namespace my-app istio-injection=enabled

$ kubectl apply -f {{< github_file >}}/samples/httpbin/httpbin.yaml -n my-app
{{< /text >}}

Despliega OPA. Fallará porque espera un `configMap` que contenga la regla Rego predeterminada a utilizar. Este `configMap` se desplegará más adelante en nuestro ejemplo.

{{< text bash >}}
$ kubectl create ns opa
$ kubectl label namespace opa istio-injection=enabled

$ kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: opa
  name: opa
  namespace: opa
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opa
  template:
    metadata:
      labels:
        app: opa
    spec:
      containers:
      - image: openpolicyagent/opa:0.61.0-envoy
        name: opa
        args:
          - "run"
          - "--server"
          - "--disable-telemetry"
          - "--config-file=/config/config.yaml"
          - "--log-level=debug" # Descomenta esta línea para habilitar los registros de depuración
          - "--diagnostic-addr=0.0.0.0:8282"
          - "/policy/policy.rego" # Política predeterminada
        volumeMounts:
          - mountPath: "/config"
            name: opa-config
          - mountPath: "/policy"
            name: opa-policy
      volumes:
        - name: opa-config
          configMap:
            name: opa-config
        - name: opa-policy
          configMap:
            name: opa-policy
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-config
  namespace: opa
data:
  config.yaml: |
    # Aquí la configuración de OPA que puedes encontrar en la documentación oficial
    decision_logs:
      console: true
    plugins:
      envoy_ext_authz_grpc:
        addr: ":9191"
        path: mypackage/mysubpackage/myrule # Ruta predeterminada para el plugin grpc
    # Aquí puedes agregar tu propia configuración con servicios y paquetes
---
apiVersion: v1
kind: Service
metadata:
  name: opa
  namespace: opa
  labels:
    app: opa
spec:
  ports:
    - port: 9191
      protocol: TCP
      name: grpc
  selector:
    app: opa
---
EOF
{{< /text >}}

Despliega la `AuthorizationPolicy` para definir qué servicios serán protegidos por OPA.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: my-opa-authz
  namespace: istio-system # Esto aplica la política en toda la malla, siendo istio-system el namespace de configuración de la malla
spec:
  selector:
    matchLabels:
      ext-authz: enabled
  action: CUSTOM
  provider:
    name: "opa.local"
  rules: [{}] # Reglas vacías, se aplicará a los selectores con la etiqueta ext-authz: enabled
EOF
{{< /text >}}

Etiquetemos la aplicación para hacer cumplir la política:

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

Observa que en este recurso, definimos el `extensionProvider` de OPA que estableciste en la configuración de Istio:

{{< text yaml >}}
[...]
  provider:
    name: "opa.local"
[...]
{{< /text >}}

## Cómo funciona

Al aplicar la `AuthorizationPolicy`, el control plane de Istio (istiod) envía las configuraciones requeridas al proxy sidecar (Envoy) de los servicios seleccionados en la política. Envoy luego enviará la solicitud al servidor OPA para verificar si la solicitud está permitida o no.

{{< image width="75%"
    link="./opa1.png"
    alt="Istio y OPA"
    >}}

El proxy Envoy funciona configurando filtros en una cadena. Uno de esos filtros es `ext_authz`, que implementa un servicio de autorización externa con un mensaje específico. Cualquier servidor que implemente el protobuf correcto puede conectarse al proxy Envoy y proporcionar la decisión de autorización; OPA es uno de esos servidores.

{{< image width="75%"
    link="./opa2.png"
    alt="Filtros"
    >}}

Antes, cuando instalaste el servidor OPA, usaste la versión Envoy del servidor. Esta imagen permite la configuración del plugin gRPC que implementa el servicio protobuf `ext_authz`.

{{< text yaml >}}
[...]
      containers:
      - image: openpolicyagent/opa:0.61.0-envoy # Esta es la versión de la imagen de OPA que trae el plugin de Envoy
        name: opa
[...]
{{< /text >}}

En la configuración, has habilitado el plugin de Envoy y el puerto que escuchará:

{{< text yaml >}}
[...]
    decision_logs:
      console: true
    plugins:
      envoy_ext_authz_grpc:
        addr: ":9191" # Este es el puerto donde escuchará el plugin de envoy
        path: mypackage/mysubpackage/myrule # Ruta predeterminada para el plugin grpc
    # Aquí puedes agregar tu propia configuración con servicios y paquetes
[...]
{{< /text >}}

Revisando la [documentación del servicio de Autorización de Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto), puedes ver que el mensaje tiene estos atributos:

{{< text json >}}
OkHttpResponse
{
  "status": {...},
  "denied_response": {...},
  "ok_response": {
      "headers": [],
      "headers_to_remove": [],
      "dynamic_metadata": {...},
      "response_headers_to_add": [],
      "query_parameters_to_set": [],
      "query_parameters_to_remove": []
    },
  "dynamic_metadata": {...}
}
{{< /text >}}

Esto significa que, basándose en la respuesta del servidor authz, Envoy puede agregar o eliminar encabezados, parámetros de consulta e incluso cambiar el estado de la respuesta. OPA también puede hacer esto, como se documenta en la [documentación de OPA](https://www.openpolicyagent.org/docs/latest/envoy-primer/#example-policy-with-additional-controls).

## Pruebas

Probemos el uso simple (autorización) y luego creemos una regla más avanzada para mostrar cómo podemos usar OPA para modificar la solicitud y la respuesta.

Despliega una aplicación para ejecutar comandos curl a la aplicación de ejemplo httpbin:

{{< text bash >}}
$ kubectl -n my-app run --image=curlimages/curl curl -- /bin/sleep 100d
{{< /text >}}

Aplica la primera regla Rego y reinicia el despliegue de OPA:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-policy
  namespace: opa
data:
  policy.rego: |
    package mypackage.mysubpackage

    import rego.v1

    default myrule := false

    myrule if {
      input.attributes.request.http.headers["x-force-authorized"] == "enabled"
    }

    myrule if {
      input.attributes.request.http.headers["x-force-authorized"] == "true"
    }
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl rollout restart deployment -n opa
{{< /text >}}

El escenario simple es permitir solicitudes si contienen el encabezado `x-force-authorized` con el valor `enabled` o `true`. Si el encabezado no está presente o tiene un valor diferente, la solicitud será denegada.

Hay múltiples formas de crear la regla Rego. En este caso, creamos dos reglas diferentes. Ejecutadas en orden, la primera que satisfaga todas las condiciones será la que se utilizará.

### Regla simple

La siguiente solicitud devolverá `403`:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "
http_code=%{http_code}" httpbin:8000/get
{{< /text >}}

La siguiente solicitud devolverá `200` y el cuerpo:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "
http_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: enabled"
{{< /text >}}

### Manipulaciones avanzadas

Ahora la regla más avanzada. Aplica la segunda regla Rego y reinicia el despliegue de OPA:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-policy
  namespace: opa
data:
  policy.rego: |
    package mypackage.mysubpackage

    import rego.v1

    request_headers := input.attributes.request.http.headers

    force_unauthenticated if request_headers["x-force-unauthenticated"] == "enabled"

    default allow := false

    allow if {
      not force_unauthenticated
      request_headers["x-force-authorized"] == "true"
    }

    default status_code := 403

    status_code := 200 if allow

    status_code := 401 if force_unauthenticated

    default body := "Unauthorized Request"

    body := "Authentication Failed" if force_unauthenticated

    myrule := {
      "body": body,
      "http_status": status_code,
      "allowed": allow,
      "headers": {"x-validated-by": "my-security-checkpoint"},
      "response_headers_to_add": {"x-add-custom-response-header": "added"},
      "request_headers_to_remove": ["x-force-authorized"],
      "dynamic_metadata": {"my-new-metadata": "my-new-value"},
    }
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl rollout restart deployment -n opa
{{< /text >}}

En esa regla, puedes ver:

{{< text plain >}}
myrule["allowed"] := allow # Observa que `allowed` es obligatorio al devolver un objeto, como aquí `myrule`
myrule["headers"] := headers
myrule["response_headers_to_add"] := response_headers_to_add
myrule["request_headers_to_remove"] := request_headers_to_remove
myrule["body"] := body
myrule["http_status"] := status_code
{{< /text >}}

Esos son los valores que se devolverán al proxy Envoy desde el servidor OPA. Envoy usará esos valores para modificar la solicitud y la respuesta.

Observa que `allowed` es obligatorio al devolver un objeto JSON en lugar de solo verdadero/falso. Esto se puede encontrar [en la documentación de OPA](https://www.openpolicyagent.org/docs/latest/envoy-primer/#output-document).

#### Cambiar el cuerpo devuelto

Probemos las nuevas capacidades:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "
http_code=%{http_code}" httpbin:8000/get
{{< /text >}}

Ahora podemos cambiar el cuerpo de la respuesta. Con `403` el cuerpo en la regla Rego se cambia a "Unauthorized Request". Con el comando anterior, deberías recibir:

{{< text plain >}}
Unauthorized Request
http_code=403
{{< /text >}}

#### Cambiar el cuerpo y el código de estado devueltos

Ejecutando la solicitud con el encabezado `x-force-authorized: enabled` deberías recibir el cuerpo "Authentication Failed" y el error "401":

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "
http_code=%{http_code}" httpbin:8000/get -H "x-force-unauthenticated: enabled"
{{< /text >}}

#### Agregar encabezados a la solicitud

Ejecutando una solicitud válida, deberías recibir el cuerpo de eco con el nuevo encabezado `x-validated-by: my-security-checkpoint` y el encabezado `x-force-authorized` eliminado:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

#### Agregar encabezados a la respuesta

Ejecutando la misma solicitud pero mostrando solo el encabezado, encontrarás el encabezado de respuesta agregado durante la verificación de Authz `x-add-custom-response-header: added`:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

#### Compartir datos entre filtros

Finalmente, puedes pasar datos a los siguientes filtros de Envoy usando `dynamic_metadata`. Esto es útil cuando quieres pasar datos a otro filtro `ext_authz` en la cadena o quieres imprimirlos en los registros de la aplicación.

{{< image width="75%"
    link="./opa3.png"
    alt="Metadatos"
    >}}

Para hacerlo, revisa el formato del registro de acceso que estableciste anteriormente:

{{< text plain >}}
[...]
    accessLogFormat: |
      [OPA DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
[...]
{{< /text >}}

`DYNAMIC_METADATA` es una palabra clave reservada para acceder al objeto de metadatos. El resto es el nombre del filtro al que quieres acceder. En tu caso, el nombre `envoy.filters.http.ext_authz` es creado automáticamente por Istio. Puedes verificar esto volcando la configuración de Envoy:

{{< text bash >}}
$ istioctl pc all deploy/httpbin -n my-app -oyaml | grep envoy.filters.http.ext_authz
{{< /text >}}

Verás las configuraciones para el filtro.

Probemos los metadatos dinámicos. En la regla avanzada, estás creando una nueva entrada de metadatos: `{"my-new-metadata": "my-new-value"}`.

Ejecuta la solicitud y verifica los registros de la aplicación:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
$ kubectl logs -n my-app deploy/httpbin -c istio-proxy --tail 1
{{< /text >}}

Verás en la salida los nuevos atributos configurados por las reglas Rego de OPA:

{{< text plain >}}
[...]
 my-new-dynamic-metadata: "{"my-new-metadata":"my-new-value","decision_id":"8a6d5359-142c-4431-96cd-d683801e889f","ext_authz_duration":7}"
[...]
{{< /text >}}

## Conclusión

En esta guía, hemos mostrado cómo integrar Istio y OPA para hacer cumplir las políticas para una aplicación de microservicios simple. También mostramos cómo usar Rego para modificar los atributos de la solicitud y la respuesta. Este es el ejemplo fundamental para construir un sistema de políticas para toda la plataforma que pueda ser utilizado por todos los equipos de aplicaciones.
