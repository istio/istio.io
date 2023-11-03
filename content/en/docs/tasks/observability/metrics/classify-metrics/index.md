---
title: Classifying Metrics Based on Request or Response
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
AttributeGen plugin that groups requests
into a fixed number of logical operations. For example, you can create an operation named
`GetReviews`, which is a common way to identify operations using the
[`Open API Spec operationId`](https://swagger.io/docs/specification/paths-and-operations/).
This information is injected into request processing as `istio_operationId` attribute with
value equal to `GetReviews`.
You can use the attribute as a dimension in Istio standard metrics. Similarly,
you can track metrics based on other operations like `ListReviews` and
`CreateReviews`.

## Classify metrics by request

You can classify requests based on their type, for example `ListReview`,
`GetReview`, `CreateReview`.

1. Create a file, for example `attribute_gen_service.yaml`, and save it with the
   following contents. This adds the `istio.attributegen` plugin.
   It also creates an attribute, `istio_operationId` and populates it
   with values for the categories to count as metrics.

    This configuration is service-specific since request paths are typically
    service-specific.

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

1. Apply your changes using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

1. After the changes take effect, visit Prometheus and look for the new or
   changed dimensions, for example `istio_requests_total` in `reviews` pods.

## Classify metrics by response

You can classify responses using a similar process as requests. Do note that the `response_code` dimension already exists by default.
The example below will change how it is populated.

1. Create a file, for example `attribute_gen_service.yaml`, and save it with
   the following contents. This adds the `istio.attributegen` plugin and
   generates the `istio_responseClass` attribute used by the stats plugin.

    This example classifies various responses, such as grouping all response
    codes in the `200` range as a `2xx` dimension.

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

1. Apply your changes using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
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
