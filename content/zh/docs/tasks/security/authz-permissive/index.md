---
title: 鉴权过程中的宽容模式
description: 展示宽容模式的的鉴权过程。
weight: 10
keywords: [security,access-control,rbac,authorization]
---

在授权策略被提交到生产环境上之前，可以使用[宽容模式的鉴权](/zh/docs/concepts/security/#授权宽容模式)来进行验证。

宽容模式鉴权是 Istio 1.1 中的一个实验性的功能。未来的版本中，其接口可能会发生变化。如果你不想尝试宽容模式的功能，可以直接[启用 Istio 访问控制](/zh/docs/tasks/security/authz-http/#enable-Istio-access-control)，跳过启用宽容模式的过程。

本任务包含了两个适用宽容模式鉴权的场景：

* **禁用访问控制**的环境中，可以用于帮助测试启用访问控制的可行性。

* **启用访问控制**的环境中，可以用来对新的策略进行测试。

## 开始之前 {#before-you-begin}

要完成这一任务，有一些先决条件：

* 阅读[授权的概念](/zh/docs/concepts/security/#授权)。

* 参看 [Kubernetes 快速启动](/zh/docs/setup/kubernetes/install/kubernetes/)，安装 Istio 并**启用双向 TLS**。

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用。

### 测试启用全局访问控制的可行性 {#test-enabling-authorization-globally}

下面的步骤展示了如何使用宽容模式的鉴权来测试是否可以安全的启用全局的访问控制：

1. 运行下面的用命令，在全局访问控制配置中启用宽容模式：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ClusterRbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["default"]
      enforcement_mode: PERMISSIVE
    EOF
    {{< /text >}}

1. 浏览网址 `http://$GATEWAY_URL/productpage`，访问 `productpage`，查看是否一切正常。

1. 应用 `rbac-permissive-telemetry.yaml`，为宽容模式启用指标收集：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    logentry.config.istio.io/rbacsamplelog created
    stdio.config.istio.io/rbacsamplehandler created
    rule.config.istio.io/rabcsamplestdio created
    {{< /text >}}

1. 在命令行向示例应用发送流量：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1. 读取遥测日志，在其中搜索 `permissiveResponseCode`：

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T21:53:42.059444Z","instance":"rbacsamplelog.logentry.istio-system","destination":"ratings","latency":"9.158879ms","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":48,"source":"reviews","user":"cluster.local/ns/default/sa/bookinfo-reviews"}
    {"level":"warn","time":"2018-08-30T21:53:41.037824Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"1.091670916s","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":379,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T21:53:41.019851Z","instance":"rbacsamplelog.logentry.istio-system","destination":"productpage","latency":"1.112521495s","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":5723,"source":"istio-ingressgateway","user":"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"}
    {{< /text >}}

1. 查看日志中是否包含 `responseCode` 为 `200`，且 `permissiveResponseCode` 为 `denied` 的条目。

1. 应用 `productpage-policy.yaml`，其中包含了宽容模式的安全策略：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    {{< /text >}}

1. 用下面的命令向示例应用发送流量：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1. 读取遥测日志，在其中搜索 `permissiveResponseCode`：

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T21:55:53.590430Z","instance":"rbacsamplelog.logentry.istio-system","destination":"ratings","latency":"4.415633ms","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":48,"source":"reviews","user":"cluster.local/ns/default/sa/bookinfo-reviews"}
    {"level":"warn","time":"2018-08-30T21:55:53.565914Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"32.97524ms","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":379,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T21:55:53.544441Z","instance":"rbacsamplelog.logentry.istio-system","destination":"productpage","latency":"57.800056ms","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"productpage-viewer","responseCode":200,"responseSize":5723,"source":"istio-ingressgateway","user":"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"}
    {{< /text >}}

1. 查看日志中 `productpage` 服务的相关内容中，是否包含 `responseCode` 为 `200`，且 `permissiveResponseCode` 为 `allowed` 的条目。

1. 使用 `kubectl` 移除启用宽容模式相关的 YAML 文件所包含的对象。

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-on-permissive.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1. 恭喜你，刚刚借助宽容模式对授权策略进行了测试，结果表明这一策略是有效的。可以依照[启用 Istio 访问控制](/zh/docs/tasks/security/authz-http/#enable-Istio-access-control)中的步骤来启用这一策略。

### 测试新增策略 {#test-adding-authorization-policy}

接下来的测试，展示了在已经启用访问控制的情况下，如何用宽容模式来测试新的授权策略。

1. 根据[为 HTTP 服务启用鉴权的第一个步骤](/zh/docs/tasks/security/authz-http/#第一步-开放到-productpage-服务的访问)中的讲述，允许访问 `producepage` 服务。

1. 用下面的命令开放在宽容模式下对 `details` 和 `reviews` 服务的访问：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy-permissive.yaml@
    {{< /text >}}

1. 用浏览器打开 `productpage` (`http://$GATEWAY_URL/productpage`)，应该会看到 `Error fetching product details` 和 `Error fetching product reviews` 两条错误信息。出错原因在于这条策略是 `PERMISSIVE` 模式的。

1. 应用 `rbac-permissive-telemetry.yaml` 文件，启用宽容模式的指标收集：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1. 向示例应用发送流量：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1. 读取遥测日志，在其中搜索 `permissiveResponseCode`：

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T22:59:42.707093Z","instance":"rbacsamplelog.logentry.istio-system","destination":"details","latency":"423.381µs","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"details-reviews-viewer","responseCode":403,"responseSize":19,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T22:59:42.763423Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"237.333µs","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"details-reviews-viewer","responseCode":403,"responseSize":19,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {{< /text >}}

1. 查看日志中 `ratings` 和 `reviews` 服务的相关内容中，是否包含 `responseCode` 为 `403`，且 `permissiveResponseCode` 为 `allowed` 的条目。

1. 使用 `kubectl` 移除启用宽容模式相关的 YAML 文件所包含的对象：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy-permissive.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1. 祝贺你，刚刚通过宽容模式来对新增授权策略进行了验证，并且证明新策略是可以工作的。要加入这一新规则，可以根据参考文档[启用 Istio 访问控制](/zh/docs/tasks/security/authz-http/#enable-Istio-access-control)中的步骤来完成。
