---
title: OpenCensus Agent
description: Learn how to configure the proxies to send OpenCensus-formatted spans to OpenTelemetry Collector.
weight: 10
keywords: [telemetry,tracing,opencensus,opentelemetry,span]
aliases:
    - /docs/tasks/opencensusagent-tracing.html
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

After completing this task, you will understand how to have your application participate in tracing with the OpenCensus Agent, export those traces to the OpenTelemetry collector, and have the OpenTelemetry collector export those spans to Jaeger.

To learn how Istio handles tracing, visit this task's [overview](../overview).

{{< boilerplate before-you-begin-egress >}}

* Install [Jaeger](/docs/ops/integrations/jaeger/#installation) into your cluster.

* Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

## Configure tracing

If you used an `IstioOperator` CR to install Istio, add the following field to your configuration:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
    meshConfig:
        defaultProviders:
            tracing:
            - "opencensus"
        enableTracing: true
        extensionProviders:
        - name: "opencensus"
          opencensus:
              service: "opentelemetry-collector.istio-system.svc.cluster.local"
              port: 55678
              context:
              - W3C_TRACE_CONTEXT
{{< /text >}}

With this configuration Istio is installed with OpenCensus Agent as the default tracer. Trace data will be sent to an OpenTelemetry backend.

By default, Istio's OpenCensus Agent tracing will attempt to read and write 4 types of trace headers:

* B3,
* gRPC's binary trace header,
* [W3C Trace Context](https://www.w3.org/TR/trace-context/),
* and Cloud Trace Context.

If you supply multiple values, the proxy will attempt to read trace headers in the specified order, using the first one that successfully parsed and writing all headers. This permits interoperability between services that use different headers, e.g. one service that propagates B3 headers and one that propagates W3C Trace Context headers can participate in the same trace. In this example we only use W3C Trace Context.

In the default profile the sampling rate is 1%. Increase it to 100% using the [Telemetry API](/docs/tasks/observability/telemetry/):

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - randomSamplingPercentage: 100.00
EOF
{{< /text >}}

### Deploy OpenTelemetry Collector

OpenTelemetry collector supports exporting traces to [several backends by default](https://github.com/open-telemetry/opentelemetry-collector/blob/master/exporter/README.md#general-information) in the core distribution. Other backends are available in the [contrib distribution](https://github.com/open-telemetry/opentelemetry-collector-contrib) of OpenTelemetry collector.

Deploy and configure the collector to receive and export spans to the Jaeger instance:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: opentelemetry-collector
  namespace: istio-system
  labels:
    app: opentelemetry-collector
data:
  config: |
    receivers:
      opencensus:
        endpoint: 0.0.0.0:55678
    processors:
      memory_limiter:
        limit_mib: 100
        spike_limit_mib: 10
        check_interval: 5s
    exporters:
      zipkin:
        # Export via zipkin for easy querying
        endpoint: http://zipkin.istio-system.svc:9411/api/v2/spans
      logging:
        loglevel: debug
    extensions:
      health_check:
        port: 13133
    service:
      extensions:
      - health_check
      pipelines:
        traces:
          receivers:
          - opencensus
          processors:
          - memory_limiter
          exporters:
          - zipkin
          - logging
---
apiVersion: v1
kind: Service
metadata:
  name: opentelemetry-collector
  namespace: istio-system
  labels:
    app: opentelemetry-collector
spec:
  type: ClusterIP
  selector:
    app: opentelemetry-collector
  ports:
    - name: grpc-opencensus
      port: 55678
      protocol: TCP
      targetPort: 55678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opentelemetry-collector
  namespace: istio-system
  labels:
    app: opentelemetry-collector
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opentelemetry-collector
  template:
    metadata:
      labels:
        app: opentelemetry-collector
    spec:
      containers:
        - name: opentelemetry-collector
          image: "otel/opentelemetry-collector:0.49.0"
          imagePullPolicy: IfNotPresent
          command:
            - "/otelcol"
            - "--config=/conf/config.yaml"
          ports:
            - name: grpc-opencensus
              containerPort: 55678
              protocol: TCP
          volumeMounts:
            - name: opentelemetry-collector-config
              mountPath: /conf
          readinessProbe:
            httpGet:
              path: /
              port: 13133
          resources:
            requests:
              cpu: 40m
              memory: 100Mi
      volumes:
        - name: opentelemetry-collector-config
          configMap:
            name: opentelemetry-collector
            items:
              - key: config
                path: config.yaml
EOF
{{< /text >}}

## Access the dashboard

[Remotely Accessing Telemetry Addons](/docs/tasks/observability/gateways) details how to configure access to the Istio addons through a gateway.

For testing (and temporary access), you may also use port-forwarding. Use the following, assuming you've deployed Jaeger to the `istio-system` namespace:

{{< text bash >}}
$ istioctl dashboard jaeger
{{< /text >}}

## Generating traces using the Bookinfo sample

1.  When the Bookinfo application is up and running, access `http://$GATEWAY_URL/productpage` one or more times
    to generate trace information.

    {{< boilerplate trace-generation >}}

1.  From the left-hand pane of the dashboard, select `productpage.default` from the **Service** drop-down list and click
    **Find Traces**:

    {{< image link="./istio-tracing-list.png" caption="Tracing Dashboard" >}}

1.  Click on the most recent trace at the top to see the details corresponding to the
    latest request to `/productpage`:

    {{< image link="./istio-tracing-details.png" caption="Detailed Trace View" >}}

1.  The trace is comprised of a set of spans,
    where each span corresponds to a Bookinfo service, invoked during the execution of a `/productpage` request, or
    internal Istio component, for example: `istio-ingressgateway`.

As you also configured logging exporter in OpenTelemetry Collector, you can see traces in the logs as well:

{{< text bash >}}
$ kubectl -n istio-system logs deploy/opentelemetry-collector
{{< /text >}}

## Cleanup

1.  Remove any `istioctl` processes that may still be running using control-C or:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

1.  If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.

1.  Remove the `Jaeger` addon:

    {{< text bash >}}
    $ kubectl delete -f {{< github_file >}}/samples/addons/jaeger.yaml
    {{< /text >}}

1.  Remove the `OpenTelemetry Collector`:

    {{< text bash >}}
    $ kubectl delete -n istio-system cm opentelemetry-collector
    $ kubectl delete -n istio-system svc opentelemetry-collector
    $ kubectl delete -n istio-system deploy opentelemetry-collector
    {{< /text >}}

1.  Remove, or set to `""`, the `meshConfig.extensionProviders` and `meshConfig.defaultProviders` setting in your Istio install configuration.

1.  Remove the telemetry resource:

    {{< text bash >}}
    $ kubectl delete telemetries.telemetry.istio.io -n istio-system mesh-default
    {{< /text >}}
