---
title: 使用 Istioctl Analyze 诊断配置
description: 演示如何使用 istioctl analyze 来识别配置中的潜在问题。
weight: 40
keywords: [istioctl, debugging, kubernetes]
---

{{< boilerplate experimental-feature-warning >}}

`istioctl analyze` 是功能强大的 Istio 诊断工具，可以检测 Istio 配置的潜在问题。
它可以针对实时群集或一组本地配置文件运行。它还可以将两者结合起来使用，从而允许您在将更改应用于集群之前发现问题。

## 一分钟入门{#getting-started-in-under-a-minute}

入门非常简单。 首先，使用一个命令将最新的 `istioctl` 下载到当前文件夹中（下载最新版本以确保它具有最完整的分析器集）：

{{< tabset cookie-name="platform" >}}

{{< tab name="Mac" cookie-value="macos" >}}

{{< text bash >}}
$ curl https://storage.googleapis.com/istio-build/dev/latest | xargs -I {} curl https://storage.googleapis.com/istio-build/dev/{}/istioctl-{}-osx.tar.gz | tar xvz
{{< /text >}}

{{< /tab >}}

{{< tab name="Linux" cookie-value="linux" >}}

{{< text bash >}}
$ curl https://storage.googleapis.com/istio-build/dev/latest | xargs -I {} curl https://storage.googleapis.com/istio-build/dev/{}/istioctl-{}-linux.tar.gz | tar xvz
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

然后，在当前的 Kubernetes 集群上运行它：

{{< text bash >}}
$ ./istioctl x analyze -k
{{< /text >}}

就是这样！ 它会为您提供任何适用的建议。

例如，如果您忘记启用 Istio 注入（一个非常常见的问题），则会收到以下警告：

{{< text plain >}}
Warn [IST0102](Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection
{{< /text >}}

注意命令中的 `x` 是因为当前这是一个实验性功能。

## 分析实时群集，本地文件或同时分析两者{#analyzing-live-clusters-local-files-or-both}

“入门”部分中的场景是对实时集群进行分析。但是该工具还支持对一组本地 Yaml 配置文件或对本地文件和实时集群的组合进行分析。

分析一组特定的本地文件：

{{< text bash >}}
$ ./istioctl x analyze a.yaml b.yaml
{{< /text >}}

分析当前文件夹中的所有 yaml 文件：

{{< text bash >}}
$ ./istioctl x analyze *.yaml
{{< /text >}}

模拟将当前文件夹中的文件应用于当前集群：

{{< text bash >}}
$ ./istioctl x analyze -k *.yaml
{{< /text >}}

您可以运行 `./istioctl x analyze --help` 来查看完整的选项集。

## 帮助我们改进此工具{#helping-us-improve-this-tool}

我们将不断增加更多的分析功能，并希望您能帮助我们确定更多的用例。
如果您发现了一些 Istio 配置 “陷阱”，一些导致您的使用出现问题的棘手情况，请提出问题并告知我们。
我们也许可以自动标记此问题，以便其他人可以提前发现并避免该问题。

为此，请您 [开启一个 issue](https://github.com/istio/istio/issues) 来描述您的情况。例如：

- 查看所有 virtual services
- 循环查看 virtual services 的 gateways 列表
- 如果某个 gateways 不存在，则报错

我们已经有针对这种特定情况的分析器，因此这仅是一个示例，用于说明您应提供的信息类型。

## Q&A{#q-a}

- **此工具针对的是哪个 Istio 版本？**

      Analysis 可与任何版本的 Istio 一起使用，并且不需要在群集中安装任何组件。您只需要获取 `istioctl` 的最新版本即可。

      在某些情况下，如果某些分析器对您的 Istio 发行版没有意义，则将不适用。但是，所有适用的分析器仍会进行分析。

      请注意，虽然 `analyze` 命令可在 Istio 发行版中使用，但并非所有其他 `istioctl` 命令都适用。因此建议您在单独的文件夹中下载最新版本的 `istioctl` 以进行分析，同时使用特定 Istio 版本随附的版本来运行其他命令。

- **现在支持哪些分析器？**

      我们仍在努力编写分析器文档。目前，您可以在 [Istio 源代码]({{<github_blob>}}/galley/pkg/config/analysis/analyzers) 中看到所有分析器。

- **analysis 分析对我的集群有影响吗？**

      分析永远不会更改配置状态。这是一个完全只读的操作，因此永远不会更改群集的状态。

- **超出配置范围的又如何分析呢？**

      今天，分析完全基于 Kubernetes 的配置，但是将来我们希望进一步扩展。例如，我们可以允许分析器查看日志以生成建议。

- **在哪里可以找到解决错误的方法？**

      [配置分析消息集](/zh/docs/reference/config/analysis/) 包含每个消息的描述以及建议的修复程序。

## 为资源状态启用验证消息{#enabling-validation-messages-for-resource-status}

{{< boilerplate experimental-feature-warning >}}

从 Istio 1.4 开始，可以通过 `galley.enableAnalysis` 标志将 Galley 设置为与主要负责的配置分发一起执行配置分析。该分析使用与 `istioctl analyze` 相同的逻辑和错误消息。来自分析的验证消息将写入受影响的 Istio 资源的状态子资源。

例如，如果您在 "ratings" 虚拟服务上网关配置错误，运行 `kubectl get virtualservice ratings` 将为您提供以下信息：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"networking.istio.io/v1alpha3","kind":"VirtualService","metadata":{"annotations":{},"name":"ratings","namespace":"default"},"spec":{"hosts":["ratings"],"http":[{"route":[{"destination":{"host":"ratings","subset":"v1"}}]}]}}
  creationTimestamp: "2019-09-04T17:31:46Z"
  generation: 11
  name: ratings
  namespace: default
  resourceVersion: "12760039"
  selfLink: /apis/networking.istio.io/v1alpha3/namespaces/default/virtualservices/ratings
  uid: dec86702-cf39-11e9-b803-42010a8a014a
spec:
  gateways:
  - bogus-gateway
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
status:
  validationMessages:
  - code: IST0101
    level: Error
    message: 'Referenced gateway not found: "bogus-gateway"'
{{< /text >}}

`enableAnalysis` 在后台运行，并将使资源的状态字段保持其当前验证状态的最新状态。请注意，这不能代替 `istioctl analyze`：

- 并非所有资源都有自定义状态字段 (例如 Kubernetes `namespace` 资源)，因此附加到这些资源的消息将不会显示验证消息。
- `enableAnalysis` 仅适用于从1.4开始的 Istio 版本，而 `istioctl analysis` 可以用于较早的版本。
- 尽管可以轻松查看特定资源的问题所在，但要在网格中全面了解验证状态更加困难。

您可以通过以下方式启用此功能：

{{< text bash >}}
$ istioctl manifest apply --set values.galley.enableAnalysis=true
{{< /text >}}
