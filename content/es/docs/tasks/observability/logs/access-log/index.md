---
title: Registros de Acceso de Envoy
description: Esta tarea muestra cómo configurar los proxies de Envoy para imprimir registros de acceso en su salida estándar.
weight: 10
keywords: [telemetry,logs]
aliases:
    - /docs/tasks/telemetry/access-log
    - /docs/tasks/telemetry/logs/access-log/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

El tipo más simple de registro de Istio es el [registro de acceso de Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage).
Los proxies de Envoy imprimen información de acceso en su salida estándar.
La salida estándar de los contenedores de Envoy se puede imprimir con el comando `kubectl logs`.

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

## Habilitar el registro de acceso de Envoy

Istio ofrece varias formas de habilitar los registros de acceso. Se recomienda el uso de la API de Telemetría.

### Usando la API de Telemetría

La API de Telemetría se puede usar para habilitar o deshabilitar los registros de acceso:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
    - providers:
      - name: envoy
{{< /text >}}

El ejemplo anterior utiliza el proveedor de registro de acceso `envoy` predeterminado, y no configuramos nada más que la configuración predeterminada.

Una configuración similar también se puede aplicar a un namespace individual, o a un workload individual, para controlar el registro a un nivel granular.

Para obtener más información sobre el uso de la API de Telemetría, consulte la [descripción general de la API de Telemetría](/es/docs/tasks/observability/telemetry/).

### Usando Mesh Config

Si utilizó una configuración de `IstioOperator` para instalar Istio, agregue el siguiente campo a su configuración:

{{< text yaml >}}
spec:
  meshConfig:
    accessLogFile: /dev/stdout
{{< /text >}}

De lo contrario, agregue la configuración equivalente a su comando `istioctl install` original, por ejemplo:

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

También puede elegir entre JSON y texto configurando `accessLogEncoding` en `JSON` o `TEXT`.

También es posible que desee personalizar el [formato](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules) del registro de acceso editando `accessLogFormat`.

Consulte las [opciones de mesh  global](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) para obtener más información
sobre estas tres configuraciones:

* `meshConfig.accessLogFile`
* `meshConfig.accessLogEncoding`
* `meshConfig.accessLogFormat`

## Formato de registro de acceso predeterminado

Istio utilizará el siguiente formato de registro de acceso predeterminado si no se especifica `accessLogFormat`:

{{< text plain >}}
[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\"
\"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER_RAW% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n
{{< /text >}}

La siguiente tabla muestra un ejemplo utilizando el formato de registro de acceso predeterminado para una solicitud enviada desde `curl` a `httpbin`:

| Operador de registro                                               | registro de acceso en curl | registro de acceso en httpbin |
|--------------------------------------------------------------------|--------------------|-----------------------|
| `[%START_TIME%]`                                                   | `[2020-11-25T21:26:18.409Z]` | `[2020-11-25T21:26:18.409Z]`
| `\"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\"` | `"GET /status/418 HTTP/1.1"` | `"GET /status/418 HTTP/1.1"`
| `%RESPONSE_CODE%`                                                  | `418` | `418`
| `%RESPONSE_FLAGS%`                                                 | `-` | `-`
| `%RESPONSE_CODE_DETAILS%`                                          | `via_upstream` | `via_upstream`
| `%CONNECTION_TERMINATION_DETAILS%`                                 | `-` | `-`
| `\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\"`                          | `"-"` | `"-"`
| `%BYTES_RECEIVED%`                                                 | `0` | `0`
| `%BYTES_SENT%`                                                     | `135` | `135`
| `%DURATION%`                                                       | `4` | `3`
| `%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%`                            | `4` | `1`
| `\"%REQ(X-FORWARDED-FOR)%\"`                                       | `"-"` | `"-"`
| `\"%REQ(USER-AGENT)%\"`                                            | `"curl/7.73.0-DEV"` | `"curl/7.73.0-DEV"`
| `\"%REQ(X-REQUEST-ID)%\"`                                          | `"84961386-6d84-929d-98bd-c5aee93b5c88"` | `"84961386-6d84-929d-98bd-c5aee93b5c88"`
| `\"%REQ(:AUTHORITY)%\"`                                            | `"httpbin:8000"` | `"httpbin:8000"`
| `\"%UPSTREAM_HOST%\"`                                              | `"10.44.1.27:80"` | `"127.0.0.1:80"`
| `%UPSTREAM_CLUSTER_RAW%`                                           | <code>outbound&#124;8000&#124;&#124;httpbin.foo.svc.cluster.local</code> | <code>inbound&#124;8000&#124;&#124;</code>
| `%UPSTREAM_LOCAL_ADDRESS%`                                         | `10.44.1.23:37652` | `127.0.0.1:41854`
| `%DOWNSTREAM_LOCAL_ADDRESS%`                                       | `10.0.45.184:8000` | `10.44.1.27:80`
| `%DOWNSTREAM_REMOTE_ADDRESS%`                                      | `10.44.1.23:46520` | `10.44.1.23:37652`
| `%REQUESTED_SERVER_NAME%`                                          | `-` | `outbound_.8000_._.httpbin.foo.svc.cluster.local`
| `%ROUTE_NAME%`                                                     | `default` | `default`

## Probar el registro de acceso

1.  Envíe una solicitud de `curl` a `httpbin`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sS -v httpbin:8000/status/418
    ...
    < HTTP/1.1 418 Unknown
    ...
    < server: envoy
    ...
    I'm a teapot!
    ...
    {{< /text >}}

1.  Verifique el registro de `curl`:

    {{< text bash >}}
    $ kubectl logs -l app=curl -c istio-proxy
    [2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 4 4 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "10.44.1.27:80" outbound|8000||httpbin.foo.svc.cluster.local 10.44.1.23:37652 10.0.45.184:8000 10.44.1.23:46520 - default
    {{< /text >}}

1.  Verifique el registro de `httpbin`:

    {{< text bash >}}
    $ kubectl logs -l app=httpbin -c istio-proxy
    [2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 3 1 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "127.0.0.1:80" inbound|8000|| 127.0.0.1:41854 10.44.1.27:80 10.44.1.23:37652 outbound_.8000_._.httpbin.foo.svc.cluster.local default
    {{< /text >}}

Tenga en cuenta que los mensajes correspondientes a la solicitud aparecen en los registros de los proxies de Istio tanto del origen como del destino, `curl` y `httpbin`, respectivamente. Puede ver en el registro el verbo HTTP (`GET`), la ruta HTTP (`/status/418`), el código de respuesta (`418`) y otra [información relacionada con la solicitud](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules).

## Limpieza

Apague los services [curl]({{< github_tree >}}/samples/curl) y [httpbin]({{< github_tree >}}/samples/httpbin):

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

### Deshabilitar el registro de acceso de Envoy

Elimine, o establezca en `""`, la configuración `meshConfig.accessLogFile` en su configuración de instalación de Istio.

{{< tip >}}
En el ejemplo siguiente, reemplace `default` con el nombre del perfil que utilizó cuando instaló Istio.
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set profile=default
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
{{< /text >}}
