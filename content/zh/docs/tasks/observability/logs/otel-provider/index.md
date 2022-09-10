---
标题：OpenTelemetry
描述：本任务告诉你如何配置 Envoy 代理发送访问日志 OpenTelemetry 收集器。
重量：10
关键字：[遥测，日志]
所有者：istio/wg-policies-and-telemetry-maintainers
测试：是
---

Envoy代理可以被配置为以[OpenTelemetry格式](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/access_loggers/open_telemetry/v3/logs_service.proto)导出[访问日志]( https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage）。
在这个中，Envoy 代理将访问日志发送到一个 [OpenTelemetry 收集器](https://github.com/open-telemetry/opentelemetry-collector)，
该收集器被配置为将日志打印到标准输出。然后可以通过`kubectl logs`命令访问器OpenTelemetry 收集的标准输出。。

{{< 开始出口前的样板文件 >}}

{{< 样板启动-httpbin-service >}}

{{< 样板启动-otel-collector-service >}}

## 启用 Envoy 的访问日志{#enable-envoy-access-logging}

要启用访问日志记录，请使用[Telemetry API](/zh/docs/tasks/observability/telemetry/)。

编辑 `MeshConfig` 名为文件，以添加一个 OpenTelemetry 提供者，`otel`。这涉及到添加一个扩展程序提供者的语句：

{{< 文本 yaml >}}
扩展提供者：
- 名称：酒店
  envoy 其他：
    服务：otel-collector.istio-system.svc.cluster.local
    端口：4317
{{< /text >}}

最终配置应类似于：

{{< 文本 yaml >}}
api版本：v1
种类：ConfigMap
元数据：
  名称：istio
  命名空间：istio-system
数据：
  网眼：|-
    访问日志文件：/dev/stdout
    默认配置：
      发现地址：istiod.istio-system.svc:15012
      代理元数据：{}
      追踪：
        拉链：
          地址：zipkin.istio-system:9411
    启用普罗米修斯合并：真
    扩展提供者：
    -名称：酒店
      envoy 其他：
        服务：otel-collector.istio-system.svc.cluster.local
        端口：4317
    根命名空间：istio-system
    信任域：cluster.local
  网状网络：'网络：{}'
{{< /text >}}

，添加一个 Telemetry 资源，告诉 Istio 将访问日志发送到 OpenTelemetry 收集器。

{{< 文本重击 >}}
$ 猫 <<EOF | kubectl 应用 -n 默认 -f -
api版本：telemetry.istio.io/v1alpha1
种类：遥测
元数据：
  名称：睡眠记录
规格：
  选择器：
    匹配标签：
      应用程序：睡眠
  访问记录：
    -提供者：
      -名称：酒店
EOF
{{< /text >}}

上面的例子使用了`otel`访问日志提供者，除了默认设置之外，我们没有配置任何东西。

类似的配置也可以举出简单的例子，控制或控制空间工作，以细粒度的日志记录。

有关使用 Telemetry API 的更多信息，请参见 [ Telemetry API 概述](/zh/docs/tasks/observability/telemetry/)。

### 使用网格配置{#using-mesh-config}

如果您使用`stioOperator` CR 安装 Istio，下面需要将字段添加到您的配置中：

{{< 文本 yaml >}}
规格：
  网格配置：
    访问日志文件：/dev/stdout
    扩展提供者：
    -名称：酒店
      envoy 其他：
        服务：otel-collector.istio-system.svc.cluster.local
        端口：4317
    默认提供者：
      访问记录：
      -特使
      -酒店
{{< /text >}}

否则，在你原来的`istioctl install`命令中加入相应的设置，说：

{{< 文本语法=bash snip_id=none >}}
$ istioctl install -f <your-istio-operator-config-file>
{{< /text >}}

## 默认访问日志格式{#default-access-log-format}

`accessLogFormat`如果未指定，Istio 将使用以下默认访问日志格式：

{{<纯文本>}}
[%START_TIME%] \" %REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL% \" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
\" %UPSTREAM_TRANSPORT_FAILURE_REASON% \" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \" %REQ(X-FORWARDED-FOR)% \"  \" %REQ(USER -AGENT)% \"  \" %REQ(X-REQUEST-ID)% \"
\" %REQ(:AUTHORITY)% \"  \" %UPSTREAM_HOST% \" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME% \n
{{< /text >}}

下面显示了一个使用默认访问日志格式的例子，即从`sleep`发送到`httpbin`的请求：

| 日志 | 日志 访问登录睡眠| httpbin 访问登录 |
|-------------|----------|------------ ------------|
| `[%START_TIME%]` | `[2020-11-25T21:26:18.409Z]` | `[2020-11-25T21:26:18.409Z]`
| `\"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\"` | `"GET /status/418 HTTP/1.1"` | `"GET /status/418 HTTP/1.1"`
| `%RESPONSE_CODE%` | `418` | `418`
| `%RESPONSE_FLAGS%` | `-` | `-`
| `%RESPONSE_CODE_DETAILS%` | `via_upstream` | `via_upstream`
| `%CONNECTION_TERMINATION_DETAILS%` | `-` | `-`
| `\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\"` | `“-”` | `"-"`
| `%BYTES_RECEIVED%` | `0` | `0`
| `%BYTES_SENT%` | `135` | `135`
| `%DURATION%` | `4` | `3`
| `%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%` | `4` | `1`
| `\"%REQ(X-FORWARDED-FOR)%\"` | `“-”` | `"-"`
| `\"%REQ(USER-AGENT)%\"` | `"curl/7.73.0-DEV"` | `"curl/7.73.0-DEV"`
| `\"%REQ(X-REQUEST-ID)%\"` | `“84961386-6d84-929d-98bd-c5aee93b5c88”` | `“84961386-6d84-929d-98bd-c5aee93b5c88”`
| `\"%REQ(:AUTHORITY)%\"` | `"httpbin:8000"` | `"httpbin:8000"`
| `\"%UPSTREAM_HOST%\"` | `“10.44.1.27:80”` | `"127.0.0.1:80"`
| `%UPSTREAM_CLUSTER%` | <code>出站|8000||httpbin.foo.svc.cluster.local</code> | <code>入站|8000||</code>
| `%UPSTREAM_LOCAL_ADDRESS%` | `10.44.1.23:37652` | `127.0.0.1:41854`
| `%DOWNSTREAM_LOCAL_ADDRESS%` | `10.0.45.184:8000` | `10.44.1.27:80`
| `%DOWNSTREAM_REMOTE_ADDRESS%` | `10.44.1.23:46520` | `10.44.1.23:37652`
| `%REQUESTED_SERVER_NAME%` | `-` | `outbound_.8000_._.httpbin.foo.svc.cluster.local`
| `%ROUTE_NAME%` | `默认` | `默认`

## 测试访问日志{#test-the-access-log}

1.  从`sleep`向`httpbin`发送一个请求：

    {{< 文本重击 >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sS -v httpbin:8000/status/418
    ...
    < HTTP/1.1 418 未知
    <服务器：特使
    ...
        -=[ 茶壶 ]=-

           _...._
         。_ _`。
        | ."` ^ `"。_,
        \_;` "---" `|//
          | ;/
          \_ _/
            ` """`
    {{< /text >}}

1.  检查`otel-collector`的日志：

    {{< 文本重击 >}}
    $ kubectl logs -l app=otel-collector -n istio-system
    [2020-11-25T21:26:18.409Z]“GET /status/418 HTTP/1.1”418-via_upstream-“-”0 135 3 1“-”“curl/7.73.0-DEV”“84961386-6d84- 929d-98bd-c5aee93b5c88" "httpbin:8000" "127.0.0.1:80" 入站|8000|| 127.0.0.1:41854 10.44.1.27:80 10.44.1.23:37652 outbound_.8000__._.httpbin.foo.svc.cluster.local 默认
    {{< /text >}}

注意，与请求相对应的信息会出现在源和目标的 Istio 代理的日志中，分别是`sleep`和`httpbin`。
你可以在日志中看到HTTP 动词（`GET`）、HTTP 路径（`/status/418`）、响应代码（`418`）和其他与[请求相关的信息](https://www.envoyproxy .io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules）。

## 收拾{#cleanup}

关闭 [ sleep ]({{< github_tree >}}/samples/sleep) 和 [ httpbin ]({{< github_tree >}}/samples/httpbin) 服务：

{{< 文本重击 >}}
$ kubectl 删除遥测睡眠记录
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl 删除 -f @samples/httpbin/httpbin.yaml@
$ kubectl delete -f @samples/open-telemetry/otel.yaml@
{{< /text >}}

### 禁止特使的访问日志{#disable-envoy-access-logging}

移除 Istio 安装配置中的`meshConfig.extensionProviders`和`meshConfig.defaultProviders`设置，或将其设为`""`。

{{< 提示 >}}
在下面的示例中，使用您安装 Istio 时使用的配置文件的名称替换`default`。
{{< /tip >}}

{{< 文本重击 >}}
$ istioctl install --set profile=default
✔ 已安装 Istio 核心
✔ Istiod 已安装
✔ 已安装入口网关
✔ 安装完成
{{< /text >}}