---
title: 使用 Helm 安装
linktitle: 使用 Helm 安装
description: 安装、配置、并深入评估 Istio。
weight: 30
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
test: no
---

请跟随本指南一起，使用
 [Helm](https://helm.sh/docs/) 安装、配置、并深入评估 Istio 网格系统。
本指南用到的 Helm chart、以及使用 [Istioctl](/zh/docs/setup/install/istioctl/)、[Operator](/zh/docs/setup/install/operator/) 安装 Istio 时用到的 chart，它们都是相同的底层 chart。

## 安装步骤 {#installation-steps}

1. 为 Istio 组件，创建命名空间 `istio-system` :

    {{< text syntax=bash snip_id=create_istio_system_namespace >}}
    $ kubectl create namespace istio-system
    {{< /text >}}

1. 安装 Istio base chart，它包含了 Istio 控制平面用到的集群范围的资源：

    {{< warning >}}
    When performing a revisioned installation, the base chart requires the `--defaultRevision` value to be set for resource
    validation to function. More information on the `--defaultRevision` option can be found in the Helm upgrade documentation.
    {{< /warning >}}

    {{< text syntax=bash snip_id=install_base >}}
    $ helm install istio-base istio/base -n istio-system
    {{< /text >}}

1. 安装 Istio discovery chart，它用于部署 `istiod` 服务：

    {{< text syntax=bash snip_id=install_discovery >}}
    $ helm install istiod istio/istiod -n istio-system --wait
    {{< /text >}}

1. (可选项) 安装 Istio 的入站网关：

    {{< text syntax=bash snip_id=install_ingressgateway >}}
    $ kubectl create namespace istio-ingress
    $ kubectl label namespace istio-ingress istio-injection=enabled
    $ helm install istio-ingress istio/gateway -n istio-ingress --wait
    {{< /text >}}

    请参阅[安装网关](/zh/docs/setup/additional-setup/gateway/)以获得关于网关安装的深入文档。
    
{{< tip >}}
有关如何使用 Helm 后期渲染器自定义 Helm chart 的深入文档，
请参见[高级 Helm Chart 自定义](/zh/docs/setup/additional-setup/customize-installation-helm/)。
{{< /tip >}}

## 验证安装 {#verifying-the-installation}

安装状态可以通过Helm进行验证:

{{< text syntax=bash snip_id=none >}}
$ helm status istiod -n istio-system
{{< /text >}}

## 更新 Istio 配置 {#updating-your-configuration}

你可以用自己的安装参数，覆盖掉前面用到的 Istio Helm chart 的默认行为，
然后按照 Helm 升级流程来定制安装你的 Istio 网格系统。
至于可用的配置项，你可以通过使用 `helm show values istio/<chart>` 来找到配置。
例如：`helm show values istio/gateway`。

### 从非 Helm 安装迁移 {#migrating-from-non-helm-installations}

如果你需要将使用 `istioctl` 或 Operator 安装的 Istio 迁移到 Helm，
那要删除当前 Istio 控制平面资源，并根据上面的说明，使用 Helm 重新安装 Istio。
在删除当前 Istio 时，前外不能删掉 Istio 的客户资源定义（CRDs），以免丢掉你的定制 Istio 资源。

{{< warning >}}
建议：从集群中删除 Istio 前，使用上面的说明备份你的 Istio 资源。
{{< /warning >}}

依据你的安装方式，选择
[Istioctl 卸载指南](/zh/docs/setup/install/istioctl#uninstall-istio) 或
[Operator 卸载指南](/zh/docs/setup/install/operator/#uninstall)。

## 卸载 {#uninstall}

卸载前面安装的 chart，以便卸载 Istio 和它的各个组件。

1. 列出在命名空间 `istio-system` 中安装的所有 Istio chart：

    {{< text syntax=bash snip_id=helm_ls >}}
    $ helm ls -n istio-system
    NAME       NAMESPACE    REVISION UPDATED         STATUS   CHART        APP VERSION
    istio-base istio-system 1        ... ... ... ... deployed base-1.0.0   1.0.0
    istiod     istio-system 1        ... ... ... ... deployed istiod-1.0.0 1.0.0
    {{< /text >}}

1. (可选项) 删除 Istio 的入/出站网关 chart:

    {{< text syntax=bash snip_id=delete_delete_gateway_charts >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. 删除 Istio discovery chart:

    {{< text syntax=bash snip_id=helm_delete_discovery_chart >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. 删除 Istio base chart:

    {{< warning >}}
    通过 Helm 删除 chart 并不会级联删除它安装的定制资源定义（CRD）。
    {{< /warning >}}

    {{< text bash >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

1. 删除命名空间 `istio-system`：

    {{< text syntax=bash snip_id=delete_istio_system_namespace >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

## 卸载稳定的版本标签资源{#uninstall-stable-revision-label-resources}

如果你决定继续使用旧的控制平面不更新，您可以通过第一次发布来卸载较新的版本及其标记 `helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags={prod-canary} --set revision=canary -n istio-system | kubectl delete -f -`。你必须按照上面的卸载程序卸载Istio 的修订版。

如果您使用就地升级安装了此版本的网关，则还必须手动重新安装上一个版本的网关，删除以前的版本及其标记不会自动恢复以前已升级的网关。

### (可选项) 删除 Istio 安装的 CRD {#deleting-customer-resource-definition-installed}

永久删除 CRD， 会删除你在集群中创建的所有 Istio 资源。
用下面命令永久删除集群中安装的 Istio CRD：

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
{{< /text >}}
