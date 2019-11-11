---
title: 获取 Envoy 访问日志
description: 此任务向您展示如何配置 Envoy 代理将访问日志打印到其标准输出。
weight: 10
keywords: [telemetry]
aliases:
    - /zh/docs/tasks/telemetry/access-log
    - /zh/docs/tasks/telemetry/logs/access-log/
---

Istio 最简单的日志类型是[Envoy 的访问日志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log)。Envoy 代理打印访问信息到标准输出。Envoy 容器的标准输出能够通过 `kubectl logs` 命令打印出来。

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

## 开启 Envoy 访问日志{#enable-envoy-s-access-logging}

修改 `istio` 配置文件:

{{< text bash >}}
$ istioctl manifest apply --set values.global.proxy.accessLogFile="/dev/stdout"
configmap "istio" replaced
{{< /text >}}

您也可以通过设置 `accessLogEncoding` 为 `JSON` 或 `TEXT` 来在两种格式之间切换。

您也许希望通过设置 `accessLogFormat` 来自定义访问日志的[格式](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log#format-rules)。

{{< tip >}}
这三种参数也可以通过[安装选项](/zh/docs/reference/config/installation-options/)来进行配置:
{{< /tip >}}

* `global.proxy.accessLogFile`
* `global.proxy.accessLogEncoding`
* `global.proxy.accessLogFormat`

## 测试访问日志{#test-the-access-log}

1.  从 `sleep` 向 `httpbin` 发送一个请求:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -v httpbin:8000/status/418
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

1.  检查 `sleep` 的日志:

    {{< text bash >}}
    $ kubectl logs -l app=sleep -c istio-proxy
    [2019-03-06T09:31:27.354Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 11 10 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "172.30.146.73:80" outbound|8000||httpbin.default.svc.cluster.local - 172.21.13.94:8000 172.30.146.82:60290 -
    {{< /text >}}

1.  检查 `httpbin` 的日志:

    {{< text bash >}}
    $ kubectl logs -l app=httpbin -c istio-proxy
    [2019-03-06T09:31:27.360Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 5 2 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "127.0.0.1:80" inbound|8000|http|httpbin.default.svc.cluster.local - 172.30.146.73:80 172.30.146.82:38618 outbound_.8000_._.httpbin.default.svc.cluster.local
    {{< /text >}}

请注意，与请求相对应的信息分别出现在源（`sleep`）和目标（`httpbin`）的 Istio 代理日志中。您可以在日志中看到 HTTP 动词(`GET`)、HTTP 路径(`/status/418`)、响应码(`418`)和其他[请求相关信息](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log#format-rules)。

## 清除{#cleanup}

关闭 [sleep]({{<github_tree>}}/samples/sleep) 和 [httpbin]({{<github_tree>}}/samples/httpbin) 服务:

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

### 关闭 Envoy 的访问日志{#disable-envoy-s-access-logging}

编辑 `istio` 配置文件然后设置 `accessLogFile` 为 `""`。

{{< text bash >}}
$ istioctl manifest apply
configmap "istio" replaced
{{< /text >}}
