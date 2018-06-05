---
title: Exporting Istio Access Logs to BigQuery, GCS, Pub/Sub through Stackdriver
description: How to export Istio Access Logs to different sinks like BigQuery, GCS, Pub/Sub through Stackdriver.
weight: 70
---

This task shows how to export Istio Access Logs to different sinks like
BigQuery, GCS, Pub/Sub through Stackdriver A user can do analytics on data
through Istio using logs flowing from Istio to StackDriver and then exporting
these logs to various configured sinks like BigQuery, Pub/Sub or GCS.

The [Bookinfo](/docs/guides/bookinfo/) sample application is used as the example
application throughout this task.

## Before you begin

[Install Istio](/docs/setup/) in your cluster and deploy an application.

## Configuring Istio for exporting logs to various sinks

Istio exports logs through logentry template configured for Mixer as [accesslog
entry](https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml#L134:9).
This specifies all the variables that would be available for analysis. It
contains information like source service, destination service, auth
metrics(coming..) among others. Following is a diagram of the pipeline:

{{< image width="75%" ratio="69.52%"
link="../img/istio-analytics-using-stackdriver.png" alt="Image is not available"
title="Diagram of exporting logs from Istio to StackDriver for analysis" >}}

Istio supports exporting logs to Stackdriver which can be extended to export
logs to your favorite sink like BigQuery, Pub/Sub or GCS. Please follow steps
below to setup your favorite sink for exporting logs first and then Stackdriver
in Istio.

### Setting up various log sinks

Common setup for all sinks:

1. Enable StackDriver Monitoring API for the project
1. Make sure `principalEmail` that would be setting up the sink has write access
to the project and Logging Admin role permissions.

#### BigQuery

1.  Create a BigQuery dataset where you would like logs to get exported in
    BigQuery
1.  Note down it’s id to be passed to Stackdriver handler as destination for the
    sink. It would be of the form
    `bigquery.googleapis.com/projects/[PROJECT_ID]/datasets/[DATASET_ID]`
1.  Give sink’s writer identity: cloud-logs@system.gserviceaccount.com BigQuery
    data editor role in IAM

#### GCS

1.  Create a GCS bucket where you would like logs to get exported in BigQuery.
1.  Note down it’s id to be passed to Stackdriver handler as destination for the
    sink. It would be of the form `storage.googleapis.com/[BUCKET_ID`
1.  Give sink’s writer identity: cloud-logs@system.gserviceaccount.com storage
    object creator role in IAM

#### Pub/Sub

1.  Create a topic where you would like logs to get exported in Pub/Sub
1.  Note down it’s id to be passed to Stackdriver handler as destination for the
    sink. It would be of the form
    `pubsub.googleapis.com/projects/[PROJECT_ID]/topics/[TOPIC_ID]`
1.  Give sink’s writer identity: cloud-logs@system.gserviceaccount.com Pub/Sub
    Publisher role in IAM

### Setting up Stackdriver

To configure exporting logs to Stackdriver, you have to write a handler for
Stackdriver. Config proto for Stackdriver can be found
[here](https://github.com/istio/istio/blob/master/mixer/adapter/stackdriver/config/config.proto).
Handler is configured based on this proto.

1.  Save following yaml file as `stackdriver.yaml`. Replace `<project_id>,
    <sink_id>, <sink_destination>, <log_filter>` with their specific values.

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
        kind: stackdriver
        metadata:
          name: handler
          namespace: istio-system
        spec:
          # We'll use the default value from the adapter, once per minute, so we don't need to supply a value.
          # pushInterval: 1m
          # Must be supplied for the Stackdriver adapter to work
          project_id: "<project_id>"
          # One of the following must be set; the preferred method is `appCredentials`, which corresponds to
          # Google Application Default Credentials. See:
          #    https://developers.google.com/identity/protocols/application-default-credentials
          # If none is provided we default to app credentials.
          # appCredentials:
          # apiKey:
          # serviceAccountPath:
          # Describes how to map Istio metrics into Stackdriver.
          # Note: most of this config is copied over from prometheus.yaml to keep our metrics consistent across backends
          metricInfo:
            requestcount.metric.istio-system:
              # Due to a bug in gogoproto deserialization, Enums in maps must be
              # specified by their integer value, not variant name. See
              # https://github.com/googleapis/googleapis/blob/master/google/api/metric.proto
              # MetricKind and ValueType for the values to provide.
              kind: 2 # DELTA
              value: 2 # INT64
            requestduration.metric.istio-system:
              kind: 2 # DELTA
              value: 5 # DISTRIBUTION
              buckets:
                explicit_buckets:
                  bounds: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
            requestsize.metric.istio-system:
              kind: 2 # DELTA
              value: 5 # DISTRIBUTION
              buckets:
                exponentialBuckets:
                  numFiniteBuckets: 8
                  scale: 1
                  growthFactor: 10
            responsesize.metric.istio-system:
              kind: 2 # DELTA
              value: 5 # DISTRIBUTION
              buckets:
                exponentialBuckets:
                  numFiniteBuckets: 8
                  scale: 1
                  growthFactor: 10
          # Describes how to map Istio logs into Stackdriver.
          logInfo:
            accesslog.logentry.istio-system:
              payloadTemplate: '{{or (.sourceIp) "-"}} - {{or (.sourceUser) "-"}} [{{or (.timestamp.Format "02/Jan/2006:15:04:05 -0700") "-"}}] "{{or (.method) "-"}} {{or (.url) "-"}} {{or (.protocol) "-"}}" {{or (.responseCode) "-"}} {{or (.responseSize) "-"}}'
              httpMapping:
                url: url
                status: responseCode
                requestSize: requestSize
                responseSize: responseSize
                latency: latency
                localIp: sourceIp
                remoteIp: destinationIp
                method: method
                userAgent: userAgent
                referer: referer
              labelNames:
              - sourceIp
              - destinationIp
              - sourceService
              - sourceUser
              - sourceNamespace
              - destinationIp
              - destinationService
              - destinationNamespace
              - apiClaims
              - apiKey
              - protocol
              - method
              - url
              - responseCode
              - responseSize
              - requestSize
              - latency
              - connectionMtls
              - userAgent
              - responseTimestamp
              - receivedBytes
              - sentBytes
              - referer
              sinkInfo:
                id: '<sink_id>'
                destination: '<sink_destination>'
                filter: '<log_filter>'
        ---
        apiVersion: "config.istio.io/v1alpha2"
        kind: rule
        metadata:
          name: stackdriver
          namespace: istio-system
        spec:
          match: "true" # If omitted match is true.
          actions:
          - handler: handler.stackdriver
            instances:
            - requestcount.metric
            - requestduration.metric
            - requestsize.metric
            - responsesize.metric
            - accesslog.logentry
        ---
    ```

1.  Push the configuration

    ```command
    $ kubectl apply -f stackdriver.yaml
    stackdriver "handler" created
    rule "stackdriver" created
    logentry "stackdriverglobalmr" created
    metric "stackdriverrequestcount" created
    metric "stackdriverrequestduration" created
    metric "stackdriverrequestsize" created
    metric "stackdriverresponsesize" created
    ```

1.  Send traffic to the sample application.

    For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
    browser or issue the following command:

    ```command
    $ curl http://$GATEWAY_URL/productpage
    ```

1.  Verify that logs are flowing through Stackdriver and further to the sink
    configured.

    *   Stackdriver: Navigate to [Stackdriver Logs
        Viewer](https://pantheon.corp.google.com/logs/viewer) for your project
        and look under "GKE Container" -> "Cluster Name" -> "Namespace Id" for
        Istio Access logs.
    *   BigQuery: Navigate to [BigQuery
        Interface](https://bigquery.cloud.google.com/) for your project and you
        should find a table with prefix `accesslog_logentry_istio` in your sink
        dataset.
    *   GCS: Navigate to [Storage
        Browser](https://pantheon.corp.google.com/storage/browser/) for your
        project and you should find a bucket named
        `accesslog.logentry.istio-system` in your sink bucket.
    *   Pub/Sub: Navigate to [Pub/Sub
        TopicList](https://pantheon.corp.google.com/cloudpubsub/topicList) for
        your project and you should find a topic for `accesslog` in your sink
        topic.

## Understanding what happened

`Stackdriver.yaml` file above configured Istio to send metric and accesslog to
StackDriver and then added a sink configuration where these logs could be
exported. In detail as follows:

1.  Added a handler of kind stackdriver

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
        kind: stackdriver
        metadata:
          name: handler
          namespace: <your defined namespace>
    ```

1.  Added logInfo in spec

    ```yaml
        spec:
          logInfo: accesslog.logentry.istio-system:
            labelNames:
            - sourceIp
            - destinationIp
            ...
            ... 
            sinkInfo:
              id: '<sink_id>'
              destination: '<sink_destination>'
              filter: '<log_filter>'
    ```yaml

    In the above configuration sinkInfo contains information about the sink where you want
    the logs to get exported to. For more information on how this gets filled for different sinks please refer
    [here](https://cloud.google.com/logging/docs/export/#sink-terms).

1.  Added a rule for Stackdriver

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
        kind: rule
        metadata:
          name: stackdriver
          namespace: istio-system spec:
          match: "true" # If omitted match is true
        actions:
        - handler: handler.stackdriver
          instances:
          - accesslog.logentry
     ```yaml

## Cleanup

*   Remove the new Stackdriver configuration:

    ```command
    $ kubectl delete -f stackdriver.yaml
    ```

*   If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/guides/bookinfo/#cleanup) instructions to shutdown
    the application.

## Availability of logs in export sinks

Export to BigQuery is within minutes(we see it to be almost instant), GCS can
have a delay of 2-12 hours and Pub/Sub is almost instant.
