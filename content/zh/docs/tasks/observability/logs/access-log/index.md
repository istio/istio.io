---
title: 获取 Envoy 访问日志
description: 此任务向您展示如何配置 Envoy 代理将访问日志打印到其标准输出。
weight: 10
keywords: [telemetry,logs]
aliases:
    - /zh/docs/tasks/telemetry/access-log
    - /zh/docs/tasks/telemetry/logs/access-log/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio 最简单的日志类型是
[Envoy 的访问日志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage)。
Envoy 代理打印访问信息到标准输出。Envoy 容器的标准输出能够通过 `kubectl logs` 命令打印出来。

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

## 开启 Envoy 访问日志  {#enable-envoy-s-access-logging}

Istio 提供了几种启用访问日志的方法，建议使用 Telemetry API。

### 使用 Telemetry API  {#using-telemetry-API}

Telemetry API 可以开启或关闭访问日志：

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

上面的示例使用默认的 `envoy` 访问日志提供程序，除了默认设置外，我们没有配置任何其他内容。

类似的配置也可以应用于单独的命名空间或单独的工作负载，以在细粒度级别控制日志记录。

关于使用 Telemetry API 的更多信息，请参见 [Telemetry API 概述](/zh/docs/tasks/observability/telemetry/)。

### 使用网格配置  {#using-mesh-config}

如果您使用 `IstioOperator` CR 来安装 Istio，请在您的配置中添加以下字段：

{{< text yaml >}}
spec:
  meshConfig:
    accessLogFile: /dev/stdout
{{< /text >}}

或者，在原来的 `istioctl install` 命令中添加相同的设置，例如：

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

您也可以通过设置 `accessLogEncoding` 为 `JSON` 或 `TEXT` 来在两种格式之间切换。

您也许希望通过设置 `accessLogFormat`
来自定义访问日志的[格式](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules)。

有关所有这三个设置的更多信息，请参阅
[global mesh options](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)：

* `meshConfig.accessLogFile`
* `meshConfig.accessLogEncoding`
* `meshConfig.accessLogFormat`

## 默认访问日志格式  {#default-access-log-format}

如果没有指定 `accessLogFormat` Istio 将使用以下默认的访问日志格式：

{{< text plain >}}
[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\"
\"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n
{{< /text >}}

下表显示了一个使用默认的访问日志格式的示例，请求从 `sleep` 发送到 `httpbin`：

| 日志运算符 | sleep 中的访问日志 | httpbin 中的访问日志  |
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

## 测试访问日志  {#test-the-access-log}

1. 从 `sleep` 向 `httpbin` 发送一个请求：

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

1. 检查 `sleep` 的日志：

    {{< text bash >}}
    $ kubectl logs -l app=sleep -c istio-proxy
    [2019-03-06T09:31:27.354Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 11 10 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "172.30.146.73:80" outbound|8000||httpbin.default.svc.cluster.local - 172.21.13.94:8000 172.30.146.82:60290 -
    {{< /text >}}

1. 检查 `httpbin` 的日志：

    {{< text bash >}}
    $ kubectl logs -l app=httpbin -c istio-proxy
    [2019-03-06T09:31:27.360Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 5 2 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "127.0.0.1:80" inbound|8000|http|httpbin.default.svc.cluster.local - 172.30.146.73:80 172.30.146.82:38618 outbound_.8000_._.httpbin.default.svc.cluster.local
    {{< /text >}}

请注意，与请求相对应的信息分别出现在源（`sleep`）和目标（`httpbin`）的 Istio
代理日志中。您可以在日志中看到 HTTP 动词（`GET`）、HTTP 路径（`/status/418`）、
响应码（`418`）和其他[请求相关信息](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules)。

## 清理 {#cleanup}

关闭 [sleep]({{<github_tree>}}/samples/sleep) 和
[httpbin]({{<github_tree>}}/samples/httpbin) 服务：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

### 关闭 Envoy 的访问日志  {#disable-envoy-s-access-logging}

编辑 `istio` 配置文件然后设置 `meshConfig.accessLogFile` 为 `""`。

{{< tip >}}
在下面的例子中，将 `default` 替换为安装 Istio 时使用的配置文件的名称。
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set profile=default
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
{{< /text >}}
