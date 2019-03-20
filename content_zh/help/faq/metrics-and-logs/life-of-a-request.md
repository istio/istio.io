---
title: 如何获知 Istio 中一个请求的生命周期？
weight: 80
---

用户可以通过打开[追踪](/zh/docs/tasks/telemetry/distributed-tracing/)功能来获知 Istio 中一个请求的流程。

另外，用户可以使用如下的一些指令来获取网格状态的更多信息：

* `istioctl proxy-config`：如果是在 Kubernetes 中运行，这一命令可以获取到代理配置方面的信息。

    {{< text plain >}}
    # 获取特定 Pod 中 Envoy 实例的启动配置信息。
    $ istioctl proxy-config bootstrap productpage-v1-bb8d5cbc7-k7qbm

    # 获取特定 Pod 中 Envoy 实例的集群配置信息。
    $ istioctl proxy-config cluster productpage-v1-bb8d5cbc7-k7qbm

    # 获取特定 Pod 中 Envoy 实例的监听器配置信息。
    $ istioctl proxy-config listener productpage-v1-bb8d5cbc7-k7qbm

    # 获取特定 Pod 中 Envoy 实例的路由配置信息。
    $ istioctl proxy-config route productpage-v1-bb8d5cbc7-k7qbm

    # 获取特定 Pod 中 Envoy 实例的 Endpoint 配置信息。
    $ istioctl proxy-config endpoints productpage-v1-bb8d5cbc7-k7qbm

    # 该命令中包含更多的相关内容：
    $ istioctl proxy-config --help
    {{< /text >}}

* `kubectl get`：获取不同资源在网格以及路由配置的信息。

    {{< text plain >}}
    # 罗列所有的虚拟服务
    $ kubectl get virtualservices
    {{< /text >}}

* Mixer 访问日志：Mixer 所记录的访问日志包含了请求的一些信息。 用户可以通过如下命令来获取：

    {{< text plain >}}
    # 使用 Istio 网格的命名空间来填充 <istio namespace>。例如：istio-system
    $ TELEMETRY_POD=`kubectl get po -n <istio namespace> | grep istio-telemetry | awk '{print $1;}'`
    $ kubectl logs $TELEMETRY_POD -c mixer  -n istio-system  | grep accesslog
    {{< /text >}}
