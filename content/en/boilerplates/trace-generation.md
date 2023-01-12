---
---
To see trace data, you must send requests to your service. The number of requests depends on Istio's sampling rate and can be configured using the [Telemetry API](/docs/tasks/observability/telemetry/). With the default sampling rate of 1%, you need to send at least 100 requests before the first trace is visible.
To send a 100 requests to the `productpage` service, use the following command:

{{< text bash >}}
$ for i in $(seq 1 100); do curl -s -o /dev/null "http://$GATEWAY_URL/productpage"; done
{{< /text >}}
