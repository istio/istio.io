---
title: 使用 Istioctl Analyze 诊断配置
description: 演示如何使用 istioctl analyze 来识别配置中的潜在问题。
weight: 40
keywords: [istioctl, debugging, kubernetes]
---

`istioctl analyze` 是一个诊断工具，可以检测 Istio 配置的潜在问题。它可以针对运行的群集或一组本地配置文件运行。它还可以将两者结合起来使用，从而允许您在将更改应用于集群之前发现问题。

## 一分钟入门{#getting-started-in-under-a-minute}

可以使用如下的命令分析您当前的集群：

{{< text bash >}}
$ istioctl analyze
{{< /text >}}

就是这样！它会给你任何合适的建议。

例如，如果您忘记启用 Istio 注入（一个非常常见的问题），则会收到以下警告：

{{< text plain >}}
Warn [IST0102](Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection
{{< /text >}}

## 分析实时群集，本地文件或同时分析两者{#analyzing-live-clusters-local-files-or-both}

上面的例子是对运行的集群进行分析。但是该工具还支持对一组本地 Kubernetes yaml 配置文件，或对本地文件和运行集群的组合进行分析。当分析一组本地文件时，文件集应该是完全独立的。通常，这用于分析打算部署到集群的整个配置文件集。

分析一组特定的本地文件：

{{< text bash >}}
$ istioctl analyze --use-kube=false a.yaml b.yaml
{{< /text >}}

分析当前文件夹中的所有 yaml 文件：

{{< text bash >}}
$ istioctl analyze --use-kube=false *.yaml
{{< /text >}}

模拟将当前文件夹中的文件应用于当前集群：

{{< text bash >}}
$ istioctl analyze *.yaml
{{< /text >}}

可以运行 `istioctl analyze --help` 来查看完整的选项集。

## 帮助我们改进此工具{#helping-us-improve-this-tool}

我们将不断增加更多的分析功能，并希望您能帮助我们发现更多的用例。
如果您发现了一些 Istio 配置 “陷阱”，一些导致您的使用出现问题的棘手情况，请提出问题并告知我们。
我们也许可以自动标记此问题，以便其他人可以提前发现并避免该问题。

为此，请您[开启一个 issue](https://github.com/istio/istio/issues) 来描述您的情况。例如：

- 查看所有 virtual services
- 循环查看 virtual services 的 gateways 列表
- 如果某个 gateways 不存在，则报错

我们已经有针对这种特定情况的分析器，因此这仅是一个示例，用于说明您应提供的信息类型。

## Q&A{#q-a}

- **此工具针对的是哪个 Istio 版本？**

      和其它 `istioctl` 工具一样，我们通常建议下载一个和您集群中部署版本相匹配的版本来使用。

      就目前而言，analysis 是向后兼容的，所以你可以在运行 Istio 1.1 的集群上使用 1.4 版本的 `istioctl analyze`，并且会得到有用的反馈。对老版本 Istio 没有意义的分析规则将被跳过。

      如果你决定使用最新的 `istioctl` 来对一个运行老版本 Istio 的集群进行分析，我们建议您将其保存在一个独立的目录中，和用于部署 Istio 的二进制文件分开。

- **现在支持哪些分析器？**

      我们仍在努力编写分析器文档。目前，您可以在 [Istio 源代码]({{<github_blob>}}/galley/pkg/config/analysis/analyzers)中看到所有分析器。

      你还可以了解一下目前支持哪些[配置分析消息](/zh/docs/reference/config/analysis/)。

- **analysis 分析对我的集群有影响吗？**

      分析永远不会更改配置状态。这是一个完全只读的操作，因此永远不会更改群集的状态。

- **超出配置范围的又如何分析呢？**

      今天，分析完全基于 Kubernetes 的配置，但是将来我们希望进一步扩展。例如，我们可以允许分析器查看日志以生成建议。

- **在哪里可以找到解决错误的方法？**

      [配置分析消息](/zh/docs/reference/config/analysis/)集包含每个消息的描述以及建议的修复程序。

## 高级功能{#advanced}

### 获取最新版本的 `istioctl analyze`{#getting-the-latest-version-of-Istio-analyze}

虽然 `istioctl analyze` 是包含在了 Istio 1.4 以及更高级的版本中，但是还可以直接下载最新版本到集群中使用的。最新版本可能不稳定，但是会有最完整和最新的分析程序集，并且可能会发现旧版本遗漏的问题。

可以使用下面的命令下载最新的 `istioctl` 到当前目录：

{{< tabset category-name="platform" >}}

{{< tab name="Mac" category-value="macos" >}}

{{< text bash >}}
$ curl https://storage.googleapis.com/istio-build/dev/latest | xargs -I {} curl https://storage.googleapis.com/istio-build/dev/{}/istioctl-{}-osx.tar.gz | tar xvz
{{< /text >}}

{{< /tab >}}

{{< tab name="Linux" category-value="linux" >}}

{{< text bash >}}
$ curl https://storage.googleapis.com/istio-build/dev/latest | xargs -I {} curl https://storage.googleapis.com/istio-build/dev/{}/istioctl-{}-linux.tar.gz | tar xvz
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 为资源状态启用验证消息{#enabling-validation-messages-for-resource-status}

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
- `enableAnalysis` 仅适用于从 1.4 开始的 Istio 版本，而 `istioctl analysis` 可以用于较早的版本。
- 尽管可以轻松查看特定资源的问题所在，但要在网格中全面了解验证状态更加困难。

您可以通过以下方式启用此功能：

{{< text bash >}}
$ istioctl manifest apply --set values.galley.enableAnalysis=true
{{< /text >}}

### 通过 CLI 忽略特定的分析器消息{#ignoring-specific-analyzer-messages-via-cli}

有时候你可能会发现，在某些情况下隐藏或忽略分析器消息很有用。例如，假设出现这样一种情况，其发出有关您无权更新资源的消息：

{{< text bash >}}
$ istioctl analyze -k --all-namespaces
Warn [IST0102] (Namespace frod) The namespace is not enabled for Istio injection. Run 'kubectl label namespace frod istio-injection=enabled' to enable it, or 'kubectl label namespace frod istio-injection=disabled' to explicitly mark it as not needing injection
Error: Analyzers found issues.
See https://istio.io/docs/reference/config/analysis for more information about causes and resolutions.
{{< /text >}}

因为您没有更新命名空间的权限，所以无法通过注释命名空间来解析消息。相反，您可以直接使用 `istioctl analyze` 来抑制上述资源中的消息：

{{< text bash >}}
$ istioctl analyze -k --all-namespaces --suppress "IST0102=Namespace frod"
✔ No validation issues found.
{{< /text >}}

用于抑制的语法与引用资源时在整个 `istioctl` 中使用的语法相同：`<kind> <name>.<namespace>`。或只是 `<kind> <name>` 用于集群范围内的资源，例如，`Namespace`。如果要抑制多个对象，则可以重复使用 `--suppress` 参数或使用通配符：

{{< text bash >}}
$ # Suppress code IST0102 on namespace frod and IST0107 on all pods in namespace baz
$ istioctl analyze -k --all-namespaces --suppress "IST0102=Namespace frod" --suppress "IST0107=Pod *.baz"
{{< /text >}}

### 通过注释忽略特定的分析器消息{#ignoring-specific-analyzer-messages-via-annotations}

您还可以使用资源上的注释忽略特定的分析器消息。例如，忽略资源 `deployment/my-deployment` 上的代码 IST0107（`MisplacedAnnotation`）：

{{< text bash >}}
$ kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107
{{< /text >}}

要忽略资源的多处代码，请用逗号分隔每处代码：

{{< text bash >}}
$ kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107,IST0002
{{< /text >}}
