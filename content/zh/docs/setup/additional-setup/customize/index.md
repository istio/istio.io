---
title: 高级安装选项
description: 自定义 Istio 安装。
weight: 35
aliases:
    - /zh/docs/setup/kubernetes/additional-setup/customize/
keywords: [kubernetes]
draft: true
---

本页面介绍了一些 Istio 组件的碎片式安装的选项。

## 仅安装 Ingress 控制器{#ingress-controller-only}

可以使用 Istio 作为 Ingress 控制器, 利用它的高级七层路由功能，例如基于版本的路由、基于 Header 的路由、gRPC/HTTP2 代理、追踪等。仅部署 Istio Pilot，并禁用其他组件。不要部署 Istio 的初始化程序。

## Ingress 控制器，并提供策略和遥测支持{#ingress-controller-with-policies-and-telemetry}

通过部署 Istio Pilot 和 Mixer，上面提到的 Ingress 控制器配置就能够得到增强，从而进一步提供深入遥测和策略实施能力，例如速率控制、访问控制等功能。

## 智能路由和遥测{#intelligent-routing-and-telemetry}

除了获得深度遥测和分布式请求追踪之外，如果您还希望充分利用 Istio 的七层路由管理功能, 就需要部署 Istio Pilot 和 Mixer。此外还可以在 Mixer 上禁用策略支持。

## 定制示例：流量管理和最小安全集合{#customization-example-traffic-management-and-minimal-security-set}

Istio 拥有丰富的功能集, 但是您可能只想要使用其中的一个子集。例如，您可能只对安装最少的必要服务来支持流量管理和安全功能感兴趣。

这个例子展示了如何只安装用于[流量管理](/zh/docs/tasks/traffic-management/)功能的最小化组件集合。

执行下列命令安装 Pilot 和 Citadel:

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set ingress.enabled=false \
  --set gateways.istio-ingressgateway.enabled=false \
  --set gateways.istio-egressgateway.enabled=false \
  --set galley.enabled=false \
  --set sidecarInjectorWebhook.enabled=false \
  --set mixer.enabled=false \
  --set prometheus.enabled=false
{{< /text >}}

在 Kubernetes 中确认 `istio-pilot-*` 和 `istio-citadel-*`  pod 被部署并且它们的容器成功运行起来:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                     READY     STATUS    RESTARTS   AGE
istio-citadel-b48446f79-wd4tk            1/1       Running   0          1m
istio-pilot-58c65f74bc-2f5xn             2/2       Running   0          1m
{{< /text >}}

在这个最小组件集的支持下，您可以安装自己的应用并为其[配置请求路由](/zh/docs/tasks/traffic-management/request-routing/)。 您将需要[手动注入 sidecar](/zh/docs/setup/additional-setup/sidecar-injection/#manual-sidecar-injection)。

[安装选项](/zh/docs/reference/config/installation-options/) 中提供完整的选项列表，可以让您根据需要定制 Istio 安装。 当您在 `helm install` 中使用 `--set` 覆盖默认值之前，请检查 `install/kubernetes/helm/istio/values.yaml` 中各选项的配置，并根据需要去掉其中的注释。
