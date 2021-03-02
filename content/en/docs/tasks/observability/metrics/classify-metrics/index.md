---
title: Classifying Metrics Based on Request or Response (Experimental)
description: This task shows you how to improve telemetry by grouping requests and responses by their type.
weight: 27
keywords: [telemetry,metrics,classify,request-based,openapispec,swagger]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

It's useful to visualize telemetry based on the type of requests and responses
handled by services in your mesh. For example, a bookseller tracks the number of times
book reviews are requested. A book review request has this structure:

{{< text plain >}}
GET /reviews/{review_id}
{{< /text >}}

Counting the number of review requests must account for the unbounded element
`review_id`. `GET /reviews/1` followed by `GET /reviews/2` should count as two
requests to get reviews.

Istio lets you create classification rules using the
[AttributeGen plugin](/docs/reference/config/proxy_extensions/attributegen/) that groups requests
into a fixed number of logical operations. For example, you can create an operation named
`GetReviews`, which is a common way to identify operations using the
[`Open API Spec operationId`](https://swagger.io/docs/specification/paths-and-operations/).
This information is injected into request processing as `istio_operationId` attribute with
value equal to `GetReviews`.
You can use the attribute as a dimension in Istio standard metrics. Similarly,
you can track metrics based on other operations like `ListReviews` and
`CreateReviews`.

For more information, see the
[reference content](/docs/reference/config/proxy_extensions/attributegen/).

Istio uses the Envoy proxy to generate metrics and provides its configuration in
the `EnvoyFilter` at
[`manifests/charts/istio-control/istio-discovery/templates/telemetryv2_1.8.yaml`]({{<github_blob>}}/manifests/charts/istio-control/istio-discovery/templates/telemetryv2_1.8.yaml).
As a result, writing classification rules involves adding attributes to the
`EnvoyFilter`.

## Classify metrics by request

You can classify requests based on their type, for example `ListReview`,
`GetReview`, `CreateReview`.

1. Create a file, for example `attribute_gen_service.yaml`, and save it with the
   following contents. This adds the `istio.attributegen` plugin to the
   `EnvoyFilter`. It also creates an attribute, `istio_operationId` and populates it
   with values for the categories to count as metrics.

    This configuration is service-specific since request paths are typically
    service-specific.

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
        proxyVersion: '1\.8.*'
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

1. Apply your changes using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

1. Find the `stats-filter-1.8` `EnvoyFilter` resource from the `istio-system`
   namespace, using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter | grep ^stats-filter-1.8
    stats-filter-1.8                    2d
    {{< /text >}}

1. Create a local file system copy of the `EnvoyFilter` configuration, using the
   following command:

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter stats-filter-1.8 -o yaml > stats-filter-1.8.yaml
    {{< /text >}}

1. Open `stats-filter-1.8.yaml` with a text editor and locate the
   `name: istio.stats` extension configuration. Update it to map `request_operation`
   dimension in the `requests_total` standard metric to `istio_operationId` attribute.
   The updated configuration file section should look like the following.

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

1. Save `stats-filter-1.8.yaml` and then apply the configuration using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f stats-filter-1.8.yaml
    {{< /text >}}

1. Generate metrics by sending traffic to your application.

1. After the changes take effect, visit Prometheus and look for the new or
   changed dimensions, for example `istio_requests_total`.

## Classify metrics by response

You can classify responses using a similar process as requests.

1. Create a file, for example `attribute_gen_service.yaml`, and save it with the
   following contents. This add the `istio.attributegen` plugin to the
   `EnvoyFilter` and generates the `istio_responseClass` attribute used by the
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
        proxyVersion: '1\.8.*'
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

1. Apply your changes using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

1. Find the `stats-filter-1.8` `EnvoyFilter` resource from the `istio-system`
   namespace, using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter | grep ^stats-filter-1.8
    stats-filter-1.8                    2d
    {{< /text >}}

1. Create a local file system copy of the `EnvoyFilter` configuration, using the
   following command:

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter stats-filter-1.8 -o yaml > stats-filter-1.8.yaml
    {{< /text >}}

1. Open `stats-filter-1.8.yaml` with a text editor and locate the
   `name: istio.stats` extension configuration. Update it to map `response_code`
   dimension in the `requests_total` standard metric to `istio_responseClass` attribute.
   The updated configuration file section should look like the following.

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

1. Save `stats-filter-1.8.yaml` and then apply the configuration using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f stats-filter-1.8.yaml
    {{< /text >}}

## Verify the results

1. Generate metrics by sending traffic to your application.

1. Visit Prometheus and look for the new or changed dimensions, for example
   `2xx`. Alternatively, use the following command to verify that Istio generates the data for your new dimension:

    {{< text bash >}}
    $ kubectl exec pod-name -c istio-proxy -- curl -sS 'localhost:15000/stats/prometheus' | grep istio_
    {{< /text >}}

    In the output, locate the metric (e.g. `istio_requests_total`) and verify the presence of the new or changed dimension.

## Troubleshooting

If classification does not occur as expected, check the following potential causes and resolutions.

Review the Envoy proxy logs for the pod that has the service on which you applied the configuration change. Check that there are no errors reported by the service in the Envoy proxy logs on the pod, (`pod-name`), where you configured classification by using the following command:

{{< text bash >}}
$ kubectl logs pod-name -c istio-proxy | grep -e "Config Error" -e "envoy wasm"
{{< /text >}}

Additionally, ensure that there are no Envoy proxy crashes by looking for signs of restarts in the output of the following command:

{{< text bash >}}
$ kubectl get pods pod-name
{{< /text >}}
