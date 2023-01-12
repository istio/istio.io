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

1. [下载 Istio 发行版](/zh/docs/setup/getting-started/#download)。
1. 执行必要的[平台安装](/zh/docs/setup/platform-setup/)。
1. 检查 [Pod 和服务的要求](/zh/docs/ops/deployment/requirements/)。

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

## 检查安装了什么 {#check-whats-installed}

`istioctl` 命令把安装 Istio 的 `IstioOperator` CR 保存到一个叫 `installed-state` 的 CR 副本中。
故无须检查 Istio 安装的 Deployment、Pod、Service 等其他资源，例如：

{{< text bash >}}
$ kubectl -n istio-system get deploy
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
istio-egressgateway    1/1     1            1           25s
istio-ingressgateway   1/1     1            1           24s
istiod                 1/1     1            1           20s
{{< /text >}}

可以查看 `installed-state` CR，来了解集群中都安装了什么，也可以看到所有的定制设置。
例如：用下面命令将它的内容导出到一个 YAML 文件：

{{< text bash >}}
$ kubectl -n istio-system get IstioOperator installed-state -o yaml > installed-state.yaml
{{< /text >}}

在一些  `istioctl` 命令中，`installed-state` CR 被用于执行检查任务，因此不能删除。

## 展示可用配置档的列表 {#display-the-list-of-available-profiles}

您可以用下面命令展示 `istioctl` 可以访问到的 Istio 配置档的名称：

{{< text bash >}}
$ istioctl profile list
Istio configuration profiles:
    default
    demo
    empty
    minimal
    openshift
    preview
    remote
{{< /text >}}

## 展示配置档的配置信息 {#display-the-configuration-of-a-profile}

您可以浏览一个配置档的配置信息。例如，运行下面命令浏览 `demo` 配置档的设置信息：

{{< text bash >}}
$ istioctl profile dump demo
components:
  egressGateways:
  - enabled: true
    k8s:
      resources:
        requests:
          cpu: 10m
          memory: 40Mi
    name: istio-egressgateway

...
{{< /text >}}

只浏览配置文件的某个部分的话，可以用 `--config-path` 参数，它将只选择配置文件中指定路径的局部内容：

{{< text bash >}}
$ istioctl profile dump --config-path components.pilot demo
enabled: true
k8s:
  env:
  - name: PILOT_TRACE_SAMPLING
    value: "100"
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
{{< /text >}}

## 显示配置文件的差异 {#show-differences-in-profiles}

`profile diff` 子命令可用于显示配置档之间的差异，
它在把更改应用到集群之前，检查定制效果方面非常有用。

您可以使用此命令显示 default 和 demo 两个配置档之间的差异：

{{< text bash >}}
$ istioctl profile diff default demo
 gateways:
   egressGateways:
-  - enabled: false
+  - enabled: true
...
     k8s:
        requests:
-          cpu: 100m
-          memory: 128Mi
+          cpu: 10m
+          memory: 40Mi
       strategy:
...
{{< /text >}}

## 安装前生成清单文件 {#generate-a-manifest-before-installation}

在安装 Istio 之前，可以用 `manifest generate` 子命令生成清单文件。
例如，用下面命令生成 `default` 配置档的清单文件：

{{< text bash >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

生成的清单文件可用于检查具体安装了什么，也可用于跟踪清单是如何随着时间而改变的。
虽然 `IstioOperator` CR 代表完整的用户配置，足以用于跟踪，
但 `manifest generate` 命令的输出还能截获底层 chart 潜在的改变，因此可以用于跟踪实际安装过的资源。

`manifest generate` 的输出还能传递给 `kubectl apply` 或类似的命令，用来安装 Istio。
然而，这些替代的安装方法不能像 `istioctl install` 那样，将相同的依赖顺序应用于资源，
并且也没有在 Istio 发行版中测试过。

{{< warning >}}
如果尝试使用 `istioctl manifest generate` 安装和管理 Istio，请注意以下事项：

1. Istio 的命名空间（默认为`istio-system`）必须手工创建。

1. 默认情况下，Istio 验证将不会被启用。
   与 `istioctl install` 不同，`manifest generate` 命令不会创建 `istiod-default-validator` 验证 webhook 配置，除非设置 `values.defaultRevision`：

    {{< text bash >}}
    $ istioctl manifest generate --set values.defaultRevision=default
    {{< /text >}}

1. `istioctl install` 会在 Kubernetes 上下文中自动探测环境特定的设置，
   但以离线运行的 `manifest generate` 不行，而且可能导致意外结果。
   特别是，如果 Kubernetes 环境不支持第三方服务帐户令牌，则必须确保遵循[这些步骤](/zh/docs/ops/best-practices/security/#configure-third-party-service-account-tokens)。

1. 用 `kubectl apply` 执行生成的清单，会显示临时错误，这是因为集群中的资源进入可用状态的顺序有问题。

1. `istioctl install` 自动清除一些资源，其实这些资源在配置改变时（例如，当您删除网关）就应该被删掉了。
   但此机制在 `kubectl` 和 `istio manifest generate` 协同使用时并不会发生，所以这些资源必须手动删除。

{{< /warning >}}

## 显示清单的差异 {#show-differences-in-manifests}

使用这一组命令，以 YAML 风格的差异对比方式，显示 default 配置项和定制安装生成的两个清单之间的差异：

{{< text bash >}}
$ istioctl manifest generate > 1.yaml
$ istioctl manifest generate -f samples/operator/pilot-k8s.yaml > 2.yaml
$ istioctl manifest diff 1.yaml 2.yaml
Differences in manifests are:


Object Deployment:istio-system:istiod has diffs:

spec:
  template:
    spec:
      containers:
        '[#0]':
          resources:
            requests:
              cpu: 500m -> 1000m
              memory: 2048Mi -> 4096Mi


Object HorizontalPodAutoscaler:istio-system:istiod has diffs:

spec:
  maxReplicas: 5 -> 10
  minReplicas: 1 -> 2
{{< /text >}}

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
