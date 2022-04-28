---
title: OpenCensus Agent
description: Learn how to configure the proxies to send OpenCensus-formatted spans to OpenTelemetry Collector.
weight: 10
keywords: [telemetry,tracing,opencensus,opentelemetry,span,port-forwarding]
aliases:
    - /docs/tasks/opencensusagent-tracing.html
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

After completing this task, you will understand how to have your application participate in tracing with the OpenCensus Agent, export those traces to the OpenTelemetry collector, and have the OpenTelemetry collector export those spans to Jaeger.

To learn how Istio handles tracing, visit this task's [overview](../overview).

## Setup Istio and Tracing

Save to following configuration to `tracing.yaml`:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
    namespace: istio-system
    name: config-istiocontrolplane
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
                - B3
                - W3C_TRACE_CONTEXT
{{< /text >}}

To install Istio on a new cluster run:

{{< text bash >}}
$ istioctl install -f tracing.yaml
{{< /text >}}

With this configuration Istio is installed with OpenCensus Agent as the default tracer. Trace data will be sent to a OpenTelemetry backend.

By default, Istio's OpenCensus Agent tracing will attempt to read and write 4 types of trace headers:

- B3,
- gRPC's binary trace header,
- [W3C Trace Context](https://www.w3.org/TR/trace-context/),
- and Cloud Trace Context.

If you supply multiple values, the proxy will attempt to read trace headers in the specified order, using the first one that successfully parsed and writing all headers. This permits interoperability between services that use different headers, e.g. one service that propagates B3 headers and one that propagates W3C Trace Context headers can participate in the same trace. In this example we only use W3C Trace Context.

In the default profile the sampling rate is 1% configure it using the Telemetry API to 100%:

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

### Install the backend

For this example, we will use Jaeger as the backend. OpenTelemetry collector supports exporting traces to a [several backends by default](https://github.com/open-telemetry/opentelemetry-collector/blob/master/exporter/README.md#general-information), with extensions that [support more](https://github.com/open-telemetry/opentelemetry-collector-contrib#exporters).

Follow the [Jaeger installation](/docs/ops/integrations/jaeger/#installation) documentation to deploy Jaeger into your cluster or run:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/jaeger.yaml
{{< /text >}}

### Install OpenTelemetry Collector

[OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) can be used to receive spans and export them to a set of backends. Configure the collector to export spans to the Jaeger instance.

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

## Deploy the Bookinfo app

The Bookinfo sample application propagates headers from incoming requests to outgoing requests for each service. Follow the directions to deploy Bookinfo to your cluster. The Istio sidecar should be injected.

See the full instructions for [setting up Bookinfo](/docs/examples/bookinfo/#deploying-the-application). If you are using the default profile, you can install bookinfo with the following commands:

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/bookinfo-gateway.yaml
{{< /text >}}

## Generate and visualize trace data

When the Bookinfo application is up and running generate some traces, you can either access `http://$GATEWAY_URL/productpage` from a browser or call it from inside the cluster:

{{< text bash >}}
$ SERVICE_IP=$(kubectl get svc -n istio-system istio-ingressgateway -ojsonpath="{.spec.clusterIP})
$ kubectl create ns curl
$ for i in {1..3}; do
$   kubectl run -n curl --rm=true -it --restart=Never --image=curlimages/curl -- curl "http://${SERVICE_IP}/productpage"
$ done
$ kubectl delete ns curl
{{< /text >}}

After we created some trace data we can see it in the dashboard

{{< text bash >}}
$ istioctl dashboard jaeger
{{< /text >}}

From the left-hand pane of the dashboard, select `productpage.default` from the **Service** drop-down list and click **Find Traces**:

{{< image link="./istio-tracing-details-jaeger.png" caption="Tracing Dashboard" >}}

1.  Click on the most recent trace at the top of the list to see the details corresponding to the latest request to the `/productpage`:

    {{< image link="./istio-tracing-details-jaeger.png" caption="Detailed Trace View" >}}

1.  The trace is composed of a set of spans, where each span corresponds to a request into or out of a Bookinfo service or internal Istio component (for example `istio-ingressgateway`) during the execution of a `/productpage` request.

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
