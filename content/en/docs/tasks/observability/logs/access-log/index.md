---
title: Envoy Access Logs
description: This task shows you how to configure Envoy proxies to print access logs to their standard output.
weight: 10
keywords: [telemetry,logs]
aliases:
    - /docs/tasks/telemetry/access-log
    - /docs/tasks/telemetry/logs/access-log/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

The simplest kind of Istio logging is
[Envoy's access logging](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage).
Envoy proxies print access information to their standard output.
The standard output of Envoy's containers can then be printed by the `kubectl logs` command.

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

## Enable Envoy's access logging

Istio offers a few ways to enable access logs. Use of the Telemetry API is recommended

### Using Telemetry API

The Telemetry API can be used to enable or disable access logs:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
    - providers:
      - name: envoy
{{< /text >}}

The above example uses the default `envoy` access log provider, and we do not configure anything other than default settings.

Similar configuration can also be applied on an individual namespace, or to an individual workload, to control logging at a fine grained level.

For more information about using the Telemetry API, see the [Telemetry API overview](/docs/tasks/observability/telemetry/).

### Using Mesh Config

If you used an `IstioOperator` CR to install Istio, add the following field to your configuration:

{{< text yaml >}}
spec:
  meshConfig:
    accessLogFile: /dev/stdout
{{< /text >}}

Otherwise, add the equivalent setting to your original `istioctl install` command, for example:

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

You can also choose between JSON and text by setting `accessLogEncoding` to `JSON` or `TEXT`.

You may also want to customize the
[format](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules) of the access log by editing `accessLogFormat`.

Refer to [global mesh options](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) for more information
on all three of these settings:

* `meshConfig.accessLogFile`
* `meshConfig.accessLogEncoding`
* `meshConfig.accessLogFormat`

## Default access log format

Istio will use the following default access log format if `accessLogFormat` is not specified:

{{< text plain >}}
[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\"
\"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n
{{< /text >}}

The following table shows an example using the default access log format for a request sent from `sleep` to `httpbin`:

| Log operator | access log in sleep | access log in httpbin |
|--------------|---------------------|-----------------------|
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

## Test the access log

1.  Send a request from `sleep` to `httpbin`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sS -v httpbin:8000/status/418
    ...
    < HTTP/1.1 418 Unknown
    < server: envoy
    ...
        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/
            `"""`
    {{< /text >}}

1.  Check `sleep`'s log:

    {{< text bash >}}
    $ kubectl logs -l app=sleep -c istio-proxy
    [2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 4 4 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "10.44.1.27:80" outbound|8000||httpbin.foo.svc.cluster.local 10.44.1.23:37652 10.0.45.184:8000 10.44.1.23:46520 - default
    {{< /text >}}

1.  Check `httpbin`'s log:

    {{< text bash >}}
    $ kubectl logs -l app=httpbin -c istio-proxy
    [2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 3 1 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "127.0.0.1:80" inbound|8000|| 127.0.0.1:41854 10.44.1.27:80 10.44.1.23:37652 outbound_.8000_._.httpbin.foo.svc.cluster.local default
    {{< /text >}}

Note that the messages corresponding to the request appear in logs of the Istio proxies of both the source and the destination, `sleep` and `httpbin`, respectively. You can see in the log the HTTP verb (`GET`), the HTTP path (`/status/418`), the response code (`418`) and other [request-related information](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules).

## Cleanup

Shutdown the [sleep]({{< github_tree >}}/samples/sleep) and [httpbin]({{< github_tree >}}/samples/httpbin) services:

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

### Disable Envoy's access logging

Remove, or set to `""`, the `meshConfig.accessLogFile` setting in your Istio install configuration.

{{< tip >}}
In the example below, replace `default` with the name of the profile you used when you installed Istio.
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set profile=default
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
{{< /text >}}
