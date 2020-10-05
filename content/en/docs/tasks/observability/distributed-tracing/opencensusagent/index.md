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

After completing this task, you will understand how to have your application participate
in tracing with the OpenCensusAgent tracer, export those traces to the OpenTelemetry
collector, and have the OpenTelemetry collector export those spans to Jaeger.

To learn how Istio handles tracing, visit this task's [overview](../overview).

## Setup

### Install a backend

For this example, we will use Jaeger as the backend. OpenTelemetry collector supports
exporting traces to a [several backends by default](https://github.com/open-telemetry/opentelemetry-collector/blob/master/exporter/README.md#general-information),
with extensions that [support more](https://github.com/open-telemetry/opentelemetry-collector-contrib#exporters).

Follow the Jaeger installation documentation to deploy Jaeger into your cluster or
run:
{{< text bash >}}
kubectl apply -f {{< github_file >}}/samples/addons/jaeger.yaml
{{< /text >}}

### Install OpenTelemetry Collector

[OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) can be used to receive spans
and export them to a set of backends. Here, we configure the collector to export
spans to the Jaeger instance we set up in the previous step.

{{<text bash>}}
kubectl apply -f - <<EOF
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
        ballast_size_mib: 20
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
          image: "otel/opentelemetry-collector:0.9.0"
          imagePullPolicy: IfNotPresent
          command:
            - "/otelcol"
            - "--config=/conf/config.yaml"
            - "--mem-ballast-size-mib=20"
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

## Deploy Istio

Once these are installed, configure Istio proxies to send opencensus-agent formatted spans to
the opentelemetry collector. Save the following as `tracing-opencensus.yaml`:
```
spec:
  values:
    global:
      proxy:
        tracer: openCensusAgent
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        openCensusAgent:
          address: "dns:opentelemetry-collector.istio-system.svc:55678"
```

and run:
{{< text bash >}}
istioctl install --set profile=demo -f tracing-opencensus.yaml
{{< /text >}}


### Deploy Bookinfo

The Bookinfo sample application propagates headers from incoming requests
to outgoing requests for each service. Follow the directions to deploy
Bookinfo to your cluster. The Istio sidecar should be injected.

See the full instructions for [setting up Bookinfo](TODO).
If you are using the demo profile, you can install bookinfo with the following commands:
{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/bookinfo-gateway.yaml
{{< /text >}}

## Generating and viewing traces

{{< text bash >}}
$ istioctl dashboard jaeger
{{< /text >}}

1.  When the Bookinfo application is up and running, access `http://$GATEWAY_URL/productpage` one or more times
    to generate trace information.

    {{< boilerplate trace-generation >}}

1.  From the left-hand pane of the dashboard, select `productpage.default` from
    the **Service** drop-down list and click **Find Traces**:

    {{< image link="./istio-tracing-list-jaeger.png" caption="Tracing Dashboard" >}}

1.  Click on the most recent trace at the top of the list to see the details corresponding to the latest
    request to the `/productpage`:

    {{< image link="./istio-tracing-details-jaeger.png" caption="Detailed Trace View" >}}

1.  The trace is composed of a set of spans, where each span corresponds to a
    request into or out of a Bookinfo service or internal Istio
    component (for example `istio-ingressgateway`) during the
    execution of a `/productpage` request.

## Configuring propagation headers

By default, Istio's OpenCensus Agent tracing will attempt to read and write 4
types of trace headers: B3, gRPC's binary trace header, W3C Trace Context, and
Cloud Trace Context. You can configure the tracer to use only the W3C Trace
Context header (`traceparent`) with:
```
spec:
  values:
    global:
      proxy:
        tracer: openCensusAgent
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        openCensusAgent:
          address: "dns:opentelemetry-collector.istio-system.svc:55678"
          context: [W3C_TRACE_CONTEXT]
```
If you supply multiple values, the proxy will attempt to read trace headers in
the specified order, using the first one that is successfully parsed and
writing all headers. This permits interoperability between services that use
different headers, e.g. one service that propagates B3 headers and one that
propagates W3C Trace Context headers can participate in the same trace.
