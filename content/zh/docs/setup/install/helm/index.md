---
title: 使用 Helm 安装
linktitle: 使用 Helm 安装
description: 使用 Helm 在 K8s 集群中安装和配置 Istio。
weight: 30
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
test: yes
---

请遵循本指南使用 [Helm](https://helm.sh/docs/) 安装和配置 Istio 网格。

{{< boilerplate helm-preamble >}}

{{< boilerplate helm-prereqs >}}

## 安装步骤 {#installation-steps}

本节介绍使用 Helm 安装 Istio 的过程。Helm 安装的一般语法是：

{{< text syntax=bash snip_id=none >}}
$ helm install <release> <chart> --namespace <namespace> --create-namespace [--set <other_parameters>]
{{< /text >}}

该命令指定的变量如下：

* `<chart>`：一个打好包的 Chart 路径，也可以是一个未打包的 Chart 目录或 URL。
* `<release>`：一个用于标识和管理安装后的 Helm Chart 的名称。
* `<namespace>`：要安装 Chart 的命名空间。

您可以使用一个或多个 `--set <parameter>=<value>` 参数更改默认配置值。
或者可以使用 `--values <file>` 参数在一个自定义值文件中指定几个参数。

{{< tip >}}
您可以使用 `helm show values <chart>` 命令显示配置参数的默认值，或参考 `artifacthub` Chart
文档中的[自定义资源参数](https://artifacthub.io/packages/helm/istio-official/base?modal=values)、
[Istiod Chart 配置参数](https://artifacthub.io/packages/helm/istio-official/istiod?modal=values)
和 [Gateway Chart 配置参数](https://artifacthub.io/packages/helm/istio-official/gateway?modal=values)。
{{< /tip >}}

1. 为 Istio 组件，创建命名空间 `istio-system`：

    {{< tip >}}
    如果在第二步使用了 `--create-namespace` 参数，可以跳过这一步。
    {{< /tip >}}

    {{< text syntax=bash snip_id=create_istio_system_namespace >}}
    $ kubectl create namespace istio-system
    {{< /text >}}

1. 安装 Istio Base Chart，它包含了集群范围的自定义资源定义 (CRD)，这些资源必须在部署 Istio 控制平面之前安装：

    {{< warning >}}
    执行修订版安装时，Base Chart 需要设置 `--set defaultRevision=<revision>` 值以使资源验证起作用。
    以下我们将安装 `default` 修订版，因此配置了 `--set defaultRevision=default` 参数。
    {{< /warning >}}

    {{< text syntax=bash snip_id=install_base >}}
    $ helm install istio-base istio/base -n istio-system --set defaultRevision=default
    {{< /text >}}

1. 使用 `helm ls` 命令验证 CRD 的安装情况：

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME       NAMESPACE    REVISION UPDATED         STATUS   CHART        APP VERSION
    istio-base istio-system 1        ... ... ... ... deployed base-1.16.1  1.16.1
    {{< /text >}}

   在输出中找到 `istio-base` 的条目，并确保状态已被设置为 `deployed`。

1. 如果您打算使用 Istio CNI Chart，那您现在就必须这样操作。
   请参阅[通过 CNI 插件安装 Istio](/zh/docs/setup/additional-setup/cni/#installing-with-helm)了解更多信息。

1. 安装 Istio Discovery Chart，它用于部署 `istiod` 服务：

    {{< text syntax=bash snip_id=install_discovery >}}
    $ helm install istiod istio/istiod -n istio-system --wait
    {{< /text >}}

1. 验证 Istio Discovery Chart 的安装情况：

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME       NAMESPACE    REVISION UPDATED         STATUS   CHART         APP VERSION
    istio-base istio-system 1        ... ... ... ... deployed base-1.16.1   1.16.1
    istiod     istio-system 1        ... ... ... ... deployed istiod-1.16.1 1.16.1
    {{< /text >}}

1. 获取已安装的 Helm Chart 的状态，确保它已部署:

    {{< text syntax=bash >}}
    $ helm status istiod -n istio-system
    NAME: istiod
    LAST DEPLOYED: Fri Jan 20 22:00:44 2023
    NAMESPACE: istio-system
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    "istiod" successfully installed!

    To learn more about the release, try:
      $ helm status istiod
      $ helm get all istiod

    Next steps:
      * Deploy a Gateway: https://istio.io/latest/docs/setup/additional-setup/gateway/
      * Try out our tasks to get started on common configurations:
        * https://istio.io/latest/docs/tasks/traffic-management
        * https://istio.io/latest/docs/tasks/security/
        * https://istio.io/latest/docs/tasks/policy-enforcement/
        * https://istio.io/latest/docs/tasks/policy-enforcement/
      * Review the list of actively supported releases, CVE publications and our hardening guide:
        * https://istio.io/latest/docs/releases/supported-releases/
        * https://istio.io/latest/news/security/
        * https://istio.io/latest/docs/ops/best-practices/security/

    For further documentation see https://istio.io website

    Tell us how your install/upgrade experience went at https://forms.gle/99uiMML96AmsXY5d6
    {{< /text >}}

1. 检查 `istiod` 服务是否安装成功，确认其 Pod 是否正在运行:

    {{< text syntax=bash >}}
    $ kubectl get deployments -n istio-system --output wide
    NAME     READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                         SELECTOR
    istiod   1/1     1            1           10m   discovery    docker.io/istio/pilot:1.16.1   istio=pilot
    {{< /text >}}

1. （可选）安装 Istio 的入站网关：

    {{< text syntax=bash snip_id=install_ingressgateway >}}
    $ kubectl create namespace istio-ingress
    $ helm install istio-ingress istio/gateway -n istio-ingress --wait
    {{< /text >}}

    参阅[安装网关](/zh/docs/setup/additional-setup/gateway/)以获得关于网关安装的详细文档。

    {{< warning >}}
    网关被部署的命名空间不得具有 `istio-injection=disabled` 标签。
    有关更多信息，请参见[控制注入策略](/zh/docs/setup/additional-setup/sidecar-injection/#controlling-the-injection-policy)。
    {{< /warning >}}

{{< tip >}}
有关如何使用 Helm 后期渲染器自定义 Helm Chart 的详细文档，
请参见[高级 Helm Chart 自定义](/zh/docs/setup/additional-setup/customize-installation-helm/)。
{{< /tip >}}

## 更新 Istio 配置 {#updating-your-configuration}

您可以用自己的安装参数，覆盖掉前面用到的 Istio Helm Chart 的默认行为，
然后按照 Helm 升级流程来定制安装您的 Istio 网格系统。
至于可用的配置项，您可以通过使用 `helm show values istio/<chart>` 来找到配置。
例如 `helm show values istio/gateway`。

### 从非 Helm 安装迁移 {#migrating-from-non-helm-installations}

如果您需要将使用 `istioctl` 或 Operator 安装的 Istio 迁移到 Helm，
那要删除当前 Istio 控制平面资源，并根据上面的说明，使用 Helm 重新安装 Istio。
在删除当前 Istio 时，千万不能删掉 Istio 的自定义资源定义（CRD），以免丢掉您的自定义 Istio 资源。

{{< warning >}}
建议：从集群中删除 Istio 前，使用上面的说明备份您的 Istio 资源。
{{< /warning >}}

依据您的安装方式，选择
[Istioctl 卸载指南](/zh/docs/setup/install/istioctl#uninstall-istio)或
[Operator 卸载指南](/zh/docs/setup/install/operator/#uninstall)。

## 卸载 {#uninstall}

您可以通过卸载上述安装的 Chart，以便卸载 Istio 和及其组件。

1. 列出在命名空间 `istio-system` 中安装的所有 Istio Chart：

    {{< text syntax=bash snip_id=helm_ls >}}
    $ helm ls -n istio-system
    NAME       NAMESPACE    REVISION UPDATED         STATUS   CHART        APP VERSION
    istio-base istio-system 1        ... ... ... ... deployed base-1.0.0   1.0.0
    istiod     istio-system 1        ... ... ... ... deployed istiod-1.0.0 1.0.0
    {{< /text >}}

1. （可选）删除 Istio 的所有网关 Chart：

    {{< text syntax=bash snip_id=delete_delete_gateway_charts >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. 删除 Istio Discovery Chart：

    {{< text syntax=bash snip_id=helm_delete_discovery_chart >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. 删除 Istio Base Chart：

    {{< tip >}}
    从设计角度而言，通过 Helm 删除 Chart 并不会删除通过该 Chart 安装的 CRD。
    {{< /tip >}}

    {{< text syntax=bash snip_id=helm_delete_base_chart >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

1. 删除命名空间 `istio-system`：

    {{< text syntax=bash snip_id=delete_istio_system_namespace >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

## 卸载稳定的修订版标签资源 {#uninstall-stable-revision-label-resources}

如果您决定继续使用旧的控制平面不更新，您可以通过第一次发布来卸载较新的版本及其标记
`helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags={prod-canary} --set revision=canary -n istio-system | kubectl delete -f -`。
您必须按照上述卸载步骤卸载 Istio 的修订版。

如果您使用就地升级安装了此版本的网关，则还必须手动重新安装上一个版本的网关，
移除以前的版本及其标记不会自动恢复以前就地升级的网关。

### （可选）删除 Istio 安装的 CRD {#deleting-customer-resource-definition-installed}

永久删除 CRD 会移除您在集群中已创建的所有 Istio 资源。
用下面命令永久删除集群中安装的 Istio CRD：

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
{{< /text >}}
