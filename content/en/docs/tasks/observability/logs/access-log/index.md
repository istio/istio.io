---
title: Getting Envoy's Access Logs
description: This task shows you how to configure Envoy proxies to print access logs to their standard output.
weight: 10
keywords: [telemetry]
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

## Test the access log

1.  Send a request from `sleep` to `httpbin`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -v httpbin:8000/status/418
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
    [2020-10-30T12:36:44.547Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 25 24 "-" "curl/7.69.1" "f13c2118-3ef9-9ed9-91b7-5d21358029c3" "httpbin:8000" "10.244.0.30:80" outbound|8000||httpbin.default.svc.cluster.local 10.244.0.29:46348 10.96.148.56:8000 10.244.0.29:44678 - default
    {{< /text >}}

1.  Check `httpbin`'s log:

    {{< text bash >}}
    $ kubectl logs -l app=httpbin -c istio-proxy
    [2020-10-30T12:36:44.553Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 3 2 "-" "curl/7.69.1" "f13c2118-3ef9-9ed9-91b7-5d21358029c3" "httpbin:8000" "127.0.0.1:80" inbound|8000|| 127.0.0.1:42940 10.244.0.30:80 10.244.0.29:46348 outbound_.8000_._.httpbin.default.svc.cluster.local default
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
