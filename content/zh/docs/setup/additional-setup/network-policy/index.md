---
title: NetworkPolicy
description: 为 Istio 组件部署可选的 Kubernetes NetworkPolicy 资源。
weight: 75
keywords: [networkpolicy,security,helm]
owner: istio/wg-networking-maintainers
test: no
---

Istio 可以选择性地为其组件部署 Kubernetes
[`NetworkPolicy`](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/) 资源。
这对于那些强制执行“默认拒绝”（default-deny）网络策略的集群非常有用，
而这正是安全环境中常见的需求。

启用此功能后，系统将为 istiod、istio-cni、ztunnel
以及通过 Helm 安装的网关创建 `NetworkPolicy`
资源，以定义各组件所需的入站端口。默认情况下，
所有出站流量均被允许，因为像 istiod
这样的组件需要连接到用户自定义的端点（例如 JWKS URL）。
网关的 `NetworkPolicy` 会自动包含在网关 Helm Values 中配置的服务端口。

{{< warning >}}
通过 Kubernetes Gateway API 或[网关注入](/zh/docs/setup/additional-setup/gateway/#deploying-a-gateway)创建的网关、
waypoint 代理以及 Sidecar **不**受 Istio 内置 `NetworkPolicy`
的覆盖——您必须为这些组件单独创建并管理 `NetworkPolicy` 资源。
这是有意为之的设计：若要自动管理这些代理的 `NetworkPolicy`，
就必须赋予 istiod 在整个集群范围内创建和修改 `NetworkPolicy` 资源的权限，
而这将对控制面的安全态势产生负面影响。
{{< /warning >}}

{{< tip >}}
如需了解 Ambient 模式如何与应用程序 Pod 上的 `NetworkPolicy` 进行交互，
请参阅 [Ambient 与 Kubernetes NetworkPolicy](/zh/docs/ambient/usage/networkpolicy/)。
{{< /tip >}}

## 启用 NetworkPolicy {#enabling-networkpolicy}

若要启用 `NetworkPolicy`，
请在安装期间设置 `global.networkPolicy.enabled=true`。

使用 `istioctl`：

{{< text bash >}}
$ istioctl install --set values.global.networkPolicy.enabled=true
{{< /text >}}

使用 Helm 时，将该设置传递给每个 Chart：

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --set global.networkPolicy.enabled=true
$ helm install istio-cni istio/cni -n istio-system --set global.networkPolicy.enabled=true
$ helm install ztunnel istio/ztunnel -n istio-system --set global.networkPolicy.enabled=true
$ helm install istio-ingressgateway istio/gateway -n istio-ingress --set global.networkPolicy.enabled=true
{{< /text >}}

## 审查生成的策略 {#reviewing-the-generated-policies}

每个组件的 `NetworkPolicy` 均允许在其所需的特定端口上接收入站流量，
并允许所有的出站流量（因为像 istiod
这样的组件需要连接到用户定义的端点，例如 JWKS URL）。

您可以使用 `helm template` 预览将要创建的确切 `NetworkPolicy` 资源：

{{< text bash >}}
$ helm template istiod istio/istiod -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

{{< text bash >}}
$ helm template istio-cni istio/cni -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

{{< text bash >}}
$ helm template ztunnel istio/ztunnel -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

安装后检查策略：

{{< text bash >}}
$ kubectl get networkpolicy -n istio-system
{{< /text >}}

## 自定义 NetworkPolicy {#customizing-networkpolicy}

Istio 所创建的 `NetworkPolicy` 资源被有意设计得较为宽泛——其入站规则
（ingress rules）采用了空的 `from` 选择器，
这意味着允许来自任何源端的流量通过指定的端口。
之所以如此设计，是因为在不同的集群环境中，合法流量的来源
（例如 kube-apiserver、Prometheus 以及各类应用 Pod）各不相同。

如果您需要更严格的策略，可以禁用 Istio 内置的 `NetworkPolicy`，
并以 `helm template` 的输出为起点，创建您自己的策略。
