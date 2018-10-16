---
title: 如何禁用 Istio 发送追踪 span 至 Zipkin？
weight: 100
---

如果已启用跟踪，则可以按如下方式禁用：

{{< text plain >}}
# Fill <istio namespace> with the namespace of your istio mesh.Ex: istio-system
TRACING_POD=`kubectl get po -n <istio namespace> | grep istio-tracing | awk ‘{print $1}`
$ kubectl delete pod $TRACING_POD -n <istio namespace>
$ kubectl delete services tracing zipkin   -n <istio namespace>
# Remove reference of zipkin url from mixer deployment
$ kubectl -n istio-system edit deployment istio-telemetry
# Now, manually remove instances of trace_zipkin_url from the file and save it.
{{< /text >}}

然后按照[分布式追踪任务的清理部分](/zh/docs/tasks/telemetry/distributed-tracing/#清理)的步骤进行操作。

如果完全不想使用追踪功能，可在 [`istio-demo.yaml`](/zh/docs/tasks/telemetry/distributed-tracing/#开始之前) 或 [`istio-demo-auth.yaml`](/zh/docs/tasks/telemetry/distributed-tracing/#开始之前) 中禁用追踪功能，或者在安装 Istio 时不启用它。