---
title: 用于生产测试的 Istio 流量镜像
description: 介绍更安全，低风险的部署和发布到生产
publishdate: 2018-02-08
subtitle: Routing rules for HTTP traffic
attribution: Christian Posta
weight: 91
keywords: [traffic-management,mirroring]
---

尝试枚举测试用例的所有可能组合以在非生产/测试环境中测试服务可能是令人生畏的, 在某些情况下，您会发现编写这些用例的所有工作都与实际生产用例不匹配, 理想情况下，我们可以使用实时生产用例和流量来帮助说明我们可能在更人为的测试环境中错过的所测试服务的所有功能区域。

Istio 可以在这里提供帮助, 随着[Istio 0.5.0](/about/notes/0.5/)的发布，Istio 可以镜像流量来帮助测试您的服务, 您可以编写类似于以下内容的路由规则来启用流量镜像：

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: mirror-traffic-to-httbin-v2
spec:
  destination:
    name: httpbin
  precedence: 11
  route:
  - labels:
      version: v1
    weight: 100
  - labels:
      version: v2
    weight: 0
  mirror:
    name: httpbin
    labels:
      version: v2
{{< /text >}}

这里有几点需要注意：

* 当流量镜像到不同的服务时，会发生在请求的关键路径之外
* 忽略对任何镜像流量的响应; 流量被视为“即发即忘”
* 您需要使用 0 加权路线来暗示 Istio 在封面下创建适当的 Envoy 群集; [这应该在未来的版本中解决](https://github.com/istio/istio/issues/3270)。

访问[镜像任务](/docs/tasks/traffic-management/mirroring/)了解有关镜像的更多信息，并查看更多信息
[在我的博客上综合处理这种情况](https://blog.christianposta.com/microservices/traffic-shadowing-with-istio-reduce-the-risk-of-code-release/).
