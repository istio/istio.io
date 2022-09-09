---
title: OpenTelemetry
description: 本任务告诉你如何配置 Envoy 代理发送访问日志到 OpenTelemetry 收集器。
weight: 10
keywords: [telemetry,logs]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Envoy 代理可以被配置为以 [OpenTelemetry 格式](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/access_loggers/open_telemetry/v3/logs_service.proto)导出[访问日志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage)。
在这个例子中，Envoy 代理将访问日志发送到一个 [OpenTelemetry 收集器](https://github.com/open-telemetry/opentelemetry-collector)，
该收集器被配置为将日志打印到标准输出。然后可以通过 `kubectl logs` 命令访问 OpenTelemetry 收集器的标准输出。。

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

{{< boilerplate start-otel-collector-service >}}

## 启用 Envoy 的访问日志{#enable-envoy-access-logging}

要启用访问日志记录，请使用 [Telemetry API](/zh/docs/tasks/observability/telemetry/)。

编辑 `MeshConfig` 文件以添加一个 OpenTelemetry 提供者，名为 `otel`。这涉及到添加一个扩展程序提供者的语句：

{{< text yaml >}}
extensionProviders:
- name: otel
  envoyOtelAls:
    service: otel-collector.istio-system.svc.cluster.local
    port: 4317
{{< /text >}}

最终配置应类似于：

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
        service: otel-collector.istio-system.svc.cluster.local
        port: 4317
    rootNamespace: istio-system
    trustDomain: cluster.local
  meshNetworks: 'networks: {}'
{{< /text >}}

接下来，添加一个 Telemetry 资源，告诉 Istio 将访问日志发送到 OpenTelemetry 收集器。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n default -f -
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: sleep-logging
spec:
  selector:
    matchLabels:
      app: sleep
  accessLogging:
    - providers:
      - name: otel
EOF
{{< /text >}}

上面的例子使用了 `otel` 访问日志提供者，除了默认设置之外，我们没有配置任何东西。

类似的配置也可以应用于单个命名空间，或单个工作负载，以控制细粒度的日志记录。

有关使用 Telemetry API 的更多信息，请参阅 [Telemetry API 概述](/zh/docs/tasks/observability/telemetry/)。

### 使用网格配置{#using-mesh-config}

如果您使用 `IstioOperator` CR 安装 Istio，请将以下字段添加到您的配置中：

{{< text yaml >}}
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    extensionProviders:
    - name: otel
      envoyOtelAls:
        service: otel-collector.istio-system.svc.cluster.local
        port: 4317
    defaultProviders:
      accessLogging:
      - envoy
      - otel
{{< /text >}}

否则，在你原来的 `istioctl install` 命令中加入相应的设置，比如说：

{{< text syntax=bash snip_id=none >}}
$ istioctl install -f <your-istio-operator-config-file>
{{< /text >}}

## 默认访问日志格式{#default-access-log-format}

`accessLogFormat` 如果未指定，Istio 将使用以下默认访问日志格式：

{{< text plain >}}
[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\"
\"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n
{{< /text >}}

下表显示了一个使用默认访问日志格式的例子，即从 `sleep` 发送到 `httpbin` 的请求：

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

## 测试访问日志{#test-the-access-log}

1.  从 `sleep` 向 `httpbin` 发送一个请求：

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

1.  检查 `otel-collector` 的日志：

    {{< text bash >}}
    $ kubectl logs -l app=otel-collector -n istio-system
    [2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 3 1 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "127.0.0.1:80" inbound|8000|| 127.0.0.1:41854 10.44.1.27:80 10.44.1.23:37652 outbound_.8000_._.httpbin.foo.svc.cluster.local default
    {{< /text >}}

注意，与请求相对应的信息会出现在源和目标的 Istio 代理的日志中，分别是 `sleep` 和 `httpbin`。你可以在日志中看到 HTTP 动词（`GET`）、HTTP路径（`/status/418`）、响应代码（`418`）和其他与[请求相关的信息](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules)。

## 清理{#cleanup}

关闭 [sleep]({{< github_tree >}}/samples/sleep) 和 [httpbin]({{< github_tree >}}/samples/httpbin)服务：

{{< text bash >}}
$ kubectl delete telemetry sleep-logging
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl delete -f @samples/open-telemetry/otel.yaml@
{{< /text >}}

### 禁用 Envoy 的访问日志{#disable-envoy-access-logging}

移除 Istio 安装配置中的 `meshConfig.extensionProviders` 和 `meshConfig.defaultProviders` 设置，或将其设为 `""`。

{{< tip >}}
在下面的例子中，用你安装 Istio 时使用的配置文件的名称替换 `default` 。
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set profile=default
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
{{< /text >}}
