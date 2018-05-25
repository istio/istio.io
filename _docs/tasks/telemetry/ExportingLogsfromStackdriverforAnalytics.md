# Exporting Logs from Stackdriver for Analytics

This document covers how to configure Istio for exporting logs from StackDriver for Analytics. 
Also, covers attributes that are being exported currently.
A user can do analytics on data through Istio using logs flowing from Istio to StackDriver and then exporting these logs to various configured sinks like BigQuery, PubSub or GCS. 

## Configuring Istio for exporting Logs to Various Sinks
Istio exports logs through logentry template configured for mixer as [accesslog entry](https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml#L134:9).
This specifies all the variables that would be available for analysis. It contains information like source service, destination service, auth metrics(coming..) among others.
Following is a diagram of the pipeline:
<img src="Istio Analytics using StackDriver.png">


Istio supports exporting logs to stackdriver which can be extended to export logs to your favorite sink like BigQuery, PubSub or GCS.
To configure this path, you have to write a handler for stackdriver.
Config proto for stackdriver can be found [here](https://github.com/istio/istio/blob/master/mixer/adapter/stackdriver/config/config.proto). 
Handler is configured based on this proto.

*Few key points*:
Add a handler of kind stackdriver
1. Ex:
   ```
   apiVersion: "config.istio.io/v1alpha2"
   kind: stackdriver
   metadata:
     name: handler
     namespace: <your defined namespace>
   ```
1. Add logInfo in spec:
   ```
   spec:
     logInfo:
       accesslog.logentry.istio-system:
         labelNames:
		      - sourceIp
          - destinationIp
          ...
          ...
          sinkInfo:
            id: '<sink_id>'
            destination: '<sink_destination>'
            filter: '<log_filter>'
    ```
In the above configuration sinkInfo contains information about the sink where you want the logs to get exported to. For more information on how this gets filled for different sinks please refer here.
1. Add a rule for stackdriver 
   ```
   apiVersion: "config.istio.io/v1alpha2"
     kind: rule
     metadata:
       name: stackdriver
       namespace: istio-system
       spec:
         match: "true" # If omitted match is true
         actions:
         - handler: handler.stackdriver
           instances:
           - accesslog.logentry
     ```
Once you configure this stackdriver handler in your istio system, you will see logs flowing to stackdriver and subsequently to the sink you configured.

## Setting up Various Log Sinks
Common setup for all sinks:
1. Enable StackDriver Monitoring API for the project
1. Make sure principalEmail that would be setting up the sink has write access to the project and Logging Admin role permissions.

### BigQuery
1. Create a bigquery dataset where you would like logs to get exported in bigquery
1. Note down it’s id to be passed to stackdriver handler as destination for the sink. It would be of the form 
*bigquery.googleapis.com/projects/[PROJECT_ID]/datasets/[DATASET_ID]*
1. Give sink’s writer identity: cloud-logs@system.gserviceaccount.com  bigquery data editor role in IAM

### GCS
1. Create a GCS bucket where you would like logs to get exported in bigquery.
1. Note down it’s id to be passed to stackdriver handler as destination for the sink. It would be of the form 
*storage.googleapis.com/[BUCKET_ID*
1. Give sink’s writer identity: cloud-logs@system.gserviceaccount.com  storage object creator role in IAM

### Pubsub
1. Create a topic where you would like logs to get exported in Pubsub
1. Note down it’s id to be passed to stackdriver handler as destination for the sink. It would be of the form 
*pubsub.googleapis.com/projects/[PROJECT_ID]/topics/[TOPIC_ID]*
1. Give sink’s writer identity: cloud-logs@system.gserviceaccount.com  Pub Sub/Publisher role in IAM

## Availability of logs in Export Sinks
Export to BigQuery is within minutes(we see it to be almost instant), GCS can have a delay of 2-12 hours and PubSub is almost instant. 
