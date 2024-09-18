---
title: "Istio 已弃用其 In-Cluster Operator"
description: 如果您在集群中运行 Operator 控制器，您需要了解哪些内容。
publishdate: 2024-08-14
attribution: "Mitch Connors (Microsoft), for the Istio Technical Oversight Committee; Translated by Wilson Wu (DaoCloud)"
keywords: [operator,deprecation]
---

Istio 的 In-Cluster Operator 已在 Istio 1.23 中弃用。
正在利用该 Operator 的用户（我们估计不到我们用户群的 10%）将需要迁移到其他安装和升级机制才能升级到
Istio 1.24 或更高版本。请继续阅读以了解我们进行此更改的原因以及 Operator 用户需要执行的操作。

## 这对您有影响吗？ {#does-this-affect-you}

此弃用仅影响 [In-Cluster Operator](https://archive.istio.io/v1.23/zh/docs/setup/install/operator/) 的用户。
**使用 <code>istioctl install</code> 命令和 `IstioOperator` YAML 文件安装 Istio 的用户不受影响**。

要确定您是否受到影响，请运行 `kubectl get deployment -n istio-system istio-operator`
和 `kubectl get IstioOperator`。如果两个命令都返回非空值，则您的集群将受到影响。
根据最近的调查，我们预计这将影响不到 10% 的 Istio 用户。

基于 Operator 的 Istio 安装将继续无限期运行，但无法升级到 1.23.x 以上。

## 我什么时候需要迁移？ {#when-do-i-need-to-migrate}

根据 Istio 针对 Beta 功能的弃用政策，Istio In-Cluster Operator
将在 Istio 1.24 发布时（距此公告大约三个月）被移除。
Istio 1.23 将支持到 2025 年 3 月，届时 Operator 用户将需要迁移到其他安装机制才能保留支持。

## 我要如何迁移？ {#how-do-i-migrate}

Istio 项目将继续支持通过 `istioctl` 命令以及 Helm 进行安装和升级。
由于 Helm 在平台工程生态系统中非常受欢迎，我们建议大多数用户迁移到 Helm。
`istioctl install` 基于 Helm 模板，未来版本可能会与 Helm 进行更深入的集成。

Helm 安装还可以使用 GitOps 工具（例如 [Flux](https://fluxcd.io/)
或 [Argo CD](https://argo-cd.readthedocs.io/)）进行管理。

喜欢使用 Operator 模式运行 Istio 的用户可以迁移到两个新的 Istio 生态系统项目之一，
即 Classic Operator Controller 或 Sail Operator。

### 迁移到 Helm {#migrating-to-helm}

Helm 迁移需要将您的 `IstioOperator` YAML 转换为 Helm `values.yaml` 文件。
支持此迁移的工具将与 Istio 1.24 版本一起提供。

### 迁移到 istioctl {#migrating-to-istioctl}

识别您的 `IstioOperator` 自定义资源：应该只有一个结果。

{{< text bash >}}
$ kubectl get IstioOperator
{{< /text >}}

使用您的资源名称，以 YAML 格式下载您的 Operator 配置：

{{< text bash >}}
$ kubectl get IstioOperator <name> > istio.yaml
{{< /text >}}

禁用 In-Cluster Operator。这不会禁用您的控制平面或中断您当前的网格流量。

{{< text bash >}}
$ kubectl scale deployment -n istio-system istio-operator –replicas 0
{{< /text >}}

当您准备将 Istio 升级到 1.24 或更高版本时，
请按照[升级说明](/zh/docs/setup/upgrade/canary/)使用上面下载的 `istio.yaml` 文件进行操作。

完成并验证迁移后，运行以下命令来清理 Operator 资源：

{{< text bash >}}
$ kubectl delete deployment -n istio-system istio-operator
$ kubectl delete customresourcedefinition istiooperator
{{< / text >}}

### 迁移到 Classic Operator Controller {#migrating-to-the-classic-operator-controller}

一个新的生态系统项目 [Classic Operator Controller](https://github.com/istio-ecosystem/classic-operator-controller)
是 Istio 内置原始控制器的一个分支。该项目与原始 Operator 保持相同的 API 和代码库，
但在 Istio 核心之外进行维护。

由于 API 相同，迁移很简单：只需要​​安装新的 Operator。

Classic Operator Controller 并非被 Istio 项目支持。

### 迁移到 Sail Operator {#migrating-to-sail-operator}

一个新的生态系统项目 [Sail Operator](https://github.com/istio-ecosystem/sail-operator)
能够在 Kubernetes 或 OpenShift 集群中安装并管理 Istio 控制平面的生命周期。

Sail Operator API 是围绕 Istio 的 Helm Chart API 构建的。
Istio 的 Helm Chart 公开的所有安装和配置选项都可以通过 Sail Operator CRD 的 `values:` 字段获得。

Sail Operator 并非被 Istio 项目支持。

## 什么是 Operator，为什么 Istio 有一个 Operator？ {#what-is-an-operator-and-why-did-istio-have-one}

[Operator 模式](https://kubernetes.io/zh-cn/docs/concepts/extend-kubernetes/operator/)于 2016 年由 CoreOS 推广，
作为一种将人类智能编码成代码的方法。最常见的用例是数据库 Operator，
用户可能在一个集群中拥有多个数据库实例，并有多个正在进行的操作任务（备份、真空、分片）。

为了解决 Helm v2 中存在的问题，Istio 在 1.4 版中引入了 istioctl 和 In-Cluster Operator。
大约在同一时间，Helm v3 的推出解决了社区的担忧，并且是当今在 Kubernetes 上安装软件的首选方法。
Istio 1.8 中添加了对 Helm v3 的支持。

Istio 的 In-Cluster Operator 负责处理服务网格组件的安装 - 该操作通常只执行一次，
并且每个集群只执行一个实例。您可以将其视为在集群内运行 istioctl 的一种方式。
但是，这意味着您在集群内运行了一个高权限控制器，这会削弱您的安全态势。
它不处理任何正在进行的管理任务（备份、抓取快照等并不是运行 Istio 的必要条件）。

Istio Operator 是您必须安装到集群中的工具，这意味着您已经必须管理某些东西的安装。
使用它来升级集群同样需要您首先下载并运行新版本的 istioctl。

使用 Operator 意味着您创建了一个间接级别，
您必须在自定义资源中提供选项来配置您可能希望更改的有关安装的所有内容。
Istio 通过提供 `IstioOperator` API 解决了这个问题，该 API 允许配置安装选项。
此资源由 In-Cluster Operator 和 istioctl 安装使用，因此 Operator 用户可以轻松迁移。

三年前 - 大约在 Istio 1.12 发布的时候 - 我们更新了我们的文档，
说明不鼓励使用 Operator 安装新的 Istio，用户应该使用 istioctl 或 Helm 来安装 Istio。

[三种不同的安装方法引起了混淆](https://blog.howardjohn.info/posts/istio-install/)，
为了给使用 Helm 或 istioctl 的用户（占我们安装基数的 90% 以上）提供最佳体验，
我们决定在 Istio 1.23 中正式弃用 In-Cluster Operator。
