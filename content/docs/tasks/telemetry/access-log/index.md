---
title: Envoy's Access Logging
description: This task shows you how to configure Envoy proxies to print access log to their standard output.
weight: 9
keywords: [telemetry]
---

The simplest kind of Istio logging is
[Envoy's access logging](https://www.envoyproxy.io/docs/envoy/latest/configuration/access_log).
Envoy proxies print access information to their standard output.
The standard output of Envoy's containers can then be printed by the `kubectl logs` command.

{{< boilerplate before-you-begin-egress >}}
{{< boilerplate start-httpbin-service >}}

## Enable Envoy's access logging

Edit the `istio` config map:

{{< text bash >}}
$ kubectl edit cm istio -n istio-system
{{< /text >}}

Set the value of `global.proxy.accessLogFile` to "/dev/stdout".
Mind escaping quotation marks with backward slashes (`\"`).

You may also want to change the
[format](https://www.envoyproxy.io/docs/envoy/latest/configuration/access_log#format-rules) of the access log.
To do it, edit `global.proxy.accessLogFormat`.

Save the config map and exit the editing mode.

## Test the access log

1.  Send a request from `sleep` to `httpbin`:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -v httpbin:8000/status/418
    *   Trying 172.21.13.94...
    * TCP_NODELAY set
    * Connected to httpbin (172.21.13.94) port 8000 (#0)
    > GET /status/418 HTTP/1.1

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
    * Connection #0 to host httpbin left intact
    {{< /text >}}

1.  Check the log of `sleep`:

    {{< text bash >}}
    $ kubectl logs -l app=sleep -c istio-proxy
    [2019-03-06T09:31:27.354Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 11 10 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "172.30.146.73:80" outbound|8000||httpbin.default.svc.cluster.local - 172.21.13.94:8000 172.30.146.82:60290 -
    {{< /text >}}

1.  Check the log of `httpbin`:

    {{< text bash >}}
    $ kubectl logs -l app=httpbin -c istio-proxy
    [2019-03-06T09:31:27.360Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 5 2 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "127.0.0.1:80" inbound|8000|http|httpbin.default.svc.cluster.local - 172.30.146.73:80 172.30.146.82:38618 outbound_.8000_._.httpbin.default.svc.cluster.local
    {{< /text >}}

Note that the messages corresponding to the request appear in logs of the Istio proxies of both the source and the destination, `sleep` and `httpbin`, respectively. You can see in the log the HTTP verb (`GET`), the HTTP path (`/status/418`), the response code (`418`) and other [request-related information](https://www.envoyproxy.io/docs/envoy/latest/configuration/access_log#format-rules).

## Cleanup

1.  Shutdown the [sleep]({{<github_tree>}}/samples/sleep) and [httpbin]({{<github_tree>}}/samples/httpbin) services:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    $ kubectl delete -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1.  Edit the `istio` config map and set `global.proxy.accessLogFile` to `""`.
    Mind escaping quotation marks with backward slashes (`\"`).

    {{< text bash >}}
    $ kubectl edit cm istio -n istio-system
    {{< /text >}}
