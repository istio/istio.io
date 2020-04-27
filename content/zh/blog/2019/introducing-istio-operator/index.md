---
title: Istio Operator 简介
description: 关于 Istio 基于 operator 的安装和控制平面管理特性的介绍。
publishdate: 2019-11-14
subtitle:
attribution: Martin Ostrowski (Google), Frank Budinsky (IBM)
keywords: [install,configuration,istioctl,operator]
target_release: 1.4
---

Kubernetes [operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) 提供了一种将人类运维知识编码到软件中的模式，是一种简化软件基础结构组件管理的流行方法。Istio 是自动 operator 的理想选择，因为它的管理具有挑战性。

到目前为止，[Helm](https://github.com/helm/helm) 一直是安装和升级 Istio 的主要工具。Istio 1.4 引入了一种新的[使用{{< istioctl >}}安装](/zh/docs/setup/install/istioctl/)方法。这种新的安装方法建立在 Helm 的优势之上，并添加了以下内容:

- 用户只需要安装一个工具：`istioctl`
- 验证所有 API 字段
- 不在 API 中的小型定制不需要更改 chart 或 API
- 版本特定的升级 hook 可以很容易和稳健地实现

[Helm 安装](/zh/docs/setup/install/helm/)方法正在弃用中。从 Istio 1.4 升级到一个默认没有安装 Helm 的版本也会被一个新的 [{{< istioctl >}} 升级特性](/zh/docs/setup/upgrade/istioctl-upgrade/)所取代。

新的 `istioctl` 安装命令使用一个[自定义资源](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)来配置安装。自定义资源是新的 Istio operator 实现的一部分，该实现旨在简化安装、升级和复杂的 Istio 配置更改等常见管理任务。安装和升级的验证和检查与工具紧密集成，以防止常见错误并简化故障排除。

## Operator API{#the-Operator-API}

每个 operator 实现都需要一个[自定义资源定义（CRD）](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) 来定义它的自定义资源，即它的 API。Istio 的 operator API 由 [`IstioControlPlane` CRD](/zh/docs/reference/config/istio.operator.v1alpha12.pb/) 定义，它是由一个 [`IstioControlPlane` 原型](https://github.com/istio/operator/blob/release-1.4/pkg/apis/istio/v1alpha2/istiocontrolplane_types.proto)生成的。API 支持所有 Istio 当前的[配置文件](/zh/docs/setup/additional-setup/config-profiles/) ，通过使用一个字段来选择 profile。例如，下面的 `IstioControlPlane` 资源使用 `demo` profile 配置 Istio：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: demo
{{< /text >}}

然后可以使用其他设置来自定义配置。例如，禁用遥测：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: demo
  telemetry:
    enabled: false
{{< /text >}}

## 通过{{< istioctl >}}安装{#install-with-Istio}

使用 Istio operator API 的推荐方法是通过一组新的 `istioctl` 命令。例如，要在集群中安装 Istio：

{{< text bash >}}
$ istioctl manifest apply -f <your-istiocontrolplane-customresource>
{{< /text >}}

通过编辑配置文件并再次执行 `istioctl manifest apply` 来更改安装配置。

升级到新版本的 Istio：

{{< text bash >}}
$ istioctl x upgrade -f <your-istiocontrolplane-config-changes>
{{< /text >}}

除了在 `IstioControlPlane` 资源中指定完整的配置外，`istioctl` 命令还可以使用 `--set` 标志传递单独的设置:

{{< text bash >}}
$ istioctl manifest apply --set telemetry.enabled=false
{{< /text >}}

还有许多其他 `istioctl` 命令，例如，它们可以帮助您列出、显示和比较配置 profile 和 manifest。

更多信息请参考 Istio [安装说明](/zh/docs/setup/install/istioctl)。

## Istio Controller (alpha){#Istio-controller-alpha}

Operator 实现使用 Kubernetes controller 来持续监控它们的自定义资源并应用相应的配置更改。Istio controller 监控一个 `IstioControlPlane` 资源，并通过更新相应集群中的 Istio 安装配置来响应更改。

在 1.4 版中，Istio controller 处于开发的 alpha 阶段，没有完全集成到 `istioctl` 中。但是，可以使用 `kubectl` 命令来做[实验](/zh/docs/setup/install/standalone-operator/)。例如，要将 controller 和默认版本的 Istio 安装到集群中，请运行以下命令:

{{< text bash >}}
$ kubectl apply -f https://<repo URL>/operator.yaml
$ kubectl apply -f https://<repo URL>/default-cr.yaml
{{< /text >}}

然后你可以对 Istio 的安装配置进行修改:

{{< text bash >}}
$ kubectl edit istiocontrolplane example-istiocontrolplane -n istio-system
{{< /text >}}

一旦资源更新，controller 将检测到这些变化，并相应地更新 Istio 安装。

Operator controller 和 `istioctl` 命令共享相同的实现。重要的区别在于其执行上下文。对于 `istioctl`，操作在管理用户的命令执行和安全上下文中运行。对于 controller，集群中的一个 pod 在其安全上下文中运行代码。在这两种情况下，都根据一个 schema 来验证配置，并执行相同的正确性检查。

## 从 Helm 迁移{#migration-from-helm}

为了方便从使用 Helm 过渡，`istioctl` 和 controller 支持对 Helm 安装 API 的透传访问。

您可以使用 `istioctl --set` 来传递 Helm 配置选项，方法是将字符串 `values.` 放在配置选项前面。例如，对于这个 Helm 命令：

{{< text bash >}}
$ helm template ... --set global.mtls.enabled=true
{{< /text >}}

您可以使用 `istioctl` 这个命令：

{{< text bash >}}
$ istioctl manifest generate ... --set values.global.mtls.enabled=true
{{< /text >}}

你也可以在一个 `IstioControlPlane` 自定义资源中设置 Helm 配置值。参见[使用 Helm 自定义 Istio 设置](/zh/docs/setup/install/istioctl/#customize-Istio-settings-using-the-helm-API)。

另一个可以帮助从 Helm 迁移的特性是这个 alpha 命令：[{{< istioctl >}} manifest migrate](/zh/docs/reference/commands/istioctl/#istioctl-manifest-migrate)。此命令可用于将 Helm `values.yaml` 文件自动转换为相应的 `IstioControlPlane` 配置。

## 实现{#implementation}

已经创建了几个框架，通过为部分或所有组件生成存根来帮助实现 operator。Istio operator 是在 [kubebuilder](https://github.com/kubernetes-sigs/kubebuilder) 和 [operator framework](https://github.com/operator-framework) 的帮助下创建的。Istio 的安装现在使用 proto 来描述 API，这样就可以通过 schema 对执行运行时进行验证。

有关实现的更多信息可以在 [Istio operator 仓库](https://github.com/istio/operator)中的 README 和 ARCHITECTURE 文档中找到。

## 总结{#summary}

从 Istio 1.4 开始，Helm 安装将被新的 `istioctl` 命令所取代，该命令使用新的 operator 自定义资源定义，`IstioControlPlane`，作为配置 API。一个 alpha controller 也被提供用于 operator 的早期实验。

新的 `istioctl` 命令和 operator controller 都会验证配置 schema，并执行安装更改或升级的一系列检查。这些检查与工具紧密集成，以防止常见错误并简化故障排除。

Istio 维护者们期望这种新方法能够改善安装和升级期间的用户体验，更好地稳定安装 API，帮助用户更好地管理和监控他们的 Istio 安装。

我们欢迎您在 [discuss.istio.io](https://discuss.istio.io/) 上对新的安装方法提出反馈。
