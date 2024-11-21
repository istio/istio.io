---
title: 自定义 Istio 指标
description: 此任务向您展示如何自定义 Istio 指标。
weight: 25
keywords: [telemetry,metrics,customize]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

此任务向您展示如何自定义 Istio 生成的指标。

Istio 可以生成各种仪表盘所使用的遥测数据，帮助您直观地显示您的网格信息。
例如，支持 Istio 的仪表盘包括：

* [Grafana](/zh/docs/tasks/observability/metrics/using-istio-dashboard/)
* [Kiali](/zh/docs/tasks/observability/kiali/)
* [Prometheus](/zh/docs/tasks/observability/metrics/querying-metrics/)

默认情况下，Istio 定义并生成一组标准指标（例如 `requests_total`），但您也可以使用
[Telemetry API](/zh/docs/tasks/observability/telemetry/)
自定义标准指标并创建新指标。

## 开始之前  {#before-you-begin}

在集群中[安装 Istio](/zh/docs/setup/)并部署应用程序。
或者，您可以设置自定义统计作为 Istio 安装的一部分。

[Bookinfo 示例](/zh/docs/examples/bookinfo/)应用程序在此任务中用作示例应用程序。
关于安装说明，请参阅部署 [Bookinfo 示例](/zh/docs/examples/bookinfo/#deploying-the-application)。

## 启用自定义指标  {#enable-custom-metrics}

例如要自定义遥测指标，可以使用以下命令，沿着入站和出站方向，将 `request_host`
和 `destination_port` 维度添加到同由 Gateway 和 Sidecar 发出的 `requests_total`：

{{< text bash >}}
$ cat <<EOF > ./custom_metrics.yaml
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: namespace-metrics
spec:
  metrics:
  - providers:
    - name: prometheus
    overrides:
    - match:
        metric: REQUEST_COUNT
      tagOverrides:
        destination_port:
          value: "string(destination.port)"
        request_host:
          value: "request.host"
EOF
$ kubectl apply -f custom_metrics.yaml
{{< /text >}}

## 验证结果  {#verify-the-results}

将流量发送到网格。对于 Bookinfo 示例，请在您的网络浏览器中访问
`http://$GATEWAY_URL/productpage` 或运行以下命令：

{{< text bash >}}
$ curl "http://$GATEWAY_URL/productpage"
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` 是 [Bookinfo](/zh/docs/examples/bookinfo/) 示例中设置的值。
{{< /tip >}}

使用以下命令验证 Istio 是否为您的新维度或修改后的维度生成数据：

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -- curl -sS 'localhost:15000/stats/prometheus' | grep istio_requests_total
{{< /text >}}

例如，在输出中，找到指标 `istio_requests_total` 并验证它是否包含您的新维度。

{{< tip >}}
代理开始应用配置可能需要很短的时间。如果未收到该指标，您可以在稍等片刻后重试发送请求，
然后再次查找该指标。
{{< /tip >}}

## 对值使用表达式  {#use-expressions-for-values}

指标配置中的值是常用表达式，这意味着您
JSON 中的字符必须双引号（例如："'string value'"）。
与 Mixer 表达式语言不同，不支持 pipe（`|`）运算符，但您
可以使用 `has` 或 `in` 操作符来模拟它，例如：

{{< text plain >}}
has(request.host) ? request.host : "unknown"
{{< /text >}}

有关详细信息，请参阅[通用表达式语言](https://opensource.google/projects/cel)。

Istio 公开了所有标准 [Envoy 属性](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/advanced/attributes)。
对等元数据可用作出站属性 `upstream_peer` 和入站属性 `downstream_peer`，具有以下字段：

| 字段         | 类型      | 值                              |
|-------------|----------|---------------------------------|
| `app`       | `string` | Application 名称。               |
| `version`   | `string` | Application 版本。               |
| `service`   | `string` | 服务实例。                        |
| `revision`  | `string` | 服务版本。                        |
| `name`      | `string` | Pod 名称。                       |
| `namespace` | `string` | Pod 所处命名空间。                |
| `type`      | `string` | 工作负载类型。                    |
| `workload`  | `string` | 工作负载名称。                    |
| `cluster`   | `string` | 此工作负载所属集群的标识符。        |

例如，要在出站配置中使用的对等 `app` 标签的表达式是 `filter_state.downstream_peer.app`
或 `filter_state.upstream_peer.app`。

## 清理  {#cleanup}

要删除 `Bookinfo` 示例应用及其配置，请参阅 [`Bookinfo` 清理](/zh/docs/examples/bookinfo/#cleanup)。
