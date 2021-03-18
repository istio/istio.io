---
title: 等待应用的配置资源状态就绪
description: 描述如何等待资源达到给定的就绪状态。
weight: 15
owner: istio/wg-user-experience-maintainers
test: yes
---

{{< warning >}}
该特性还处于 `Alpha` 阶段，参考 [Istio Feature Status](/zh/about/feature-stages/)。欢迎您的反馈 [Istio User Experience discussion](https://discuss.istio.io/c/UX/23)。目前这些特性仅在单控制平面低容量存储版本的集群中进行了测试。
{{< /warning >}}

Istio 的网格配置是声明式的，意味着您声明或修改一个配置信息不会立即生效而是随着时间慢慢应用到网格中。因此您的命令很可能在相关资源就绪之前就开始使用了网格服务。

在 Istio 1.6 及之后的版本，您可以使用 `kubectl wait` 命令对 Istio 应用配置更改到网格中的方式实行更好的掌控。为了实现该目的， `kubectl wait` 命令监控资源状态的 [`status`](/zh/docs/reference/config/config-status/) 字段，该字段在 Istio 传播配置更改的时候会被更新。

## 开始之前 {#before-you-begin}

该特性在默认情况下是关闭的。在安装的过程中使用以下命令设置 `status` 的相关配置参数开启该特性。

{{< text syntax=bash snip_id=install_with_enable_status >}}
$ istioctl install --set values.pilot.env.PILOT_ENABLE_STATUS=true --set values.global.istiod.enableAnalysis=true
{{< /text >}}

## 等待资源就绪 {#wait-for-resource-readiness}

您可以先 `apply` 更改的内容，然后等待完成。例如，等待下面的虚拟服务，可以使用以下命令：

{{< text syntax=bash snip_id=apply_and_wait_for_httpbin_vs >}}
$ kubectl apply -f @samples/httpbin/httpbin.yaml@
$ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@
$ kubectl wait --for=condition=Reconciled virtualservice/httpbin
virtualservice.networking.istio.io/httpbin condition met
{{< /text >}}

该命令会一直保持阻塞状态，直到虚拟服务被成功下发到网格内所有的代理中，或者命令执行超时。

当您在脚本中使用 `kubectl wait` 命令时，返回码 `0` 代表成功，非 `0` 代表超时状态。

关于更多用法和语法信息请参考 [kubectl wait](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#wait) 命令。
