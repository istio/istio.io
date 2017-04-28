---
title: Collecting Metrics and Logs
overview: This task shows you how to configure Mixer to collect metrics and logs from Envoy instances in every pod.

order: 80

bodyclass: docs
layout: docs
type: markdown
---

This task shows how to configure Mixer to automatically gather additional
telemetry for a running cluster. At the end of this task, two new metrics
will be enabled for calls to a service within your cluster, as well as an
additional log stream.

The [BookInfo sample application]({{site.bareurl}}/docs/samples/bookinfo.html)
is used as the example application throughout this task.

__TODO__: Add log stream config bits

## Before you begin
* [Install Istio](/docs/tasks/installing-istio.html) in your kubernetes
  cluster and deploy an application. Be sure to install the optional
  add-ons ([Prometheus](https://prometheus.io) and [Grafana](https://grafana.com/)),
  as we will use them to verify task success.

## Collecting new telemetry data

1. Validate that you can retrieve Mixer configuration via the `istioctl`
   tool by retrieving the rules for the `global` scope and the `global`
   subject. These rules apply to all requests within the Istio cluster.

   ```shell
   $ istioctl mixer rule get global global
   revision: "2022"
   rules:
   - aspects:
     - kind: attributes
       params:
         attribute_bindings:
           source.ip: sourcePodIp
           source.labels: sourceLabels
           source.name: sourcePodName
           source.namespace: sourceNamespace
           source.service: sourceService
           source.serviceAccount: sourceServiceAccountName
           target.ip: targetPodIp
           target.labels: targetLabels
           target.name: targetPodName
           target.namespace: targetNamespace
           target.service: targetService
           target.serviceAccount: targetServiceAccountName
         input_expressions:
           originUID: origin.uid | ""
           sourceUID: source.uid | ""
           targetService: request.headers["authority"] | request.host | ""
           targetUID: target.uid | ""
     - kind: quotas
       params:
         quotas:
         - descriptorName: RequestCount
           expiration: 1s
           maxAmount: 5
     - adapter: prometheus
       kind: metrics
       params:
         metrics:
         - descriptor_name: request_count
           labels:
             method: api.method | request.path | "unknown"
             response_code: response.code | 200
             service: api.name | target.labels["app"] | "unknown"
             source: source.service | "unknown"
             target: target.service | "unknown"
           value: "1"
         - descriptor_name: request_duration
           labels:
             method: api.method | request.path | "unknown"
             response_code: response.code | 200
             service: api.name | target.labels["app"] | "unknown"
             source: source.service | "unknown"
             target: target.service | "unknown"
           value: response.latency | response.duration | "0ms"
     - kind: access-logs
       params:
         log:
           descriptor_name: accesslog.common
           labels:
             method: request.method
             originIp: origin.ip
             protocol: request.scheme
             responseCode: response.code
             responseSize: response.size
             sourceUser: origin.user
             timestamp: request.time
             url: request.path
           template_expressions:
             method: request.method
             originIp: origin.ip
             protocol: request.scheme
             responseCode: response.code
             responseSize: response.size
             sourceUser: origin.user
             timestamp: request.time
             url: request.path
         logName: access_log
   subject: namespace:ns
   ```

   If you have issues connecting via `istioctl`, you will need to provide
   the tool with a way to connect to Mixer. This can be achieved by
   setting up port-forwarding to the Mixer Config API port (typically, 9094).

   ```shell
   $ kubectl port-forward $(kubectl get pod -l istio=mixer -o jsonpath='{.items[0].metadata.name}') 9094:9094 &
   $ export ISTIO_MIXER_API_SERVER=localhost:9094
   ```

1. Create a new yaml file (`new_metrics.yml`) to hold configuration for
   the new metrics that Istio will collect automatically.

   ```shell
   $ cat <<EOF >new_metrics.yml
   revision: "1"
   rules:
   - aspects:
     - adapter: prometheus
       kind: metrics
       params:
         metrics:
         - descriptor_name:  response_size
           value: response.size | 0
           labels:
             source: source.service | "unknown"
             target: target.service | "unknown"
             service: api.name | target.labels["app"] | "unknown"
             method: api.method | request.path | "unknown"
             response_code: response.code | 200
         - descriptor_name:  request_size
           value: request.size | 0
           labels:
             source: source.service | "unknown"
             target: target.service | "unknown"
             service: api.name | target.labels["app"] | "unknown"
             method: api.method | request.path | "unknown"
             response_code: response.code | 200
   EOF
   ```

1. Pick a target service for the new metrics rule. If using the BookInfo
   sample, select `reviews.default.svc.cluster.local`.

1. Validate that the selected service has no service-specific rules
   already applied with `istioctl`.

   ```shell
   $ istioctl mixer rule get global reviews.default.svc.cluster.local
   Error: Not Found
   ```

   If your selected service has service-specific rules, update `new_metrics.yml`
   to include the existing rules appropriately. This should be as simple
   as appending the rule from `new_metrics.yml` to the existing `rules`
   block and then saving the updated content back over `new_metrics.yml`.

1. Push the new configuration to Mixer for a specific service, via
   `istioctl`.

   ```shell
   $ istioctl mixer rule create global reviews.default.svc.cluster.local -f new_metrics.yml
   ```

1. Send traffic to that service.

   For the BookInfo sample, this can be achieved by simply visiting the
   `/productpage` application page.

1. Verify that the new metrics are being collected.

   _TODO_: instructions for grafana

   To verify directly against Mixer, visit the exposed Prometheus port.
   The simplest way to do that is to port-forward and visit via `localhost`.

   ```shell
   $ kubectl port-forward $(kubectl get pod -l istio=mixer -o jsonpath='{.items[0].metadata.name}') 42422:42422 &
   ```

   Browse to `localhost:42422/metrics`. Search for `request_size`. You
   will find text similar to:

   ```
   # HELP request_size request size by source, target, and service
   # TYPE request_size histogram
   request_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="1"} 1
   request_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="10"} 1
   request_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="100"} 1
   request_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="1000"} 1
   request_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="10000"} 1
   request_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="100000"} 1
   request_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="1e+06"} 1
   request_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="1e+07"} 1
   request_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="1e+08"} 1
   request_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="+Inf"} 1
   request_size_sum{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local"} 0
   request_size_count{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local"} 1
   # HELP response_size response size by source, target, and service
   # TYPE response_size histogram
   response_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="1"} 0
   response_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="10"} 0
   response_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="100"} 0
   response_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="1000"} 1
   response_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="10000"} 1
   response_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="100000"} 1
   response_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="1e+06"} 1
   response_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="1e+07"} 1
   response_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="1e+08"} 1
   response_size_bucket{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local",le="+Inf"} 1
   response_size_sum{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local"} 355
   response_size_count{method="/reviews",response_code="200",service="reviews",source="productpage.default.svc.cluster.local",target="reviews.default.svc.cluster.local"} 1

   ```



## Understanding the new telemetry rule

In this task, you added a new rule for a service within your cluster.
The new rule instructed Mixer to automatically generate and report two
new metrics for all traffic going to a specific service.

The new rule was comprised of a new `aspect` definition. This `aspect`
definition was for the aspect kind of `metrics` and directed Mixer to
report the metrics to the `prometheus` adapter. The `metrics` portion of
the rule instructed Mixer on _how_ to generate metric values for any given
request, based on the attributes reported by Envoy (and generated by
Mixer itself).

The schema for the metrics came from predefined metric `descriptors`
known to Mixer. In this task, the descriptors used were `request_size`
and `response_size`. Both metric descriptors use buckets to record a
distribution of values, making it easier for the backend metrics systems
to provide summary statistics for a bunch of requests in aggregate (as
is often desirable when looking at request and response sizes).

The new rules instructed Mixer to generate values for the metrics based
on the values of attributes , `request.size` and `response.size`
respectively. Default values of `0` were added, in case Envoy did not
report the values as expected.

A set of dimensions were also configured for each metric value, via the
`labels` chunks of configuration. For both of the new metrics, the dimensions
were`source`, `target`, `service`, `method`, and `response_code`.

Dimensions provide a way to slice, aggregate, and analyze metric data according to different
needs and directions of inquiry. For instance, it may be desirable to only
consider response sizes for non-error responses when troubleshooting the
rollout of a new application version.

The new rules instructed Mixer to populate values for these dimensions
based on attribute values. For instance, for the `service` dimension, the
new rule requested that the value be taken from the `api.name` attribute.
The rule also instructs Mixer to use the `target.labels["app"]` attribute
if `api.name` is not populated. Finally, if neither attribute has a known
value, Mixer is instructed to use a default value of `"unknown"`.

At the moment, it is not possible to programmatically generate new metric
descriptors for use within Mixer. As a result, all new metric configurations
must use one of the predefined metrics descriptors: `request_count`,
`request_duration`, `request_size`, and `response_size`.

Work is ongoing to extend the Mixer Config API to add support for creating
new descriptors.

## What's next
* Learn more about [Mixer](/docs/concepts/mixer.html) and [Mixer Config](/docs/concepts/mixer-config.html).
* Discover the full [Attribute Vocabulary](/docs/reference/attribute-vocabulary.html).
* Read the reference guide to [Writing Config](/docs/reference/writing-config.html).
* See the [Configuring Mixer](/docs/tasks/configuring-mixer.html) task.



