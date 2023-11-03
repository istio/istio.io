---
title: 使用 Istioctl Analyze 诊断配置
description: 演示如何使用 istioctl analyze 来识别配置中的潜在问题。
weight: 40
keywords: [istioctl, debugging, kubernetes]
owner: istio/wg-user-experience-maintainers
test: yes
---

`istioctl analyze` 是一个诊断工具，可以检测 Istio 配置的潜在问题。
它可以针对运行的集群或一组本地配置文件运行。它还可以将两者结合起来使用，
从而允许您在将更改应用于集群之前发现问题。

## 一分钟入门 {#getting-started-in-under-a-minute}

可以使用如下的命令分析您当前的集群：

{{< text syntax=bash snip_id=analyze_all_namespaces >}}
$ istioctl analyze --all-namespaces
{{< /text >}}

就是这样！它会给您任何合适的建议。

例如，如果您忘记启用 Istio 注入（一个非常常见的问题），则会收到以下警告：

{{< text syntax=plain snip_id=analyze_all_namespace_sample_response >}}
Info [IST0102] (Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection.
{{< /text >}}

可使用如下命令修复：

{{< text syntax=bash snip_id=fix_default_namespace >}}
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

然后再重试一下：

{{< text syntax=bash snip_id=try_with_fixed_namespace >}}
$ istioctl analyze --namespace default
✔ No validation issues found when analyzing namespace: default.
{{< /text >}}

## 分析活动集群、本地文件或同时分析两者 {#analyzing-live-clusters-local-files-or-both}

分析当前的活动集群，模拟在 `samples/bookinfo/networking` 目录下应用诸如
`bookinfo-gateway.yaml` 和 `destination-rule-all.yaml` 等额外 yaml
文件的效果：

{{< text syntax=bash snip_id=analyze_sample_destrule >}}
$ istioctl analyze @samples/bookinfo/networking/bookinfo-gateway.yaml@ @samples/bookinfo/networking/destination-rule-all.yaml@
Error [IST0101] (Gateway default/bookinfo-gateway samples/bookinfo/networking/bookinfo-gateway.yaml:9) Referenced selector not found: "istio=ingressgateway"
Error [IST0101] (VirtualService default/bookinfo samples/bookinfo/networking/bookinfo-gateway.yaml:41) Referenced host not found: "productpage"
Error: Analyzers found issues when analyzing namespace: default.
See https://istio.io/v{{< istio_version >}}/docs/reference/config/analysis for more information about causes and resolutions.
{{< /text >}}

分析整个 `networking` 目录：

{{< text syntax=bash snip_id=analyze_networking_directory >}}
$ istioctl analyze samples/bookinfo/networking/
{{< /text >}}

分析 `networking` 目录下的所有 yaml 文件：

{{< text syntax=bash snip_id=analyze_all_networking_yaml >}}
$ istioctl analyze samples/bookinfo/networking/*.yaml
{{< /text >}}

上面的例子是对活动集群进行分析。但是该工具还支持对一组本地 Kubernetes yaml
配置文件，或对本地文件和活动集群的组合进行分析。当分析一组本地文件时，
文件集应该是完全独立的。通常，这用于分析打算部署到集群的整个配置文件集。
要使用此功能，只需添加 `--use-kube=false` 标志。

分析 `networking` 目录下的所有 yaml 文件：

{{< text syntax=bash snip_id=analyze_all_networking_yaml_no_kube >}}
$ istioctl analyze --use-kube=false samples/bookinfo/networking/*.yaml
{{< /text >}}

可以运行 `istioctl analyze --help` 来查看完整的选项集。

## 高级功能 {#advanced}

### 为资源状态启用验证消息 {#enabling-validation-messages-for-resource-status}

{{< boilerplate experimental-feature-warning >}}

从 Istio 1.5 开始，可以通过 `istiod.enableAnalysis` 标志将 Galley
设置为与其主要负责的配置分发一起执行配置分析。
此分析使用与 `istioctl analysis` 相同的逻辑和错误消息。
来自分析的验证消息被写入受影响的 Istio 资源的状态子资源。

例如：如果您的 "ratings" VirtualService 上网关配置错误，运行
`kubectl get virtualservice ratings` 会给您类似这样的结果：

{{< text syntax=yaml snip_id=vs_yaml_with_status >}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
...
spec:
  gateways:
  - bogus-gateway
  hosts:
  - ratings
...
status:
  observedGeneration: "1"
  validationMessages:
  - documentationUrl: https://istio.io/v{{< istio_version >}}/docs/reference/config/analysis/ist0101/
    level: ERROR
    type:
      code: IST0101
{{< /text >}}

`enableAnalysis` 在后台运行，并将保持资源的状态字段与其当前验证状态保持同步。
请注意，这不是`istioctl analysis`的替代品：

- 并非所有资源都有自定义状态字段（例如 Kubernetes `namespace` 资源），
  因此附加到这些资源的消息不会显示验证消息。
- `enableAnalysis` 仅适用于从 1.5 开始的 Istio 版本，而 `istioctl analysis`
  可用于旧版本。
- 虽然可以轻松查看特定资源的问题，但很难全面了解网格中的验证状态。

您可以通过以下命令启动此功能：

{{< text syntax=bash snip_id=install_with_custom_config_analysis >}}
$ istioctl install --set values.global.istiod.enableAnalysis=true
{{< /text >}}

### 通过 CLI 忽略特定的分析者消息 {#ignoring-specific-analyzer-messages-via-cli}

有时您可能会发现在某些情况下隐藏或忽略分析器消息很有用。例如，
想象这样一种情况，其中发出一条关于您无权更新的资源的消息：

{{< text syntax=bash snip_id=analyze_k_frod >}}
$ istioctl analyze -k --namespace frod
Info [IST0102] (Namespace frod) The namespace is not enabled for Istio injection. Run 'kubectl label namespace frod istio-injection=enabled' to enable it, or 'kubectl label namespace frod istio-injection=disabled' to explicitly mark it as not needing injection.
{{< /text >}}

由于您无权更新命名空间，因此无法通过注解命名空间来解析消息。相反，
您可以使用 `istioctl analysis` 来抑制资源上的上述消息：

{{< text syntax=bash snip_id=analyze_suppress0102 >}}
$ istioctl analyze -k --namespace frod --suppress "IST0102=Namespace frod"
✔ No validation issues found when analyzing namespace: frod.
{{< /text >}}

当引用：`<kind> <name>.<namespace>` 资源时，用于抑制的语法与整个
`istioctl` 中使用的语法相同，或者仅使用 `<kind> <name>` 对于 `Namespace`
集群范围的资源。如果您想抑制多个对象，您可以重复 `--suppress` 参数或使用通配符：

{{< text syntax=bash snip_id=analyze_suppress_frod_0107_baz >}}
$ # Suppress code IST0102 on namespace frod and IST0107 on all pods in namespace baz
$ istioctl analyze -k --all-namespaces --suppress "IST0102=Namespace frod" --suppress "IST0107=Pod *.baz"
{{< /text >}}

### 通过注解忽略特定的分析器消息 {#ignoring-specific-analyzer-messages-via-annotations}

您也可以使用资源上的注解忽略特定的分析器消息。例如，要忽略资源
`deployment/my deployment` 上的代码IST0107（`MisplacedAnnotation`）：

{{< text syntax=bash snip_id=annotate_for_deployment_suppression >}}
$ kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107
{{< /text >}}

要忽略资源的多个代码，请用英文逗号分隔每个代码：

{{< text syntax=bash snip_id=annotate_for_deployment_suppression_107 >}}
$ kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107,IST0002
{{< /text >}}

## 帮助我们改进此工具 {#helping-us-improve-this-tool}

我们将不断增加更多的分析功能，并希望您能帮助我们发现更多的用例。
如果您发现了一些 Istio 配置“陷阱”，一些导致您的使用出现问题的棘手情况，请提出问题并告知我们。
我们也许可以自动标记此问题，以便其他人可以提前发现并避免该问题。

为此，请您[开启一个 issue](https://github.com/istio/istio/issues)
来描述您的情况。例如：

- 查看所有 virtual services
- 循环查看 virtual services 的 gateways 列表
- 如果某个 gateways 不存在，则报错

我们已经有针对这种特定情况的分析器，因此这仅是一个示例，用于说明您应提供的信息类型。

## Q&A

- **此工具针对的是哪个 Istio 版本？**

    和其它 `istioctl` 工具一样，我们通常建议下载一个和您集群中部署版本相匹配的版本来使用。

    就目前而言，analysis 是向后兼容的，所以您可以在运行 Istio 1.1 的集群上使用 1.4 版本的
   `istioctl analyze`，并且会得到有用的反馈。对老版本 Istio 没有意义的分析规则将被跳过。

    如果您决定使用最新的 `istioctl` 来对一个运行老版本 Istio 的集群进行分析，
    我们建议您将其保存在一个独立的目录中，和用于部署 Istio 的二进制文件分开。

- **现在支持哪些分析器？**

    我们仍在努力编写分析器文档。目前，您可以在
    [Istio 源代码]({{< github_tree >}}/pkg/config/analysis/analyzers)中看到所有分析器。

    您还可以了解一下目前支持哪些[配置分析消息](/zh/docs/reference/config/analysis/)。

- **analysis 分析对我的集群有影响吗？**

    分析永远不会更改配置状态。这是一个完全只读的操作，因此永远不会更改集群的状态。

- **超出配置范围的又如何分析呢？**

    今天，分析完全基于 Kubernetes 的配置，但是将来我们希望进一步扩展。例如，
    我们可以允许分析器查看日志以生成建议。

- **在哪里可以找到解决错误的方法？**

    [配置分析消息](/zh/docs/reference/config/analysis/)集包含每个消息的描述以及建议的修复程序。
