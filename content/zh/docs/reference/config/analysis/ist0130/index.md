---
title: VirtualServiceUnreachableRule
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

如果因为之前的规则中指定了相同的匹配规则，在 VirtualService 包含永远不会使用的匹配规则时，
会出现此消息。当多个规则不存在任何匹配时，此消息也会出现。

## 示例 {#example}

当您的集群中包含下列 Virtual Service 时：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: sample-foo-cluster01
  namespace: foo
spec:
  hosts:
  - sample.foo.svc.cluster.local
  http:
  - fault:
      delay:
        fixedDelay: 5s
        percentage:
          value: 100
    route:
    - destination:
        host: sample.foo.svc.cluster.local
  - mirror:
      host: sample.bar.svc.cluster.local
    route:
    - destination:
        host: sample.bar.svc.cluster.local
        subset: v1
{{< /text >}}

您将会收到以下警告消息：

{{< text plain >}}
Warning [IST0130] (VirtualService sample-foo-cluster01.default) VirtualService rule #1 not used (only the last rule can have no matches).
{{< /text >}}

在这个示例中，VirtualService 同时指定了 fault 和 mirror。
允许同时使用，但是必须在同一个路由下。用户在此处使用了两个不同的
http 路由条目（每个 `-` 一个条目），第一个会覆盖第二个。

## 如何修复 {#how-to-resolve}

当您有一个没有被 `match` 的 `http`，那么只能存在一个 http 路由。
在这个示例中，移除 `mirror` 之前无法匹配的路由 `"-"`，
最终的结果为：发生故障且进行镜像的路由，而不是一条故障路由和一条镜像路由。

设置复杂的路由时，请小心处理 YAML 文件格式。

重新排列您的路线，将最具体的路由放在前面。请在最后配置 'catch all' 路线。
