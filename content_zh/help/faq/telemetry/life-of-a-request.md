---
title: 如何获知 Istio 中一个请求的生命周期？
weight: 80
---

用户可以通过打开[追踪](/zh/docs/tasks/telemetry/distributed-tracing/)功能来获知 Istio 中一个请求的流程。

另外，用户可以使用如下的一些指令来获取网格状态的更多信息：

* `istioctl proxy-config`: 如果是在 Kubernetes 中运行，可以从 endpoint 代理或 Pilot 的特定 pod 中检索代理配置。

    {{< text plain >}}
    # 从 endpoint 代理的 productpage-v1-bb8d5cbc7-k7qbm pod 中检索所有的配置
    $ istioctl proxy-config endpoint productpage-v1-bb8d5cbc7-k7qbm

    # 尝试如下命令来了解更多代理-配置命令行的信息:
    $ istioctl proxy-config --help
    {{< /text >}}

* `kubectl get`: 获取不同资源在网格以及路由配置的信息。

    {{< text plain >}}
    # 罗列所有的虚拟服务
    $ istioctl get virtualservices

    # 尝试如下命令来了解更多代理-配置命令行的信息:
    $ istioctl proxy-config --help
    {{< /text >}}

* Mixer AccessLogs: Mixer 所记录的访问日志包含了请求的一些信息。 用户可以通过如下命令来获取：

    {{< text plain >}}
    # 使用 istio 网格的命名空间来填充 <istio namespace>。例如: istio-system
    $ TELEMETRY_POD=`kubectl get po -n <istio namespace> | grep istio-telemetry | awk '{print $1;}'`
    $ kubectl logs $TELEMETRY_POD -c mixer  -n istio-system  | grep accesslog
    {{< /text >}}