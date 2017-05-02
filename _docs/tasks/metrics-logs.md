---
title: Collecting Metrics and Logs
overview: This task shows you how to configure Mixer to collect metrics and logs from Envoy instances in every pod.

order: 80

layout: docs
type: markdown
---

This task shows how to configure Mixer to automatically gather telemetry
for a service within a cluster. At the end of this task, two new metrics
will be enabled for calls to a service within your cluster, as well as an
additional log stream.

The [BookInfo sample application](/docs/samples/bookinfo.html) is used
as the example application throughout this task.

## Before you begin
* [Install Istio](/docs/tasks/installing-istio.html) in your kubernetes
  cluster and deploy an application. Be sure to install the optional
  add-ons ([Prometheus](https://prometheus.io) and [Grafana](https://grafana.com/)),
  as we will use them to verify task success.

## Collecting new telemetry data

1. Validate that you can retrieve Mixer configuration via the `istioctl`
   tool by retrieving the rules for the `global` scope and the `global`
   subject. These rules apply to all requests within the Istio cluster.

   ```bash
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

   ```bash
   $ kubectl port-forward $(kubectl get pod -l istio=mixer -o jsonpath='{.items[0].metadata.name}') 9094:9094 &
   $ export ISTIO_MIXER_API_SERVER=localhost:9094
   ```

1. Create a new YAML file (`new_rule.yml`) to hold configuration for
   the new metrics that Istio will collect automatically.

   ```bash
   $ cat <<EOF >new_rule.yml
   revision: "1"
   rules:
   - aspects:
     - adapter: prometheus
       kind: metrics
       params:
         metrics:
         - descriptor_name: response_size
           value: response.size | 0
           labels:
             source: source.service | "unknown"
             target: target.service | "unknown"
             service: api.name | target.labels["app"] | "unknown"
             method: api.method | request.path | "unknown"
             response_code: response.code | 200
         - descriptor_name: request_size
           value: request.size | 0
           labels:
             source: source.service | "unknown"
             target: target.service | "unknown"
             service: api.name | target.labels["app"] | "unknown"
             method: api.method | request.path | "unknown"
             response_code: response.code | 200
     - adapter: stdioLogger
       kind: access-logs
       params:
         logName: combined_log
         log:
           descriptor_name: accesslog.combined
           template_expressions:
             originIp: origin.ip
             sourceUser: origin.user
             timestamp: request.time
             method: request.method
             url: request.path
             protocol: request.scheme
             responseCode: response.code
             responseSize: response.size
             referer: request.headers["referer"]
             userAgent: request.headers["user-agent"]
           labels:
             originIp: origin.ip
             sourceUser: origin.user
             timestamp: request.time
             method: request.method
             url: request.path
             protocol: request.scheme
             responseCode: response.code
             responseSize: response.size
             referer: request.headers["referer"]
             userAgent: request.headers["user-agent"]
   EOF
   ```

1. Pick a target service for the new rule. If using the BookInfo
   sample, select `reviews.default.svc.cluster.local`. You will need to
   use a fully-qualified domain name for the service in the following
   steps.

1. Validate that the selected service has no service-specific rules
   already applied with `istioctl`.

   ```bash
   $ istioctl mixer rule get global reviews.default.svc.cluster.local
   Error: Not Found
   ```

   If your selected service has service-specific rules, update `new_rule.yml`
   to include the existing rules appropriately. This should be as simple
   as appending the rule from `new_rule.yml` to the existing `rules`
   block and then saving the updated content back over `new_rule.yml`.

1. Push the new configuration to Mixer for a specific service, via
   `istioctl`.

   ```bash
   $ istioctl mixer rule create global reviews.default.svc.cluster.local -f new_rule.yml
   ```

1. Send traffic to that service.

   For the BookInfo sample, this can be achieved by simply visiting the
   `/productpage` application page.

1. Verify that the new metrics are being collected.

   To verify directly against Mixer, visit the exposed Prometheus port.
   The simplest way to do that is to port-forward and visit via `localhost`.

   ```bash
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

1. Verify that the logs stream has been created and is being populated
   for requests.

   Find the pod for Mixer as follows:

   ```bash
   $ kubectl get pods
   NAME                                        READY     STATUS    RESTARTS   AGE
   ...
   istio-mixer-88439463-xnllx                  1/1       Running   0          14m
   ...
   ```

   Then, look through the logs for the pod as follows:

   ```bash
   $ kubectl logs istio-mixer-88439463-xnllx | grep \"combined_log\"
   {"logName":"combined_log","labels":{"referer":"","responseSize":871,"timestamp":"2017-04-29T02:11:54.989466058Z","url":"/reviews","userAgent":"python-requests/2.11.1"},"textPayload":"- - - [29/Apr/2017:02:11:54 +0000] \"- /reviews -\" - 871 - python-requests/2.11.1"}
   ```

## Understanding the new telemetry rule

In this task, you added a new rule for a service within your cluster.
The new rule instructed Mixer to automatically generate and report two
new metrics and a new log stream for all traffic going to a specific
service.

The new rule was comprised of a new `aspect` definitions. These `aspect`
definitions were for the aspect kind of `metrics` and `access-logs`.

### Understanding the rule's metrics aspect

The `metrics` aspect direct Mixer to report metrics to the `prometheus`
adapter. The adapter `params` tell Mixer _how_ to generate metric values
for any given request, based on the attributes reported by Envoy (and
generated by Mixer itself).

The schema for the metrics come from predefined metric `descriptors`
known to Mixer. In this task, the descriptors used were `request_size`
and `response_size`. Both metric descriptors use buckets to record a
distribution of values, making it easier for the backend metrics systems
to provide summary statistics for a bunch of requests in aggregate (as
is often desirable when looking at request and response sizes).

The new rule instructs Mixer to generate values for the metrics based
on the values of attributes, `request.size` and `response.size`
respectively. Default values of `0` were added, in case Envoy does not
report the values as expected.

A set of dimensions were also configured for each metric value, via the
`labels` chunks of configuration. For both of the new metrics, the dimensions
were `source`, `target`, `service`, `method`, and `response_code`.

Dimensions provide a way to slice, aggregate, and analyze metric data
according to different needs and directions of inquiry. For instance, it
may be desirable to only consider response sizes for non-error responses
when troubleshooting the rollout of a new application version.

The new rule instructs Mixer to populate values for these dimensions
based on attribute values. For instance, for the `service` dimension, the
new rule requests that the value be taken from the `api.name` attribute.
The rule also instructs Mixer to use the `target.labels["app"]` attribute
if `api.name` is not populated. Finally, if neither attribute has a known
value, the rule instructs Mixer to use a default value of `"unknown"`.

At the moment, it is not possible to programmatically generate new metric
descriptors for use within Mixer. As a result, all new metric configurations
must use one of the predefined metrics descriptors: `request_count`,
`request_duration`, `request_size`, and `response_size`.

Work is ongoing to extend the Mixer Config API to add support for creating
new descriptors.

### Understanding the rule's access_logs aspect

The `access-logs` aspect directs Mixer to send access logs to the `stdioLogger`
adapter. The adapter `params` tell Mixer _how_ to generate the access
logs for incoming requests based on attributes reported by Envoy.

The `logName` parameter is used by Mixer to identify a logs stream. In
this task, we used the log name (`combined_log`) to identify the log
stream amidst the rest of the Mixer logging output. This name should be
used to uniquely identify log streams to various logging backends.

The `log` section of the rule describes the shape of the access log that
Mixer will generate when the rule is applied. In this task, we used the
pre-configured definition for an access log named `accesslog.combined`. It
is based on the well-known [Combined Log Format](https://httpd.apache.org/docs/1.3/logs.html#combined).

Access logs use a template to generate a plaintext log from a set of
named arguments. The template is defined in the configured `descriptor`
for the aspect. In this task, the template used is defined in the
descriptor named `accesslog.combined`. The set of inputs to the `template_expressions`
is fixed in the descriptor and cannot be altered in aspect configuration.

The `template_expressions` describe how to translate attribute values
into the named arguments for the template processing. For example, the
value for `userAgent` is to be derived directly from the value for the
attribute `request.headers["user-agent"]`.

Mixer supports structured log generation in addition to plaintext logs. In
this task, we configured a set of `labels` to populate for structured
log generation. These `labels` are populated from attribute values
according to attribute expresssions, in exactly the same manner as the
`template_expressions`.

While it is common practice to include the same set of arguments in the
`labels` as in the `template_expressions`, this is not required. Mixer
will generate the `labels` completely independently of the `template_expressions`.
Operators should feel free to add additional `labels` or remove unwanted
labels to meet their needs.

As with metric descriptors, it is not currently possible to programmatically
generate new access logs descriptors. Work is ongoing to extend the Mixer
Config API to add support for creating new descriptors.

## What's next
* Learn more about [Mixer](/docs/concepts/policy-and-control/mixer.html) and [Mixer Config](/docs/concepts/policy-and-control/mixer-config.html).
* Discover the full [Attribute Vocabulary](/docs/reference/attribute-vocabulary.html).
* Read the reference guide to [Writing Config](/docs/reference/writing-config.html).
* See the [Configuring Mixer](/docs/tasks/configuring-mixer.html) task.
