---
title: 高级安装选项
description: 定制 Istio 安装的介绍。
weight: 20
keywords: [kubernetes]
draft: true
---

本节介绍了一些 Istio 组件的碎片式安装的选项。

## 仅安装 Ingress 控制器

将 Istio 用作 Ingress 控制器是可行的，可以用于在七层提供路由方面的支撑，例如基于版本的路由、基于 Header 的路由、gRPC/HTTP2 代理、跟踪等。仅部署 Istio Pilot，并禁用其他组件。不要部署 Istio 的 `initializer`。

## Ingress 控制器，并提供遥测和策略支持

部署 Istio Pilot 和 Mixer 之后，上面提到的 Ingress 控制器配置就能够得到增强，进一步提供深入的遥测和策略实施能力了，其中包含了速率控制、访问控制等功能。

## 智能路由和遥测

如果要在深度遥测和分布式请求跟踪之外，还希望享受 Istio 的七层流量管理能力，就需要部署 Istio Pilot 和 Mixer；另外还可以在 Mixer 上禁用策略支持。

## 定制示例：支持安全和流量管理的最小集合

Istio 有丰富的功能，但是你可能只想要使用其中的一个子集。例如只想安装安全和流量管理功能的相关服务。

这个例子展示了如何只安装用于支持[流量管理](/zh/docs/tasks/traffic-management/)的最小化组件集合。

执行下列命令安装 Pilot 和 Citadel：

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set ingress.enabled=false \
  --set gateways.istio-ingressgateway.enabled=false \
  --set gateways.istio-egressgateway.enabled=false \
  --set galley.enabled=false \
  --set sidecarInjectorWebhook.enabled=false \
  --set mixer.enabled=false \
  --set prometheus.enabled=false \
  --set global.proxy.envoyStatsd.enabled=false
{{< /text >}}

在 Kubernetes 中确认 `istio-pilot-*` 以及 `istio-citadel-*` Pod 被正确部署，其中的容器正在运行：

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                     READY     STATUS    RESTARTS   AGE
istio-citadel-b48446f79-wd4tk            1/1       Running   0          1m
istio-pilot-58c65f74bc-2f5xn             2/2       Running   0          1m
{{< /text >}}

在这个最小组件集的支持下，可以安装你自己的应用并为其[配置请求路由](/zh//docs/tasks/traffic-management/request-routing/)。可能需要[手工注入 Sidecar](/zh/docs/setup/kubernetes/sidecar-injection/#手工注入-sidecar)。

[安装选项参考](/zh/docs/reference/config/installation-options/)中列出了所有可用于对 Istio 安装进行按需裁剪的参数。在使用 `helm install` 的 `--set` 参数覆盖缺省值之前，请检查 `install/kubernetes/helm/istio/values.yaml` 中的配置，并按照实际需要去掉其中的注释标志。
