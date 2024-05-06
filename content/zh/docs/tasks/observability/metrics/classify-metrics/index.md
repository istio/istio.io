---
title: 根据请求或响应对指标进行分类
description: 此任务向您展示如何通过按类型对请求和响应进行分组来改进遥测。
weight: 27
keywords: [telemetry,metrics,classify,request-based,openapispec,swagger]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

根据网格中服务处理的请求和响应的类型来可视化遥测数据非常有用。
例如，书商跟踪请求书评的次数。书评请求具有以下结构：

{{< text plain >}}
GET /reviews/{review_id}
{{< /text >}}

计算审查请求的数量必须考虑到无界元素 `review_id`。
`GET /reviews/1` 紧随其后的 `GET /reviews/2` 应该算作两次获得评论的请求。

Istio 允许您使用 AttributeGen 插件创建分类规则，该插件将请求分组为固定数量的逻辑操作。
例如，您可以创建一个名为 `GetReviews` 的操作，
这是使用 [`Open API Spec operationId`](https://swagger.io/docs/specification/paths-and-operations/)。
此信息作为 `istio_operationId` 属性注入到请求处理中值等于 `GetReviews`。
您可以将属性用作 Istio 标准指标中的维度。
相似地，您可以基于 `ListReviews` 和 `CreateReviews` 这类其他操作跟踪指标。

## 按请求分类指标 {#classify-metrics-by-request}

您可以根据请求的类型对请求进行分类，例如 `ListReview`、`GetReview`、`CreateReview`。

1. 创建一个文件，例如 `attribute_gen_service.yaml`，并使用以下内容保存它。
   这将会添加 `istio.attributegen` 插件。它还创建一个属性 `istio_operationId` 并使用类别值填充此属性以计为指标。

    此配置是特定于服务的，因为请求路径通常是特定于服务的。

    {{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: istio-attributegen-filter
spec:
  selector:
    matchLabels:
      app: reviews
  url: https://storage.googleapis.com/istio-build/proxy/attributegen-359dcd3a19f109c50e97517fe6b1e2676e870c4d.wasm
  imagePullPolicy: Always
  phase: AUTHN
  pluginConfig:
    attributes:
    - output_attribute: "istio_operationId"
      match:
        - value: "ListReviews"
          condition: "request.url_path == '/reviews' && request.method == 'GET'"
        - value: "GetReview"
          condition: "request.url_path.matches('^/reviews/[[:alnum:]]*$') && request.method == 'GET'"
        - value: "CreateReview"
          condition: "request.url_path == '/reviews/' && request.method == 'POST'"
---
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: custom-tags
spec:
  metrics:
    - overrides:
        - match:
            metric: REQUEST_COUNT
            mode: CLIENT_AND_SERVER
          tagOverrides:
            request_operation:
              value: istio_operationId
      providers:
        - name: prometheus
    {{< /text >}}

1. 使用以下命令应用您的更改：

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

1. 更改生效后，访问 Prometheus 并查找新的或更改的维度，例如 `reviews` Pod 中的 `istio_requests_total`。

## 按响应对指标进行分类 {#classify-metrics-by-response}

您可以使用与请求类似的过程对响应进行分类。请注意，`response_code` 默认情况下该维度已存在。下面的示例将更改它的填充方式。

1. 创建一个文件，例如 `attribute_gen_service.yaml`，并在填写以下内容后保存。
   这将添加 `istio.attributegen` 插件并生成供统计插件使用的 `istio_responseClass` 属性。

    此示例对各种响应进行分类，例如将所有响应分组将 `200` 范围内的代码作为 `2xx` 维度。

    {{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: istio-attributegen-filter
spec:
  selector:
  matchLabels:
    app: productpage
  url: https://storage.googleapis.com/istio-build/proxy/attributegen-359dcd3a19f109c50e97517fe6b1e2676e870c4d.wasm
  imagePullPolicy: Always
  phase: AUTHN
   pluginConfig:
     attributes:
       - output_attribute: istio_responseClass
         match:
           - value: 2xx
             condition: response.code >= 200 && response.code <= 299
           - value: 3xx
             condition: response.code >= 300 && response.code <= 399
           - value: "404"
             condition: response.code == 404
           - value: "429"
             condition: response.code == 429
           - value: "503"
             condition: response.code == 503
           - value: 5xx
             condition: response.code >= 500 && response.code <= 599
           - value: 4xx
             condition: response.code >= 400 && response.code <= 499
---
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: custom-tags
spec:
  metrics:
    - overrides:
        - match:
            metric: REQUEST_COUNT
            mode: CLIENT_AND_SERVER
          tagOverrides:
            response_code:
              value: istio_responseClass
      providers:
        - name: prometheus
    {{< /text >}}

1. 使用以下命令应用您的更改：

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

## 验证结果 {#verify-the-results}

1. 通过向您的应用程序发送流量来生成指标。

1. 访问 Prometheus 并查找新的或更改的维度，例如 `2xx`。
   或者，使用以下命令验证 Istio 是否为您的新维度生成数据：

    {{< text bash >}}
    $ kubectl exec pod-name -c istio-proxy -- curl -sS 'localhost:15000/stats/prometheus' | grep istio_
    {{< /text >}}

    在输出中，找到指标（例如 `istio_requests_total`）并验证是否存在新的或更改的维度。

## 故障排除 {#troubleshooting}

如果分类未按预期进行，请检查以下潜在原因和解决方法。

对于已应用了配置变更的 Service 所对应的 Pod，审查 Envoy 代理日志。
在使用以下命令配置分类的 Pod (`pod-name`) 上的 Envoy 代理日志中检查服务是否没有报告错误：

{{< text bash >}}
$ kubectl logs pod-name -c istio-proxy | grep -e "Config Error" -e "envoy wasm"
{{< /text >}}

此外，通过在以下命令的输出中查找重新启动的迹象，确保没有 Envoy 代理崩溃：

{{< text bash >}}
$ kubectl get pods pod-name
{{< /text >}}

## 清理 {#cleanup}

删除 yaml 配置文件。

{{< text bash >}}
$ kubectl -n istio-system delete -f attribute_gen_service.yaml
{{< /text >}}
