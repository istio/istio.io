---
title: 使用 Istioctl 安装
description: 安装、定制 Istio 配置文件，用于深入评估及生产发布。
weight: 10
keywords: [istioctl,kubernetes]
owner: istio/wg-environments-maintainers
test: no
---

跟随本指南安装、配置 Istio 网格，用于深入评估及生产发布。
如果您是 Istio 新手，只想简单尝试，请参考[快速入门指南](/zh/docs/setup/getting-started)。

本安装指南使用命令行工具 [istioctl](/zh/docs/reference/commands/istioctl/)，
它提供丰富的定制功能，用于定制 Istio 控制平面以及数据平面 Sidecar。
它还提供用户输入验证功能，这有助于防止安装错误；提供定制选项，可以覆盖配置的任何方面。

使用这些说明，您可以选取任意一个 Istio 内置的[配置档](/zh/docs/setup/additional-setup/config-profiles/)，
为您的特定需求进一步定制配置。

`istioctl` 命令通过命令行的选项支持完整的
[`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/)，
这些选项用于单独设置、以及接收包含 IstioOperator {{<gloss CRD>}}定制资源（CR）{{</gloss>}}的 yaml 文件。

## 先决条件 {#prerequisites}

开始之前，检查下列先决条件：

1. [下载 Istio 发行版](/zh/docs/setup/additional-setup/download-istio-release/)。
1. 执行必要的[平台安装](/zh/docs/setup/platform-setup/)。
1. 检查 [Pod 和 Service 的要求](/zh/docs/ops/deployment/application-requirements/)。

## 使用默认配置档安装 Istio {#install-using-default-profile}

最简单的选择是用下面命令安装 Istio 默认[配置档](/zh/docs/setup/additional-setup/config-profiles/)：

{{< text bash >}}
$ istioctl install
{{< /text >}}

此命令在 Kubernetes 集群上安装 `default` 配置档。
`default` 配置档是建立生产环境的一个良好起点，
这和较大的 `demo` 配置档不同，后者常用于评估一组广泛的 Istio 特性。

可以配置各种设置来修改安装。比如，要启动访问日志：

{{< text bash >}}
$ istioctl install --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

{{< tip >}}
本页和文档其他地方的许多示例都是使用 `--set` 来修改安装参数，
而不是用 `-f` 传递配置文件。
这么做可以让例子更紧凑。
这两种方法是等价的，但强烈推荐在生产环境使用 `-f`。
上面的命令可以用 `-f` 写成如下的形式：

{{< text bash >}}
$ cat <<EOF > ./my-config.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
EOF
$ istioctl install -f my-config.yaml
{{< /text >}}

{{< /tip >}}

{{< tip >}}
完整的 API 记录在 [`IstioOperator` API 参考文档](/zh/docs/reference/config/istio.operator.v1alpha1/)。
通常，您可以像使用 Helm 一样，在 `istioctl` 中使用 `--set` 参数，
并且当前 Helm 的 `values.yaml` API 向后兼容。
唯一的区别是您必须给原有 `values.yaml` 路径前面加上 `values.` 前缀，这是 Helm 透传 API 的前缀。
{{< /tip >}}

## 从外部 chart 安装 {#install-from-external-charts}

默认情况下，`istioctl` 使用内置 chart 生成安装清单。
这些 chart 随同 `istioctl` 一起发布，用以满足审计和定制，您可以在发行包的 `manifests` 目录下找到它们。
`istioctl` 除了使用内置 chart 外，还可以使用外部 chart。
为了选择外部 chart，可以设置参数 `manifests` 指向本地文件系统路径：

{{< text bash >}}
$ istioctl install --manifests=manifests/
{{< /text >}}

如果使用 `istioctl` {{< istio_full_version >}} 版本的二进制文件，此命令将得到和独立运行 `istioctl install` 相同的结果，
这是因为它指向了和内置 chart 相同的 chart。
除非要实验或测试新特性，我们建议使用内置的 chart，而不是外部 chart，以保障 `istioctl` 与 chart 的兼容性。

## 安装一个不同的配置档 {#install-a-different-profile}

其他的 Istio 配置档，可以通过在命令行传递配置档名称的方式，安装到集群。
例如，下面命令可以用来安装 `demo` 配置档。

{{< text bash >}}
$ istioctl install --set profile=demo
{{< /text >}}

## 安装前生成清单文件 {#generate-a-manifest-before-installation}

在安装 Istio 之前，可以用 `manifest generate`
子命令生成清单文件。例如，使用以下命令为可以使用 `kubectl`
安装的 `default` 配置文件生成清单：

{{< text bash >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

生成的清单可用于检查具体安装了什么以及跟踪清单随时间的变化。
虽然 `IstioOperator` CR 代表完整的用户配置并且足以跟踪它，
但 `manifest generate` 的输出还捕获了底层图表中可能的变化，
因此可用于跟踪实际安装的资源。

{{< tip >}}
您通常用于安装的任何其他标志或自定义值覆盖也应提供给 `istioctl manifest generate` 命令。
{{< /tip >}}

{{< warning >}}
如果尝试使用 `istioctl manifest generate` 安装和管理 Istio，请注意以下事项：

1. Istio 的命名空间（默认为`istio-system`）必须手工创建。

1. 默认情况下，Istio 验证将不会被启用。
   与 `istioctl install` 不同，`manifest generate` 命令不会创建 `istiod-default-validator` 验证 webhook 配置，除非设置 `values.defaultRevision`：

    {{< text bash >}}
    $ istioctl manifest generate --set values.defaultRevision=default
    {{< /text >}}

1. 资源可能没有按照与 `istioctl install` 相同的依赖项顺序进行安装。

1. 此方法尚未作为 Istio 版本的一部分进行测试。

1. `istioctl install` 会在 Kubernetes 上下文中自动探测环境特定的设置，
   但以离线运行的 `manifest generate` 不行，而且可能导致意外结果。
   特别是，如果 Kubernetes 环境不支持第三方服务帐户令牌，
   则必须确保遵循[这些步骤](/zh/docs/ops/best-practices/security/#configure-third-party-service-account-tokens)。
   建议在 `istio manifest generate` 命令后附加'`--cluster-specific` 以检测目标集群的环境，
   这会将这些特定于集群的环境设置嵌入到生成的清单中。这需要对正在运行的集群进行网络访问。

1. 用 `kubectl apply` 执行生成的清单，会显示临时错误，
   这是因为集群中的资源进入可用状态的顺序有问题。

1. `istioctl install` 自动清除一些资源，其实这些资源在配置改变时（例如，当您删除网关）就应该被删掉了。
   但此机制在 `kubectl` 和 `istio manifest generate`
   协同使用时并不会发生，所以这些资源必须手动删除。

{{< /warning >}}

## 验证安装是否成功 {#verify-a-successful-installation}

您可以用 `verify-install` 命令检查 Istio 是否安装成功，此命令用您指定的清单对比集群中实际的安装情况。

如果您在部署前还没有生成清单文件，那现在就运行下面命令生成一个：

{{< text bash >}}
$ istioctl manifest generate <your original installation options> > $HOME/generated-manifest.yaml
{{< /text >}}

紧接着运行 `verify-install` 命令，查看安装是否成功：

{{< text bash >}}
$ istioctl verify-install -f $HOME/generated-manifest.yaml
{{< /text >}}

有关定制安装的更多信息，请参阅[定制安装配置](/zh/docs/setup/additional-setup/customize-installation/)。

## 卸载 Istio {#uninstall}

要从集群中完整卸载 Istio，运行下面命令：

{{< text bash >}}
$ istioctl uninstall --purge
{{< /text >}}

{{< warning >}}
可选的 `--purge` 参数将移除所有 Istio 资源，包括可能被其他 Istio 控制平面共享的、集群范围的资源。
{{< /warning >}}

或者，只移除指定的 Istio 控制平面，运行以下命令：

{{< text bash >}}
$ istioctl uninstall <your original installation options>
{{< /text >}}

或

{{< text bash >}}
$ istioctl manifest generate <your original installation options> | kubectl delete --ignore-not-found=true -f -
{{< /text >}}

控制平面的命名空间（例如：`istio-system`）默认不会被移除。
如果确认不再需要，用下面命令移除该命名空间：

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}
