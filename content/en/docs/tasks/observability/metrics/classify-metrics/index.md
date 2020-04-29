---
title: Classifying Metrics Based on Request or Response (Experimental)
description: This task shows you how to improve telemetry by grouping requests and responses by their type. 
weight: 27
keywords: [telemetry,metrics,classify,request-based,openapispec,swagger]
---

It's useful to visualize telemetry based on the type of requests and responses
handled by services in your mesh. For example, a bookseller tracks the number of
times their web site gets book reviews from a backend service. A book review
request has this structure:

{{< text plain >}}
GET /reviews/{review_id}
{{< /text >}}

Counting the number of review requests becomes complicated by the unbounded
element, `review_id`. If you don't classify requests, you will count
`request_id`s instead of the number of review requests as intended. To resolve
this problem, Istio lets you create classification rules that group requests
into a fixed number of logical operations. For example, create an operation named
`GetReviews`, which is a common way to identify operations using the
[`Open API Spec operationId`](https://swagger.io/docs/specification/paths-and-operations/).
You can use the operation as a dimension in Istio standard metrics. Similarly,
you can track metrics based on other operations like `ListReviews` and
`CreateReviews`.

Istio lets you create classification rules
that group requests into a more useful dimension for your telemetry, such as
creating and counting the results of a higher-level `GetReviews` dimension.

For more information, see the
[reference content](/docs/reference/config/proxy_extensions/attributegen/).

Istio uses the Envoy proxy to generate metrics and provides its configuration in
the `EnvoyFilter` at
[`manifests/charts/istio-control/istio-discovery/templates/telemetryv2_1.6.yaml`]({{<github_blob>}}/manifests/charts/istio-control/istio-discovery/templates/telemetryv2_1.6.yaml).
As a result, writing classification rules involves adding attributes to the
`EnvoyFilter`.

For more information, see [configuration reference](/docs/reference/config/telemetry/).

## Classify metrics by request

You can classify requests based on their type, for example `ListReview`,
`GetReview`, `CreateReview`.

1. Create a file, for example `attribute_gen_service.yaml`, and save it with the
   following contents. This adds the `istio.attributegen` plugin to the
   `EnvoyFilter`. It also creates an attribute, `istio.operationId` and populates it
   with values for the categories to count as metrics.

    This configuration is service-specific, meaning that you must perform these
    steps on each pod hosting services for which you want to modify metrics.

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
          proxyVersion: '1\.6.*'
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
            type_url: type.googleapis.com/envoy.config.filter.http.wasm.v2.Wasm
            value:
              config:
                configuration: |
                  {
                    "attributes": [
                      {
                        "output_attribute": "istio.operationId",
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

1. Apply your changes using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

1. Find the `stats-filter-1.6` `EnvoyFilter` resource from the `istio-system`
   namespace, using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter | grep ^stats-filter-1.6
    stats-filter-1.6                    2d
    {{< /text >}}

1. Create a local file system copy of the `EnvoyFilter` configuration, using the
   following command:

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter stats-filter-1.6 -o yaml > stats-filter-1.6.yaml
    {{< /text >}}

1. Open `stats-filter-1.6.yaml` with a text editor and locate the
   `envoy.wasm.stats` extension configuration. The default configuration is in
   the `configuration` section and looks like this example:

    {{< text json >}}
    {
    "debug": "false",
    "stat_prefix": "istio"
    }
    {{< /text >}}

1. Edit `stats-filter-1.6.yaml` to add the `request.operation` dimension to the
   standard metrics and associate it with `istio.operationId` using the
   following example:

    {{< text json >}}
    {
    "debug": "false",
    "stat_prefix": "istio",
    "metrics": [
        {
            "name": "requests_total",
            "dimensions": {
              "request_operation": "has(istio.operationId)?istio.operationId:'unknown'",
            }
        }
    ]
    }
    {{< /text >}}

1. Save `stats-filter-1.6.yaml` and then apply the configuration using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f stats-filter-1.6.yaml
    {{< /text >}}

1. Generate metrics by sending traffic to your application.

1. After the changes take effect, visit Prometheus and look for the new or
   changed dimensions, for example `istio_requests_total`.

## Classify metrics by response

You can classify responses using a similar process as requests.

1. Create a file, for example `attribute_gen_service.yaml`, and save it with the
   following contents. This add the `istio.attributegen` plugin to the
   `EnvoyFilter` and generates the `istio.responseClass` attribute used by the
   stats plugin.

    This example classifies various responses, such as grouping all response
    codes in the `200` range as a `2xx` dimension.

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
          proxyVersion: '1\.6.*'
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
            type_url: type.googleapis.com/envoy.config.filter.http.wasm.v2.Wasm
            value:
              config:
                configuration: |
                  {
                    "attributes": [
                      {
                        "output_attribute": "istio.responseClass",
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
                            "value": "401",
                            "condition": "response.code == 401"
                          },
                          {
                            "value": "403",
                            "condition": "response.code == 403"
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

1. Apply your changes using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

1. Find the `stats-filter-1.6` `EnvoyFilter` resource from the `istio-system`
   namespace, using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter | grep ^stats-filter-1.6
    stats-filter-1.6                    2d
    {{< /text >}}

1. Create a local file system copy of the `EnvoyFilter` configuration, using the
   following command:

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter stats-filter-1.6 -o yaml > stats-filter-1.6.yaml
    {{< /text >}}

1. Open `stats-filter-1.6.yaml` with a text editor and locate the
   `envoy.wasm.stats` extension configuration. The default configuration is in
   the `configuration` section like this example:

    {{< text json >}}
    {
    "debug": "false",
    "stat_prefix": "istio"
    }
    {{< /text >}}

1. Edit the configuration section for each instance of the extension
   configuration. For example, to update `response_code` and add
   `request_operation` dimensions to the standard `requests_total` metric,
   change it like this example:

    {{< text json >}}
    {
    "debug": "false",
    "stat_prefix": "istio",
    "metrics": [
        {
            "name": "requests_total",
            "dimensions": {
              "response_code": "has(istio.responseClass)?istio.responseClass:response.code",
              "request_operation": "has(istio.operationId)?istio.operationId:'unknown'"
            }
        }
    ]
    }
    {{< /text >}}

1. Save `stats-filter-1.6.yaml` and then apply the configuration using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f stats-filter-1.6.yaml
    {{< /text >}}

## Verify the results

1. Generate metrics by sending traffic to your application.

1. Visit Prometheus and look for the new or changed dimensions, for example
   `2xx`. Alternatively, use the following command to verify that Istio generates the data for your new dimension:

    {{< text bash >}}
    $ kubectl exec pod-name -c istio-proxy -- curl 'localhost:15000/stats/prometheus' | grep istio_
    {{< /text >}}

    In the output, locate the metric (e.g. `istio_requests_total`) and verify the presence of the new or changed dimension.

## Troubleshooting

If classification does not occur as expected, check the following potential causes and resolutions.

Review the Envoy proxy logs for the pod that has the service on which you applied the configuration change. Check that there are no errors reported by the service in the Envoy proxy logs on the pod, (`pod-name`), where you configured classification by using the following command:

{{< text bash >}}
$ kubectl log pod-name -c istio-proxy | grep "Config Error"
{{< /text >}}

Additionally, ensure that there are no Envoy proxy crashes by looking for signs of restarts in the output of the following command:

{{< text bash >}}
$ kubectl get pods pod-name
{{< /text >}}
