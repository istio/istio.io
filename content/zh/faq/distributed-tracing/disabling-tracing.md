---
title: 如何禁用追踪？
weight: 50
---

如果您已经安装了启用追踪功能的 Istio，可以通过执行如下步骤禁用它：

{{< text plain >}}
# 用您的 Istio mesh 命名空间名填充下述命令中的 <istio namespace>。例如：istio-system
TRACING_POD=`kubectl get po -n <istio namespace> | grep istio-tracing | awk '{print $1}'`
$ kubectl delete pod $TRACING_POD -n <istio namespace>
$ kubectl delete services tracing zipkin   -n <istio namespace>
# 现在，手动从文件中移除 trace_zipkin_url 的实例，保存文件
{{< /text >}}

然后遵循[分布式追踪任务的清理部分](/zh/docs/tasks/observability/distributed-tracing/zipkin/#cleanup)的步骤进行后续操作。

如果您不想要追踪功能，那么就在安装 Istio 时[禁用追踪](/zh/docs/tasks/observability/distributed-tracing/zipkin/#before-you-begin)。
