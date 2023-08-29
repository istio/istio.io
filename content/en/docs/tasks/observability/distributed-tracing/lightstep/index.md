---
title: Cloud Observability from ServiceNow
description: How to configure the proxies to send tracing requests to Cloud Observability (formerly Lightstep).
weight: 11
keywords: [telemetry,tracing,lightstep, servicenow, cloud observability]
aliases:
 - /docs/tasks/telemetry/distributed-tracing/lightstep/
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

You use the [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) to send Istio metrics to Cloud Observability using Istio proxies within each pod. Metrics are collected and forwarded to the OpenTelemetry Collector, which acts as a central collection and processing point and then sends those metrics to Cloud Observability.

To set up Istio metrics ingestion using OpenTelemetry Collector, you:

1. Create a configuration file for the OpenTelemetry Collector, specifying the sources, processors, and exporters to be used.
1. Create a configuration file for the Istio Operator for your Kubernetes environment.
1. Create access permissions for the Collector.
1. Configure Istio to send metrics to the OpenTelemetry Collector by modifying Istio's configuration files.
1. Create your [Cloud Observability access token](https://docs.lightstep.com/docs/create-and-manage-access-tokens) as a Kubernetes secret.
1. Verify that metrics from Istio are successfully ingested by the OpenTelemetry Collector and exported to Cloud Observability.

## Prerequisites

* Istio configured as a network mesh on a Kubernetes cluster
* A running OpenTelemetry Collector version 0.77 or later, configured to [export metric data](https://docs.lightstep.com/docs/ingest-metrics-otel-collector) to Cloud Observability
* A good understanding of Kubernetes

## Configure the Collector

You use a Kubernetes ConfigMap file to configure the Collector to scrape Prometheus metrics and a deployment file to deploy it to Kubernetes.

1. Create an `otel-collector-configmap.yaml` file by copying the following code.

    {{< text yaml >}}
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: otel-collector-conf
    data:
      otel-collector-config.yaml: |
        receivers:
          prometheus:
            config:
              scrape_configs:
                - job_name: 'otel-collector'
                  scrape_interval: 5s
                  static_configs:
                    - targets: ['0.0.0.0:8888']
                - job_name: "istio"
                  scrape_interval: 5s
                  metrics_path: "/stats/prometheus"
                  kubernetes_sd_configs:
                    - role: "pod"
                  relabel_configs:
                  // add labels

       processors:
          batch:

        exporters:
            logging:
            loglevel: debug
          otlp:
            endpoint: ingest.lightstep.com:443
            headers:
                    "lightstep-access-token": "{LS_ACCESS_TOKEN}"

        service:
          telemetry:
            logs:
              level: "debug"
          pipelines:
            metrics:
              receivers: [prometheus]
              processors: [batch]
              exporters: [logging,otlp]
    {{< /text >}}

2. Create an `otel-collector-deployment.yaml` file by copying the following code.

    {{< text yaml >}}
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: otel-collector
      labels:
        app: otel-collector
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: otel-collector
      template:
        metadata:
          labels:
            app: otel-collector
        spec:
          serviceAccountName: otel-collector
          containers:
          - name: otel-collector
            image: otel/opentelemetry-collector-contrib:latest
            args:
            - "--config=/conf/otel-collector-config.yaml"
            ports:
            - containerPort: 55681
            env:
            - name: LS_ACCESS_TOKEN
              valueFrom:
                secretKeyRef:
                  name: lightstep-access-token
                  key: {LS_ACCESS_TOKEN}

            volumeMounts:
            - name: otel-collector-config-vol
              mountPath: /conf
          volumes:
          - configMap:
              name: otel-collector-conf
            name: otel-collector-config-vol
    {{< /text >}}

## Configure Istio Operator

Create an `istio-operator.yaml` file by copying the following code.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  profile: default
  components:
    prometheus:
      enabled: true
  values:
    global:
      proxy:
        autoInject: "enabled"
{{< /text >}}

## Configure RBAC (Role-based access control)

Create an `otel-collector-rbac.yaml` file by copying the following code.

{{< text yaml >}}

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: otel-collector
rules:
  - apiGroups: [""]
    resources:
      - nodes
      - nodes/metrics
      - nodes/proxy
      - nodes/stats
      - pods
      - services
    verbs: ["get", "list", "watch"]
  - nonResourceURLs: ["/metrics"]
    verbs: ["get"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: otel-collector
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: otel-collector
subjects:
  - kind: ServiceAccount
    name: otel-collector
    namespace: default

{{< /text >}}

## Configure LS secret

Create a `lightstep-secret.yaml` file to hold your access token by copying the following code and replacing `${LS_ACCESS_TOKEN}` with your access token.

{{< text yaml >}}
apiVersion: v1
kind: Secret
metadata:
  name: lightstep-access-token
type: Opaque
data:
  access_token: ${LS_ACCESS_TOKEN}
{{< /text >}}

## Apply the configurations to your Kubernetes cluster

1. Apply the deployment file.

    {{< text plain >}}
    kubectl apply -f otel-collector-deployment.yaml
    {{< /text >}}

    Verify that the OpenTelemetry Collector is running:

    {{< text plain >}}
    kubectl get pods -l app=otel-collector
    {{< /text >}}

2. Apply the ConfigMap to your Kubernetes cluster

    {{< text plain >}}
    kubectl apply -f otel-collector-configmap.yaml
    {{< /text >}}

    Verify that the ConfigMap has been created

    {{< text plain >}}
    kubectl get configmap otel-collector-conf
    {{< /text >}}

3. Apply the Secret to your Kubernetes cluster

    {{< text plain >}}
    kubectl apply -f lightstep-secret.yaml
    {{< /text >}}

## View metrics in Cloud Observability

Once you have Cloud Observability ingesting the Istio metrics, you can begin using them to [build dashboards](https://docs.lightstep.com/docs/create-and-manage-dashboards) in Cloud Observability.

## Trace sampling

Istio captures traces at a configurable trace sampling percentage. To learn how to modify the trace sampling percentage,
visit the [Distributed Tracing trace sampling section](/docs/tasks/observability/distributed-tracing/mesh-and-proxy-config/#customizing-trace-sampling).
