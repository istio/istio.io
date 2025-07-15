---
title: OpenTelemetry
description: Esta tarea muestra cómo configurar los proxies de Envoy para enviar registros de acceso con el colector de OpenTelemetry.
weight: 10
keywords: [telemetry,logs]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Los proxies de Envoy se pueden configurar para exportar sus [registros de acceso](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage) en [formato OpenTelemetry](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/access_loggers/open_telemetry/v3/logs_service.proto).
En este ejemplo, los proxies envían registros de acceso a un [colector de OpenTelemetry](https://github.com/open-telemetry/opentelemetry-collector), que está configurado para imprimir los registros en la salida estándar.
Se puede acceder a la salida estándar del colector de OpenTelemetry mediante el comando `kubectl logs`.

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

{{< boilerplate start-otel-collector-service >}}

## Habilitar el registro de acceso de Envoy

Para habilitar el registro de acceso, use la [API de Telemetría](/es/docs/tasks/observability/telemetry/).

Edite `MeshConfig` para agregar un proveedor de OpenTelemetry, llamado `otel`. Esto implica agregar una estrofa de proveedor de extensión:

{{< text yaml >}}
extensionProviders:
- name: otel
  envoyOtelAls:
    service: opentelemetry-collector.observability.svc.cluster.local
    port: 4317
{{< /text >}}

La configuración final debería verse algo así:

{{< text yaml >}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: istio
  namespace: istio-system
data:
  mesh: |-
    accessLogFile: /dev/stdout
    defaultConfig:
      discoveryAddress: istiod.istio-system.svc:15012
      proxyMetadata: {}
      tracing:
        zipkin:
          address: zipkin.istio-system:9411
    enablePrometheusMerge: true
    extensionProviders:
    - name: otel
      envoyOtelAls:
        service: opentelemetry-collector.observability.svc.cluster.local
        port: 4317
    rootNamespace: istio-system
    trustDomain: cluster.local
  meshNetworks: 'networks: {}'
{{< /text >}}

Luego, agregue un recurso Telemetry que le diga a Istio que envíe registros de acceso al colector de OpenTelemetry.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n default -f -
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: curl-logging
spec:
  selector:
    matchLabels:
      app: curl
  accessLogging:
    - providers:
      - name: otel
EOF
{{< /text >}}

El ejemplo anterior utiliza el proveedor de registro de acceso `otel`, y no configuramos nada más que la configuración predeterminada.

Una configuración similar también se puede aplicar a un namespace individual, o a un workload individual, para controlar el registro a un nivel granular.

Para obtener más información sobre el uso de la API de Telemetría, consulte la [descripción general de la API de Telemetría](/es/docs/tasks/observability/telemetry/).

### Usando Mesh Config

Si utilizó una configuración de `IstioOperator` para instalar Istio, agregue el siguiente campo a su configuración:

{{< text yaml >}}
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    extensionProviders:
    - name: otel
      envoyOtelAls:
        service: opentelemetry-collector.observability.svc.cluster.local
        port: 4317
    defaultProviders:
      accessLogging:
      - envoy
      - otel
{{< /text >}}

De lo contrario, agregue la configuración equivalente a su comando `istioctl install` original, por ejemplo:

{{< text syntax=bash snip_id=none >}}
$ istioctl install -f <your-istio-operator-config-file>
{{< /text >}}

## Formato de registro de acceso predeterminado

Istio utilizará el siguiente formato de registro de acceso predeterminado si no se especifica `accessLogFormat`:

{{< text plain >}}
[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\"
\"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n
{{< /text >}}

La siguiente tabla muestra un ejemplo utilizando el formato de registro de acceso predeterminado para una solicitud enviada desde `curl` a `httpbin`:

| Operador de registro | registro de acceso en curl | registro de acceso en httpbin |
|--------------|--------------------|-----------------------|
| `[%START_TIME%]` | `[2020-11-25T21:26:18.409Z]` | `[2020-11-25T21:26:18.409Z]`
| `\"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\"` | `"GET /status/418 HTTP/1.1"` | `"GET /status/418 HTTP/1.1"`
| `%RESPONSE_CODE%` | `418` | `418`
| `%RESPONSE_FLAGS%` | `-` | `-`
| `%RESPONSE_CODE_DETAILS%` | `via_upstream` | `via_upstream`
| `%CONNECTION_TERMINATION_DETAILS%` | `-` | `-`
| `\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\"` | `"-"` | `"-"`
| `%BYTES_RECEIVED%` | `0` | `0`
| `%BYTES_SENT%` | `135` | `135`
| `%DURATION%` | `4` | `3`
| `%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%` | `4` | `1`
| `\"%REQ(X-FORWARDED-FOR)%\"` | `"-"` | `"-"`
| `\"%REQ(USER-AGENT)%\"` | `"curl/7.73.0-DEV"` | `"curl/7.73.0-DEV"`
| `\"%REQ(X-REQUEST-ID)%\"` | `"84961386-6d84-929d-98bd-c5aee93b5c88"` | `"84961386-6d84-929d-98bd-c5aee93b5c88"`
| `\"%REQ(:AUTHORITY)%\"` | `"httpbin:8000"` | `"httpbin:8000"`
| `\"%UPSTREAM_HOST%\"` | `"10.44.1.27:80"` | `"127.0.0.1:80"`
| `%UPSTREAM_CLUSTER%` | <code>outbound&#124;8000&#124;&#124;httpbin.foo.svc.cluster.local</code> | <code>inbound&#124;8000&#124;&#124;</code>
| `%UPSTREAM_LOCAL_ADDRESS%` | `10.44.1.23:37652` | `127.0.0.1:41854`
| `%DOWNSTREAM_LOCAL_ADDRESS%` | `10.0.45.184:8000` | `10.44.1.27:80`
| `%DOWNSTREAM_REMOTE_ADDRESS%` | `10.44.1.23:46520` | `10.44.1.23:37652`
| `%REQUESTED_SERVER_NAME%` | `-` | `outbound_.8000_._.httpbin.foo.svc.cluster.local`
| `%ROUTE_NAME%` | `default` | `default`

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

1.  Verifique el registro de `otel-collector`:

    {{< text bash >}}
    $ kubectl logs -l app=opentelemetry-collector -n observability
    [2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 3 1 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "127.0.0.1:80" inbound|8000|| 127.0.0.1:41854 10.44.1.27:80 10.44.1.23:37652 outbound_.8000_._.httpbin.foo.svc.cluster.local default
    {{< /text >}}

Tenga en cuenta que los mensajes correspondientes a la solicitud aparecen en los registros de los proxies de Istio tanto del origen como del destino, `curl` y `httpbin`, respectivamente. Puede ver en el registro el verbo HTTP (`GET`), la ruta HTTP (`/status/418`), el código de respuesta (`418`) y otra [información relacionada con la solicitud](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules).

## Limpieza

Apague los services [curl]({{< github_tree >}}/samples/curl) y [httpbin]({{< github_tree >}}/samples/httpbin):

{{< text bash >}}
$ kubectl delete telemetry curl-logging
$ kubectl delete -f @samples/curl/curl.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n istio-system
$ kubectl delete namespace observability
{{< /text >}}

### Deshabilitar el registro de acceso de Envoy

Elimine, o establezca en `""`, la configuración `meshConfig.extensionProviders` y `meshConfig.defaultProviders` en su configuración de instalación de Istio.

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
