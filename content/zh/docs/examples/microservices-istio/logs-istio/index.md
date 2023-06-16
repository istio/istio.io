---
title: 监控 Istio
overview: 收集和查询网格指标。
weight: 72

owner: istio/wg-docs-maintainers
test: no
---

监控是支持向微服务架构过渡的关键。

在 Istio 中，它默认就提供监控微服务之间的流量的功能。
您可以使用 Istio Dashboard 来实时监控您的微服务。

Istio 集成了开箱即用的 [Prometheus 的时序数据库和监控系统](https://prometheus.io)。
Prometheus 收集了各种流量相关的指标，
并为其提供[丰富的查询语言](https://prometheus.io/docs/prometheus/latest/querying/basics/)。

请看下面几个 Prometheus 查询 Istio-related 的例子。

1. 通过 [http://my-istio-logs-database.io](http://my-istio-logs-database.io)
   访问 Prometheus UI 界面。（这  `my-istio-logs-database.io` URL
   在您[之前配置](/zh/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)的
   `/etc/hosts` 文件中）。

    {{< image width="80%" link="prometheus.png" caption="Prometheus Query UI" >}}

1. 在 **Expression** 输入框中运行以下示例查询。按下 **Execute** 按钮，在 **Console**
   中查看查询结果。这个查询使用 `tutorial` 作为应用的命名空间，您可以替换成您自己的命名空间。
   在查询数据时，为了能够得到更棒的效果，请运行前面步骤中描述的实时流量模拟器。

    1. 查询命名空间的所有请求：

        {{< text plain >}}
        istio_requests_total{destination_service_namespace="tutorial", reporter="destination"}
        {{< /text >}}

    1. 查询命名空间请求的总和：

        {{< text plain >}}
        sum(istio_requests_total{destination_service_namespace="tutorial", reporter="destination"})
        {{< /text >}}

    1. 查询 `reviews` 微服务的请求：

        {{< text plain >}}
        istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews"}
        {{< /text >}}

    1. 在过去5分钟内， `reviews` 微服务实例中的所有请求的[请求速率](https://prometheus.io/docs/prometheus/latest/querying/functions/#rate)：

        {{< text plain >}}
        rate(istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews"}[5m])
        {{< /text >}}

上面使用的请求采用 `istio_requests_total` 指标，这是一个标准的 Istio 指标。
您可以观察其他指标，特别是 Envoy（[Envoy](https://www.envoyproxy.io)
是 Istio 的 Sidecar 代理）。您可以在 **insert metric at cursor**
下拉菜单的看到收集的数据记录。

## 下一步 {#next-steps}

祝贺完成本教程！

通过这些 `demo` 安装任务是初学者进一步了解 Istio 的方式：

- [配置请求路由](/zh/docs/tasks/traffic-management/request-routing/)
- [故障注入](/zh/docs/tasks/traffic-management/fault-injection/)
- [流量转移](/zh/docs/tasks/traffic-management/traffic-shifting/)
- [通过 Prometheus 查询度量指标](/zh/docs/tasks/observability/metrics/querying-metrics/)
- [使用 Grafana 可视化指标](/zh/docs/tasks/observability/metrics/using-istio-dashboard/)
- [访问外部服务](/zh/docs/tasks/traffic-management/egress/egress-control/)
- [网络可视化](/zh/docs/tasks/observability/kiali/)

在您自定义 Istio 产品之前，可以先了解这些资源：

- [部署模型](/zh/docs/ops/deployment/deployment-models/)
- [Deployment 最佳实践](/zh/docs/ops/best-practices/deployment/)
- [Pod 和 Service](/zh/docs/ops/deployment/requirements/)
- [安装](/zh/docs/setup/)

## 加入 Istio 社区 {#join-the-Istio-community}

我们欢迎您通过加入 [Istio 社区](/zh/get-involved/) 提出并反馈问题。
