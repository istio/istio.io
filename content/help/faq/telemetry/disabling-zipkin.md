---
title: How can I prevent Istio from sending trace spans to ZipKin?
weight: 100
---

If you already have tracing enabled, you can disable it as follows:

{{< text plain >}}
# Fill <istio namespace> with the namespace of your istio mesh.Ex: istio-system
TRACING_POD=`kubectl get po -n <istio namespace> | grep istio-tracing | awk ‘{print $1}`
$ kubectl delete pod $TRACING_POD -n <istio namespace>
$ kubectl delete services tracing zipkin   -n <istio namespace>
# Remove reference of zipkin url from mixer deployment
$ kubectl -n istio-system edit deployment istio-telemetry
# Now, manually remove instances of trace_zipkin_url from the file and save it.
{{< /text >}}

Then follow the steps of the [cleanup section of the Distributed Tracing task](/docs/tasks/telemetry/distributed-tracing/#cleanup).

If you don’t want tracing functionality at all, then disable tracing in [`istio-demo.yaml` or `istio-demo-auth.yaml`](/docs/tasks/telemetry/distributed-tracing/#before-you-begin) or don’t enable it when installing Istio.
