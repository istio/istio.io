The number of requests you need to send in order to see trace data depends on the sampling rate set at the time Istio was installed.
By default, the sampling rate is set to 1%, meaning that you need to send at least 100 requests before the first trace will be visible.

To send multiple requests, use a command like:

{{< text bash >}}
$ for i in `seq 1 100`; do curl -s -o /dev/null http://$GATEWAY_URL/productpage; done
{{< /text >}}