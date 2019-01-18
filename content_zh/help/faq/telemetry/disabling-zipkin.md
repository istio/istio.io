---
title: 如何禁用 Istio 发送追踪 span 至 Zipkin？
weight: 100
---

如果已启用追踪，则可以按如下方式禁用：

{{< text plain >}}
# 使用 Istio 所在命名空间名称来替换 <istio namespace>，例如：istio-system。
TRACING_POD=`kubectl get po -n <istio namespace> | grep istio-tracing | awk ‘{print $1}`
$ kubectl delete pod $TRACING_POD -n <istio namespace>
$ kubectl delete services tracing zipkin   -n <istio namespace>
# 从 mixer 部署中删除 Zipkin 的 url。
$ kubectl -n istio-system edit deployment istio-telemetry
# 然后手工从文件中删除 trace_zipkin_url 的实例并保存。
{{< /text >}}

然后按照[分布式追踪任务的清理部分](/zh/docs/tasks/telemetry/distributed-tracing/zipkin/#清理)的步骤进行操作。

如果完全不想使用追踪功能，可在 `istio-demo.yaml` 或 `istio-demo-auth.yaml` 中[禁用追踪功能](/zh/docs/tasks/telemetry/distributed-tracing/zipkin/#开始之前)，或者在安装 Istio 时不启用它。
