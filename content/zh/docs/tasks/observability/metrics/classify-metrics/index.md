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

Istio 允许您使用
[AttributeGen 插件](/zh/docs/reference/config/proxy_extensions/attributegen/) 创建分类规则，该插件将请求分组为固定数量的逻辑操作。
例如，您可以创建一个名为 `GetReviews` 的操作，
，这是使用 [`Open API Spec operationId`](https://swagger.io/docs/specification/paths-and-operations/)。
此信息作为 `istio_operationId` 属性注入到请求处理中值等于 `GetReviews`。
您可以将属性用作 Istio 标准指标中的维度。
相似地，您可以根据其他操作（例如 `ListReviews` 和 `CreateReviews`)。

有关详细信息，请参阅[参考内容](/zh/docs/reference/config/proxy_extensions/attributegen/)。

Istio 使用 Envoy 代理生成指标并在 `EnvoyFilter` 在
[manifests/charts/istio-control/istio-discovery/templates/telemetryv2_{{< istio_version >}}.yaml]({{<github_blob>}}/manifests/charts/istio-control/istio-discovery/templates/telemetryv2_{{< istio_version >}}.yaml)。
因此，编写分类规则涉及将属性添加到 `EnvoyFilter`。

## 按请求分类指标{#classify-metrics-by-request}

您可以根据请求的类型对请求进行分类，例如： `ListReview` 、 `GetReview` 、 `CreateReview`。

1. 创建一个文件，例如 `attribute_gen_service.yaml`，并使用以下内容保存它。
   这会将 `istio.attributegen` 插件添加到 `EnvoyFilter`。它还创建一个属性， `istio_operationId` 并使用类别值填充它以计为指标。

   此配置是特定于服务的，因为请求路径通常是特定于服务的。

    {{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: istio-attributegen-filter
spec:
  workloadSelector:
    labels:
      app: reviews
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      proxy:
        proxyVersion: '1\.9.*'
      listener:
        filterChain:
          filter:
            name: "envoy.http_connection_manager"
            subFilter:
              name: "istio.stats"
    patch:
      operation: INSERT_BEFORE
      value:
        name: istio.attributegen
        typed_config:
          "@type": type.googleapis.com/udpa.type.v1.TypedStruct
          type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
          value:
            config:
              configuration:
                "@type": type.googleapis.com/google.protobuf.StringValue
                value: |
                  {
                    "attributes": [
                      {
                        "output_attribute": "istio_operationId",
                        "match": [
                          {
                            "value": "ListReviews",
                            "condition": "request.url_path == '/reviews' && request.method == 'GET'"
                          },
                          {
                            "value": "GetReview",
                            "condition": "request.url_path.matches('^/reviews/[[:alnum:]]*$') && request.method == 'GET'"
                          },
                          {
                            "value": "CreateReview",
                            "condition": "request.url_path == '/reviews/' && request.method == 'POST'"
                          }
                        ]
                      }
                    ]
                  }
              vm_config:
                runtime: envoy.wasm.runtime.null
                code:
                  local: { inline_string: "envoy.wasm.attributegen" }
    {{< /text >}}

1. 使用以下命令应用您的更改：

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

1. 查找 `stats-filter-{{< istio_version >}}` `EnvoyFilter` 资源从 `istio-system` 命名空间中 `istio-system`，使用以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter | grep ^stats-filter-{{< istio_version >}}
    stats-filter-{{< istio_version >}}                    2d
    {{< /text >}}

1. 创建 `EnvoyFilter` 配置的本地文件系统副本，使用以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter stats-filter-{{< istio_version >}} -o yaml > stats-filter-{{< istio_version >}}.yaml
    {{< /text >}}

1. 使用文本编辑器打开 `stats-filter-{{< istio_version >}}.yaml` 并找到
   `name: istio.stats` 扩展配置。更新它以映射 `request_operation`
   `requests_total` 标准指标中的指标到 `istio_operationId` 属性。
   更新后的配置文件部分应如下所示。

    {{< text json >}}
        name: istio.stats
        typed_config:
          '@type': type.googleapis.com/udpa.type.v1.TypedStruct
          type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
          value:
            config:
              configuration:
                "@type": type.googleapis.com/google.protobuf.StringValue
                value: |
                  {
                    "metrics": [
                     {
                       "name": "requests_total",
                       "dimensions": {
                         "request_operation": "istio_operationId"
                       }
                     }]
                  }
    {{< /text >}}

1. 保存 `stats-filter-{{< istio_version >}}.yaml`，然后使用以下命令应用配置：

    {{< text bash >}}
    $ kubectl -n istio-system apply -f stats-filter-{{< istio_version >}}.yaml
    {{< /text >}}

1. 将以下配置添加到网格配置中。这导致添加了 `request_operation` 作为
   `istio_requests_total` 指标的新维度。
   没有它，一个名为   `envoy_request_operation___somevalue___istio_requests_total` 的新指标
   被建造。

    {{< text yaml >}}
    meshConfig:
      defaultConfig:
        extraStatTags:
        - request_operation
    {{< /text >}}

1. 通过向您的应用程序发送流量来生成指标。

1. 更改生效后，访问 Prometheus 并查找新的或更改的维度，例如： `istio_requests_total`。

## 按响应对指标进行分类{#classify-metrics-by-response}

您可以使用与请求类似的过程对响应进行分类。请注意，`response_code` 默认情况下该维度已存在。下面的示例将更改它的填充方式。

1. 创建一个文件，例如 `attribute_gen_service.yaml`，并使用以下内容。
   这会将 `istio.attributegen` 插件添加到 `EnvoyFilter` 并生成  `istio_responseClass` 属性供统计插件。

    此示例对各种响应进行分类，例如将所有响应分组将 `200` 范围内的代码作为 `2xx` 维度。

    {{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: istio-attributegen-filter
spec:
  workloadSelector:
    labels:
      app: productpage
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      proxy:
        proxyVersion: '1\.9.*'
      listener:
        filterChain:
          filter:
            name: "envoy.http_connection_manager"
            subFilter:
              name: "istio.stats"
    patch:
      operation: INSERT_BEFORE
      value:
        name: istio.attributegen
        typed_config:
          "@type": type.googleapis.com/udpa.type.v1.TypedStruct
          type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
          value:
            config:
              configuration:
                "@type": type.googleapis.com/google.protobuf.StringValue
                value: |
                  {
                    "attributes": [
                      {
                        "output_attribute": "istio_responseClass",
                        "match": [
                          {
                            "value": "2xx",
                            "condition": "response.code >= 200 && response.code <= 299"
                          },
                          {
                            "value": "3xx",
                            "condition": "response.code >= 300 && response.code <= 399"
                          },
                          {
                            "value": "404",
                            "condition": "response.code == 404"
                          },
                          {
                            "value": "429",
                            "condition": "response.code == 429"
                          },
                          {
                            "value": "503",
                            "condition": "response.code == 503"
                          },
                          {
                            "value": "5xx",
                            "condition": "response.code >= 500 && response.code <= 599"
                          },
                          {
                            "value": "4xx",
                            "condition": "response.code >= 400 && response.code <= 499"
                          }
                        ]
                      }
                    ]
                  }
              vm_config:
                runtime: envoy.wasm.runtime.null
                code:
                  local: { inline_string: "envoy.wasm.attributegen" }
    {{< /text >}}

1. 使用以下命令应用您的更改：

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

1. 从 `istio-system` 中找到 `stats-filter-{{< istio_version >}}` `EnvoyFilter` 资源
   命名空间，使用以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter | grep ^stats-filter-{{< istio_version >}}
    stats-filter-{{< istio_version >}}                    2d
    {{< /text >}}

1. 创建 `EnvoyFilter` 配置的本地文件系统副本，使用以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter stats-filter-{{< istio_version >}} -o yaml > stats-filter-{{< istio_version >}}.yaml
    {{< /text >}}

1. 使用文本编辑器打开 `stats-filter-{{< istio_version >}}.yaml` 并找到 `name: istio.stats` 扩展配置。
   更新它以映射 `response_code` 在 `requests_total` 标准指标中的维度到 `istio_responseClass` 属性。
   更新后的配置文件部分应如下所示。

    {{< text json >}}
        name: istio.stats
        typed_config:
          '@type': type.googleapis.com/udpa.type.v1.TypedStruct
          type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
          value:
            config:
              configuration:
                "@type": type.googleapis.com/google.protobuf.StringValue
                value: |
                  {
                    "metrics": [
                     {
                       "name": "requests_total",
                       "dimensions": {
                         "response_code": "istio_responseClass"
                       }
                     }]
                  }
    {{< /text >}}

1. 保存 `stats-filter-{{< istio_version >}}.yaml`，然后使用以下命令应用配置：

    {{< text bash >}}
    $ kubectl -n istio-system apply -f stats-filter-{{< istio_version >}}.yaml
    {{< /text >}}

## 验证结果{#verify-the-results}

1. 通过向您的应用程序发送流量来生成指标。

1. 访问 Prometheus 并查找新的或更改的维度，例如： `2xx`。
   或者，使用以下命令验证 Istio 是否为您的新维度生成数据：

    {{< text bash >}}
    $ kubectl exec pod-name -c istio-proxy -- curl -sS 'localhost:15000/stats/prometheus' | grep istio_
    {{< /text >}}

    在输出中，找到指标（例如：`istio_requests_total`）并验证是否存在新的或更改的维度。

## 故障排除{#troubleshooting}

如果分类未按预期进行，请检查以下潜在原因和解决方法。

查看具有您应用了配置更改的服务的 Pod 的 Envoy 代理日志。
在您使用以下命令配置分类的 Pod (`pod-name`) 上的 Envoy 代理日志中检查服务是否没有报告错误：

{{< text bash >}}
$ kubectl logs pod-name -c istio-proxy | grep -e "Config Error" -e "envoy wasm"
{{< /text >}}

此外，通过在以下命令的输出中查找重新启动的迹象，确保没有 Envoy 代理崩溃：

{{< text bash >}}
$ kubectl get pods pod-name
{{< /text >}}
